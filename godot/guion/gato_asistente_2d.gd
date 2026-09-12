## Gato 2D de escritorio para SIGA (#92).
##
## Dibujo procedural: no depende de sprites ni de licencias externas. Su papel
## es equivalente al de un ayudante de escritorio: acompaña el mensaje, pero no
## añade controles ni modifica ninguna regla de juego.
class_name GatoAsistente2D
extends Control

const ANCHO := 92.0
const ALTO := 104.0


func _ready() -> void:
	custom_minimum_size = Vector2(ANCHO, ALTO)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var tinta := Color(0.12, 0.12, 0.14)
	var papel := Color(0.86, 0.87, 0.82)
	var sombra := Color(0.38, 0.39, 0.36)
	var ojo := Color(0.03, 0.03, 0.04)

	# Cabeza y orejas, deliberadamente geométricas para encajar con SIGA.
	draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(18, 35),
				Vector2(13, 8),
				Vector2(35, 24),
				Vector2(57, 24),
				Vector2(80, 8),
				Vector2(74, 36)
			]
		),
		papel
	)
	draw_circle(Vector2(46, 50), 31.0, papel)
	draw_arc(Vector2(46, 50), 31.0, 0.0, TAU, 32, tinta, 3.0)

	# Cara.
	draw_circle(Vector2(35, 47), 3.4, ojo)
	draw_circle(Vector2(57, 47), 3.4, ojo)
	draw_colored_polygon(
		PackedVector2Array([Vector2(42, 57), Vector2(50, 57), Vector2(46, 63)]), sombra
	)
	draw_line(Vector2(46, 63), Vector2(46, 69), tinta, 2.0)
	draw_line(Vector2(46, 67), Vector2(39, 72), tinta, 2.0)
	draw_line(Vector2(46, 67), Vector2(53, 72), tinta, 2.0)

	# Bigotes.
	for y in [58.0, 64.0, 70.0]:
		draw_line(Vector2(30, y), Vector2(7, y - 3.0), tinta, 2.0)
		draw_line(Vector2(62, y), Vector2(85, y - 3.0), tinta, 2.0)

	# Cuerpo mínimo y cola para que no se lea como icono suelto.
	draw_arc(Vector2(47, 105), 29.0, PI, TAU, 24, tinta, 4.0)
	draw_arc(Vector2(73, 88), 17.0, -0.4, 2.7, 18, tinta, 3.0)
