#!/usr/bin/env python3
"""Ejecuta importación, suite y arranque sin aceptar falsos verdes de Godot."""

import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

RAIZ = Path(__file__).resolve().parents[1]
RESUMEN = re.compile(r"^(\d+) pasadas, (\d+) fallos$", re.MULTILINE)
ERROR_GUION = re.compile(r"^(?:SCRIPT ERROR:|.*Parse Error:)", re.MULTILINE)
ERROR_MOTOR = re.compile(r"^ERROR:", re.MULTILINE)


def validar(salida, codigo, minimo=None, importando=False):
    """Godot puede imprimir errores y terminar con código cero."""
    if codigo != 0:
        raise ValueError(f"Godot terminó con código {codigo}")
    if ERROR_GUION.search(salida):
        raise ValueError("Godot registró un error de guion")
    # La primera importación puede avisar de traducciones todavía no generadas.
    # En la suite y el arranque ya deben existir TODOS los recursos.
    errores = ERROR_MOTOR.findall(salida)
    # La prueba de recuperación escribe JSON corrupto deliberadamente. Es el
    # único diagnóstico esperado en la suite, nunca en el arranque del juego.
    if minimo is not None:
        salida = re.sub(r"^ERROR: Parse JSON failed\.[^\n]*$", "", salida, flags=re.MULTILINE)
        errores = ERROR_MOTOR.findall(salida)
    if not importando and errores:
        raise ValueError("Godot registró un error de motor o recurso")
    if minimo is not None:
        resumenes = RESUMEN.findall(salida)
        if len(resumenes) != 1:
            raise ValueError("Falta el resumen único de la suite")
        pasadas, fallos = map(int, resumenes[0])
        if fallos or pasadas < minimo:
            raise ValueError(f"Suite incompleta: {pasadas} pasadas, {fallos} fallos; mínimo {minimo}")


def ejecutar():
    motor = os.environ.get("GODOT_BIN", "godot4")
    version = (RAIZ / ".godot-version").read_text().strip().replace("-", ".")
    actual = subprocess.run(
        [motor, "--version"], text=True, capture_output=True, check=True, timeout=15
    ).stdout.strip()
    if not actual.startswith(version + "."):
        raise ValueError(f"Se requiere Godot {version}; encontrado {actual}")
    minimo = int((RAIZ / "godot/pruebas/minimo.txt").read_text())
    if minimo <= 0:
        raise ValueError("El mínimo de comprobaciones debe ser positivo")
    with tempfile.TemporaryDirectory(prefix="legado-qa-") as temporal:
        entorno = os.environ.copy()
        entorno["LEGADO_PRUEBAS_AISLADAS"] = "1"
        # Las pruebas y el arranque nunca usan la partida real de quien verifica.
        for variable, carpeta in [("XDG_DATA_HOME", "datos"),
                                  ("XDG_CONFIG_HOME", "config"),
                                  ("XDG_CACHE_HOME", "cache")]:
            entorno[variable] = str(Path(temporal) / carpeta)
        etapas = [
            ("importación", ["--editor", "--import", "--quit"], 120, None),
            ("suite", ["--script", "pruebas/pruebas.gd"], 120, minimo),
            ("recorrido", ["--script", "pruebas/recorrido.gd"], 60, 72),
            ("arranque", ["--quit-after", "90"], 30, None),
        ]
        for nombre, argumentos, limite, suelo in etapas:
            print(f"\nGodot: {nombre}", flush=True)
            resultado = subprocess.run(
                [motor, "--headless", "--language", "es", "--path", str(RAIZ / "godot"),
                 *argumentos],
                env=entorno, text=True, stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT, timeout=limite, check=False,
            )
            print(resultado.stdout, flush=True)
            validar(resultado.stdout, resultado.returncode, suelo, nombre == "importación")


if __name__ == "__main__":
    try:
        ejecutar()
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        print(f"Validación Godot fallida: {error}", file=sys.stderr)
        sys.exit(1)
