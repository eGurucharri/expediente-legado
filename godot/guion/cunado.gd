## El compañero que se acerca a mirar.
##
## Aparece cuando empieza un careo y se queda comentando. Es la única voz del
## juego que no es el sistema, y su función es **desinflar**: la cinemática se
## toma el careo tan en serio como el sistema se toma a sí mismo, y hace falta
## alguien apoyado en la mampara diciendo que eso él lo habría cerrado el martes.
##
## La regla dura, y hay prueba que la exige: **el cuñado no da información**.
## Ni una de sus frases nombra una jugada, ni acierta lo que viene, ni dice qué
## deberías hacer. En cuanto una lo hiciera dejaría de ser un cuñado y pasaría a
## ser un sistema de pistas con acento — y este juego ya tiene un asistente que
## habla de más.
##
## Lo que sí hace es tener razón sobre cosas que no importan y equivocarse con
## aplomo sobre las que sí.
class_name Cunado
extends RefCounted

const AL_LLEGAR := [
	"CUNADO_LLEGADA_1",
	"CUNADO_LLEGADA_2",
	"CUNADO_LLEGADA_3",
	"CUNADO_LLEGADA_4",
	"CUNADO_LLEGADA_5",
]

const AL_GANAR_RONDA := [
	"CUNADO_GANA_1",
	"CUNADO_GANA_2",
	"CUNADO_GANA_3",
	"CUNADO_GANA_4",
]

const AL_PERDER_RONDA := [
	"CUNADO_PIERDE_1",
	"CUNADO_PIERDE_2",
	"CUNADO_PIERDE_3",
	"CUNADO_PIERDE_4",
	"CUNADO_PIERDE_5",
]

const AL_EMPATAR := [
	"CUNADO_EMPATE_1",
	"CUNADO_EMPATE_2",
	"CUNADO_EMPATE_3",
]

const AL_GASTAR_HABILIDAD := [
	"CUNADO_HABILIDAD_1",
	"CUNADO_HABILIDAD_2",
	"CUNADO_HABILIDAD_3",
]

const AL_VENCER := [
	"CUNADO_VICTORIA_1",
	"CUNADO_VICTORIA_2",
	"CUNADO_VICTORIA_3",
]

const AL_CAER := [
	"CUNADO_DERROTA_1",
	"CUNADO_DERROTA_2",
	"CUNADO_DERROTA_3",
	"CUNADO_DERROTA_4",
]

const POR_MOMENTO := {
	"llegada": AL_LLEGAR,
	"gana_jugador": AL_GANAR_RONDA,
	"gana_rival": AL_PERDER_RONDA,
	"empate": AL_EMPATAR,
	"habilidad": AL_GASTAR_HABILIDAD,
	"victoria": AL_VENCER,
	"derrota": AL_CAER,
}


## Nombrar una jugada = estar diciéndote qué hacer. La prueba usa esta lista
## para recorrer todo lo que puede decir.
##
## Se DERIVA de las jugadas que existen, no se copia al lado: una lista escrita
## a mano no falla, se desincroniza — el día que el combate estrene una cuarta
## jugada, el cuñado podría nombrarla sin que saltara nada. Es la misma regla
## del cartel de reglas que se deriva de las constantes del motor.
static func palabras_prohibidas() -> Array:
	var palabras := []
	for tipo in Combate.ETIQUETAS:
		var nombre := Combate.etiqueta(tipo)
		palabras.append(nombre)
		palabras.append(nombre.to_lower())
	return palabras


## Lo que dice en un momento dado. [param azar] es el mismo generador del
## combate: el cuñado es ambiente y no debe tener su propia suerte.
static func comentario(momento: String, azar: Callable) -> String:
	var frases: Array = POR_MOMENTO.get(momento, [])
	if frases.is_empty():
		return ""
	return TranslationServer.translate(frases[int(azar.call() * frases.size()) % frases.size()])


## Lo que comenta de una ronda, a partir de su crónica. Habla de la habilidad
## si se ha gastado una, porque es lo que un cuñado miraría; si no, del
## resultado.
static func sobre_ronda(ronda: Dictionary, azar: Callable) -> String:
	if not ronda.get("habilidad", "").is_empty():
		return comentario("habilidad", azar)
	return comentario(ronda.get("veredicto", ""), azar)


## Todo lo que puede llegar a decir. Existe para que la prueba pueda recorrerlo
## entero: una regla sobre lo que se dice solo vale si se comprueba sobre TODO
## lo que se puede decir, no sobre una muestra.
static func todas_las_frases() -> Array:
	var todas := []
	for momento in POR_MOMENTO:
		for clave in POR_MOMENTO[momento]:
			todas.append(TranslationServer.translate(clave))
	return todas
