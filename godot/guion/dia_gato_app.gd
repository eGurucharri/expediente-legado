## Capa de presentación del gato compartido entre casa, SIGA y sueño (#92).
##
## La casa sigue perteneciendo a `dia_app.gd`. Esta capa no crea otra relación
## ni otro contador: lee `jornada.gato` y traduce el mismo estado a dos señales.
## En SIGA es un asistente no interactivo; en el sueño es el mismo cuerpo del
## gato, visible junto a la entrada y orientado solo cuando está bien cuidado.
extends "res://guion/dia_objetivos_app.gd"

var _gato_guia: Gato
var _entrada_guia := Vector3.ZERO
var _salida_guia := Vector3.ZERO
var _hay_rumbo_guia := false


func _espacio_de(fase: String) -> Dictionary:
	var espacio: Dictionary = super._espacio_de(fase)
	_hay_rumbo_guia = false
	if fase != "sueño":
		return espacio
	if _objetivos_espacio.is_empty():
		return espacio
	_entrada_guia = espacio.get("entrada", Vector3.ZERO)
	_salida_guia = _objetivos_espacio[0].get("pos", _entrada_guia)
	_hay_rumbo_guia = true
	return espacio


func _entrar_en(fase: String) -> void:
	super._entrar_en(fase)
	_gato_guia = null
	if fase == "sueño":
		_montar_guia_sueno()


func _abrir_expediente() -> void:
	super._abrir_expediente()
	if _pantalla == null:
		return
	_montar_asistente_siga()


func _montar_asistente_siga() -> void:
	var lineas := GatoAyuda.lineas_asistente(jornada.get("gato", {}))
	if lineas.is_empty():
		return

	var panel := PanelContainer.new()
	panel.theme = EstiloSiga.tema()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	panel.offset_left = 12
	panel.offset_top = -144
	panel.offset_right = 520
	panel.offset_bottom = -12
	_pantalla.add_child(panel)

	var fila := HBoxContainer.new()
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(fila)

	var avatar := GatoAsistente2D.new()
	fila.add_child(avatar)

	var caja := VBoxContainer.new()
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(caja)

	for clave in lineas:
		var frase := Label.new()
		frase.text = tr(String(clave))
		frase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		frase.custom_minimum_size.x = 370
		frase.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caja.add_child(frase)


func _montar_guia_sueno() -> void:
	var gato: Dictionary = jornada.get("gato", {})
	if not GatoAyuda.guia_visible(gato) or not _hay_rumbo_guia:
		return

	var rumbo := _salida_guia - _entrada_guia
	rumbo.y = 0.0
	if rumbo.length() < 0.01:
		return

	var direccion := rumbo.normalized()
	var posicion := _entrada_guia + direccion * 1.4
	_gato_guia = Gato.new()
	_mundo.add_child(_gato_guia)
	_gato_guia.empezar(posicion, [posicion])

	# Bien cuidado funciona como una brújula viva: mira en la dirección general
	# del primer objetivo pendiente, pero no lo convierte en waypoint. Con
	# hambre sigue apareciendo —es el mismo gato—, pero ya no orienta.
	if GatoAyuda.guia_orienta(gato):
		_gato_guia.rotation.y = atan2(direccion.x, direccion.z)
