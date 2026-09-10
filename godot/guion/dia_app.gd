## El día: la pantalla que lo hila.
##
## Monta el espacio de la fase actual, escucha sus salidas y avanza la jornada.
## No sabe qué hay en ninguna sala —eso es `EspaciosCatalogo`— ni qué significa
## avanzar —eso es `Jornada`—: aquí solo se pega una cosa con la otra.
extends Node3D

var partida := Partida.new()
var jornada: Dictionary = {}

var _caminante: CharacterBody3D
var _mundo: Node3D
var _rotulo: Label
var _nomina: Label


func _ready() -> void:
	partida.cargar()
	jornada = partida.estado.get("jornada", Jornada.nueva())
	partida.estado["jornada"] = jornada

	_montar_entorno()
	_montar_interfaz()
	_entrar_en(jornada["fase"])


## Luz y ambiente. Una sola direccional y bastante ambiente: en un sitio de
## cajas planas, las sombras duras solo enseñan que son cajas.
func _montar_entorno() -> void:
	var entorno := WorldEnvironment.new()
	var ajustes := Environment.new()
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

	_caminante = load("res://escenas/caminante.tscn").instantiate()
	add_child(_caminante)


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
	jornada["fase"] = fase
	if _mundo != null:
		_mundo.queue_free()
	_mundo = Node3D.new()
	add_child(_mundo)

	var espacio := _espacio_de(fase)
	for salida in Espacio3D.construir(_mundo, espacio):
		salida.body_entered.connect(_al_pisar_salida.bind(salida))

	_caminante.situar(espacio["entrada"])
	_refrescar_rotulos(espacio)


## Dónde se está. Los sitios del día están declarados uno por fase; el sueño no
## puede estarlo, porque son tres escenas distintas cada noche y cuáles depende
## de lo que se leyó ese día. Es la única fase que pregunta en vez de mirar el
## catálogo, y aun así esta pantalla no sabe qué forma tiene ninguna sala.
func _espacio_de(fase: String) -> Dictionary:
	if fase != "sueño":
		return EspaciosCatalogo.de_fase(fase)

	if jornada["sueno_escenas"].is_empty():
		jornada["sueno_escenas"] = Sueno.noche(
			jornada["dia"], jornada["leido_hoy"], jornada["mapa"])
	var id: String = jornada["sueno_escenas"][0]
	# Se apunta al ENTRAR y no al salir: el mapa es lo que has pisado, y
	# despertarse de golpe en mitad de una sala no la borra de haber estado.
	Sueno.recordar(jornada["mapa"], id)
	return Sueno.espacio(id, jornada["sueno_escenas"].size() - 1)


func _al_pisar_salida(cuerpo: Node3D, salida: Area3D) -> void:
	if cuerpo != _caminante:
		return
	var destino: String = salida.get_meta("destino")

	# Cada tránsito es un acto de la jornada, no solo un cambio de sala: al
	# salir de la oficina se ficha y se cobra; al meterse en la cama se paga el
	# día y el gato cuenta una noche más.
	match jornada["fase"]:
		"archivo":
			var paga := Jornada.fichar_salida(jornada)
			_nomina.text = "Nómina del día %d: %d (base %d + %d por %d expediente(s)).  Tiene %d." % [
				jornada["dia"], paga["bruto"], paga["base"], paga["por_expedientes"],
				paga["expedientes"], paga["dinero"]]
		"casa":
			var noche := Jornada.dormir(jornada)
			_nomina.text = "Vivir cuesta %d. Le quedan %d.%s" % [
				noche["coste"], noche["dinero"],
				"  El gato no está." if noche["gato_se_fue"] else ""]
		"sueño":
			# Se sale de la escena que se acaba de recorrer. Si quedan más, la
			# noche sigue en la siguiente y no se despierta: el destino de la
			# salida ya lo decía.
			jornada["sueno_escenas"].pop_front()
			if jornada["sueno_escenas"].is_empty():
				var dia := Jornada.despertar(jornada)
				_nomina.text = "Día %d." % dia
		_:
			pass

	partida.guardar()
	_entrar_en(destino)


func _refrescar_rotulos(espacio: Dictionary) -> void:
	_rotulo.text = "Día %d  ·  %s  ·  %d en el bolsillo%s" % [
		jornada["dia"], espacio.get("rotulo", ""), jornada["dinero"],
		"" if jornada["gato"]["presente"] else "  ·  sin gato"]
