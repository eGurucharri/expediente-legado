## El visor de expedientes: la pieza de riesgo del port.
##
## Es la pantalla que decide si Godot sirve para este juego. Todo lo demás
## (logros, tarot, combate) es lo que un motor hace bien; leer un memorándum
## largo y notar una frase concreta dentro de él es lo que un navegador hacía
## gratis y aquí hay que demostrar.
##
## Sustituye a `caso.html` + `documento-viewer.js` + `legacy-documentos.js`. No
## contiene ninguna regla del juego: el contenido llega de `Contenido`, dónde
## están las marcas lo dice `Marcas` y cómo se pintan `BBCode`. Esta clase solo
## coloca cajas y traduce un clic en "descubre esta pista".
extends Control

const MARGEN := 8

const ICONOS_POR_TIPO := {
	"FACTURA": "[$]",
	"MEMORANDO": "[M]",
	"EMPLEADO": "[P]",
	"ACTA": "[A]",
	"OFICIO": "[O]",
	"CIRCULAR": "[C]",
	"FAX": "[F]",
}

var contenido := Contenido.new()
var partida := Partida.new()
var caso: Dictionary = {}
var descubiertas: Array = []
var registro_actual: Dictionary = {}

## La jornada en curso: abrir un documento por primera vez hoy gasta una de las
## acciones del día.
var jornada: Dictionary = {}

## Lo que hay que contar al jugador sobre su partida guardada, si es que hay
## algo que contar. Una partida apartada por ilegible no puede parecerse a no
## haber jugado nunca.
var _aviso_partida := ""

var _lista: ItemList
var _archivo: ItemList
var _titulo_ventana: Label
var _imputar: Button
var _documento: RichTextLabel
var _cabecera: Label
var _estado: Label


## La raíz del azar de esta partida (#147). Se lee de la partida y no se guarda
## aparte: un segundo sitio donde viviera la semilla sería un segundo sitio
## donde pudiera estar desfasada.
func _raiz() -> int:
	return int(partida.estado.get("semilla", 0))


func _ready() -> void:
	theme = EstiloSiga.tema()
	if not contenido.cargar():
		return

	var carga := partida.cargar()
	descubiertas = partida.estado["pistas_descubiertas"]
	jornada = Jornada.completar(partida.estado.get("jornada", Jornada.nueva(_raiz())), _raiz())
	partida.estado["jornada"] = jornada
	if carga["resultado"] == "apartada":
		_aviso_partida = tr("VISOR_PARTIDA_APARTADA") % [carga["motivo"], carga["copia"]]
	caso = contenido.casos[0]
	_construir()
	# No se abre nada solo: abrir cuesta una acción, y un documento servido de
	# regalo al arrancar se podría cobrar cerrando y reabriendo el juego.
	_documento.text = ""
	_cabecera.text = tr("VISOR_ELIJA")
	_refrescar_estado()
	_archivo.grab_focus()


func _draw() -> void:
	# La ventana entera es un panel saliente, como el marco de un programa de
	# la época.
	EstiloSiga.dibujar_bisel(self, Rect2(Vector2.ZERO, size), EstiloSiga.GRIS, true)


func _construir() -> void:
	var raiz := VBoxContainer.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.offset_left = MARGEN
	raiz.offset_top = MARGEN
	raiz.offset_right = -MARGEN
	raiz.offset_bottom = -MARGEN
	raiz.add_theme_constant_override("separation", MARGEN)
	add_child(raiz)

	raiz.add_child(_barra_titulo())

	var columnas := HSplitContainer.new()
	columnas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columnas.split_offset = 240
	raiz.add_child(columnas)

	columnas.add_child(_columna_indice())
	columnas.add_child(_columna_documento())

	_imputar = Button.new()
	_imputar.text = tr("VISOR_IMPUTAR")
	_imputar.pressed.connect(_abrir_formulario)
	raiz.add_child(_imputar)

	_estado = _etiqueta("", EstiloSiga.NEGRO)
	var barra_estado := _hueco()
	barra_estado.custom_minimum_size.y = 26
	barra_estado.add_child(_centrado(_estado))
	raiz.add_child(barra_estado)


func _barra_titulo() -> Control:
	var barra := PanelContainer.new()
	var caja := StyleBoxFlat.new()
	caja.bg_color = EstiloSiga.AZUL_TITULO
	caja.set_corner_radius_all(0)
	caja.content_margin_left = 6
	caja.content_margin_top = 3
	caja.content_margin_bottom = 3
	barra.add_theme_stylebox_override("panel", caja)

	var titulo := _etiqueta(
		# El año llega del JSON como número en coma flotante: sin el int()
		# la barra de título anuncia "Expediente 1999.0".
		(
			tr("VISOR_BARRA_TITULO")
			% (int(caso["anioSuceso"]) if caso.get("anioSuceso") != null else tr("SIN_FECHA_CORTA"))
		),
		EstiloSiga.BLANCO
	)
	barra.add_child(titulo)
	_titulo_ventana = titulo
	return barra


