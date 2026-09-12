## Bajada de la planta 4 al portal.
##
## No cambia de fase, no ficha y no calcula nómina: recibe el tránsito ya
## resuelto por el día y solo pone cuerpo visual a esos segundos entre archivo
## y calle. El reproductor común se ocupa de skip, reducción de movimiento y
## acortado progresivo.
class_name AscensorCinematica
extends RefCounted

const ID := "ascensor-bajada"

const CABINA := Color("48494c")
const PUERTA := Color("6c6d70")
const HUECO := Color("17181a")
const PANEL := Color("27282b")
const LUZ := Color("c48a43")
const APAGADA := Color("55565a")


static func planos_de(vistas: int = 0) -> Array:
	return Cinematica.resolver(_planos(), {}, vistas)


static func _planos() -> Array:
	return [
		{
			"tipo": "2d",
			"nombre": "planta-4",
			"segundos": 1.1,
			"figura": _cabina(4, false),
			"desde": Vector2.ZERO,
			"hasta": Vector2.ZERO,
		},
		{
			"tipo": "2d",
			"nombre": "bajada",
			"segundos": 1.1,
			"figura": _cabina(2, false),
			"desde": Vector2(0, -14),
			"hasta": Vector2(0, 14),
		},
		{
			"tipo": "2d",
			"nombre": "portal",
			"segundos": 0.9,
			"figura": _cabina(0, true),
			"desde": Vector2.ZERO,
			"hasta": Vector2.ZERO,
		},
	]


## La planta no se escribe como texto: el panel tiene cinco posiciones y la
## luz activa baja de la cuarta al portal. Así la escena sigue siendo legible
## aunque el idioma cambie y no duplica un rótulo permanente.
static func _cabina(planta: int, abierta: bool) -> Array:
	var figura := [
		{"rect": Rect2(-230, -180, 460, 300), "color": CABINA},
		{"rect": Rect2(-205, -155, 410, 250), "color": HUECO},
		{"rect": Rect2(145, -145, 42, 205), "color": PANEL},
	]
	if abierta:
		(
			figura
			. append_array(
				[
					{"rect": Rect2(-205, -155, 92, 250), "color": PUERTA},
					{"rect": Rect2(113, -155, 92, 250), "color": PUERTA},
				]
			)
		)
	else:
		(
			figura
			. append_array(
				[
					{"rect": Rect2(-205, -155, 203, 250), "color": PUERTA},
					{"rect": Rect2(2, -155, 203, 250), "color": PUERTA},
				]
			)
		)

	var activa := clampi(4 - planta, 0, 4)
	for i in 5:
		(
			figura
			. append(
				{
					"rect": Rect2(156, -126 + float(i) * 35.0, 20, 20),
					"color": LUZ if i == activa else APAGADA,
				}
			)
		)
	return figura
