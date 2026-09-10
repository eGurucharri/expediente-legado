## Los sitios del día, declarados.
##
## Uno por fase de `Jornada`. El motor de `Espacio3D` no conoce ninguno por su
## nombre: aquí solo hay medidas, bultos y a dónde lleva cada salida, así que
## añadir un sitio es una entrada más y no tocar el motor.
##
## Los bultos son cajas con nombre de mueble y nada más. Una mesa es una caja
## hasta que haya un asset con su ficha; llamarla mesa aquí es lo que permite
## sustituirla luego sin tocar la geografía.
class_name EspaciosCatalogo
extends RefCounted

const OFICINA := {
	"rotulo": "SIGA — Archivo, planta 4",
	"suelo": Vector2(14, 10),
	"color_suelo": Color(0.30, 0.29, 0.27),
	"color_muro": Color(0.58, 0.57, 0.52),
	"color_techo": Color(0.80, 0.80, 0.76),
	"entrada": Vector3(0, 0, 3),
	"bultos": [
		# Cuatro puestos idénticos: la planta es la misma para todos, que es
		# parte de lo que cuenta.
		{"pos": Vector3(-4, 0.37, -2), "tam": Vector3(2.0, 0.75, 1.0)},
		{"pos": Vector3(-4, 0.37, 1), "tam": Vector3(2.0, 0.75, 1.0)},
		{"pos": Vector3(1, 0.37, -2), "tam": Vector3(2.0, 0.75, 1.0)},
		{"pos": Vector3(1, 0.37, 1), "tam": Vector3(2.0, 0.75, 1.0)},
		# Archivadores contra el muro del fondo.
		{"pos": Vector3(5.5, 0.9, -4), "tam": Vector3(1.0, 1.8, 0.6),
			"color": Color(0.40, 0.39, 0.36)},
		{"pos": Vector3(5.5, 0.9, -2.5), "tam": Vector3(1.0, 1.8, 0.6),
			"color": Color(0.40, 0.39, 0.36)},
	],
	"salidas": [
		{"pos": Vector3(-6.4, 1.1, 3.5), "destino": "trayecto", "rotulo": "Salida"},
	],
}

const CALLE := {
	"rotulo": "De vuelta a casa",
	"suelo": Vector2(9, 34),
	"color_suelo": Color(0.22, 0.22, 0.23),
	"color_muro": Color(0.30, 0.29, 0.30),
	"color_techo": Color(0.10, 0.10, 0.13),
	"entrada": Vector3(0, 0, -15),
	"bultos": [
		{"pos": Vector3(-3.2, 1.4, -6), "tam": Vector3(1.2, 2.8, 4.0),
			"color": Color(0.26, 0.25, 0.26)},
		{"pos": Vector3(3.2, 1.4, 1), "tam": Vector3(1.2, 2.8, 6.0),
			"color": Color(0.26, 0.25, 0.26)},
		{"pos": Vector3(-3.2, 1.4, 8), "tam": Vector3(1.2, 2.8, 5.0),
			"color": Color(0.26, 0.25, 0.26)},
	],
	"salidas": [
		{"pos": Vector3(0, 1.1, 15.5), "destino": "casa", "rotulo": "Portal"},
	],
}

const CASA := {
	"rotulo": "Casa",
	"suelo": Vector2(8, 7),
	"color_suelo": Color(0.32, 0.27, 0.22),
	"color_muro": Color(0.52, 0.47, 0.42),
	# En casa la luz es de bombilla, no de fluorescente: más cálida y más floja.
	"color_techo": Color(0.62, 0.54, 0.42),
	"entrada": Vector3(0, 0, 2.5),
	"bultos": [
		# La cama, que es la salida del día.
		{"pos": Vector3(-2.4, 0.28, -2), "tam": Vector3(1.4, 0.55, 2.2),
			"color": Color(0.40, 0.33, 0.30)},
		{"pos": Vector3(2.6, 0.45, -2.4), "tam": Vector3(1.6, 0.9, 0.7),
			"color": Color(0.44, 0.38, 0.32)},
		# El cuenco del gato. Vacío mientras no se compre comida.
		{"pos": Vector3(2.8, 0.05, 1.5), "tam": Vector3(0.3, 0.1, 0.3),
			"color": Color(0.55, 0.50, 0.20)},
	],
	"salidas": [
		{"pos": Vector3(-2.4, 0.9, -2), "destino": "sueño", "rotulo": "Dormir",
			"tam": Vector3(1.6, 1.2, 2.4)},
	],
}

## El sueño NO está aquí, y esa ausencia es el issue #86.
##
## Los sitios del día son uno por fase y siempre el mismo. El sueño son tres
## escenas distintas cada noche, elegidas por lo que se leyó ese día, así que
## no se puede declarar: se compone. Vive en `Sueno` y en `SuenoFormas`, y
## quien pinta el día se lo pide en vez de buscarlo en esta tabla.


const POR_FASE := {
	"archivo": OFICINA,
	"trayecto": CALLE,
	"casa": CASA,
}


static func de_fase(fase: String) -> Dictionary:
	return POR_FASE.get(fase, OFICINA)
