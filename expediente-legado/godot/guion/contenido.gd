## Carga los expedientes desde datos/casos.json.
##
## Sustituye a [code]DataSeeder[/code] y a los repositorios JPA: el contenido
## ya no es código, así que escribir un caso nuevo no es recompilar nada.
class_name Contenido
extends RefCounted

const RUTA := "res://datos/casos.json"

var casos: Array = []
var conceptos: Array = []

func cargar(ruta: String = RUTA) -> bool:
	var fichero := FileAccess.open(ruta, FileAccess.READ)
	if fichero == null:
		push_error("No se pudo abrir %s" % ruta)
		return false
	var crudo = JSON.parse_string(fichero.get_as_text())
	fichero.close()
	if typeof(crudo) != TYPE_DICTIONARY:
		push_error("%s no contiene un objeto JSON" % ruta)
		return false
	casos = crudo.get("casos", [])
	conceptos = crudo.get("conceptos", [])
	return true

## Los casos que cuentan para el final principal. El caso 8 está marcado como
## no principal en el contenido original.
func principales() -> Array:
	return casos.filter(func(c): return c.get("principal", true))

func caso(id: String) -> Dictionary:
	for c in casos:
		if c["id"] == id:
			return c
	return {}

## Los conceptos que el jugador ya conoce: los que tienen al menos una de sus
## pistas descubierta. Un concepto del que aún no se sabe nada no puede
## aparecer en el corcho ni presentarse en la Ventanilla.
func conceptos_desbloqueados(descubiertas: Array) -> Array:
	return conceptos.filter(func(c):
		return c.get("pistas", []).any(func(p): return descubiertas.has(p)))


## Quiénes pueden reclamar en la Ventanilla: personas y comités que el jugador
## ya conoce. Las empresas, lugares y documentos no se presentan a reclamar.
func reclamantes(descubiertas: Array) -> Array:
	return conceptos_desbloqueados(descubiertas).filter(
		func(c): return c["tipo"] in ["PERSONA", "COMITE"])


## Las pistas cuya frase gatillo vive en un registro dado.
func pistas_de_registro(un_caso: Dictionary, registro_id: String) -> Array:
	return un_caso.get("pistas", []).filter(
		func(p): return p.get("registroOrigen") == registro_id)
