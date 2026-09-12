## Capa de progreso por objetivos para el sueño (#299).
##
## Sustituye únicamente la salida normal de las escenas oníricas: el resto del
## día, el temporizador y las capas superiores siguen heredándose.
extends "res://guion/dia_alquiler_app.gd"

const TAM_OBJETIVO := Vector3(2.8, 2.4, 2.8)
const DEMORA_RESOLUCION := 0.35

var _objetivos_espacio: Array = []
var _objetivo_escena := ""


func _espacio_de(fase: String) -> Dictionary:
	var espacio: Dictionary = super._espacio_de(fase)
	_objetivos_espacio = []
	_objetivo_escena = ""
	if fase != "sueño":
		return espacio
	if jornada.get("sueno_escenas", []).is_empty():
		return espacio

	_objetivo_escena = String(jornada["sueno_escenas"][0])
	var salidas: Array = espacio.get("salidas", [])
	var foco: Vector3 = espacio.get("entrada", Vector3.ZERO)
	if not salidas.is_empty():
		# La antigua señal de #293 se conserva como anomalía ambiental, pero el
		# trigger deja de ser una salida y pasa a ser uno de tres focos posibles.
		foco = salidas[0].get("pos", foco)
	espacio["salidas"] = []

	var posiciones: Array = _posiciones_objetivo(espacio, foco)
	for i in SuenoObjetivos.POSIBLES_PRIMER_CORTE:
		_objetivos_espacio.append(
			{
				"id": "%s:%d" % [_objetivo_escena, i],
				"pos": posiciones[i],
			}
		)
	return espacio


func _entrar_en(fase: String) -> void:
	super._entrar_en(fase)
	if fase == "sueño":
		_montar_objetivos_sueno()


func _posiciones_objetivo(espacio: Dictionary, foco: Vector3) -> Array:
	var posiciones: Array = []
	var bloques: Array = espacio.get("planta", [])
	if not bloques.is_empty():
		for celda in Planta.repartidas(bloques, SuenoObjetivos.POSIBLES_PRIMER_CORTE, []):
			posiciones.append(Planta.centro_en_metros(bloques, celda) + Vector3(0, 1.0, 0))
	while posiciones.size() < SuenoObjetivos.POSIBLES_PRIMER_CORTE:
		posiciones.append(foco)

	var figuras: Array = espacio.get("figuras", [])
	if not figuras.is_empty():
		posiciones[0] = figuras[0].get("pos", posiciones[0]) + Vector3(0, 1.0, 0)
	var carteles: Array = espacio.get("carteles", [])
	if not carteles.is_empty():
		posiciones[1] = carteles[0].get("pos", posiciones[1]) + Vector3(0, 1.0, 0)
	posiciones[2] = foco
	return posiciones


func _clave_objetivos_actual() -> String:
	return "%d:%s" % [int(jornada.get("dia", 0)), _objetivo_escena]


func _estado_objetivos_actual() -> Dictionary:
	if not jornada.has("sueno_objetivos"):
		jornada["sueno_objetivos"] = {}
	var estados: Dictionary = jornada["sueno_objetivos"]
	var clave: String = _clave_objetivos_actual()
	if not estados.has(clave):
		var ids: Array = _objetivos_espacio.map(func(objetivo): return objetivo["id"])
		estados[clave] = SuenoObjetivos.nuevo(ids)
	return estados[clave]


func _montar_objetivos_sueno() -> void:
	if _objetivos_espacio.is_empty():
		return
	var estado: Dictionary = _estado_objetivos_actual()
	var completados: Array = estado.get("completados", [])
	for objetivo in _objetivos_espacio:
		if completados.has(objetivo["id"]):
			continue
		var zona := Area3D.new()
		zona.name = "ObjetivoSueno_%s" % objetivo["id"]
		zona.position = objetivo["pos"]
		zona.set_meta("objetivo", objetivo["id"])
		var colision := CollisionShape3D.new()
		var caja := BoxShape3D.new()
		caja.size = TAM_OBJETIVO
		colision.shape = caja
		zona.add_child(colision)
		_mundo.add_child(zona)
		zona.body_entered.connect(_al_pisar_objetivo.bind(zona))
	if SuenoObjetivos.resuelto(estado):
		call_deferred("_resolver_objetivos_sueno")


func _al_pisar_objetivo(cuerpo: Node3D, zona: Area3D) -> void:
	if cuerpo != _caminante or jornada.get("fase", "") != "sueño" or _pantalla != null:
		return
	var estado: Dictionary = _estado_objetivos_actual()
	var id := String(zona.get_meta("objetivo", ""))
	if not SuenoObjetivos.completar(estado, id):
		return
	zona.monitoring = false

	var progreso: Vector2i = SuenoObjetivos.progreso(estado)
	# Feedback compacto, no checklist: al primer eco la escena gana luz; al
	# segundo se cierra el patrón y la transición ocurre tras un instante.
	_ambiente.ambient_light_energy = minf(_ambiente.ambient_light_energy + 0.14, 1.5)
	_rotulo.text = "◆  ◇" if progreso.x < progreso.y else "◆  ◆"
	if not SuenoObjetivos.resuelto(estado):
		_guardar_o_avisar("")
		return

	_caminante.set_physics_process(false)
	get_tree().create_timer(DEMORA_RESOLUCION).timeout.connect(_resolver_objetivos_sueno)


func _resolver_objetivos_sueno() -> void:
	if jornada.get("fase", "") != "sueño" or _objetivo_escena.is_empty():
		return
	var estado: Dictionary = _estado_objetivos_actual()
	if not SuenoObjetivos.resuelto(estado):
		return

	jornada["sueno_escenas"].pop_front()
	var destino := "sueño"
	if jornada["sueno_escenas"].is_empty():
		var dia := Jornada.despertar(jornada)
		_hablando = false
		_nomina.text = tr("DIA_NUEVO") % dia
		destino = "archivo"
	if not _guardar_o_avisar(destino):
		_caminante.set_physics_process(true)
		return
	_entrar_en(destino)
	_caminante.set_physics_process(true)
