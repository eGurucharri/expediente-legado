## El día: la pantalla que lo hila.
##
## Monta el espacio de la fase actual, escucha sus salidas y avanza la jornada.
## No sabe qué hay en ninguna sala —eso es `EspaciosCatalogo`— ni qué significa
## avanzar —eso es `Jornada`—: aquí solo se pega una cosa con la otra.
extends Node3D

## Lo que se anda entre paso y paso. Una zancada de persona son unos setenta
## centímetros.
const METROS_POR_ZANCADA := 0.72

var partida := Partida.new()
var contenido := Contenido.new()
var jornada: Dictionary = {}

var _caminante: CharacterBody3D
var _mundo: Node3D
var _rotulo: Label
var _nomina: Label
var _pantalla: CanvasLayer
var _ambiente: Environment
var _sol: DirectionalLight3D
var _voz: AudioStreamPlayer
var _pisada: AudioStreamPlayer3D
var _desde_paso := 0.0
## Si lo que se lee ahora mismo es algo que dijo alguien. Lo que dice un
## compañero es de la oficina y del momento: llevárselo a la calle o al sueño
## lo convierte en una voz que te sigue.
var _hablando := false


func _ready() -> void:
	partida.cargar()
	contenido.cargar()
	jornada = Jornada.completar(partida.estado.get("jornada", Jornada.nueva()))
	partida.estado["jornada"] = jornada

	_montar_entorno()
	_montar_interfaz()
	_entrar_en(jornada["fase"])
	# Conserva la plantilla inicial y las migraciones antes de abrir el visor,
	# que lee su propia instancia de Partida.
	partida.guardar()


## Luz y ambiente. Una sola direccional y bastante ambiente: en un sitio de
## cajas planas, las sombras duras solo enseñan que son cajas.
func _montar_entorno() -> void:
	var entorno := WorldEnvironment.new()
	var ajustes := Environment.new()
	_ambiente = ajustes
	ajustes.background_mode = Environment.BG_COLOR
	ajustes.background_color = Color(0.05, 0.05, 0.06)
	ajustes.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ajustes.ambient_light_color = Color(0.55, 0.55, 0.58)
	ajustes.ambient_light_energy = 0.7
	entorno.environment = ajustes
	add_child(entorno)

	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-55, -35, 0)
	sol.light_energy = 0.7
	add_child(sol)
	_sol = sol

	_caminante = load("res://escenas/caminante.tscn").instantiate()
	add_child(_caminante)

	# Dos voces: lo que pasa (una puerta, la nómina) y lo que haces tú (andar).
	# La segunda va pegada al cuerpo, que es de donde salen los pasos.
	_voz = AudioStreamPlayer.new()
	add_child(_voz)
	_pisada = AudioStreamPlayer3D.new()
	_pisada.unit_size = 3.0
	_caminante.add_child(_pisada)


func _montar_interfaz() -> void:
	var capa := CanvasLayer.new()
	add_child(capa)

	var caja := VBoxContainer.new()
	caja.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	caja.offset_left = 12
	caja.offset_top = 10
	caja.theme = EstiloSiga.tema()
	capa.add_child(caja)

	_rotulo = Label.new()
	_rotulo.add_theme_color_override("font_color", EstiloSiga.BLANCO)
	_rotulo.add_theme_color_override("font_outline_color", EstiloSiga.NEGRO)
	_rotulo.add_theme_constant_override("outline_size", 4)
	caja.add_child(_rotulo)

	_nomina = Label.new()
	_nomina.add_theme_color_override("font_color", EstiloSiga.BLANCO)
	_nomina.add_theme_color_override("font_outline_color", EstiloSiga.NEGRO)
	_nomina.add_theme_constant_override("outline_size", 4)
	caja.add_child(_nomina)


func _entrar_en(fase: String) -> void:
	if _hablando:
		_nomina.text = ""
		_hablando = false
	jornada["fase"] = fase
	if _mundo != null:
		_mundo.queue_free()
	_mundo = Node3D.new()
	add_child(_mundo)

	var espacio := _espacio_de(fase)
	for salida in Espacio3D.construir(_mundo, espacio):
		salida.body_entered.connect(_al_pisar_salida.bind(salida))

	# Cada sitio trae su luz general. El archivo no se ilumina como la calle, y
	# con un solo ambiente para todo el día uno de los dos está siempre mal.
	_ambiente.ambient_light_color = espacio.get("ambiente", Color(0.55, 0.55, 0.58))
	_ambiente.ambient_light_energy = espacio.get("ambiente_energia", 0.7)
	_sol.light_energy = espacio.get("sol", 0.7)

	_caminante.situar(espacio["entrada"], espacio.get("mirada", NAN))
	_refrescar_rotulos(espacio)


