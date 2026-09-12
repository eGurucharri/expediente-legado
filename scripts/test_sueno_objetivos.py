from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
REGLA = ROOT / "godot" / "guion" / "sueno_objetivos.gd"
CAPA = ROOT / "godot" / "guion" / "dia_objetivos_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"


class SuenoObjetivosTest(unittest.TestCase):
    def setUp(self):
        self.regla = REGLA.read_text(encoding="utf-8")
        self.capa = CAPA.read_text(encoding="utf-8")
        self.escena = ESCENA.read_text(encoding="utf-8")

    def test_vertical_tres_objetivos_dos_requeridos(self):
        self.assertIn("POSIBLES_PRIMER_CORTE := 3", self.regla)
        self.assertIn("REQUERIDOS_PRIMER_CORTE := 2", self.regla)
        self.assertIn('"completados": []', self.regla)
        self.assertIn('completados.has(id)', self.regla)
        self.assertIn('estado["resuelto"] = true', self.regla)

    def test_el_sueno_ya_no_monta_la_salida_como_progreso_normal(self):
        self.assertIn('espacio["salidas"] = []', self.capa)
        self.assertIn("_montar_objetivos_sueno", self.capa)
        self.assertIn('zona.set_meta("objetivo"', self.capa)
        self.assertIn("_al_pisar_objetivo", self.capa)

    def test_segundo_objetivo_resuelve_y_transiciona(self):
        self.assertIn("SuenoObjetivos.resuelto(estado)", self.capa)
        self.assertIn('jornada["sueno_escenas"].pop_front()', self.capa)
        self.assertIn("Jornada.despertar(jornada)", self.capa)
        self.assertIn('_entrar_en(destino)', self.capa)

    def test_el_gato_apunta_a_objetivo_y_no_a_puerta(self):
        self.assertIn('_salida_guia = _objetivos_espacio[0]["pos"]', self.capa)
        self.assertIn("_hay_rumbo_guia = true", self.capa)

    def test_la_escena_activa_la_capa_nueva(self):
        self.assertIn('path="res://guion/dia_objetivos_app.gd"', self.escena)


if __name__ == "__main__":
    unittest.main()
