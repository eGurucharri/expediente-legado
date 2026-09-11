## Suite del primer corte del port a Godot. Se ejecuta sin abrir el editor:
##
##     godot4 --headless --path godot --script pruebas/pruebas.gd
##
## Los casos vienen de las pruebas JUnit del backend Java (WikiLinkServiceTest,
## HotspotServiceTest, CartaOcultaServiceTest, ProgresoServiceTest), portadas
## una a una: si el port cambia una decisión del original, la prueba lo dice.
extends SceneTree

var fallos := 0
var pasadas := 0


func _init() -> void:
	_marcas_hotspot()
	_marcas_cartas()
	_marcas_referencias()
	_marcas_solapamiento()
	_bbcode()
	_progreso()
	_contenido()

	var comprobar_cb := Callable(self, "comprobar")

	PruebasPrometeoYCombate._prometeo(comprobar_cb)
	PruebasPrometeoYCombate._partida(comprobar_cb)
	PruebasPrometeoYCombate._borrar_el_avance(comprobar_cb)
	PruebasPrometeoYCombate._historias(comprobar_cb)
	PruebasPrometeoYCombate._combate(comprobar_cb)
	PruebasPrometeoYCombate._ventanilla(comprobar_cb)
	PruebasPrometeoYCombate._jornada(comprobar_cb)
	PruebasPrometeoYCombate._procedencia(comprobar_cb)

	PruebasEspaciosYSueno._espacios(comprobar_cb)
	PruebasEspaciosYSueno._acciones_y_vuelta(comprobar_cb)
	PruebasEspaciosYSueno._acusacion(comprobar_cb)
	PruebasEspaciosYSueno._careo(comprobar_cb)
	PruebasEspaciosYSueno._cinematicas(comprobar_cb)
	PruebasEspaciosYSueno._mando(comprobar_cb)
	PruebasEspaciosYSueno._plantas(comprobar_cb)
	PruebasEspaciosYSueno._sueno(comprobar_cb)
	PruebasEspaciosYSueno._traducciones(comprobar_cb)
	PruebasEspaciosYSueno._sueno_contenido(comprobar_cb)

	PruebasSuenoFinal._compilan(comprobar_cb)
	PruebasSuenoFinal._salida_del_sueno(comprobar_cb)
	PruebasSuenoFinal._jornada_antigua(comprobar_cb)
	PruebasSuenoFinal._companeros(comprobar_cb)
	PruebasSuenoFinal._sonido(comprobar_cb)

	PruebasSemilla._semilla(comprobar_cb)
	PruebasHistoria.catalogo(comprobar_cb)

	print("\n%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO %s\n  esperado: %s\n  obtenido: %s" % [nombre, esperado, obtenido])


# --- HotspotServiceTest -----------------------------------------------------


func _marcas_hotspot() -> void:
	var texto := "El pago se autorizó sin revisión previa por orden directa."

	# renderReturnsEscapedContentWhenNoTriggerPhraseIsProvided
	comprobar(
		"sin frase gatillo: un solo segmento plano",
		Marcas.segmentar(texto, [Marcas.frase(texto, "", "pista", {})]),
		[{"texto": texto, "tipo": "", "meta": {}}]
	)

	# renderLeavesContentUnchangedWhenTriggerPhraseIsNotFound
	comprobar(
		"frase ausente: un solo segmento plano",
		Marcas.segmentar(texto, [Marcas.frase(texto, "no está aquí", "pista", {})]).size(),
		1
	)

	# renderHighlightsPhraseAsButtonWhenNotDiscovered
	var sin_descubrir := Marcas.segmentar(
		texto, [Marcas.frase(texto, "sin revisión previa", "pista", {"pista": "p1"})]
	)
	comprobar("pista sin descubrir: tres segmentos", sin_descubrir.size(), 3)
	comprobar(
		"pista sin descubrir: el del medio es la frase",
		sin_descubrir[1],
		{"texto": "sin revisión previa", "tipo": "pista", "meta": {"pista": "p1"}}
	)

	# renderHighlightsPhraseAsReadMarkerWhenAlreadyDiscovered
	var descubierta := Marcas.segmentar(
		texto, [Marcas.frase(texto, "sin revisión previa", "pista_vista", {"pista": "p1"})]
	)
	comprobar("pista descubierta: queda como leída", descubierta[1]["tipo"], "pista_vista")


# --- CartaOcultaServiceTest -------------------------------------------------


