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

## El destino al que no se llegó a entrar porque no se pudo guardar. Mientras
## haya uno, pisar cualquier salida REINTENTA el guardado en vez de volver a
## fichar: la nómina y la noche ya están cobradas en memoria, y cobrarlas dos
## veces sería peor que no haberlas escrito.
var _transito_pendiente := ""
var _borrar: Button
var _borrar_confirmando := false
var _pantalla: CanvasLayer
## Los rótulos del día. Se guarda para poder apagarlos mientras se pone la
## entrada de la vuelta.
var _hud: CanvasLayer
## La entrada de la vuelta mientras se está poniendo (#68). Fuera de ella es
## nula: el reproductor se descarta al terminar en vez de quedarse escuchando.
var _entrada: Node3D
var _ambiente: Environment
var _sol: DirectionalLight3D
var _voz: AudioStreamPlayer
var _pisada: AudioStreamPlayer3D
var _desde_paso := 0.0
## Si lo que se lee ahora mismo es algo que dijo alguien. Lo que dice un
## compañero es de la oficina y del momento: llevárselo a la calle o al sueño
## lo convierte en una voz que te sigue.
var _hablando := false


## La raíz del azar de esta partida (#147). Se lee de la partida y no se guarda
## aparte: un segundo sitio donde viviera la semilla sería un segundo sitio
## donde pudiera estar desfasada.
func _raiz() -> int:
	return int(partida.estado.get("semilla", 0))


func _ready() -> void:
	partida.cargar()
	contenido.cargar()
	jornada = Jornada.completar(partida.estado.get("jornada", Jornada.nueva(_raiz())), _raiz())
	partida.estado["jornada"] = jornada

	_montar_entorno()
	_montar_interfaz()
	_entrar_en(jornada["fase"])
	# Conserva la plantilla inicial y las migraciones antes de abrir el visor,
	# que lee su propia instancia de Partida.
	_abrir_vuelta()


## La entrada de una vida laboral (#68).
##
## Se pone ENCIMA de la oficina ya montada y no antes de montarla: así al
## terminar no hay ningún fotograma en negro esperando a que se construya el
## archivo, y saltarla deja al jugador exactamente donde estaría.
##
## Solo abre una vuelta —día uno, en el archivo y con la jornada entera por
## delante—, que es lo que distingue empezar de volver a cargar una partida a
## medias. Una entrada que se repita cada vez que se abre el juego dejaría de
## ser una entrada.
##
## Ocurre al arrancar y también a media sesión: cuando firmar cuesta la última
## vida, `_cerrar_expediente` vuelve a llamar aquí por `_reasignar`. Esa es la
## razón de que la condición mire la jornada y no una bandera de "ya
## arrancamos" — lo que abre una entrada es que la vida laboral esté por
## estrenar, venga de donde venga.
func _abrir_vuelta() -> void:
	if jornada["fase"] != "archivo" or jornada["dia"] != 1:
		return
	if jornada["acciones"] != Jornada.ACCIONES_POR_DIA:
		return

	# El cuerpo se queda quieto mientras dura: la cinemática se salta con
	# cualquier tecla, y sin esto esa misma tecla sería también un paso.
	_caminante.set_physics_process(false)

	# Y los rótulos del día se apagan. No es limpieza: la oficina ya está
	# montada detrás, así que sin esto la frase de un compañero se lee ENCIMA de
	# la pantalla de arranque —alguien te habla antes de que hayas entrado, en la
	# cinemática cuyo remate es que no hay nadie más—.
	_hud.visible = false

	_entrada = load("res://escenas/cinematica.tscn").instantiate()
	add_child(_entrada)
	_entrada.terminada.connect(_cerrar_vuelta)
	var vistas := Cinematica.vistas_de(partida.estado, EntradaCinematica.ID)
	_entrada.reproducir(EntradaCinematica.planos_de(vistas), EntradaCinematica.ID, partida.estado)


## Al acabar la entrada se guarda, y no por costumbre: lo que hay que conservar
## es que se ha visto. Sin este guardado la cuenta se pierde al cerrar el juego
## y la entrada volvería a durar lo mismo para siempre, que es justo lo que el
## acortado de #67 vino a evitar.
func _cerrar_vuelta() -> void:
	if _entrada == null:
		return
	_entrada.queue_free()
	_entrada = null
	_caminante.set_physics_process(true)
	_hud.visible = true
	_guardar_o_avisar("")


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
	_hud = capa

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

	# Empezar de cero se pide en CASA y no en la oficina: el sistema no te
	# ofrece borrarte a ti mismo desde dentro. Dos pulsaciones, porque esto se
	# lleva la memoria de todas las vueltas y no hay deshacer dentro del juego.
	_borrar = Button.new()
	_borrar.text = tr("CASA_BORRAR")
	_borrar.visible = false
	_borrar.pressed.connect(_al_pulsar_borrar)
	caja.add_child(_borrar)


