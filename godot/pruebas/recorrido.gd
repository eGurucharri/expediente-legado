## Integración de escenas reales, solo bajo el verificador con datos aislados.
extends SceneTree

var pasadas := 0
var fallos := 0


func _init() -> void:
	if OS.get_environment("LEGADO_PRUEBAS_AISLADAS") != "1":
		printerr("Usa scripts/verificar_godot.py para no tocar partidas personales.")
		quit(1)
		return
	_recorrer.call_deferred()


func _recorrer() -> void:
	var escena_dia := load("res://escenas/dia.tscn")
	var dia = escena_dia.instantiate()
	root.add_child(dia)
	await process_frame
	dia.jornada["plantilla"] = 427
	dia.jornada["dia"] = 5
	dia.jornada["acciones"] = 3
	dia._abrir_expediente()
	await process_frame
	var visor = dia._pantalla.get_child(0)
	_comprobar("el puesto abre en el mismo día", visor.jornada["dia"], 5)
	_comprobar("la plantilla no cambia al sentarse", visor.jornada["plantilla"], 427)
	_comprobar("el archivo ofrece los ocho expedientes", visor._archivo.item_count, 8)
	for i in visor.contenido.casos.size():
		visor._al_elegir_caso(i)
		_comprobar(
			"seleccionar cambia el expediente", visor.caso["id"], visor.contenido.casos[i]["id"]
		)
		_comprobar(
			"cada expediente muestra sus documentos",
			visor._lista.item_count,
			visor.caso["registros"].size()
		)
	_comprobar("navegar no consume jornada", visor.jornada["acciones"], 3)
	_comprobar("navegar no abre un documento a escondidas", visor._documento.text, "")
	_comprobar(
		"el confidencial se identifica",
		visor._archivo.get_item_text(5).contains("CONFIDENCIAL"),
		true
	)
	visor._al_elegir_caso(0)
	visor._al_elegir_documento(0)
	dia._cerrar_expediente()
	await process_frame
	_comprobar("levantarse conserva la lectura", dia.jornada["leido_hoy"].size(), 1)
	_comprobar("levantarse no regala acciones", dia.jornada["acciones"], 2)

	# Reproducir la salida real del trayecto. Antes se guardaba la fase anterior.
	dia._entrar_en("trayecto")
	var salida := Area3D.new()
	salida.set_meta("frase", "")
	salida.set_meta("destino", "casa")
	dia._al_pisar_salida(dia._caminante, salida)
	salida.free()
	var releida := Partida.new()
	releida.cargar()
	_comprobar("el portal guarda la llegada a casa", releida.estado["jornada"]["fase"], "casa")
	_comprobar("el portal conserva el día", releida.estado["jornada"]["dia"], 5)
	_comprobar(
		"los contadores cargados son enteros", typeof(releida.estado["jornada"]["dia"]), TYPE_INT
	)
	dia.queue_free()
	await process_frame
	var vuelta = escena_dia.instantiate()
	root.add_child(vuelta)
	await process_frame
	_comprobar("reiniciar abre en casa", vuelta.jornada["fase"], "casa")
	_comprobar("reiniciar conserva las acciones gastadas", vuelta.jornada["acciones"], 2)
	vuelta._abrir_expediente()
	await process_frame
	var archivo = vuelta._pantalla.get_child(0)
	archivo.partida.estado["veredictos"][archivo.caso["id"]] = archivo.caso["sospechosos"][0]["id"]
	archivo._refrescar_estado()
	archivo._al_elegir_documento(1)
	_comprobar(
		"un expediente firmado sigue siendo legible", archivo._documento.text.is_empty(), false
	)
	_comprobar("releer un expediente firmado es gratis", archivo.jornada["acciones"], 2)
	_comprobar("una firma firme desactiva imputar", archivo._imputar.disabled, true)
	_comprobar(
		"el expediente firmado cambia de fondo",
		archivo._archivo.get_item_custom_bg_color(0),
		EstiloSiga.GRIS
	)
	var antes: Array = archivo.descubiertas.duplicate()
	archivo._al_pulsar_marca("pista:" + archivo.caso["pistas"][0]["id"])
	_comprobar("no se modifica un expediente firmado", archivo.descubiertas, antes)
	vuelta.queue_free()
	await process_frame
	# El mezclador libera las voces de las puertas en su propio hilo.
	await create_timer(0.25).timeout
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos else 0)


func _comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO %s: %s != %s" % [nombre, obtenido, esperado])