func _marcas_cartas() -> void:
	# aplicarResaltaLaFraseCuandoElFolioTieneUnaCartaAsignada
	comprobar("folio con carta", CartasOcultas.en_folio("F-1996-00187")["carta"], "la-luna")
	# aplicarDejaElHtmlSinCambiosCuandoElFolioNoTieneCartaAsignada
	comprobar("folio sin carta", CartasOcultas.en_folio("EMP-0456"), {})
	# aplicarToleraFolioONulos
	comprobar("folio nulo", CartasOcultas.en_folio(null), {})

	# aplicarResaltaFrasesConAcentosSobreHtmlYaEscapadoPorHotspotService:
	# en Java esta prueba existía porque la frase se buscaba sobre HTML ya
	# escapado y una tilde (é -> &eacute;) no coincidía. Aquí no hay escapado
	# intermedio, así que la tilde es texto normal — pero la comprobación se
	# conserva porque el fallo que cubría (una carta que no aparece nunca) es
	# el mismo.
	var fax := "Trazos que no corresponden a ningún alfabeto reconocido."
	var carta := CartasOcultas.en_folio("FAX-1996-077")
	comprobar(
		"carta con tildes se localiza",
		Marcas.frase(fax, carta["frase"], "carta", {}).is_empty(),
		false
	)

	# aplicarDejaElHtmlSinCambiosCuandoLaFraseNoApareceEnElContenido
	comprobar(
		"carta cuya frase no está en el documento",
		Marcas.frase("Otro contenido.", carta["frase"], "carta", {}),
		{}
	)


# --- WikiLinkServiceTest ----------------------------------------------------


func _marcas_referencias() -> void:
	var texto := "Llegó a [[Empleado #427]] y después al [[Archivo Muerto]]."

	# extraerReferenciasDevuelveLosNombresEnOrdenDeAparicion
	var nombres := Marcas.referencias(texto, []).map(func(h): return h["meta"]["nombre"])
	comprobar("referencias en orden", nombres, ["Empleado #427", "Archivo Muerto"])

	# extraerReferenciasDevuelveListaVaciaSinReferenciasOTextoNulo
	comprobar("texto sin referencias", Marcas.referencias("Sin corchetes.", []), [])
	comprobar("texto vacío", Marcas.referencias("", []), [])

	# extraerReferenciasPreservaAcentosSinPasarPorEscapadoHtml
	var con_tilde := "Ver [[Carcosa Servicios Escénicos]]."
	comprobar(
		"referencia con tilde",
		Marcas.referencias(con_tilde, [])[0]["meta"]["nombre"],
		"Carcosa Servicios Escénicos"
	)

	# renderCreatesLinksForUnlockedConceptsAndLocksUnknownOnes
	var mezcla := Marcas.referencias(texto, ["Empleado #427"])
	comprobar("concepto desbloqueado", mezcla[0]["tipo"], "concepto")
	comprobar("concepto sin desbloquear", mezcla[1]["tipo"], "concepto_pendiente")

	# renderEscapesHtmlAndPreservesReferenceText: los corchetes desaparecen y
	# lo que queda es el nombre.
	var segmentos := Marcas.segmentar(texto, Marcas.referencias(texto, ["Empleado #427"]))
	var visible := ""
	for s in segmentos:
		visible += s["texto"]
	comprobar(
		"el texto visible pierde los corchetes",
		visible,
		"Llegó a Empleado #427 y después al Archivo Muerto."
	)


# --- Propio del port: lo que el encadenado de Java no decidía ---------------


func _marcas_solapamiento() -> void:
	# En Java, CartaOcultaService hacía indexOf sobre el HTML que ya había
	# generado HotspotService: una frase de carta contenida en una frase de
	# pista partía el marcado por la mitad. Aquí gana la que empieza antes y
	# la otra se descarta entera.
	var texto := "El sello no corresponde: es de color amarillo, sin duda."
	var hallazgos := [
		Marcas.frase(texto, "es de color amarillo, sin duda", "pista", {"pista": "p1"}),
		Marcas.frase(texto, "es de color amarillo", "carta", {"carta": "la-luna"}),
	]
	var segmentos := Marcas.segmentar(texto, hallazgos)
	comprobar("solapamiento: gana la que empieza antes", segmentos[1]["tipo"], "pista")
	var recompuesto := ""
	for s in segmentos:
		recompuesto += s["texto"]
	comprobar("solapamiento: el texto se conserva entero", recompuesto, texto)


# --- BBCode -----------------------------------------------------------------


