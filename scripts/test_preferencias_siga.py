from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "godot" / "guion" / "preferencias_siga.gd"


class PreferenciasSigaTest(unittest.TestCase):
    def setUp(self):
        self.source = SOURCE.read_text(encoding="utf-8")

    def test_adaptador_y_persistencia_son_aislados(self):
        self.assertIn("class_name PreferenciasSiga", self.source)
        self.assertIn("extends RefCounted", self.source)
        for funcion in ("nuevas", "conflicto", "remapear", "aplicar", "guardar", "cargar"):
            self.assertIn(f"static func {funcion}", self.source)
        self.assertNotIn("Partida", self.source)

    def test_cubre_teclado_mando_y_conflictos(self):
        self.assertIn('"teclado"', self.source)
        self.assertIn('"mando"', self.source)
        self.assertIn('"motivo": "conflicto"', self.source)
        self.assertIn("InputMap.action_add_event", self.source)

    def test_guardado_es_atomico_y_preferencias_no_partida(self):
        self.assertIn('var temporal := ruta + ".nuevo"', self.source)
        self.assertIn("DirAccess.rename_absolute", self.source)
        self.assertIn('"reduccion_movimiento"', self.source)
        self.assertIn('"volumen"', self.source)


if __name__ == "__main__":
    unittest.main()