func _entrar_en(fase: String) -> void:
	if _hablando:
		_nomina.text = ""
		_hablando = false
	jornada["fase"] = fase
	if _borrar != null:
		# Solo en casa, y la confirmación no sobrevive a salir de la habitación:
		# volver a entrar tiene que volver a pedirla.
		_borrar.visible = fase == "casa"
		_borrar_confirmando = false
		_borrar.text = tr("CASA_BORRAR")
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
			jornada["dia"], jornada["leido_hoy"], jornada["mapa"], _raiz()
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
	var reparto := (
		SuenoContenido
		. repartir(
			fuentes,
			Sueno.ESCENAS_POR_NOCHE,
			Sueno.semilla(jornada["dia"], jornada["leido_hoy"], _raiz()),
		)
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
		if not _guardar_o_avisar("archivo"):
			return
		_entrar_en("archivo")
		return
	_rotulo.text = _texto_de_rotulo(Sueno.senal_de_noche(Jornada.noche_restante(jornada)))


## Escribe la partida y dice si pudo. Si no pudo, apunta el tránsito que se
## queda esperando y lo cuenta: nada de esto deshace lo ya aplicado a la
## jornada, que sigue siendo lo vigente aunque el disco no se haya enterado.
func _guardar_o_avisar(destino: String) -> bool:
	if partida.guardar():
		return true
	_transito_pendiente = destino
	_hablando = false
	_nomina.text = tr("ARCHIVO_ERROR_GUARDAR")
	return false


## El reintento. Solo vuelve a escribir el mismo estado —ni ficha, ni paga, ni
## gasta una acción— y, si esta vez sale, termina el tránsito que quedó a
## medias.
func _reintentar_guardado() -> void:
	var destino := _transito_pendiente
	if not _guardar_o_avisar(destino):
		return
	_transito_pendiente = ""
	_nomina.text = tr("ARCHIVO_GUARDADO_HECHO")
	if destino.is_empty():
		return
	if jornada["fase"] != "sueño":
		_sonar("puerta_abre")
	_entrar_en(destino)


func _al_pisar_salida(cuerpo: Node3D, salida: Area3D) -> void:
	# Con un guardado a medias no se empieza nada nuevo: cada pisada es el
	# reintento, y no vuelve a aplicar la jugada que ya está hecha.
	if partida.guardado_pendiente and cuerpo == _caminante:
		_reintentar_guardado()
		return
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
	# trayecto no hay otra regla que cambie la fase a casa. Por eso aquí el
	# tránsito pendiente se queda vacío: ya se ha entrado, y lo único que falta
	# por hacer es escribirlo.
	_guardar_o_avisar("")


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
					"modelo": Companeros.cuerpo_de(quien),
					"retrato": quien.get("retrato", ""),
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
## Empezar de cero, en dos pulsaciones.
##
## La primera avisa de lo que se lleva por delante; la segunda lo hace. Es el
## mismo gesto de dos tiempos que el canje de una carta por una vida, y por el
## mismo motivo: lo que no se puede deshacer no se dispara con un clic suelto.
func _al_pulsar_borrar() -> void:
	if not _borrar_confirmando:
		_borrar_confirmando = true
		_borrar.text = tr("CASA_BORRAR_SEGURO")
		return

	_borrar_confirmando = false
	_borrar.text = tr("CASA_BORRAR")
	if not partida.borrar():
		_nomina.text = tr("ARCHIVO_ERROR_GUARDAR")
		return

	jornada = Jornada.completar(partida.estado.get("jornada", Jornada.nueva(_raiz())), _raiz())
	partida.estado["jornada"] = jornada
	_nomina.text = tr("CASA_BORRADO")
	_sonar("puerta_cierra")
	_entrar_en(jornada["fase"])


func _abrir_expediente() -> void:
	if partida.guardado_pendiente:
		_reintentar_guardado()
		return
	if not _guardar_o_avisar(""):
		return
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

	# De qué vida laboral se levantó. Se apunta ANTES de releer, porque firmar
	# puede haberla terminado y lo que vuelve del fichero sería ya la
	# siguiente, indistinguible de la de antes.
	var vuelta_antes := int(jornada.get("vuelta", 1))

	partida.cargar()
	jornada = Jornada.completar(partida.estado.get("jornada", Jornada.nueva(_raiz())), _raiz())
	partida.estado["jornada"] = jornada

	_caminante.set_physics_process(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Le han reasignado mientras firmaba: se levanta otra persona de esa silla.
	if int(jornada.get("vuelta", 1)) != vuelta_antes:
		_reasignar()
		return

	# Se sale del puesto ANDANDO hacia atrás: quedarse encima del disparador
	# reabriría el expediente en cuanto se mueva un dedo.
	_caminante.situar(Vector3(-4, 0, 3.2))
	_refrescar_rotulos(EspaciosCatalogo.de_fase(jornada["fase"]))


## Empezar la vida laboral siguiente sin salir del juego.
##
## `Acusacion.perder_vida` ya ha hecho lo suyo en los datos —día uno, dinero de
## partida, otra plantilla— pero el mundo montado sigue siendo el de antes: los
## compañeros de la vuelta anterior siguen sentados, porque las figuras se
## construyen al entrar en el sitio y nadie ha vuelto a entrar.
##
## Así que se entra otra vez, con la fase que la jornada nueva ya trae puesta, y
## se abre la vuelta por la puerta: la entrada (#68) se ve cada vida laboral, y
## sin esto la segunda empezaría sin ella. Aquí no hay cinemática de despido
## —eso es #73—, solo la garantía de que el ciclo no se queda a medias.
func _reasignar() -> void:
	_entrar_en(jornada["fase"])
	_abrir_vuelta()


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
