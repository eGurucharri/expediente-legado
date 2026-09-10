## El reproductor común de cinemáticas.
##
## Es la respuesta a que el medio lo elija cada momento: si cada cinemática
## trajera su propio reproductor, diez momentos darían diez ritmos, diez
## rótulos y diez formas de saltar. Aquí sabe pintar planos 3D (mueve una
## cámara por el mundo que le den) y planos 2D (mueve figuras declaradas como
## rectángulos sobre un fondo), y aporta lo común: el rótulo, la voz, el salto
## y el acortado por repetición.
##
## No sabe qué cinemática está poniendo. Recibe planos ya resueltos y emite
## `terminada` cuando acaba o cuando la saltan — quien la pidió decide qué pasa
## después.
extends Node3D

signal terminada

## Avisa de en qué plano va. Existe para que una escena pueda colgar algo de un
## momento concreto —el compañero que se acerca en el segundo plano del careo—
## sin tener que llevar su propio reloj en paralelo, que es como se
## desincronizan las cosas.
signal plano_entrado(indice: int, plano: Dictionary)

## El mundo 3D sobre el que mover la cámara. Si es nulo, los planos 3D no
## tienen dónde ocurrir y se saltan: una cinemática 3D sin escena no es un
## fallo del reproductor, es una cinemática mal pedida.
var mundo: Node3D = null

var _rodaje: Array = []
var _plano := 0
var _transcurrido := 0.0
var _reproduciendo := false
var _id := ""
var _estado: Dictionary = {}

var _camara: Camera3D
var _lienzo: Control
var _rotulo: Label
var _voz: Label
var _fondo: ColorRect
var _figuras: Node2D
var _video: VideoStreamPlayer


func _ready() -> void:
	_montar()


## Pone una cinemática ya resuelta (ver `Cinematica.resolver`).
##
## Si se le dan [param id] y [param estado], **anota él mismo** que se ha visto,
## al terminar o al saltar. Podría hacerlo cada llamante, y por eso lo hace el
## reproductor: de diez sitios que tengan que acordarse, uno no se acuerda, y su
## cinemática se quedaría eterna mientras las otras nueve se acortan.
func reproducir(rodaje: Array, id: String = "", estado: Dictionary = {}) -> void:
	_id = id
	_estado = estado
	_rodaje = rodaje
	_plano = -1
	_reproduciendo = true
	visible = true
	_siguiente()


func saltar() -> void:
	if not _reproduciendo:
		return
	_terminar()


func _process(delta: float) -> void:
	if not _reproduciendo:
		return
	_transcurrido += delta
	var plano: Dictionary = _rodaje[_plano]
	var duracion: float = plano["segundos"]
	var avance: float = clampf(_transcurrido / duracion, 0.0, 1.0)

	match plano["tipo"]:
		"3d":
			_mover_camara(plano, avance)
		"2d":
			_figuras.queue_redraw()

	if _transcurrido >= duracion:
		_siguiente()


func _unhandled_input(evento: InputEvent) -> void:
	# Saltable siempre, con lo que sea. Una cinemática que no se puede saltar es
	# lo que hace que la segunda partida se juegue mirando a otro lado.
	if _reproduciendo and evento.is_pressed():
		saltar()


func _siguiente() -> void:
	_plano += 1
	_transcurrido = 0.0
	if _plano >= _rodaje.size():
		_terminar()
		return

	var plano: Dictionary = _rodaje[_plano]
	_rotulo.text = String(plano.get("rotulo", ""))
	_voz.text = String(plano.get("voz", ""))
	# Un rótulo largo es una frase y quiere cuerpo menor; uno corto es un
	# nombre y quiere presencia.
	_rotulo.add_theme_font_size_override("font_size", 34 if _rotulo.text.length() > 28 else 48)

	plano_entrado.emit(_plano, plano)

	var es_2d: bool = plano["tipo"] == "2d"
	var es_video: bool = plano["tipo"] == "video"
	# El fondo negro es de los dos planos que NO son el mundo: tapa la escena 3D
	# que haya detrás igual para una figura declarada que para uno rodado.
	_fondo.visible = es_2d or es_video
	_figuras.visible = es_2d
	if _camara != null:
		_camara.current = not (es_2d or es_video) and mundo != null

	_poner_video(plano if es_video else {})