func _bbcode() -> void:
	comprobar(
		"texto plano pasa tal cual",
		BBCode.render([{"texto": "Sin marcas.", "tipo": "", "meta": {}}]),
		"Sin marcas."
	)

	# El equivalente del escapado HTML del original: un corchete literal en un
	# expediente abriría una etiqueta de RichTextLabel.
	comprobar(
		"un corchete del texto se escapa",
		BBCode.render([{"texto": "Anexo [sic] al margen", "tipo": "", "meta": {}}]),
		"Anexo [lb]sic] al margen"
	)

	comprobar(
		"una pista es pulsable",
		BBCode.render([{"texto": "sin revisión previa", "tipo": "pista", "meta": {"pista": "p1"}}]),
		"[url=pista:p1][color=#0000aa][u]sin revisión previa[/u][/color][/url]"
	)

	comprobar(
		"un concepto pendiente no lleva a ninguna parte",
		BBCode.render([{"texto": "Archivo Muerto", "tipo": "concepto_pendiente", "meta": {}}]),
		"[color=#808080]Archivo Muerto[/color]"
	)


# --- ProgresoServiceTest ----------------------------------------------------


func _progreso() -> void:
	var caso_a := {"id": "a", "pistas": [{"id": "p1"}, {"id": "p2"}]}
	var caso_b := {"id": "b", "pistas": [{"id": "p3"}]}
	var sin_pistas := {"id": "c", "pistas": []}

	# casoResueltoReturnsTrueOnlyWhenAllPistasAreDiscovered
	comprobar("caso a medias no está resuelto", Progreso.caso_resuelto(caso_a, ["p1"]), false)
	comprobar("caso completo está resuelto", Progreso.caso_resuelto(caso_a, ["p1", "p2"]), true)
	comprobar(
		"un caso sin pistas nunca está resuelto", Progreso.caso_resuelto(sin_pistas, []), false
	)

	# todosResueltosRequiresNonEmptyCaseListAndAllCasesClosed
	comprobar("lista vacía de casos no es victoria", Progreso.todos_resueltos([], []), false)
	comprobar(
		"todos resueltos", Progreso.todos_resueltos([caso_a, caso_b], ["p1", "p2", "p3"]), true
	)
	comprobar("uno sin resolver", Progreso.todos_resueltos([caso_a, caso_b], ["p1", "p2"]), false)

	# progresoBuildsCaseProgressSummary
	var resumen := Progreso.de_casos([caso_a, caso_b], ["p1", "p3"])
	comprobar(
		"resumen del primer caso",
		[resumen[0]["total"], resumen[0]["encontradas"], resumen[0]["resuelto"]],
		[2, 1, false]
	)
	comprobar(
		"resumen del segundo caso",
		[resumen[1]["total"], resumen[1]["encontradas"], resumen[1]["resuelto"]],
		[1, 1, true]
	)


# --- El contenido de verdad -------------------------------------------------


