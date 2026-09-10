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

## Nombra a una jugada = está diciéndote qué hacer. La prueba usa esta lista
## para recorrer todo lo que puede decir.
const PALABRAS_PROHIBIDAS := ["Objeción", "objeción", "Silencio", "silencio",
	"Insistencia", "insistencia"]

const AL_LLEGAR := [
	"¿Es el careo? Uy. A ese yo no le habría acusado un lunes.",
	"Espera que me traigo la silla.",
	"Yo tuve uno igual en el 96. Bueno, igual no. Parecido.",
	"¿Has puesto el asunto en mayúsculas? Es que si no, no consta.",
	"Yo esto lo veo desde aquí, que si me ven implicado me toca declarar.",
]

const AL_GANAR_RONDA := [
	"Suerte. Una vez, ¿eh? Pero suerte.",
	"Eso yo lo hacía todos los días antes de que lo digitalizaran.",
	"Claro, es que le has pillado con el turno cambiado.",
	"Bien, bien. Aunque yo habría ido por lo civil.",
]

const AL_PERDER_RONDA := [
	"Uy. Eso te lo iba a decir.",
	"Ya. Es que ahí tenías que haber hecho lo otro.",
	"A mí me pasó igual. Bueno, a mí no, a uno de contabilidad.",
	"No pasa nada, hombre. Bueno, sí pasa, pero no pasa nada.",
	"Es que has ido de frente. Con estos nunca de frente.",
]

const AL_EMPATAR := [
	"Esto puede durar años. Literalmente. Yo he visto uno de nueve.",
	"Mira, así por lo menos no consta nada.",
	"¿Bajamos luego a por café? Digo cuando acabe esto.",
]

const AL_GASTAR_HABILIDAD := [
	"Eso lo quitaron en la reforma. Bueno, o lo pusieron. Alguna de las dos.",
	"¿Y eso se puede? Yo pregunto.",
	"Anda, si funciona. Pues nada.",
]

const AL_VENCER := [
	"Bueno, bueno. Ya te vale, ya.",
	"Enhorabuena. Ahora te toca el papeleo, que es lo gordo.",
	"Yo lo habría cerrado el martes, pero oye, cada uno.",
]

const AL_CAER := [
	"Es que se lo has puesto muy fácil.",
	"Bueno. Tampoco es para tanto. A ver, sí lo es.",
	"Yo de ti no volvía a intentarlo hasta el jueves.",
	"¿Ves? Por ir de frente.",
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


## Lo que dice en un momento dado. [param azar] es el mismo generador del
## combate: el cuñado es ambiente y no debe tener su propia suerte.
static func comentario(momento: String, azar: Callable) -> String:
	var frases: Array = POR_MOMENTO.get(momento, [])
	if frases.is_empty():
		return ""
	return frases[int(azar.call() * frases.size()) % frases.size()]


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
		todas.append_array(POR_MOMENTO[momento])
	return todas