func _columna_indice() -> Control:
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 4)
	columna.custom_minimum_size.x = 300
	columna.add_child(_etiqueta(tr("ARCHIVO_TITULO"), EstiloSiga.NEGRO))
	_archivo = ItemList.new()
	_archivo.custom_minimum_size.y = 220
	_archivo.add_theme_stylebox_override("panel", _caja_hundida(EstiloSiga.BLANCO))
	_archivo.add_theme_color_override("font_color", EstiloSiga.NEGRO)
	_archivo.add_theme_color_override("font_selected_color", EstiloSiga.BLANCO)
	_archivo.item_selected.connect(_al_elegir_caso)
	columna.add_child(_archivo)
	_refrescar_archivo()
	_archivo.select(0)
	columna.add_child(_etiqueta(tr("VISOR_DOCUMENTOS"), EstiloSiga.NEGRO))

	_lista = ItemList.new()
	_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lista.add_theme_stylebox_override("panel", _caja_hundida(EstiloSiga.BLANCO))
	_lista.add_theme_color_override("font_color", EstiloSiga.NEGRO)
	# Sin esto el documento abierto queda en blanco sobre blanco: se veía la
	# lista con una fila vacía arriba y ningún indicio de cuál se está leyendo.
	_lista.add_theme_color_override("font_selected_color", EstiloSiga.BLANCO)
	var seleccion := StyleBoxFlat.new()
	seleccion.bg_color = EstiloSiga.AZUL_TITULO
	seleccion.set_corner_radius_all(0)
	_lista.add_theme_stylebox_override("selected", seleccion)
	_lista.add_theme_stylebox_override("selected_focus", seleccion)
	_archivo.add_theme_stylebox_override("selected", seleccion)
	_archivo.add_theme_stylebox_override("selected_focus", seleccion)
	for registro in caso["registros"]:
		_lista.add_item(tr("VISOR_ITEM") % [_icono(registro["tipo"]), registro["folio"]])
	_lista.item_selected.connect(_al_elegir_documento)
	columna.add_child(_lista)
	return columna


func _refrescar_archivo() -> void:
	var resumenes := Progreso.de_casos(contenido.casos, descubiertas)
	_archivo.clear()
	for i in contenido.casos.size():
		var ficha: Dictionary = contenido.casos[i]
		var progreso: Dictionary = resumenes[i]
		var cerrado := Acusacion.esta_cerrado(partida.estado, ficha["id"])
		var titulo: String = ficha["titulo"]
		if ficha.get("confidencial", false):
			titulo = tr("ARCHIVO_CONFIDENCIAL") + titulo
		var nombre: String = (
			tr("ARCHIVO_ITEM")
			% [
				tr("ARCHIVO_SELLADO") if cerrado else tr("ARCHIVO_ABIERTO"),
				progreso["encontradas"],
				progreso["total"],
				titulo
			]
		)
		_archivo.add_item(nombre)
		_archivo.set_item_tooltip(i, nombre)
		if cerrado:
			_archivo.set_item_custom_bg_color(i, EstiloSiga.GRIS)
		if ficha["id"] == caso["id"]:
			_archivo.select(i)


func _al_elegir_caso(indice: int) -> void:
	caso = contenido.casos[indice]
	registro_actual = {}
	_aviso_partida = ""
	_documento.text = ""
	_cabecera.text = tr("VISOR_ELIJA")
	_titulo_ventana.text = (
		tr("VISOR_BARRA_TITULO")
		% (int(caso["anioSuceso"]) if caso.get("anioSuceso") != null else tr("SIN_FECHA_CORTA"))
	)
	_lista.clear()
	for registro in caso["registros"]:
		_lista.add_item(tr("VISOR_ITEM") % [_icono(registro["tipo"]), registro["folio"]])
	_refrescar_estado()


func _columna_documento() -> Control:
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 4)

	_cabecera = _etiqueta("", EstiloSiga.NEGRO)
	columna.add_child(_cabecera)

	_documento = RichTextLabel.new()
	_documento.bbcode_enabled = true
	_documento.fit_content = false
	_documento.scroll_active = true
	_documento.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_documento.add_theme_stylebox_override("normal", _caja_hundida(EstiloSiga.BLANCO))
	_documento.add_theme_color_override("default_color", EstiloSiga.NEGRO)
	_documento.add_theme_font_override("normal_font", theme.get_font("mono_font", "RichTextLabel"))
	_documento.add_theme_font_size_override("normal_font_size", 15)
	_documento.meta_clicked.connect(_al_pulsar_marca)
	columna.add_child(_documento)
	return columna


## Un tipo de documento se reconoce antes de leerlo, como en un gestor de
## archivos de la época.
func _icono(tipo: String) -> String:
	return ICONOS_POR_TIPO.get(tipo, "[ ]")