func _contenido() -> void:
	var contenido := Contenido.new()
	comprobar("casos.json carga", contenido.cargar(), true)

	# Las mismas cifras que las llamadas .save() de DataSeeder.java.
	comprobar("ocho casos", contenido.casos.size(), 8)
	comprobar("dieciséis conceptos", contenido.conceptos.size(), 16)
	var registros := 0
	var pistas := 0
	var sospechosos := 0
	for c in contenido.casos:
		registros += c["registros"].size()
		pistas += c["pistas"].size()
		sospechosos += c["sospechosos"].size()
	comprobar("treinta y dos registros", registros, 32)
	comprobar("treinta y cinco pistas", pistas, 35)
	comprobar("veintisiete sospechosos", sospechosos, 27)
	# Seis, no siete: el expediente de la herencia Karamázov y el del empleado
	# #427 están marcados como no principales en el contenido original, así que
	# el final principal no depende de ellos.
	comprobar("seis casos principales", contenido.principales().size(), 6)

	# Los años son enteros, no "1999.0". Es el fallo del float de JSON, que ya
	# se coló dos veces en pantallas distintas antes de arreglarse por donde
	# entra.
	var anios_decimales := contenido.casos.filter(
		func(c): return c.get("anioSuceso") != null and typeof(c["anioSuceso"]) != TYPE_INT
	)
	comprobar("los años son enteros", anios_decimales, [])

	# Y ninguno se queda SIN año. La comprobación de arriba filtra por
	# `!= null`, así que un caso sin la clave pasaba de largo: el caso 8 llevaba
	# así desde el sembrado, y el A-7 le enseñaba "sin fecha" al jugador (#53).
	var sin_campo := func(campo: String) -> Array:
		return (
			contenido
			. casos
			. filter(
				func(c): return c.get(campo) == null or str(c.get(campo)).strip_edges().is_empty()
			)
			. map(func(c): return c["id"])
		)
	comprobar("ningún caso se queda sin año", sin_campo.call("anioSuceso"), [])
	comprobar("ni sin estado", sin_campo.call("estado"), [])
	comprobar("ni sin título", sin_campo.call("titulo"), [])

	# Toda referencia [[...]] de un concepto apunta a un concepto que existe:
	# si no, el corcho tendría un enlace a un expediente inexistente.
	var nombres := contenido.conceptos.map(func(c): return c["nombre"])
	var rotas := []
	for concepto in contenido.conceptos:
		for hallazgo in Marcas.referencias(concepto.get("resumen", ""), nombres):
			if not nombres.has(hallazgo["meta"]["nombre"]):
				rotas.append(hallazgo["meta"]["nombre"])
	comprobar("ninguna referencia del corcho apunta al vacío", rotas, [])

	# Las ocho cartas ocultas tienen que estar en un documento de verdad, y su
	# frase tiene que aparecer en él: es lo único que las hace encontrables.
	var perdidas := []
	for folio in CartasOcultas.POR_FOLIO:
		var encontrado := false
		for c in contenido.casos:
			for r in c["registros"]:
				if r["folio"] == folio:
					encontrado = true
					if String(r["contenido"]).find(CartasOcultas.POR_FOLIO[folio]["frase"]) < 0:
						perdidas.append(folio + " (frase ausente)")
		if not encontrado:
			perdidas.append(folio + " (folio inexistente)")
	comprobar("las ocho cartas ocultas son alcanzables", perdidas, [])

	# Toda pista con frase gatillo debe poder resaltarse en su documento.
	var gatillos_rotos := []
	for c in contenido.casos:
		for p in c["pistas"]:
			if p.get("fraseGatillo") == null:
				continue
			for r in c["registros"]:
				if (
					r["id"] == p["registroOrigen"]
					and String(r["contenido"]).find(p["fraseGatillo"]) < 0
				):
					gatillos_rotos.append(p["id"])
	comprobar("toda frase gatillo está en su documento", gatillos_rotos, [])

	# Dos cosas que el extractor perdió en silencio y que ninguna cuenta veía:
	# los enlaces de un concepto a sus pistas (llegaban vacíos) y las réplicas
	# de un sospechoso (llegaban como UNA cadena con las tres pegadas).
	var enlaces_rotos := []
	var ids_pista := {}
	for c in contenido.casos:
		for p in c["pistas"]:
			ids_pista[p["id"]] = true
	for concepto in contenido.conceptos:
		for id in concepto.get("pistas", []):
			if not ids_pista.has(id):
				enlaces_rotos.append(id)
	comprobar("los conceptos citan pistas que existen", enlaces_rotos, [])
	comprobar(
		"y casi todos citan alguna",
		contenido.conceptos.filter(func(c): return not c.get("pistas", []).is_empty()).size(),
		15
	)

	var replicas_mal := []
	for c in contenido.casos:
		for sospechoso in c["sospechosos"]:
			var ataques = sospechoso.get("ataques")
			if ataques == null:
				continue
			if typeof(ataques) != TYPE_ARRAY or ataques.size() != 3:
				replicas_mal.append(sospechoso["nombre"])
	comprobar("los cuatro rivales tienen sus tres réplicas sueltas", replicas_mal, [])

	# La cadena entera sobre un documento de verdad, que es lo que el visor
	# pinta: contenido -> marcas -> BBCode.
	var memo := {}
	for r in contenido.casos[0]["registros"]:
		if r["folio"] == "MEMO-1999-088":
			memo = r
	var pistas_memo := contenido.pistas_de_registro(contenido.casos[0], memo["id"])
	var sin_ver := BBCode.render(Marcas.de_registro(memo, pistas_memo, []))
	comprobar("un memorándum real deja su frase pulsable", sin_ver.contains("[url=pista:"), true)
	var ya_visto := BBCode.render(Marcas.de_registro(memo, pistas_memo, [pistas_memo[0]["id"]]))
	comprobar("y al descubrirla queda marcada como leída", ya_visto.contains("[bgcolor="), true)
	comprobar(
		"el texto del documento no cambia al descubrirla",
		_sin_etiquetas(sin_ver),
		_sin_etiquetas(ya_visto)
	)


## El texto visible, sin el marcado: lo que el jugador lee.
func _sin_etiquetas(bbcode: String) -> String:
	var expresion := RegEx.new()
	expresion.compile("\\[[^\\]]*\\]")
	return expresion.sub(bbcode, "", true)
