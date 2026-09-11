## La entrada: lo primero que se ve de una vida laboral.
##
## Hasta ella el juego abría directamente en un expediente, sin decir quién
## eres, dónde estás ni qué es SIGA. Tiene que dejar tres cosas puestas antes de
## que nadie lea nada: que esto es una **copia restaurada** de un sistema de los
## noventa, que **tú eres el auditor** que la abre, y que **nadie más va a
## mirar** — lo último es el remate, y es lo que convierte el resto del juego en
## algo que ocurre sin testigos.
##
## Es 2D a propósito, al revés que el careo. El careo presenta a una persona y
## por eso necesita una sala y un contrapicado; aquí no hay a quién mirar: lo
## que arranca es un programa, y un programa de esta época se presenta como una
## pantalla que se enciende. No hay regla que diga qué momento va en qué medio
## —lo dice `Cinematica`— y esta es la mitad 2D de esa afirmación.
##
## **Se ve cada vuelta** (decisión de 2026-09-10). Cada vez que te reasignan
## vuelves a entrar por la puerta, y algo ha cambiado: la copia está un poco
## peor que la anterior. La repetición es el reloj del juego, que es lo que un
## juego de vueltas quiere. Lo que evita que canse no es verla menos, es que el
## reproductor la acorta solo a partir de la segunda vista (#67), así que a la
## quinta vuelta lo que queda es justo lo que ha cambiado.
class_name EntradaCinematica
extends RefCounted

## Con qué nombre lleva el reproductor la cuenta de veces vista.
const ID := "entrada"

## El usuario del jugador. No es un nombre inventado para esta cinemática: es el
## que el archivo ya usa —`auditor01` aparece en los expedientes, incluso en uno
## que lo lista como firmante autorizado desde 1958—. Escribir aquí otro nombre
## sería estrenar un segundo protagonista.
const USUARIO := "auditor01"

## Lo que dice el registro de restauración, una línea por vuelta. **La copia se
## degrada**: es la variación que pide la decisión de #68, y no es decorado —
## dice, sin decirlo, que cada vida laboral se archiva sobre la anterior.
##
## Se recorre por la cuenta de vistas, que ya es de por vida y no de la vuelta,
## así que esto no necesita ningún contador propio. La última se repite para
## siempre: quedarse sin líneas no puede dejar la pantalla muda, y una copia que
## ya no sabe cuántas veces se ha restaurado es el final honesto de la serie.
const REGISTRO_POR_VUELTA := [
	"ENTRADA_COPIA_INTEGRA",
	"ENTRADA_COPIA_SECTORES",
	"ENTRADA_COPIA_INDICES",
	"ENTRADA_COPIA_SIN_CUENTA",
]

## El gris de fósforo de un terminal de la época y el ámbar del testigo de la
## unidad de cinta. No salen de `EstiloSiga` porque no son el escritorio: son la
## pantalla de ANTES del escritorio, que es la que se ve mientras el sistema
## todavía no ha arrancado.
const FOSFORO := Color(0.72, 0.74, 0.70)
const TESTIGO := Color(0.85, 0.62, 0.22)
const APAGADO := Color(0.20, 0.21, 0.20)
## El bloque que todavía no se ha restaurado. Tiene que verse —si fuera del
## color del marco, la barra parecería más corta en vez de ir por la mitad.
const HUECO := Color(0.33, 0.34, 0.32)

## Cuántos bloques tiene la barra de la cinta, cuánto mide cada uno y cuántos
## van llenos.
##
## Va a MEDIAS y no entera: el reproductor mueve una figura, no la revela por
## partes, así que una barra con sus veinticuatro bloques puestos se lee como
## una restauración que ya ha terminado — que es lo contrario de lo que dice el
## plano. A medias, la misma figura quieta se lee como una en curso.
const BLOQUES := 24
const BLOQUE := Vector2(22, 26)
const BLOQUES_LLENOS := 15

## Por debajo de esto empieza el rótulo del reproductor, y una figura que baje
## más se le mete debajo. No es margen de gusto: en la primera versión la lista
## de usuarios acababa detrás de su propio rótulo.
const SUELO_FIGURA := 95.0


## El plano de rodaje de esta vuelta.
##
## [param vistas] es la cuenta que lleva el reproductor: elige la línea del
## registro y, aparte, es lo que hace que la cinemática se acorte sola. Los dos
## usos son del mismo dato a propósito — la copia se degrada al mismo ritmo al
## que la entrada se abrevia, así que lo que sobrevive del último plano es lo
## que peor está.
static func planos_de(vistas: int = 0) -> Array:
	return Cinematica.resolver(planos(vistas), {"usuario": USUARIO}, vistas)


