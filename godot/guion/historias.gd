## Las ocho historias políticas de las cartas ocultas.
##
## Encontrar una carta escondida en un documento abre un relato con cuatro
## salidas, una por eje. Lo que se elige hace tres cosas a la vez, y por eso
## este módulo es la bisagra de media capa de Prometeo:
##
## - **cuenta para el final político** (`Prometeo.eje_ganador`);
## - **da una carga de habilidad** para el combate, con tope de dos — la
##   partida política ES el equipamiento, sin pantalla de asignación;
## - **deja una secuela**, que apunta a una pista real todavía por descubrir si
##   la elección era la útil para ese expediente, o a una pista falsa si no.
##
## La corrección es POR SITUACIÓN y no por ideología: cada eje es útil en
## exactamente cuatro de las ocho cartas (invariante probada en
## `Prometeo.UTILIDAD_CARTAS`). Sin eso, el juego estaría diciendo cuál es la
## ideología buena — y eso sí sería moralizar.
class_name Historias
extends RefCounted

const CATALOGO := "res://datos/prometeo.json"

## Tope de cargas por eje. Elegir el mismo eje ocho veces no da ocho usos: dos
## es el techo, así que la ventaja de casarse con una ideología se agota.
const TOPE_CARGAS := 2

## Qué hace cada habilidad dentro de una ronda. Ninguna es un bonus pasivo:
## todas son una decisión que se gasta.
const HABILIDADES := {
	"comunismo": {
		"nombre": "Asamblea",
		"efecto": "Esta ronda, el empate también golpea al rival.",
	},
	"centrista": {
		"nombre": "Mesa de diálogo",
		"efecto": "Esta ronda nadie pierde vida.",
	},
	"socialdemocrata": {
		"nombre": "Comisión de seguimiento",
		"efecto": "Revela la réplica que viene.",
	},
	"neoliberal": {
		"nombre": "Externalizar",
		"efecto": "Esta ronda el daño cuenta doble, gane quien gane.",
	},
}

var catalogo: Dictionary = {}


func cargar(ruta: String = CATALOGO) -> bool:
	var fichero := FileAccess.open(ruta, FileAccess.READ)
	if fichero == null:
		push_error("No se pudo abrir %s" % ruta)
		return false
	var crudo = JSON.parse_string(fichero.get_as_text())
	fichero.close()
	if typeof(crudo) != TYPE_DICTIONARY:
		return false
	catalogo = crudo.get("historias", {})
	return not catalogo.is_empty()


func de(carta_id: String) -> Dictionary:
	return catalogo.get(carta_id, {})


## Qué enseñar al abrir una carta: sus cuatro opciones si está sin resolver, o
## su secuela si ya se decidió. Una historia no se vuelve a preguntar — la
## decisión política de una partida se toma una vez.
func vista(estado: Dictionary, carta_id: String) -> Dictionary:
	var historia := de(carta_id)
	if historia.is_empty():
		return {}

	var elegido = estado.get("historias_cartas", {}).get(carta_id)
	if elegido == null:
		return {
			"estado": "pendiente",
			"texto": historia["texto"],
			"opciones": historia["opciones"],
		}
	return {
		"estado": "resuelta",
		"texto": historia["texto"],
		"eje": elegido,
		"clasificacion": Prometeo.clasificar_eleccion(carta_id, elegido),
		"secuela": _secuela(historia, carta_id, elegido),
	}


## Registra la elección y devuelve lo que hay que contar. Muta el estado: la
## decisión es de la partida, no de la pantalla que la pregunta.
##
## Una historia ya resuelta NO se sobrescribe. En el original la asignación era
## incondicional y solo la interfaz impedía volver a preguntar, así que el
## primer sitio que llamara sin comprobarlo antes habría dejado cambiar el voto
## — y con él las cargas y el final.
func resolver(estado: Dictionary, carta_id: String, eje: String) -> Dictionary:
	var historia := de(carta_id)
	if historia.is_empty():
		return {}

	var historias: Dictionary = estado.get("historias_cartas", {})
	if not historias.has(carta_id):
		historias[carta_id] = eje
		estado["historias_cartas"] = historias

	return vista(estado, carta_id)


## Las cargas de habilidad disponibles, por eje.
func cargas(estado: Dictionary) -> Dictionary:
	var puntos := Prometeo.puntos_por_eje(
		estado.get("historias_cartas", {}), catalogo.keys())
	var disponibles := {}
	for eje in Prometeo.EJES:
		disponibles[eje] = mini(TOPE_CARGAS, puntos[eje])
	return disponibles


## Cuántas historias quedan por decidir. El final político no llega hasta que
## se han resuelto las ocho.
func pendientes(estado: Dictionary) -> int:
	var resueltas: Dictionary = estado.get("historias_cartas", {})
	var quedan := 0
	for id in catalogo:
		if not resueltas.has(id):
			quedan += 1
	return quedan


func _secuela(historia: Dictionary, carta_id: String, eje: String) -> String:
	return historia["secuelaUtil"] \
		if Prometeo.clasificar_eleccion(carta_id, eje) == "pista" \
		else historia["secuelaConfusion"]
