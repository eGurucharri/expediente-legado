## La entrada del acusado: una cinemática de juego de acción para presentar a
## un comité de archivo.
##
## El chiste no es que quede épico por error. Es que **el sistema se toma a sí
## mismo exactamente así de en serio**: la misma solemnidad con la que sella un
## documento por triplicado, aplicada a la persona a la que acabas de firmar una
## acusación. Por eso la cinemática se hace en serio —órbita lenta, contrapicado,
## rótulo con su cargo— y por eso hay un compañero apoyado en la mampara
## diciendo que él eso lo habría cerrado el martes (`Cunado`). Sin esa segunda
## voz sería una imitación; con ella es la broma.
##
## Una cinemática es DATOS: una lista de planos con su cámara y su duración. Ni
## este módulo ni el que la reproduce saben a quién están presentando, así que
## un acusado nuevo no toca nada — trae su nombre y su cargo y ya está.
class_name CareoCinematica
extends RefCounted

## Un plano dura lo que dura. Se pueden saltar todos, siempre: una cinemática
## que no se puede saltar es lo que hace que la segunda partida se juegue en
## silencio.
const PLANOS := [
	{
		# Contrapicado desde el suelo: la primera imagen del acusado es
		# mirándole desde abajo, que es como se mira a una instancia superior.
		"nombre": "contrapicado",
		"camara": Vector3(0.0, 0.35, 3.2),
		"mira": Vector3(0.0, 1.9, 0.0),
		"segundos": 1.6,
		"rotulo": "",
	},
	{
		# Órbita lenta. Lo que hay que ver es que no hay nada que ver: es un
		# bulto gris con un cargo.
		"nombre": "orbita",
		"camara": Vector3(2.8, 1.7, 2.0),
		"mira": Vector3(0.0, 1.4, 0.0),
		"segundos": 2.2,
		"rotulo": "{nombre}",
	},
	{
		# El cargo, que es lo que de verdad da miedo.
		"nombre": "cargo",
		"camara": Vector3(-1.6, 1.5, 2.4),
		"mira": Vector3(0.0, 1.5, 0.0),
		"segundos": 2.0,
		"rotulo": "{cargo}",
	},
	{
		# Y el corte a la altura de los ojos, que es donde empieza el careo.
		"nombre": "frente",
		"camara": Vector3(0.0, 1.6, 2.6),
		"mira": Vector3(0.0, 1.5, 0.0),
		"segundos": 1.2,
		"rotulo": "EXPEDIENTE {folio}",
	},
]

## Lo que se lee bajo el nombre cuando el acusado no tiene cargo escrito. No es
## un relleno: que no conste el cargo de alguien a quien estás acusando es
## exactamente el problema de este archivo.
const CARGO_POR_DEFECTO := "Cargo no consta en el expediente"


## El plano de rodaje ya resuelto para un acusado. Devuelve copias, así que
## reproducir una cinemática no puede estropear la siguiente.
static func planos_de(acusado: Dictionary, folio: String = "") -> Array:
	var nombre: String = acusado.get("nombre", "")
	var cargo: String = acusado.get("cargo", "")
	if cargo.is_empty():
		cargo = _cargo_deducido(acusado)

	var rodaje := []
	for plano in PLANOS:
		var copia: Dictionary = plano.duplicate(true)
		copia["rotulo"] = String(plano["rotulo"]) \
			.replace("{nombre}", nombre) \
			.replace("{cargo}", cargo) \
			.replace("{folio}", folio if not folio.is_empty() else "SIN NÚMERO")
		rodaje.append(copia)
	return rodaje


## Cuánto dura entera, para que quien la reproduzca pueda decirlo.
static func duracion(rodaje: Array) -> float:
	var total := 0.0
	for plano in rodaje:
		total += plano["segundos"]
	return total


## El cargo sale de la descripción que ya trae el sospechoso: su primera frase.
## Escribir un cargo aparte sería duplicar contenido que ya existe, y duplicado
## se desincroniza — el mismo motivo por el que el cartel de reglas del
## blackjack se deriva de las constantes del motor.
static func _cargo_deducido(acusado: Dictionary) -> String:
	var descripcion: String = acusado.get("descripcion", "")
	if descripcion.is_empty():
		return CARGO_POR_DEFECTO
	var punto := descripcion.find(".")
	var primera := descripcion.substr(0, punto) if punto > 0 else descripcion
	return primera.strip_edges().to_upper()
