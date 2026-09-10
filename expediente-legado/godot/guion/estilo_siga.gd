## El aspecto de SIGA-98: un programa de escritorio de finales de los 90.
##
## Port de `legacy-theme.css`, donde el relieve eran `border-style: outset` e
## `inset`. Aquí se dibuja, porque un StyleBoxFlat solo admite UN color de
## borde y este bisel necesita dos: la luz arriba y a la izquierda, la sombra
## abajo y a la derecha. Invertir esos dos colores es toda la diferencia entre
## un botón que sobresale y un hueco donde va texto — el mismo vocabulario de
## relieve que usa la piel de los muros de la nave en el otro proyecto.
class_name EstiloSiga
extends RefCounted

const GRIS := Color("c0c0c0")           ## el gris de sistema de la época
const GRIS_CLARO := Color("dfdfdf")     ## la luz del bisel
const GRIS_OSCURO := Color("808080")    ## su sombra
const NEGRO := Color("000000")
const BLANCO := Color("ffffff")
const AZUL_TITULO := Color("000080")    ## la barra de título activa
const AZUL_ENLACE := Color("0000aa")
const AMARILLO_VISTO := Color("c8c800") ## una frase gatillo ya leída
const GRIS_TEXTO := Color("808080")

const GROSOR := 2


## Dibuja el bisel sobre un rectángulo. [param saliente] a false lo hunde.
static func dibujar_bisel(lienzo: CanvasItem, rect: Rect2, fondo: Color, saliente: bool) -> void:
	var luz := GRIS_CLARO if saliente else GRIS_OSCURO
	var sombra := GRIS_OSCURO if saliente else GRIS_CLARO
	lienzo.draw_rect(rect, fondo)
	for i in GROSOR:
		var d := float(i)
		# Arriba e izquierda.
		lienzo.draw_line(rect.position + Vector2(d, d),
			rect.position + Vector2(rect.size.x - d, d), luz)
		lienzo.draw_line(rect.position + Vector2(d, d),
			rect.position + Vector2(d, rect.size.y - d), luz)
		# Abajo y derecha.
		lienzo.draw_line(rect.position + Vector2(d, rect.size.y - 1.0 - d),
			rect.position + Vector2(rect.size.x - d, rect.size.y - 1.0 - d), sombra)
		lienzo.draw_line(rect.position + Vector2(rect.size.x - 1.0 - d, d),
			rect.position + Vector2(rect.size.x - 1.0 - d, rect.size.y - d), sombra)