## Dónde se está. Los sitios del día están declarados uno por fase; el sueño no
## puede estarlo, porque son tres escenas distintas cada noche y cuáles depende
## de lo que se leyó ese día. Es la única fase que pregunta en vez de mirar el
## catálogo, y aun así esta pantalla no sabe qué forma tiene ninguna sala.
func _espacio_de(fase: String) -> Dictionary:
	if fase != "sueño":
		# En copia: el catálogo es una constante, y añadirle la plantilla de
		# esta vuelta encima la dejaría pegada para toda la partida.
		var sitio := EspaciosCatalogo.de_fase(fase).duplicate(true)
		sitio["figuras"] = _plantilla_en(sitio)
		return sitio

	if jornada["sueno_escenas"].is_empty():
		jornada["sueno_escenas"] = Sueno.noche(
			jornada["dia"], jornada["leido_hoy"], jornada["mapa"]
		)
	var id: String = jornada["sueno_escenas"][0]
	# Se apunta al ENTRAR y no al salir: el mapa es lo que has pisado, y
	# despertarse de golpe en mitad de una sala no la borra de haber estado.
	Sueno.recordar(jornada["mapa"], id)

	# De qué está hecha esta escena (#87). El reparto es de la NOCHE y no de la
	# sala: se calcula con la lista entera de escenas y se coge el trozo que le
	# toca a esta, o las tres saldrían amuebladas con lo mismo.
	var fuentes := SuenoContenido.fuentes(
		jornada["leido_hoy"],
		contenido.casos,
		partida.estado["pistas_descubiertas"],
		partida.estado.get("veredictos", {})
	)
	var reparto := SuenoContenido.repartir(
		fuentes, Sueno.ESCENAS_POR_NOCHE, Sueno.semilla(jornada["dia"], jornada["leido_hoy"])
	)
	var cual: int = Sueno.ESCENAS_POR_NOCHE - jornada["sueno_escenas"].size()
	return Sueno.espacio(
		id, jornada["sueno_escenas"].size() - 1, reparto[clampi(cual, 0, reparto.size() - 1)]
	)


## El reloj de la noche. Solo corre dentro del sueño: el día no tiene prisa y
## el sueño sí, que es media parte de la diferencia entre los dos.
func _process(delta: float) -> void:
	_andar(delta)

	if jornada.get("fase", "") != "sueño":
		return
	if Jornada.gastar_sueno(jornada, delta):
		var dia := Jornada.despertar_de_golpe(jornada)
		_hablando = false
		_nomina.text = tr("DIA_DESPERTAR_DE_GOLPE") % dia
		partida.guardar()
		_entrar_en("archivo")
		return
	_rotulo.text = _texto_de_rotulo(Sueno.senal_de_noche(Jornada.noche_restante(jornada)))


func _al_pisar_salida(cuerpo: Node3D, salida: Area3D) -> void:
	if cuerpo != _caminante or _pantalla != null:
		return
	# Alguien que dice algo al pasar. No lleva a ninguna parte, así que se
	# atiende antes de mirar destinos.
	var frase: String = salida.get_meta("frase")
	if not frase.is_empty():
		_nomina.text = tr("DIA_DICE") % tr(frase)
		_hablando = true
		return

	var destino: String = salida.get_meta("destino")

	# Hay dos clases de sitio que se pisan: los que llevan a otra parte del día
	# y los que abren una PANTALLA. El puesto de trabajo es de los segundos —
	# se sigue estando en la oficina mientras se lee.
	if destino == "expediente":
		_sonar("documento")
		_abrir_expediente()
		return

	# Cada tránsito es un acto de la jornada, no solo un cambio de sala: al
	# salir de la oficina se ficha y se cobra; al meterse en la cama se paga el
	# día y el gato cuenta una noche más.
	match jornada["fase"]:
		"archivo":
			var paga := Jornada.fichar_salida(jornada)
			_sonar("nomina")
			_hablando = false
			_nomina.text = (
				tr("DIA_NOMINA")
				% [
					jornada["dia"],
					paga["bruto"],
					paga["base"],
					paga["por_expedientes"],
					paga["expedientes"],
					paga["dinero"]
				]
			)
		"casa":
			var noche := Jornada.dormir(jornada)
			_hablando = false
			_nomina.text = (
				tr("DIA_VIVIR")
				% [
					noche["coste"],
					noche["dinero"],
					tr("DIA_SIN_GATO_AVISO") if noche["gato_se_fue"] else ""
				]
			)
		"sueño":
			# Se sale de la escena que se acaba de recorrer. Si quedan más, la
			# noche sigue en la siguiente y no se despierta: el destino de la
			# salida ya lo decía.
			jornada["sueno_escenas"].pop_front()
			if jornada["sueno_escenas"].is_empty():
				var dia := Jornada.despertar(jornada)
				_hablando = false
				_nomina.text = tr("DIA_NUEVO") % dia
		_:
			pass

	if jornada["fase"] != "sueño":
		_sonar("puerta_abre")
	_entrar_en(destino)
	# El destino y el mapa ya tienen que estar asentados al escribir: en el
	# trayecto no hay otra regla que cambie la fase a casa.
	partida.guardar()


