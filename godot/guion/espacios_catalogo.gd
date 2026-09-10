## Los sitios del día, declarados.
##
## Uno por fase de `Jornada`. El motor de `Espacio3D` no conoce ninguno por su
## nombre: aquí solo hay medidas, bultos y a dónde lleva cada salida, así que
## añadir un sitio es una entrada más y no tocar el motor.
##
## Los rótulos son CLAVES de traducción, no texto: el texto vive en
## `datos/textos.csv` y lo resuelve quien lo pinta.
##
## Los bultos son cajas con nombre de mueble y nada más. Una mesa es una caja
## hasta que haya un asset con su ficha; llamarla mesa aquí es lo que permite
## sustituirla luego sin tocar la geografía.
class_name EspaciosCatalogo
extends RefCounted

const OFICINA := {
	"rotulo": "SITIO_OFICINA",
	"suelo": Vector2(14, 10),
	"color_suelo": Color(0.30, 0.29, 0.27),
	"color_muro": Color(0.58, 0.57, 0.52),
	"color_techo": Color(0.80, 0.80, 0.76),
	"textura_suelo": "linoleo",
	"textura_muro": "gotele",
	"textura_techo": "techo",
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
	# La luz del archivo es de fluorescente: fría, plana y de más, que es lo
	# que hace que a las tres de la tarde no se sepa qué hora es.
	"ambiente": Color(0.42, 0.43, 0.45),
	"ambiente_energia": 0.55,
	"sol": 0.25,
	"luces": [
		{"pos": Vector3(-4, 2.65, -2), "color": Color(0.86, 0.90, 0.92), "energia": 2.2},
		{"pos": Vector3(-4, 2.65, 2), "color": Color(0.86, 0.90, 0.92), "energia": 2.2},
		{"pos": Vector3(2, 2.65, -2), "color": Color(0.86, 0.90, 0.92), "energia": 2.2},
		{"pos": Vector3(2, 2.65, 2), "color": Color(0.86, 0.90, 0.92), "energia": 2.2},
		# El que parpadea no existe todavía; cuando exista, es una entrada más.
		{"pos": Vector3(5.5, 2.65, 0), "color": Color(0.86, 0.90, 0.92), "energia": 1.6},
	],
	# Uno en su puesto y otro en el de al lado, que no es suyo y también humea.
	"cigarros": [Vector3(-3.3, 0.76, 1.2), Vector3(1.4, 0.76, -2.1)],
	"salidas": [
		{"pos": Vector3(-6.4, 1.1, 3.5), "destino": "trayecto", "rotulo": "SALIDA_OFICINA"},
		# El puesto de trabajo. No lleva a una fase del día: abre una PANTALLA,
		# y se entra en ella pisando el sitio donde se trabaja — igual que se
		# ficha saliendo por la puerta. Un botón flotante diría que el archivo
		# es un menú; el puesto dice que es un sitio.
		{"pos": Vector3(-4, 1.1, 1), "destino": "expediente", "rotulo": "SALIDA_PUESTO",
			"tam": Vector3(2.4, 2.2, 2.2)},
	],
}

const CALLE := {
	"rotulo": "SITIO_CALLE",
	"suelo": Vector2(9, 34),
	"color_suelo": Color(0.22, 0.22, 0.23),
	"color_muro": Color(0.30, 0.29, 0.30),
	"color_techo": Color(0.10, 0.10, 0.13),
	"textura_suelo": "asfalto",
	"textura_muro": "gotele",
	"entrada": Vector3(0, 0, -15),
	# Se entra por un extremo y el portal está en el otro: hay que mirar hacia
	# donde se anda.
	"mirada": 180.0,
	"bultos": [
		{"pos": Vector3(-3.2, 1.4, -6), "tam": Vector3(1.2, 2.8, 4.0),
			"color": Color(0.26, 0.25, 0.26)},
		{"pos": Vector3(3.2, 1.4, 1), "tam": Vector3(1.2, 2.8, 6.0),
			"color": Color(0.26, 0.25, 0.26)},
		{"pos": Vector3(-3.2, 1.4, 8), "tam": Vector3(1.2, 2.8, 5.0),
			"color": Color(0.26, 0.25, 0.26)},
	],
	"ambiente": Color(0.16, 0.17, 0.22),
	"ambiente_energia": 0.35,
	"sol": 0.08,
	# Farolas de sodio: naranjas, separadas, y con oscuridad de verdad entre
	# una y otra. Es lo que hace que la calle se ande y no se cruce.
	"luces": [
		{"pos": Vector3(0, 2.6, -10), "color": Color(1.0, 0.72, 0.38), "energia": 3.0,
			"alcance": 11.0, "tam": Vector3(0.5, 0.12, 0.5)},
		{"pos": Vector3(0, 2.6, 0), "color": Color(1.0, 0.72, 0.38), "energia": 3.0,
			"alcance": 11.0, "tam": Vector3(0.5, 0.12, 0.5)},
		{"pos": Vector3(0, 2.6, 10), "color": Color(1.0, 0.72, 0.38), "energia": 3.0,
			"alcance": 11.0, "tam": Vector3(0.5, 0.12, 0.5)},
	],
	"salidas": [
		{"pos": Vector3(0, 1.1, 15.5), "destino": "casa", "rotulo": "SALIDA_PORTAL"},
	],
}

const CASA := {
	"rotulo": "SITIO_CASA",
	"suelo": Vector2(8, 7),
	"color_suelo": Color(0.32, 0.27, 0.22),
	"color_muro": Color(0.52, 0.47, 0.42),
	# En casa la luz es de bombilla, no de fluorescente: más cálida y más floja.
	"color_techo": Color(0.62, 0.54, 0.42),
	"textura_suelo": "moqueta",
	"textura_muro": "gotele",
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
	"ambiente": Color(0.30, 0.26, 0.22),
	"ambiente_energia": 0.45,
	"sol": 0.10,
	# Una bombilla. No hay más luz en casa, y eso es parte de lo que se cuenta.
	"luces": [
		{"pos": Vector3(0, 2.5, 0), "color": Color(1.0, 0.84, 0.62), "energia": 2.6,
			"alcance": 9.0, "tam": Vector3(0.22, 0.22, 0.22)},
	],
	# El de casa está en la mesa, encendido y solo. Nadie lo ha apagado.
	"cigarros": [Vector3(2.6, 0.91, -2.4)],
	"salidas": [
		{"pos": Vector3(-2.4, 0.9, -2), "destino": "sueño", "rotulo": "SALIDA_DORMIR",
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