## Pone o quita el plano rodado. Se llama SIEMPRE al cambiar de plano, también
## con un diccionario vacío: un vídeo que no se para al salir de su plano se
## sigue oyendo por debajo del siguiente.
func _poner_video(plano: Dictionary) -> void:
	if _video == null:
		return
	if plano.is_empty():
		if _video.is_playing():
			_video.stop()
		_video.visible = false
		return

	var ruta: String = Cinematica.RUTA_VIDEO + String(plano.get("fichero", ""))
	var flujo := Cinematica.flujo_de(ruta)
	if flujo == null:
		# No se pinta nada y el plano pasa igual: el reproductor lleva su propio
		# reloj, así que un fichero que falta cuesta unos segundos en negro y no
		# una cinemática colgada. `Cinematica.validar` lo caza antes, al
		# construir el catálogo — esto es la red de debajo.
		push_warning("No hay vídeo en %s" % ruta)
		_video.visible = false
		return
	_video.stream = flujo
	_video.visible = true
	_video.play()


func _terminar() -> void:
	_reproduciendo = false
	_poner_video({})
	# Saltarla cuenta como verla: quien la salta ya la conoce, que es
	# exactamente lo que el acortado quiere premiar.
	if not _id.is_empty() and not _estado.is_empty():
		Cinematica.anotar_vista(_estado, _id)
	_rotulo.text = ""
	_voz.text = ""
	_fondo.visible = false
	_figuras.visible = false
	terminada.emit()


func _mover_camara(plano: Dictionary, avance: float) -> void:
	if _camara == null or mundo == null:
		return
	var destino: Vector3 = plano["camara"]
	# Se acerca despacio durante el plano. Uno quieto se lee como una imagen;
	# uno que avanza se lee como alguien mirando.
	var acercamiento: Vector3 = destino.normalized() * -0.25 * avance
	_camara.global_position = destino + acercamiento
	_camara.look_at(plano["mira"], Vector3.UP)


## Los planos 2D se dibujan aquí: la figura es una lista de rectángulos con
## color, y `desde`/`hasta` la desplazan. El reproductor no sabe si está
## pintando un sello o una carta.
func _dibujar_figuras() -> void:
	if not _reproduciendo or _plano < 0 or _plano >= _rodaje.size():
		return
	var plano: Dictionary = _rodaje[_plano]
	if plano["tipo"] != "2d":
		return

	var duracion: float = plano["segundos"]
	var avance: float = clampf(_transcurrido / duracion, 0.0, 1.0)
	var desde: Vector2 = plano.get("desde", Vector2.ZERO)
	var hasta: Vector2 = plano.get("hasta", desde)
	var deriva: Vector2 = desde.lerp(hasta, avance)
	var centro := _lienzo.size / 2.0

	for pieza in plano["figura"]:
		var rect: Rect2 = pieza["rect"]
		_figuras.draw_rect(
			Rect2(centro + rect.position + deriva, rect.size), pieza.get("color", EstiloSiga.BLANCO)
		)


# --- Cajas ------------------------------------------------------------------


func _montar() -> void:
	_camara = Camera3D.new()
	add_child(_camara)

	var capa := CanvasLayer.new()
	add_child(capa)

	_lienzo = Control.new()
	_lienzo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lienzo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(_lienzo)

	_fondo = ColorRect.new()
	_fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fondo.color = Color(0.10, 0.10, 0.11)
	_fondo.visible = false
	_lienzo.add_child(_fondo)

	_figuras = Node2D.new()
	_figuras.draw.connect(_dibujar_figuras)
	_figuras.visible = false
	_lienzo.add_child(_figuras)

	# Los planos rodados (#66). Va DEBAJO de los rótulos y encima del fondo, en
	# el mismo sitio que las figuras: un plano rodado es un plano más, así que
	# lleva su rótulo y su voz como los otros dos y se salta igual.
	_video = VideoStreamPlayer.new()
	_video.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# `expand` deja que ocupe el cuadro en vez de quedarse al tamaño del
	# fichero. `VideoStreamPlayer` no tiene modos de encaje como un `TextureRect`
	# —solo esto—, así que la proporción se cuida al CODIFICAR: por eso la receta
	# de `Cinematica.RUTA_VIDEO` fija 320x240 y no lo deja a gusto de cada plano.
	_video.expand = true
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video.visible = false
	_lienzo.add_child(_video)

	_rotulo = _texto(48)
	_rotulo.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_rotulo.offset_top = -230
	_rotulo.offset_left = 60
	_rotulo.offset_right = -60
	_rotulo.offset_bottom = -120
	_rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lienzo.add_child(_rotulo)

	_voz = _texto(18)
	_voz.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_voz.offset_top = -60
	_voz.offset_left = 16
	_voz.offset_right = -16
	_voz.offset_bottom = -20
	_voz.add_theme_color_override("font_color", Color(0.85, 0.82, 0.55))
	_lienzo.add_child(_voz)


func _texto(tamano: int) -> Label:
	var etiqueta := Label.new()
	etiqueta.theme = EstiloSiga.tema()
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", EstiloSiga.BLANCO)
	etiqueta.add_theme_color_override("font_outline_color", EstiloSiga.NEGRO)
	etiqueta.add_theme_constant_override("outline_size", 5)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return etiqueta
