"""Regresiones de CI: una suite rota nunca puede pasar por cero fallos."""

import unittest

from verificar_godot import validar


class ValidacionGodotTest(unittest.TestCase):
    def test_suite_completa_y_creciente(self):
        for total in (376, 400):
            validar(f"{total} pasadas, 0 fallos\n", 0, 376)

    def test_rechaza_falsos_verdes(self):
        for salida in (
            "375 pasadas, 0 fallos\n",
            "376 pasadas, 1 fallos\n",
            "SCRIPT ERROR: Invalid operands\n376 pasadas, 0 fallos\n",
            "ERROR: Failed loading resource\n376 pasadas, 0 fallos\n",
            "Godot arrancó pero no ejecutó la suite\n",
            "376 pasadas, 0 fallos\n376 pasadas, 0 fallos\n",
        ):
            with self.subTest(salida=salida), self.assertRaises(ValueError):
                validar(salida, 0, 376)

    def test_rechaza_codigo_de_salida(self):
        with self.assertRaises(ValueError):
            validar("376 pasadas, 0 fallos\n", 1, 376)

    def test_importacion_no_oculta_errores_de_guion(self):
        validar("ERROR: Traducción pendiente de importar\n", 0, importando=True)
        with self.assertRaises(ValueError):
            validar("SCRIPT ERROR: Parse Error: guion roto\n", 0, importando=True)

    def test_arranque_no_admite_recursos_rotos(self):
        validar("Godot Engine\n", 0)
        with self.assertRaises(ValueError):
            validar("ERROR: Failed loading resource\n", 0)

    def test_json_corrupto_solo_se_espera_en_la_suite(self):
        error = "ERROR: Parse JSON failed. Error at line 0: Expected key\n"
        validar(error + "376 pasadas, 0 fallos\n", 0, 376)
        with self.assertRaises(ValueError):
            validar(error, 0)


if __name__ == "__main__":
    unittest.main()