## Los planos sin resolver. Aparte de `planos_de` para poder validarlos: un
## plano mal declarado tiene que reventar al construir el catálogo y no a mitad
## de la cinemática, donde se quedaría clavado y parecería un cuelgue.
static func planos(vistas: int = 0) -> Array:
	return [
		{
			# La unidad de cinta buscando. Un solo testigo encendido sobre negro:
			# antes de que haya nada que leer, lo único que hay es una máquina
			# haciendo ruido.
			"tipo": "2d",
			"nombre": "cinta",
			"figura": _testigo(),
			"desde": Vector2.ZERO,
			"hasta": Vector2.ZERO,
			"segundos": 2.0,
			"rotulo": "ENTRADA_RESTAURANDO",
			"voz": registro_de(vistas),
		},
		{
			# La barra que se llena. Va con bloques y no con una barra lisa
			# porque una barra lisa es de ahora: en esta máquina el progreso se
			# contaba en cuadrados que aparecen de golpe.
			"tipo": "2d",
			"nombre": "volcado",
			"figura": _barra(),
			"desde": Vector2.ZERO,
			"hasta": Vector2.ZERO,
			"segundos": 2.4,
			"rotulo": "ENTRADA_SISTEMA",
			"voz": "ENTRADA_VOZ_VOLUMEN",
		},
		{
			# Y quién lo está abriendo. La ficha entra desde la izquierda, que es
			# el gesto de algo que el sistema saca de un cajón.
			"tipo": "2d",
			"nombre": "acreditacion",
			"figura": _ficha(),
			"desde": Vector2(-420, 0),
			"hasta": Vector2.ZERO,
			"segundos": 2.2,
			"rotulo": "ENTRADA_AUDITOR",
			"voz": "ENTRADA_VOZ_TURNO",
		},
		{
			# El remate: nadie más tiene acceso a este volumen. Es la frase que
			# hay que conservar por muy vista que esté la cinemática, y por eso
			# va la última — el suelo del remate (`Cinematica.SUELO_REMATE`) es
			# más alto que el de los demás planos justo para esto.
			"tipo": "2d",
			"nombre": "solo",
			"figura": _solo(),
			"desde": Vector2.ZERO,
			"hasta": Vector2.ZERO,
			"segundos": 2.6,
			"rotulo": "ENTRADA_NADIE_MIRA",
			"voz": "ENTRADA_VOZ_SOLO",
		},
	]


## Qué dice el registro de restauración en esta vuelta. La serie se agota en su
## última línea en vez de dar la vuelta: volver a "copia íntegra" en la quinta
## vida laboral desharía lo único que esta variación afirma.
static func registro_de(vistas: int) -> String:
	var cual := clampi(vistas, 0, REGISTRO_POR_VUELTA.size() - 1)
	return REGISTRO_POR_VUELTA[cual]


# --- Las figuras ------------------------------------------------------------
#
# Rectángulos con color y nada más: el reproductor no sabe que está pintando una
# unidad de cinta, igual que no sabe que el careo le pasa una sala. Las
# coordenadas son relativas al centro de la pantalla, que es lo que
# `cinematica_app` les suma.


static func _testigo() -> Array:
	return [
		# El frontal de la unidad, y su testigo encendido a un lado.
		{"rect": Rect2(-180, -100, 360, 80), "color": APAGADO},
		{"rect": Rect2(-160, -74, 28, 28), "color": TESTIGO},
		# Las dos bobinas, que es lo que hace reconocible el trasto.
		{"rect": Rect2(-60, -84, 48, 48), "color": FOSFORO},
		{"rect": Rect2(40, -84, 48, 48), "color": FOSFORO},
	]


static func _barra() -> Array:
	var figura := [{"rect": Rect2(-280, -60, 560, 60), "color": APAGADO}]
	for i in BLOQUES:
		(
			figura
			. append(
				{
					"rect": Rect2(-268 + float(i) * BLOQUE.x, -43, BLOQUE.x - 4, BLOQUE.y),
					"color": FOSFORO if i < BLOQUES_LLENOS else HUECO,
				}
			)
		)
	return figura


static func _ficha() -> Array:
	return [
		# La tarjeta, su franja de datos y el hueco de la foto — vacío, porque
		# en este archivo la foto de un auditor tampoco consta.
		{"rect": Rect2(-210, -190, 420, 250), "color": FOSFORO},
		{"rect": Rect2(-190, -170, 120, 150), "color": APAGADO},
		{"rect": Rect2(-50, -170, 240, 22), "color": APAGADO},
		{"rect": Rect2(-50, -130, 190, 16), "color": APAGADO},
		{"rect": Rect2(-50, -102, 210, 16), "color": APAGADO},
		{"rect": Rect2(-190, -6, 380, 12), "color": TESTIGO},
	]


static func _solo() -> Array:
	# Una sola casilla marcada en una lista de usuarios con sitio para seis. Lo
	# que dice el plano no es que estés solo: es que la lista tiene dónde poner
	# a alguien más y no hay nadie más.
	var figura := []
	for i in 6:
		figura.append({"rect": Rect2(-240, -190 + float(i) * 46, 480, 28), "color": APAGADO})
	figura.append({"rect": Rect2(-240, -190, 480, 28), "color": FOSFORO})
	figura.append({"rect": Rect2(-268, -188, 20, 24), "color": TESTIGO})
	return figura