func _al_elegir_documento(indice: int) -> void:
	var registro: Dictionary = caso["registros"][indice]

	# Releer es GRATIS. Cobrar por volver a un documento castigaría justo lo que
	# el juego pide hacer; lo que cuesta es abrir uno nuevo, así que la decisión
	# del día es QUÉ mirar y no cuánto.
	var ya_visto: bool = jornada["leido_hoy"].has(registro["folio"])
	if not ya_visto and not Acusacion.esta_cerrado(partida.estado, caso["id"]):
		if not Jornada.gastar_accion(jornada):
			Sonido.sonar(self, "error")
			_aviso_partida = tr("VISOR_SIN_JORNADA")
			_refrescar_estado()
			return
		Jornada.anotar_lectura(jornada, registro["folio"])
		partida.guardar()

	# Abrir un documento nuevo suena a papel; releer, a nada. La diferencia se
	# oye antes de leer el aviso, y es la que cuesta una acción.
	Sonido.sonar(self, "documento" if not ya_visto else "pulsar")

	_aviso_partida = ""
	_mostrar_registro(registro)


func _mostrar_registro(registro: Dictionary) -> void:
	registro_actual = registro
	var fecha = registro.get("fecha")
	_cabecera.text = (
		tr("VISOR_CABECERA")
		% [
			registro["folio"],
			registro["tipo"].capitalize(),
			fecha if fecha != null else tr("VISOR_SIN_FECHA")
		]
	)

	var pistas := contenido.pistas_de_registro(caso, registro["id"])
	_documento.text = BBCode.render(Marcas.de_registro(registro, pistas, descubiertas))
	_refrescar_estado()


func _al_pulsar_marca(meta: Variant) -> void:
	if Acusacion.esta_cerrado(partida.estado, caso["id"]):
		return
	var partes := String(meta).split(":", true, 1)
	match partes[0]:
		"pista":
			if not descubiertas.has(partes[1]):
				descubiertas.append(partes[1])
				_refrescar_archivo()
				# Se guarda al descubrir y no al salir: este juego se cierra
				# leyendo un documento, no desde un menú.
				if not partida.guardar():
					_aviso_partida = tr("ARCHIVO_ERROR_GUARDAR")
				_mostrar_registro(registro_actual)
		"carta":
			# El relato de la carta oculta vive en prometeo-ui.js y no está
			# portado todavía; de momento solo se acusa el hallazgo.
			_estado.text = tr("VISOR_CARTA") % partes[1]
		"concepto":
			_estado.text = tr("VISOR_CONCEPTO") % partes[1]


## Abre el formulario A-7. La ventana no decide nada: rellena un papel y
## devuelve lo que  haya resuelto.
func _abrir_formulario() -> void:
	if Acusacion.esta_cerrado(partida.estado, caso["id"]):
		_aviso_partida = tr("ARCHIVO_YA_FIRMADO")
		_refrescar_estado()
		return

	var formulario: Control = load("res://escenas/acusacion.tscn").instantiate()
	formulario.caso = caso
	formulario.estado = partida.estado
	formulario.jornada = jornada
	formulario.descubiertas = descubiertas
	formulario.firmada.connect(_al_firmar.bind(formulario))
	formulario.cancelada.connect(func(): formulario.queue_free())
	add_child(formulario)


func _al_firmar(resultado: Dictionary, formulario: Control) -> void:
	formulario.queue_free()
	partida.guardar()

	_aviso_partida = (
		tr("VISOR_CERRADO")
		% [resultado["desenlace"], tr("VISOR_PRECIPITADA") if resultado["precipitada"] else ""]
	)
	_refrescar_estado()


func _refrescar_estado() -> void:
	_imputar.disabled = Acusacion.esta_cerrado(partida.estado, caso["id"])
	_refrescar_archivo()
	if not _aviso_partida.is_empty():
		_estado.text = _aviso_partida
		return
	var resumen: Dictionary = Progreso.de_casos([caso], descubiertas)[0]
	_estado.text = (
		tr("VISOR_ESTADO")
		% [
			caso["titulo"],
			resumen["encontradas"],
			resumen["total"],
			jornada.get("dia", 1),
			jornada.get("acciones", 0),
			tr("VISOR_RESUELTO") if resumen["resuelto"] else ""
		]
	)


# --- Cajas ------------------------------------------------------------------


func _etiqueta(texto: String, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.add_theme_font_size_override("font_size", 14)
	return etiqueta


func _caja_hundida(fondo: Color) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = fondo
	caja.set_corner_radius_all(0)
	caja.border_width_top = EstiloSiga.GROSOR
	caja.border_width_left = EstiloSiga.GROSOR
	caja.border_width_bottom = EstiloSiga.GROSOR
	caja.border_width_right = EstiloSiga.GROSOR
	caja.border_color = EstiloSiga.GRIS_OSCURO
	caja.content_margin_left = 8
	caja.content_margin_right = 8
	caja.content_margin_top = 6
	caja.content_margin_bottom = 6
	return caja


func _hueco() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _caja_hundida(EstiloSiga.GRIS))
	return panel


func _centrado(hijo: Control) -> Control:
	var caja := HBoxContainer.new()
	caja.add_child(hijo)
	return caja