## Los compañeros de esta vida laboral, sentados donde el sitio diga.
##
## La plantilla se sortea por la semilla de la vuelta, que vive en la jornada:
## te reasignan y los de al lado son otros, pero volver a cargar la partida no
## los cambia. Una oficina cuya gente cambia al recargar no es una oficina.
func _plantilla_en(sitio: Dictionary) -> Array:
	var sitios: Array = sitio.get("sitios_companeros", [])
	if sitios.is_empty():
		return []
	var figuras := []
	var quienes := Companeros.plantilla(jornada["plantilla"])
	for i in mini(quienes.size(), sitios.size()):
		var quien: Dictionary = quienes[i]
		(
			figuras
			. append(
				{
					"pos": sitios[i],
					"color": quien["color"],
					"rotulo": tr(quien["nombre"]),
					"frase": Companeros.frase_de(quien, jornada["dia"]),
				}
			)
		)
	return figuras


## Los pasos. Suenan por DISTANCIA andada y no por tiempo: parado no se pisa,
## y a la misma velocidad la zancada es siempre la misma. Con un temporizador,
## quedarse quieto contra una pared seguiría sonando a alguien caminando.
func _andar(delta: float) -> void:
	if _pantalla != null or not _caminante.is_physics_processing():
		return
	var avance := Vector2(_caminante.velocity.x, _caminante.velocity.z).length() * delta
	_desde_paso += avance
	if _desde_paso < METROS_POR_ZANCADA:
		return
	_desde_paso = 0.0
	_pisada.stream = Sonido.paso()
	_pisada.pitch_scale = randf_range(0.94, 1.06)
	_pisada.play()


func _sonar(nombre: String) -> void:
	var stream := Sonido.stream(nombre)
	if stream != null:
		_voz.stream = stream
		_voz.play()


## El expediente, encima del día y sin salir de él.
##
## El visor es una pantalla completa con su propia partida: mientras está
## abierta manda ella, y al cerrarse el día vuelve a LEER el fichero en vez de
## confiar en la copia que tenía. Es la costura entre los dos, y va en un solo
## sitio: dos dueños del mismo estado a la vez es como se pierden partidas.
func _abrir_expediente() -> void:
	partida.guardar()
	_caminante.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_pantalla = CanvasLayer.new()
	add_child(_pantalla)
	_pantalla.add_child(load("res://escenas/visor.tscn").instantiate())

	# El botón de volver lo pone el DÍA y no el visor: el visor también se usa
	# suelto, y no tiene por qué saber que hay una oficina alrededor.
	var volver := Button.new()
	volver.theme = EstiloSiga.tema()
	volver.text = tr("PUESTO_LEVANTARSE")
	volver.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	volver.offset_left = -190
	volver.offset_top = 4
	volver.offset_right = -8
	volver.pressed.connect(_cerrar_expediente)
	_pantalla.add_child(volver)

	_hablando = false
	_nomina.text = tr("DIA_EN_EL_PUESTO")


func _cerrar_expediente() -> void:
	if _pantalla == null:
		return
	_pantalla.queue_free()
	_pantalla = null
	_sonar("puerta_cierra")

	partida.cargar()
	jornada = Jornada.completar(partida.estado.get("jornada", Jornada.nueva()))
	partida.estado["jornada"] = jornada

	_caminante.set_physics_process(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Se sale del puesto ANDANDO hacia atrás: quedarse encima del disparador
	# reabriría el expediente en cuanto se mueva un dedo.
	_caminante.situar(Vector3(-4, 0, 3.2))
	_refrescar_rotulos(EspaciosCatalogo.de_fase(jornada["fase"]))


func _refrescar_rotulos(espacio: Dictionary) -> void:
	_rotulo.text = _texto_de_rotulo(tr(espacio.get("rotulo", "")))


func _texto_de_rotulo(sitio: String) -> String:
	return (
		tr("DIA_ROTULO")
		% [
			jornada["dia"],
			sitio,
			jornada["dinero"],
			"" if jornada["gato"]["presente"] else tr("DIA_SIN_GATO")
		]
	)
