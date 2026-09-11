## Entrada al sueño: la casa sigue reconocible mientras deja de serlo.
##
## La noche, el mapa y la primera sala ya están calculados cuando esta pieza se
## reproduce. Aquí no se elige contenido ni se modifica la jornada: solo se
## representa el cambio de género entre casa y sueño.
class_name EntradaSuenoCinematica
extends RefCounted

const ID := "entrada-sueno"

const CASA := Color("77736b")
const PAPEL := Color("dedbd2")
const TINTA := Color("3e3e42")
const SOMBRA := Color("29282b")
const UMBRAL := Color("5b5660")


## El único dato variable es un folio que YA fue leído ese día. Si no hay
## ninguno, la misma transición funciona sin inventar contenido de relleno.
## Todos los planos son estáticos: comunica lo mismo con movimiento reducido.
static func planos_de(folios_leidos: Array, vistas: int = 0) -> Array:
	var rodaje := Cinematica.resolver(_planos(), {}, vistas)
	if not folios_leidos.is_empty():
		rodaje[1]["rotulo"] = str(folios_leidos[0])
	return rodaje


static func _planos() -> Array:
	return [
		{
			"tipo": "2d",
			"segundos": 0.85,
			"figura": _habitacion(),
			"desde": Vector2.ZERO,
			"hasta": Vector2.ZERO,
		},
		{
			"tipo": "2d",
			"segundos": 0.9,
			"figura": _habitacion_alterada(),
			"desde": Vector2.ZERO,
			"hasta": Vector2.ZERO,
		},
		{
			"tipo": "2d",
			"segundos": 1.0,
			"figura": _umbral(),
			"desde": Vector2.ZERO,
			"hasta": Vector2.ZERO,
		},
	]


static func _habitacion() -> Array:
	return [
		{"rect": Rect2(-190, 70, 380, 28), "color": CASA},
		{"rect": Rect2(-142, 6, 176, 64), "color": CASA},
		{"rect": Rect2(-126, -8, 62, 14), "color": PAPEL},
		{"rect": Rect2(92, -92, 66, 92), "color": SOMBRA},
	]


## La composición sigue siendo la casa; lo que no encaja es el expediente que
## aparece donde antes solo había dormitorio. Su identificador se rotula aparte
## y procede de `leido_hoy`.
static func _habitacion_alterada() -> Array:
	var figura := _habitacion()
	(
		figura
		. append_array(
			[
				{"rect": Rect2(-42, -108, 116, 78), "color": PAPEL},
				{"rect": Rect2(-28, -88, 82, 7), "color": TINTA},
				{"rect": Rect2(-28, -66, 58, 7), "color": TINTA},
			]
		)
	)
	return figura


static func _umbral() -> Array:
	return [
		{"rect": Rect2(-210, -130, 420, 260), "color": SOMBRA},
		{"rect": Rect2(-88, -118, 176, 236), "color": UMBRAL},
		{"rect": Rect2(-54, -82, 108, 164), "color": TINTA},
		{"rect": Rect2(-18, -22, 36, 44), "color": PAPEL},
	]
