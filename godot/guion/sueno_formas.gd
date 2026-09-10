## Las salas del sueño, declaradas.
##
## Pocas y GRANDES (#86): el sueño no es un laberinto de cuartos encadenados
## sino unos pocos sitios amplios y mal hechos donde uno se pierde de verdad.
## Por eso son cinco y no cincuenta, y por eso ninguna es un rectángulo — una
## sala rara no es una caja más grande, que es exactamente lo que `Espacio3D`
## sabía construir hasta ahora.
##
## Todo va en CELDAS de `Planta`. Nadie escribe aquí un muro ni una medida en
## metros: la geometría sale del contorno de los bloques, así que una forma es
## literalmente su silueta y no se puede quedar con un lado abierto.
##
## Lo que NO hay aquí es contenido. De qué está hecho un sueño —los documentos
## que leíste convertidos en salas, los sospechosos como figuras, las frases
## gatillo en las paredes— es #87, y meterlo antes de tiempo llenaría estas
## salas de cosas sin original detrás, que es justo lo que #79 prohíbe.
## La luz: el sueño es oscuro, pero un sitio que no se lee no da miedo, no se
## ve. Los tonos van bajos y sin saturar y aun así por encima del punto en el
## que una sala se convierte en una silueta negra — y el techo va CLARO por lo
## mismo que en la oficina: su cara de abajo está siempre en el mínimo, así que
## un techo oscuro no es oscuro, es un agujero encima de tu cabeza.
## Y el encuadre: se entra mirando hacia -z, que es a donde mira la cámara del
## caminante cuando no se la ha girado. Por eso las entradas están al fondo del
## eje largo de cada sala y no en cualquier celda de dentro: aparecer a dos
## metros de un muro convierte una nave en un armario hasta que giras.
class_name SuenoFormas
extends RefCounted

## Cuántas celdas tiene que medir una sala para contar como grande. Con la
## celda a dos metros son unos 240 m²: una nave, no un despacho.
const MINIMO_GRANDE := 60

const FORMAS := {
	# Dos naves cruzadas. Desde el centro se ven cuatro fondos y ninguno dice
	# nada; desde un brazo no se ve el resto.
	"crucero": {
		"rotulo": "SUENO_ROTULO",
		"bloques": [Rect2i(0, 5, 22, 6), Rect2i(8, 0, 6, 16)],
		"entrada": Vector2i(11, 14),
		"color_suelo": Color(0.26, 0.24, 0.30),
		"color_muro": Color(0.33, 0.30, 0.39),
		"color_techo": Color(0.19, 0.17, 0.22),
	},
	# Un anillo alrededor de un patio al que no se entra. Es la forma que
	# justifica el issue entero: sus cuatro muros de dentro no los declara
	# nadie, salen de que el patio también es contorno.
	"patio": {
		"rotulo": "SUENO_ROTULO",
		"bloques": [
			Rect2i(0, 0, 18, 3), Rect2i(0, 15, 18, 3),
			Rect2i(0, 0, 3, 18), Rect2i(15, 0, 3, 18),
		],
		"entrada": Vector2i(1, 16),
		"color_suelo": Color(0.28, 0.27, 0.26),
		"color_muro": Color(0.35, 0.34, 0.32),
		"color_techo": Color(0.17, 0.16, 0.15),
	},
	# El archivo, si el archivo fuera infinito a lo ancho: un pasillo larguísimo
	# con estanterías que son salas.
	"peine": {
		"rotulo": "SUENO_ROTULO",
		"bloques": [
			Rect2i(0, 0, 26, 4),
			Rect2i(2, 4, 4, 9), Rect2i(11, 4, 4, 9), Rect2i(20, 4, 4, 9),
		],
		"entrada": Vector2i(3, 11),
		"color_suelo": Color(0.27, 0.24, 0.20),
		"color_muro": Color(0.37, 0.33, 0.27),
		"color_techo": Color(0.19, 0.17, 0.13),
	},
	# Salas que se desbordan una en otra en diagonal. Se anda siempre torcido.
	"escalera": {
		"rotulo": "SUENO_ROTULO",
		"bloques": [Rect2i(0, 0, 10, 6), Rect2i(7, 5, 10, 6), Rect2i(14, 10, 10, 6)],
		"entrada": Vector2i(15, 14),
		"color_suelo": Color(0.20, 0.24, 0.28),
		"color_muro": Color(0.27, 0.32, 0.37),
		"color_techo": Color(0.14, 0.17, 0.19),
	},
	# Una nave enorme que se estrecha hasta un cuello y se vuelve a abrir. Se
	# ve el final desde el principio y aun así hay que rodear.
	"embudo": {
		"rotulo": "SUENO_ROTULO",
		"bloques": [Rect2i(0, 0, 16, 9), Rect2i(6, 9, 4, 4), Rect2i(2, 13, 12, 7)],
		"entrada": Vector2i(8, 18),
		"color_suelo": Color(0.30, 0.23, 0.23),
		"color_muro": Color(0.37, 0.27, 0.27),
		"color_techo": Color(0.18, 0.13, 0.13),
	},
}


static func ids() -> Array:
	var lista := FORMAS.keys()
	lista.sort()
	return lista


static func de(id: String) -> Dictionary:
	return FORMAS.get(id, FORMAS[ids()[0]])
