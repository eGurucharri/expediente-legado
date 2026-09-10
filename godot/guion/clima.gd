## Qué tiempo hace hoy.
##
## Sale del NÚMERO DE DÍA y de nada más, así que no hay que guardarlo: recargar
## una partida devuelve el mismo cielo, y eso importa más de lo que parece —un
## tiempo sorteado al arrancar haría que el día que te acuerdas de que llovía
## amaneciera despejado—. Es la misma disciplina que la plantilla de compañeros,
## que se sortea una vez por vuelta y se queda.
##
## **El primer día está despejado, siempre.** No es un valor por defecto que
## resulta que cae ahí: está escrito. Y como `Jornada.reiniciar_vuelta` devuelve
## el día a 1, cada vida laboral nueva empieza con buen tiempo — que es una
## broma que se cuenta sola la tercera vez que te reasignan.
##
## Lo que el clima **no** hace es cambiar ninguna regla: no se cobra menos con
## lluvia ni se anda más despacio con nieve. Es la diferencia entre un día y
## otro en un trabajo donde todos los días son el mismo, y por eso es
## exactamente todo lo que tiene que ser.
class_name Clima
extends RefCounted

const DESPEJADO := "despejado"

## Cada tiempo con lo suyo: cómo tiñe la luz de un sitio al aire libre y qué
## cae del cielo. `particulas` vacío es que no cae nada — y no todos los tiempos
## traen algo: la niebla y el bochorno se ven en la luz y en nada más.
const TIEMPOS := {
	DESPEJADO:
	{
		"rotulo": "CLIMA_DESPEJADO",
		"ambiente": Color(0.34, 0.36, 0.44),
		"energia": 0.55,
		"sol": 0.30,
		"particulas": "",
	},
	"nublado":
	{
		"rotulo": "CLIMA_NUBLADO",
		"ambiente": Color(0.26, 0.27, 0.30),
		"energia": 0.42,
		"sol": 0.10,
		"particulas": "",
	},
	"lluvia":
	{
		"rotulo": "CLIMA_LLUVIA",
		"ambiente": Color(0.20, 0.23, 0.28),
		"energia": 0.38,
		"sol": 0.05,
		"particulas": "lluvia",
	},
	"niebla":
	{
		"rotulo": "CLIMA_NIEBLA",
		# La niebla no oscurece: LEVANTA el negro. Lo que hace es que no se vea
		# lejos, y en una calle de faroles eso se lee como un ambiente alto y un
		# sol bajo, no como una noche más cerrada.
		"ambiente": Color(0.33, 0.33, 0.34),
		"energia": 0.50,
		"sol": 0.04,
		"particulas": "",
	},
	"nieve":
	{
		"rotulo": "CLIMA_NIEVE",
		"ambiente": Color(0.38, 0.40, 0.46),
		"energia": 0.60,
		"sol": 0.12,
		"particulas": "nieve",
	},
}

## En qué orden se reparten los días a partir del segundo. Es una RUEDA y no un
## sorteo: con azar, tres días seguidos de lluvia son perfectamente posibles y
## se leen como que el clima está roto. Una rueda de cinco sobre un ciclo de
## trabajo hace además que el tiempo no case con la semana, que es lo que evita
## que el jugador aprenda «los martes llueve».
const RUEDA := ["nublado", "lluvia", "despejado", "niebla", "nieve", "nublado", "lluvia"]


## El tiempo del día [param dia]. El primero, despejado.
static func de_dia(dia: int) -> Dictionary:
	var cual := id_de_dia(dia)
	return TIEMPOS.get(cual, TIEMPOS[DESPEJADO])


## Solo el nombre, para quien no necesite la tabla entera.
static func id_de_dia(dia: int) -> String:
	if dia <= 1:
		return DESPEJADO
	return RUEDA[(dia - 2) % RUEDA.size()]


## Aplica el tiempo sobre la declaración de un sitio, y devuelve la copia.
##
## Solo toca los sitios que se declaran **al aire libre**: dentro de una oficina
## sin ventanas no se nota que llueve, y teñir el archivo de gris porque fuera
## hay nubes sería afirmar que se ve algo que no se ve. La calle lo declara; la
## oficina y la casa, no.
##
## En copia porque el catálogo es una constante: pintarle el tiempo encima
## dejaría el martes lloviendo para el resto de la partida.
static func vestir(espacio: Dictionary, dia: int) -> Dictionary:
	if not espacio.get("exterior", false):
		return espacio
	var tiempo := de_dia(dia)
	var vestido := espacio.duplicate(true)
	vestido["ambiente"] = tiempo["ambiente"]
	vestido["ambiente_energia"] = tiempo["energia"]
	vestido["sol"] = tiempo["sol"]
	if not tiempo["particulas"].is_empty():
		vestido["precipitacion"] = tiempo["particulas"]
	return vestido
