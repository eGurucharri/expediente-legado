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
	_prometeo()
	_partida()
	_historias()
	_combate()
	_ventanilla()
	_jornada()
	_procedencia()
	_espacios()
	_acciones_y_vuelta()
	_acusacion()
	_careo()
	_cinematicas()
	_plantas()
	_sueno()
	_traducciones()

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
	comprobar("sin frase gatillo: un solo segmento plano",
		Marcas.segmentar(texto, [Marcas.frase(texto, "", "pista", {})]),
		[{"texto": texto, "tipo": "", "meta": {}}])

	# renderLeavesContentUnchangedWhenTriggerPhraseIsNotFound
	comprobar("frase ausente: un solo segmento plano",
		Marcas.segmentar(texto, [Marcas.frase(texto, "no está aquí", "pista", {})]).size(), 1)

	# renderHighlightsPhraseAsButtonWhenNotDiscovered
	var sin_descubrir := Marcas.segmentar(
		texto, [Marcas.frase(texto, "sin revisión previa", "pista", {"pista": "p1"})])
	comprobar("pista sin descubrir: tres segmentos", sin_descubrir.size(), 3)
	comprobar("pista sin descubrir: el del medio es la frase",
		sin_descubrir[1], {"texto": "sin revisión previa", "tipo": "pista", "meta": {"pista": "p1"}})

	# renderHighlightsPhraseAsReadMarkerWhenAlreadyDiscovered
	var descubierta := Marcas.segmentar(
		texto, [Marcas.frase(texto, "sin revisión previa", "pista_vista", {"pista": "p1"})])
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
	comprobar("carta con tildes se localiza",
		Marcas.frase(fax, carta["frase"], "carta", {}).is_empty(), false)

	# aplicarDejaElHtmlSinCambiosCuandoLaFraseNoApareceEnElContenido
	comprobar("carta cuya frase no está en el documento",
		Marcas.frase("Otro contenido.", carta["frase"], "carta", {}), {})

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
	comprobar("referencia con tilde",
		Marcas.referencias(con_tilde, [])[0]["meta"]["nombre"], "Carcosa Servicios Escénicos")

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
	comprobar("el texto visible pierde los corchetes",
		visible, "Llegó a Empleado #427 y después al Archivo Muerto.")

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
	comprobar("texto plano pasa tal cual",
		BBCode.render([{"texto": "Sin marcas.", "tipo": "", "meta": {}}]), "Sin marcas.")

	# El equivalente del escapado HTML del original: un corchete literal en un
	# expediente abriría una etiqueta de RichTextLabel.
	comprobar("un corchete del texto se escapa",
		BBCode.render([{"texto": "Anexo [sic] al margen", "tipo": "", "meta": {}}]),
		"Anexo [lb]sic] al margen")

	comprobar("una pista es pulsable",
		BBCode.render([{"texto": "sin revisión previa", "tipo": "pista", "meta": {"pista": "p1"}}]),
		"[url=pista:p1][color=#0000aa][u]sin revisión previa[/u][/color][/url]")

	comprobar("un concepto pendiente no lleva a ninguna parte",
		BBCode.render([{"texto": "Archivo Muerto", "tipo": "concepto_pendiente", "meta": {}}]),
		"[color=#808080]Archivo Muerto[/color]")

# --- ProgresoServiceTest ----------------------------------------------------

func _progreso() -> void:
	var caso_a := {"id": "a", "pistas": [{"id": "p1"}, {"id": "p2"}]}
	var caso_b := {"id": "b", "pistas": [{"id": "p3"}]}
	var sin_pistas := {"id": "c", "pistas": []}

	# casoResueltoReturnsTrueOnlyWhenAllPistasAreDiscovered
	comprobar("caso a medias no está resuelto", Progreso.caso_resuelto(caso_a, ["p1"]), false)
	comprobar("caso completo está resuelto", Progreso.caso_resuelto(caso_a, ["p1", "p2"]), true)
	comprobar("un caso sin pistas nunca está resuelto",
		Progreso.caso_resuelto(sin_pistas, []), false)

	# todosResueltosRequiresNonEmptyCaseListAndAllCasesClosed
	comprobar("lista vacía de casos no es victoria", Progreso.todos_resueltos([], []), false)
	comprobar("todos resueltos",
		Progreso.todos_resueltos([caso_a, caso_b], ["p1", "p2", "p3"]), true)
	comprobar("uno sin resolver",
		Progreso.todos_resueltos([caso_a, caso_b], ["p1", "p2"]), false)

	# progresoBuildsCaseProgressSummary
	var resumen := Progreso.de_casos([caso_a, caso_b], ["p1", "p3"])
	comprobar("resumen del primer caso",
		[resumen[0]["total"], resumen[0]["encontradas"], resumen[0]["resuelto"]], [2, 1, false])
	comprobar("resumen del segundo caso",
		[resumen[1]["total"], resumen[1]["encontradas"], resumen[1]["resuelto"]], [1, 1, true])

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
		func(c): return c.get("anioSuceso") != null and typeof(c["anioSuceso"]) != TYPE_INT)
	comprobar("los años son enteros", anios_decimales, [])

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
				if r["id"] == p["registroOrigen"] and String(r["contenido"]).find(p["fraseGatillo"]) < 0:
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
	comprobar("y casi todos citan alguna",
		contenido.conceptos.filter(func(c): return not c.get("pistas", []).is_empty()).size(),
		15)

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
	comprobar("un memorándum real deja su frase pulsable",
		sin_ver.contains("[url=pista:"), true)
	var ya_visto := BBCode.render(
		Marcas.de_registro(memo, pistas_memo, [pistas_memo[0]["id"]]))
	comprobar("y al descubrirla queda marcada como leída",
		ya_visto.contains("[bgcolor="), true)
	comprobar("el texto del documento no cambia al descubrirla",
		_sin_etiquetas(sin_ver), _sin_etiquetas(ya_visto))


## El texto visible, sin el marcado: lo que el jugador lee.
func _sin_etiquetas(bbcode: String) -> String:
	var expresion := RegEx.new()
	expresion.compile("\\[[^\\]]*\\]")
	return expresion.sub(bbcode, "", true)


# --- prometeo-logic.test.js -------------------------------------------------

func _prometeo() -> void:
	# fusionarConGuardado
	var actuales := [{"id": "a", "titulo": "Nuevo título", "desbloqueado": false}]
	comprobar("fusión: conserva el estado guardado y adopta los metadatos nuevos",
		Prometeo.fusionar_con_guardado(
			[{"id": "a", "titulo": "Título viejo", "desbloqueado": true}],
			actuales, ["desbloqueado"]),
		[{"id": "a", "titulo": "Nuevo título", "desbloqueado": true}])
	comprobar("fusión: sin guardado previo quedan los valores de serie",
		Prometeo.fusionar_con_guardado([], actuales, ["desbloqueado"]), actuales)
	comprobar("fusión: encuentra el guardado por un id renombrado",
		Prometeo.fusionar_con_guardado(
			[{"id": "viejo", "desbloqueado": true}], actuales,
			["desbloqueado"], {"a": "viejo"})[0]["desbloqueado"], true)
	comprobar("fusión: no muta la lista de entrada",
		actuales[0]["desbloqueado"], false)

	# desbloquearCartaEnLista
	var tarot := [{"id": "la-luna", "recogida": false}, {"id": "el-loco", "recogida": true}]
	comprobar("carta nueva: hay novedad", Prometeo.desbloquear_carta(tarot, "la-luna"), true)
	comprobar("carta ya recogida: no hay novedad",
		Prometeo.desbloquear_carta(tarot, "el-loco"), false)
	comprobar("carta inexistente: no hay novedad",
		Prometeo.desbloquear_carta(tarot, "no-existe"), false)

	# esAcusacionPrecipitada
	comprobar("acusar con poca evidencia es precipitado",
		Prometeo.acusacion_precipitada(1, 5, 0.5), true)
	comprobar("acusar justo en el umbral no es precipitado",
		Prometeo.acusacion_precipitada(3, 6, 0.5), false)
	comprobar("un caso sin pistas nunca da acusación precipitada",
		Prometeo.acusacion_precipitada(0, 0, 0.5), false)

	# calcularEjeGanador
	var historias := {
		"la-luna": "neoliberal", "el-sol": "neoliberal", "el-carro": "centrista"}
	comprobar("gana el eje más votado",
		Prometeo.eje_ganador(historias, ["la-luna", "el-sol", "el-carro"]), "neoliberal")
	comprobar("en empate gana el primero del orden",
		Prometeo.eje_ganador({"a": "centrista", "b": "comunismo"}, ["a", "b"]), "comunismo")
	comprobar("sin historias resueltas gana el primero del orden",
		Prometeo.eje_ganador({}, []), "comunismo")
	comprobar("un eje desconocido no cuenta",
		Prometeo.eje_ganador({"a": "monarquia"}, ["a"]), "comunismo")

	# contarPuntosPorEje
	comprobar("puntos por eje",
		Prometeo.puntos_por_eje(historias, ["la-luna", "el-sol", "el-carro"]),
		{"comunismo": 0, "socialdemocrata": 0, "centrista": 1, "neoliberal": 2})
	comprobar("una historia sin resolver no puntúa",
		Prometeo.puntos_por_eje(historias, [])["neoliberal"], 0)

	# UTILIDAD_CARTAS: las dos invariantes de #45
	comprobar("las ocho historias tienen dos ejes útiles cada una",
		Prometeo.UTILIDAD_CARTAS.values().all(func(u): return u.size() == 2), true)
	var veces_util := {}
	for eje in Prometeo.EJES:
		veces_util[eje] = 0
	for utiles in Prometeo.UTILIDAD_CARTAS.values():
		for eje in utiles:
			veces_util[eje] += 1
	# Sin esto el juego estaría diciendo cuál es la ideología correcta.
	comprobar("cada ideología es útil en exactamente 4 de las 8 cartas",
		veces_util, {"comunismo": 4, "socialdemocrata": 4, "centrista": 4, "neoliberal": 4})
	comprobar("un eje útil de la carta es pista",
		Prometeo.clasificar_eleccion("la-luna", "centrista"), "pista")
	comprobar("un eje que no lo es, confusión",
		Prometeo.clasificar_eleccion("la-luna", "comunismo"), "confusion")

	# indiceJugadaRival
	comprobar("modo ciclo: el ritmo autorado del duelo",
		[Prometeo.jugada_rival("ciclo", 0, 3, func(): return 0.0),
		 Prometeo.jugada_rival("ciclo", 4, 3, func(): return 0.0)], [0, 1])
	# Con tirada baja contesta a la última jugada: lo que vence a X es el
	# índice anterior a X en la cadena circular. La tirada va como secuencia y
	# no como valor fijo porque la rama que NO reacciona gasta dos tiradas (una
	# para decidir y otra para elegir), y con un valor único las dos ramas
	# pueden dar el mismo número por casualidad — que es lo que le pasaba a
	# esta prueba antes.
	comprobar("modo reactiva: con tirada baja contraataca la jugada 1",
		Prometeo.jugada_rival("reactiva", 0, 3, _tiradas([0.1]), 1), 0)
	comprobar("modo reactiva: con tirada alta ignora la jugada y va al azar",
		Prometeo.jugada_rival("reactiva", 0, 3, _tiradas([0.9, 0.5]), 1), 1)
	comprobar("modo reactiva: en la primera ronda no hay a qué contestar",
		Prometeo.jugada_rival("reactiva", 0, 3, _tiradas([0.99]), -1), 2)


	# actualizarRacha
	comprobar("ganar suma y puede batir la marca",
		Prometeo.actualizar_racha(2, 2, true), {"racha": 3, "mejor": 3})
	comprobar("ganar sin batir conserva la marca",
		Prometeo.actualizar_racha(1, 9, true), {"racha": 2, "mejor": 9})
	comprobar("perder devuelve a cero sin tocar la marca",
		Prometeo.actualizar_racha(5, 9, false), {"racha": 0, "mejor": 9})

	# reiniciarEstadoPerRunEnEstado: la frontera de #46
	var estado := {
		"vida": 1, "despido_mostrado": true, "historias_cartas": {"a": "comunismo"},
		"final_politico_mostrado": true, "final_verdadero_mostrado": true,
		"epilogo_avisado": true, "perdio_vida_en_esta_vuelta": true,
		"tarot": [
			{"id": "el-loco", "recogida": false, "gastada": true},
			{"id": "la-luna", "recogida": true, "gastada": true}],
		"logros": [
			{"id": "desempeno", "por_vuelta": true, "desbloqueado": true},
			{"id": "vitrina", "por_vuelta": false, "desbloqueado": true}],
		"cartas_conocidas": ["la-luna"], "coliseo_racha_mejor": 7,
		"dificultad": "dura", "algunavez_perdio": true,
	}
	Prometeo.reiniciar_vuelta(estado, 3)

	comprobar("la vuelta borra la vida y los avisos",
		[estado["vida"], estado["despido_mostrado"], estado["epilogo_avisado"]],
		[3, false, false])
	comprobar("la vuelta borra las decisiones políticas y los finales",
		[estado["historias_cartas"], estado["final_politico_mostrado"],
		 estado["final_verdadero_mostrado"]], [{}, false, false])
	comprobar("el tarot vuelve a la posesión inicial: solo El Loco",
		estado["tarot"], [
			{"id": "el-loco", "recogida": true, "gastada": false},
			{"id": "la-luna", "recogida": false, "gastada": false}])
	comprobar("los logros de desempeño se re-bloquean",
		estado["logros"][0]["desbloqueado"], false)
	comprobar("los de vitrina NO se tocan", estado["logros"][1]["desbloqueado"], true)
	comprobar("la memoria de por vida sobrevive entera",
		[estado["cartas_conocidas"], estado["coliseo_racha_mejor"],
		 estado["dificultad"], estado["algunavez_perdio"]],
		[["la-luna"], 7, "dura", true])
## Un generador de tiradas guionizado, para poder distinguir las dos ramas del
## rival reactivo.
func _tiradas(valores: Array) -> Callable:
	var estado := {"i": 0}
	return func():
		var valor: float = valores[estado["i"]]
		estado["i"] += 1
		return valor


# --- Persistencia -----------------------------------------------------------

const RUTA_PRUEBA := "user://partida-de-prueba.json"

func _partida() -> void:
	_borrar_pruebas()

	# Sin fichero se empieza de cero, y se DICE que se empieza de cero: que una
	# partida no se haya podido leer no puede parecerse a no haber jugado nunca.
	var partida := Partida.new()
	comprobar("sin partida guardada se empieza una nueva",
		partida.cargar(RUTA_PRUEBA)["resultado"], "nueva")
	comprobar("los catálogos llegan enteros",
		[partida.estado["logros"].size(), partida.estado["tarot"].size()], [20, 22])
	comprobar("solo El Loco viene de serie",
		partida.estado["tarot"].filter(func(c): return c["recogida"]).map(
			func(c): return c["id"]), ["el-loco"])

	# Ida y vuelta.
	partida.estado["pistas_descubiertas"] = ["p1", "p2"]
	partida.estado["coliseo_racha_mejor"] = 4
	Prometeo.desbloquear_carta(partida.estado["tarot"], "la-luna")
	comprobar("guardar dice que guardó", partida.guardar(RUTA_PRUEBA), true)

	var releida := Partida.new()
	comprobar("la partida se recupera", releida.cargar(RUTA_PRUEBA)["resultado"], "cargada")
	comprobar("con sus pistas y su racha",
		[releida.estado["pistas_descubiertas"], releida.estado["coliseo_racha_mejor"]],
		[["p1", "p2"], 4])
	comprobar("y con la carta conseguida",
		releida.estado["tarot"].filter(func(c): return c["recogida"]).map(
			func(c): return c["id"]), ["el-loco", "la-luna"])

	# El guardado NO se lleva una copia del contenido: si lo hiciera, reescribir
	# la descripción de un logro dejaría las partidas viejas mostrando la
	# antigua. Solo ids y banderas.
	var crudo := FileAccess.open(RUTA_PRUEBA, FileAccess.READ).get_as_text()
	comprobar("la partida guardada no lleva texto de los catálogos",
		crudo.contains("Abriste el menú"), false)
	comprobar("pero sí los ids y su estado",
		crudo.contains("primer-mirada") and crudo.contains("desbloqueado"), true)
	comprobar("y al releerla los títulos vuelven del catálogo",
		releida.estado["logros"][0]["titulo"], "Primer mirada")

	# Un logro que la versión nueva añade aparece en una partida antigua sin
	# borrar lo ya conseguido: es la fusión de #46, no una carga a secas.
	var vieja := Partida.nueva()
	vieja["logros"] = [{"id": "sospecha", "desbloqueado": true}]
	vieja["tarot"] = []
	_escribir(RUTA_PRUEBA, vieja)
	var migrada := Partida.new()
	migrada.cargar(RUTA_PRUEBA)
	comprobar("una partida con menos logros recupera el catálogo entero",
		migrada.estado["logros"].size(), 20)
	comprobar("y conserva el que ya tenía desbloqueado",
		migrada.estado["logros"].filter(
			func(l): return l["id"] == "sospecha")[0]["desbloqueado"], true)
	comprobar("los logros nuevos llegan bloqueados",
		migrada.estado["logros"].filter(
			func(l): return l["id"] == "primer-mirada")[0]["desbloqueado"], false)

	# Una partida ilegible se aparta, NO se pisa. Es la diferencia entre perder
	# una partida y poder recuperarla.
	_escribir_texto(RUTA_PRUEBA, "{esto no es json")
	var rota := Partida.new()
	var resultado := rota.cargar(RUTA_PRUEBA)
	comprobar("una partida corrupta se aparta", resultado["resultado"], "apartada")
	comprobar("y queda una copia del fichero original",
		FileAccess.file_exists(RUTA_PRUEBA + ".roto"), true)
	comprobar("mientras tanto se juega con una nueva",
		rota.estado["pistas_descubiertas"], [])

	# Una partida de una versión POSTERIOR tampoco se interpreta a medias.
	var futura := Partida.nueva()
	futura["version"] = Partida.VERSION + 1
	futura["pistas_descubiertas"] = ["no debería leerse"]
	_escribir(RUTA_PRUEBA, futura)
	var adelantada := Partida.new()
	comprobar("una partida de una versión posterior se aparta",
		adelantada.cargar(RUTA_PRUEBA)["resultado"], "apartada")
	comprobar("y no se lee nada de ella",
		adelantada.estado["pistas_descubiertas"], [])

	_borrar_pruebas()


func _escribir(ruta: String, datos: Dictionary) -> void:
	_escribir_texto(ruta, JSON.stringify(datos))


func _escribir_texto(ruta: String, texto: String) -> void:
	var fichero := FileAccess.open(ruta, FileAccess.WRITE)
	fichero.store_string(texto)
	fichero.close()


func _borrar_pruebas() -> void:
	for sufijo in ["", ".roto", ".nuevo"]:
		var ruta: String = RUTA_PRUEBA + sufijo
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))


# --- Las historias políticas -------------------------------------------------

func _historias() -> void:
	var historias := Historias.new()
	comprobar("el catálogo de historias carga", historias.cargar(), true)
	comprobar("son ocho", historias.catalogo.size(), 8)

	# Una historia por carta oculta, ni más ni menos: una carta sin historia
	# sería un hallazgo que no lleva a ninguna parte, y una historia sin carta
	# un relato inalcanzable.
	var ids_historias := historias.catalogo.keys()
	ids_historias.sort()
	var ids_cartas := CartasOcultas.POR_FOLIO.values().map(func(c): return c["carta"])
	ids_cartas.sort()
	comprobar("cada carta oculta tiene su historia y al revés", ids_historias, ids_cartas)

	var estado := {"historias_cartas": {}}

	# Sin resolver se ofrecen las cuatro salidas.
	var pendiente := historias.vista(estado, "la-luna")
	comprobar("una historia sin resolver ofrece sus opciones", pendiente["estado"], "pendiente")
	comprobar("y son cuatro, una por eje",
		pendiente["opciones"].map(func(o): return o["eje"]),
		["comunismo", "centrista", "socialdemocrata", "neoliberal"])

	# La Luna es útil para centrista y neoliberal (Prometeo.UTILIDAD_CARTAS).
	var util := historias.resolver(estado, "la-luna", "centrista")
	comprobar("la elección útil se clasifica como pista", util["clasificacion"], "pista")
	comprobar("y su secuela apunta a documentos reales",
		util["secuela"] == historias.de("la-luna")["secuelaUtil"], true)

	# Una historia resuelta ya no se vuelve a preguntar, y NO se puede cambiar
	# el voto: en el original la asignación era incondicional y solo la interfaz
	# lo impedía.
	comprobar("una historia resuelta no vuelve a ofrecer opciones",
		historias.vista(estado, "la-luna")["estado"], "resuelta")
	historias.resolver(estado, "la-luna", "comunismo")
	comprobar("y el voto no se puede cambiar",
		estado["historias_cartas"]["la-luna"], "centrista")

	# Una elección que no era la útil da la secuela que despista.
	var confusa := historias.resolver(estado, "la-justicia", "centrista")
	comprobar("la elección inútil se clasifica como confusión",
		confusa["clasificacion"], "confusion")
	comprobar("y su secuela es la que despista",
		confusa["secuela"] == historias.de("la-justicia")["secuelaConfusion"], true)

	# Las cargas: tope de dos, así que casarse con una ideología no da ocho usos.
	comprobar("dos elecciones del mismo eje dan dos cargas",
		historias.cargas(estado)["centrista"], 2)
	historias.resolver(estado, "el-carro", "centrista")
	comprobar("la tercera ya no suma: el tope es dos",
		historias.cargas(estado)["centrista"], 2)
	comprobar("un eje sin elegir no tiene cargas",
		historias.cargas(estado)["neoliberal"], 0)

	comprobar("quedan cinco historias por decidir", historias.pendientes(estado), 5)

	# Cada eje tiene su habilidad declarada, o una carga sería inservible.
	comprobar("los cuatro ejes tienen habilidad",
		Prometeo.EJES.all(func(e): return Historias.HABILIDADES.has(e)), true)

	# Una carta que no existe no revienta ni inventa una historia.
	comprobar("una carta sin historia devuelve vacío", historias.vista(estado, "el-loco"), {})


# --- El motor de combate -----------------------------------------------------

func _combate() -> void:
	# La cadena circular tiene que cerrarse: si un tipo no venciera a nadie o
	# venciera a dos, habría una jugada dominante y el juego se acabaría.
	var vencidos := Combate.TIPOS.map(func(t): return Combate.vence_a(t))
	vencidos.sort()
	var todos := Combate.TIPOS.duplicate()
	todos.sort()
	comprobar("cada tipo lo vence exactamente otro", vencidos, todos)
	comprobar("objeción vence al silencio", Combate.vence_a("silencio"), "objecion")

	var rival := {"nombre": "La Ventanilla", "ataques": ["Vuelva usted mañana."]}
	var sin_azar := func(): return 0.0

	# En modo ciclo el rival es la ronda módulo tres: determinista y aprendible.
	var duelo := Combate.nuevo("ciclo", rival)
	var r1 := Combate.jugar(duelo, "objecion", "", sin_azar)
	comprobar("ronda 0 en ciclo: el rival abre con el primero",
		r1["tipo_rival"], "objecion")
	comprobar("mismo tipo es empate", r1["veredicto"], "empate")
	comprobar("y un empate no cuesta vidas",
		[duelo["vida_jugador"], duelo["vida_rival"]], [3, 3])

	var r2 := Combate.jugar(duelo, "objecion", "", sin_azar)
	comprobar("ronda 1: el rival pasa al siguiente", r2["tipo_rival"], "silencio")
	comprobar("objeción vence a silencio", r2["veredicto"], "gana_jugador")
	comprobar("y el rival pierde una vida", duelo["vida_rival"], 2)

	# Tres victorias acaban el combate. En ciclo el rival juega TIPOS[ronda % 3],
	# así que para ganar hay que jugar el que le vence.
	Combate.jugar(duelo, "silencio", "", sin_azar)      # ronda 2: rival insistencia
	var final := Combate.jugar(duelo, "insistencia", "", sin_azar)  # ronda 3: objecion
	comprobar("el combate termina al agotar al rival", final["terminado"], true)
	comprobar("y lo gana el jugador", final["ganador"], "jugador")
	comprobar("una ronda más no hace nada",
		Combate.jugar(duelo, "objecion", "", sin_azar), {})

	# --- Las cuatro habilidades ---
	var cargas := {"comunismo": 1, "centrista": 1, "socialdemocrata": 1, "neoliberal": 1}

	# Asamblea: el empate también golpea al rival. Es lo único que hace que un
	# empate sirva de algo.
	var asamblea := Combate.nuevo("ciclo", rival, cargas)
	var ra := Combate.jugar(asamblea, "objecion", "comunismo", sin_azar)
	comprobar("Asamblea: el empate golpea al rival",
		[ra["veredicto"], asamblea["vida_rival"]], ["empate", 2])
	comprobar("y gasta su carga", asamblea["cargas"]["comunismo"], 0)
	comprobar("gastar una carga que no se tiene no hace nada",
		Combate.jugar(asamblea, "objecion", "comunismo", sin_azar)["habilidad"], "")

	# Mesa de diálogo: nadie pierde vida, ni siquiera perdiendo la ronda.
	var mesa := Combate.nuevo("ciclo", rival, cargas)
	Combate.jugar(mesa, "objecion", "", sin_azar)          # ronda 0, empate
	var rm := Combate.jugar(mesa, "insistencia", "centrista", sin_azar)
	comprobar("Mesa de diálogo: la ronda se pierde igual",
		rm["veredicto"], "gana_rival")
	comprobar("pero no cuesta vidas",
		[mesa["vida_jugador"], mesa["vida_rival"]], [3, 3])

	# Externalizar: el daño cuenta doble, y también en contra.
	var externa := Combate.nuevo("ciclo", rival, cargas)
	Combate.jugar(externa, "objecion", "", sin_azar)
	var re := Combate.jugar(externa, "objecion", "neoliberal", sin_azar)
	comprobar("Externalizar: ganar quita dos vidas",
		[re["veredicto"], externa["vida_rival"]], ["gana_jugador", 1])
	var contra := Combate.nuevo("ciclo", rival, cargas)
	Combate.jugar(contra, "objecion", "", sin_azar)
	Combate.jugar(contra, "insistencia", "neoliberal", sin_azar)
	comprobar("y perder también cuesta dos", contra["vida_jugador"], 1)

	# Comisión de seguimiento: revela la réplica que viene, y esa réplica es la
	# que sale de verdad. Si el motor volviera a tirar, la habilidad mentiría.
	var comision := Combate.nuevo("reactiva", rival, cargas)
	var rc := Combate.jugar(comision, "objecion", "socialdemocrata", sin_azar)
	comprobar("Comisión de seguimiento anuncia una réplica",
		rc["revelada"].is_empty(), false)
	var anunciada: String = rc["revelada"]
	var siguiente := Combate.jugar(comision, "objecion", "", sin_azar)
	comprobar("y la ronda siguiente juega justo esa",
		Combate.etiqueta(siguiente["tipo_rival"]), anunciada)

	# El rival reactivo contesta a la última jugada: se puede cebar.
	var ventanilla := Combate.nuevo("reactiva", rival, {})
	# Cada ronda gasta tiradas: las del rival (una o dos) y una más para elegir
	# su réplica de ambiente.
	Combate.jugar(ventanilla, "objecion", "", _tiradas([0.9, 0.5, 0.0]))
	var cebo := Combate.jugar(ventanilla, "silencio", "", _tiradas([0.1, 0.0]))
	comprobar("el rival reactivo contraataca la última jugada",
		cebo["tipo_rival"], Combate.vence_a("objecion"))

	# La réplica es ambiente y nada más: un rival sin ataques calla en vez de
	# soltar una frase genérica.
	comprobar("un rival con réplicas dice una", cebo["replica"], "Vuelva usted mañana.")
	var mudo := Combate.nuevo("ciclo", {"nombre": "Nadie"}, {})
	comprobar("uno sin réplicas no dice nada",
		Combate.jugar(mudo, "objecion", "", sin_azar)["replica"], "")

	# Las cargas a cero no se ofrecen: una habilidad sin carga no es una opción.
	comprobar("solo se ofrecen las cargas que quedan",
		Combate.cargas_disponibles({"cargas": {"comunismo": 0, "centrista": 2}}),
		{"centrista": 2})


# --- La Ventanilla -----------------------------------------------------------

func _ventanilla() -> void:
	var contenido := Contenido.new()
	contenido.cargar()

	# Sin haber investigado nada, la Ventanilla NO está vacía: atiende el de
	# oficio. Una lista vacía sería indistinguible de una pantalla rota.
	var recien_llegado := Ventanilla.disponibles(contenido, [])
	comprobar("una partida nueva tiene un reclamante", recien_llegado.size(), 1)
	comprobar("y es el de oficio", recien_llegado[0]["de_oficio"], true)
	comprobar("que tiene réplicas propias",
		recien_llegado[0]["ataques"].is_empty(), false)

	# Al descubrir pistas se van presentando los conceptos que las citan.
	var todas := []
	for c in contenido.casos:
		for p in c["pistas"]:
			todas.append(p["id"])
	var con_todo := Ventanilla.disponibles(contenido, todas)
	comprobar("investigándolo todo se presentan los ocho conocidos y el de oficio",
		con_todo.size(), 9)
	comprobar("y ninguno es una empresa, un lugar ni un documento",
		con_todo.all(func(r): return r["tipo"] in ["PERSONA", "COMITE"]), true)

	# La racha: la marca solo sube, y los hitos son los tres logros de #43.
	var estado := {"coliseo_racha_mejor": 0}
	var dos := Ventanilla.cerrar(estado, 2, true)
	comprobar("ganar sube la racha y la marca", [dos["racha"], dos["mejor"]], [3, 3])
	comprobar("y a las tres seguidas se gana su logro",
		dos["logros"], ["ventanilla-tres"])
	var perdida := Ventanilla.cerrar(estado, 3, false)
	comprobar("perder devuelve la racha a cero", perdida["racha"], 0)
	comprobar("pero la mejor marca no baja nunca", estado["coliseo_racha_mejor"], 3)
	comprobar("sin racha no hay logros", perdida["logros"], [])
	comprobar("a las diez se ganan los tres hitos",
		Ventanilla.cerrar(estado, 9, true)["logros"],
		["ventanilla-tres", "funcionario-del-mes", "ventanilla-inagotable"])


# --- La jornada --------------------------------------------------------------

func _jornada() -> void:
	var dia := Jornada.nueva()
	comprobar("se empieza el día uno en el archivo",
		[dia["dia"], dia["fase"]], [1, "archivo"])

	# El orden del día es circular y vive en un solo sitio.
	comprobar("el día va archivo -> trayecto -> casa -> sueño -> archivo",
		[Jornada.siguiente_fase("archivo"), Jornada.siguiente_fase("trayecto"),
		 Jornada.siguiente_fase("casa"), Jornada.siguiente_fase("sueño")],
		["trayecto", "casa", "sueño", "archivo"])

	# La nómina: se cobra por CERRAR, no por acertar. Un expediente mal cerrado
	# paga lo mismo, que es toda la sátira.
	dia["cerrados_hoy"] = 2
	var nomina := Jornada.fichar_salida(dia)
	comprobar("la nómina se desglosa",
		[nomina["base"], nomina["expedientes"], nomina["por_expedientes"]],
		[Jornada.BASE_DIARIA, 2, Jornada.POR_EXPEDIENTE * 2])
	comprobar("y se cobra entera",
		dia["dinero"], 120 + Jornada.BASE_DIARIA + Jornada.POR_EXPEDIENTE * 2)
	comprobar("fichar lleva al trayecto", dia["fase"], "trayecto")
	comprobar("no se puede fichar dos veces", Jornada.fichar_salida(dia), {})

	# Un día sin cerrar nada también paga: el sueldo base no depende de ti.
	var flojo := Jornada.nueva()
	comprobar("un día sin cerrar nada paga la base",
		Jornada.fichar_salida(flojo)["bruto"], Jornada.BASE_DIARIA)

	# Gastar: sin dinero no hay compra, y no hay crédito.
	comprobar("no se puede gastar más de lo que hay",
		Jornada.gastar(dia, dia["dinero"] + 1), false)
	var antes: int = dia["dinero"]
	comprobar("una compra que cabe se hace", Jornada.gastar(dia, 10), true)
	comprobar("y descuenta", dia["dinero"], antes - 10)
	comprobar("gastar cero o menos no es una compra", Jornada.gastar(dia, 0), false)

	# --- El gato ---
	# No se muere: si lo desatiendes, un día no está.
	var casa := Jornada.nueva()
	casa["fase"] = "casa"
	for i in Jornada.PACIENCIA_GATO:
		var noche := Jornada.dormir(casa)
		comprobar("el gato aguanta la noche %d" % (i + 1), noche["gato_se_fue"], false)
		casa["fase"] = "sueño"
		Jornada.despertar(casa)
		casa["fase"] = "casa"
	var ultima := Jornada.dormir(casa)
	comprobar("pasada su paciencia, el gato se va", ultima["gato_se_fue"], true)
	comprobar("y ya no está", casa["gato"]["presente"], false)
	comprobar("no vuelve a irse: ya se fue",
		Jornada.dormir(casa).get("gato_se_fue", false), false)

	# Darle de comer reinicia la cuenta, y es una compra: puede no poder hacerse.
	var cuidada := Jornada.nueva()
	cuidada["fase"] = "casa"
	Jornada.dormir(cuidada)
	comprobar("darle de comer reinicia la cuenta",
		Jornada.alimentar_gato(cuidada, 10) and cuidada["gato"]["dias_sin_comer"] == 0, true)
	cuidada["dinero"] = 0
	comprobar("sin dinero no se le puede dar de comer",
		Jornada.alimentar_gato(cuidada, 10), false)
	comprobar("y a un gato que ya se fue tampoco",
		Jornada.alimentar_gato(casa, 0), false)

	# Vivir cuesta, y no se baja de cero: no hay deuda.
	var pobre := Jornada.nueva()
	pobre["fase"] = "casa"
	pobre["dinero"] = 5
	comprobar("el coste de vivir no deja saldo negativo",
		Jornada.dormir(pobre)["dinero"], 0)

	# --- El día siguiente ---
	var ciclo := Jornada.nueva()
	Jornada.anotar_lectura(ciclo, "MEMO-1999-088")
	Jornada.anotar_lectura(ciclo, "MEMO-1999-088")
	comprobar("lo leído hoy no se repite", ciclo["leido_hoy"].size(), 1)
	Jornada.anotar_lectura(ciclo, "")
	comprobar("un folio vacío no se anota", ciclo["leido_hoy"].size(), 1)

	ciclo["cerrados_hoy"] = 3
	ciclo["fase"] = "sueño"
	comprobar("despertar pasa al día dos", Jornada.despertar(ciclo), 2)
	comprobar("y devuelve al archivo con todo a cero",
		[ciclo["fase"], ciclo["cerrados_hoy"], ciclo["leido_hoy"]],
		["archivo", 0, []])
	comprobar("no se despierta dos veces", Jornada.despertar(ciclo), 2)


# --- Procedencia de los assets ------------------------------------------------

const RUTA_ASSETS := "res://assets"

func _procedencia() -> void:
	var fichero := FileAccess.open(RUTA_ASSETS + "/procedencia.json", FileAccess.READ)
	comprobar("hay registro de procedencia", fichero != null, true)
	if fichero == null:
		return
	var registro = JSON.parse_string(fichero.get_as_text())
	fichero.close()
	comprobar("y es un objeto", typeof(registro), TYPE_DICTIONARY)

	var fichas: Array = registro.get("assets", [])
	var por_ruta := {}
	var fichas_incompletas := []
	for ficha in fichas:
		for campo in ["ruta", "titulo", "autor", "licencia", "fuente", "sha256"]:
			if String(ficha.get(campo, "")).strip_edges().is_empty():
				fichas_incompletas.append("%s sin %s" % [ficha.get("ruta", "?"), campo])
		por_ruta[ficha.get("ruta", "")] = ficha
	comprobar("ninguna ficha está a medias", fichas_incompletas, [])

	# En las dos direcciones: ni ficheros sin ficha ni fichas sin fichero.
	var sin_ficha := []
	var mal_resumidos := []
	for ruta in _ficheros_bajo(RUTA_ASSETS):
		if ruta in ["procedencia.json", "LEEME.md"]:
			continue
		if not por_ruta.has(ruta):
			sin_ficha.append(ruta)
			continue
		var real := FileAccess.get_sha256(RUTA_ASSETS + "/" + ruta)
		if real != por_ruta[ruta]["sha256"]:
			mal_resumidos.append(ruta)
	comprobar("ningún asset sin ficha", sin_ficha, [])
	comprobar("el sha256 de cada ficha es el del fichero real", mal_resumidos, [])

	var huerfanas := []
	for ruta in por_ruta:
		if not FileAccess.file_exists(RUTA_ASSETS + "/" + ruta):
			huerfanas.append(ruta)
	comprobar("ninguna ficha apunta a un fichero que no existe", huerfanas, [])


## Todo lo que cuelga de un directorio, con la ruta relativa a él. Se ignoran
## los `.import` que Godot genera: son suyos, no material de terceros.
func _ficheros_bajo(raiz: String, prefijo: String = "") -> Array:
	var encontrados := []
	var actual := raiz + ("/" + prefijo if not prefijo.is_empty() else "")
	for nombre in DirAccess.get_files_at(actual):
		if nombre.ends_with(".import") or nombre.ends_with(".uid"):
			continue
		encontrados.append(prefijo + nombre if prefijo.is_empty() else prefijo + "/" + nombre)
	for dir in DirAccess.get_directories_at(actual):
		encontrados.append_array(
			_ficheros_bajo(raiz, dir if prefijo.is_empty() else prefijo + "/" + dir))
	return encontrados


# --- Los espacios del día ----------------------------------------------------

func _espacios() -> void:
	# Cada fase de la jornada tiene su sitio: una fase sin espacio dejaría al
	# jugador en la nada.
	# El sueño es la excepción declarada: no es un sitio, son tres cada noche
	# (#86), y lo compone `Sueno`. Se comprueba aparte, en `_sueno()`.
	var sin_sitio := Jornada.FASES.filter(
		func(f): return f != "sueño" and not EspaciosCatalogo.POR_FASE.has(f))
	comprobar("cada fase del día tiene su espacio", sin_sitio, [])

	# Y las salidas forman un ciclo cerrado que vuelve al archivo: un sitio del
	# que no se sale es un sitio donde se acaba la partida sin decirlo.
	var rotos := []
	var sin_salida := []
	for fase in EspaciosCatalogo.POR_FASE:
		var espacio: Dictionary = EspaciosCatalogo.POR_FASE[fase]
		var salidas: Array = espacio.get("salidas", [])
		if salidas.is_empty():
			sin_salida.append(fase)
		for salida in salidas:
			if not EspaciosCatalogo.POR_FASE.has(salida["destino"]) \
					and salida["destino"] != "sueño":
				rotos.append("%s -> %s" % [fase, salida["destino"]])
	comprobar("ningún espacio es un callejón sin salida", sin_salida, [])
	comprobar("ninguna salida lleva a un sitio que no existe", rotos, [])

	# Las salidas siguen el orden del día: no hay atajos que se salten una fase.
	var desordenadas := []
	for fase in EspaciosCatalogo.POR_FASE:
		for salida in EspaciosCatalogo.POR_FASE[fase].get("salidas", []):
			if salida["destino"] != Jornada.siguiente_fase(fase):
				desordenadas.append("%s -> %s" % [fase, salida["destino"]])
	comprobar("las salidas siguen el orden del día", desordenadas, [])

	# Se entra pisando suelo, no dentro de un muro ni fuera de la sala.
	var mal_situadas := []
	for fase in EspaciosCatalogo.POR_FASE:
		var espacio: Dictionary = EspaciosCatalogo.POR_FASE[fase]
		var medidas: Vector2 = espacio["suelo"]
		var entrada: Vector3 = espacio["entrada"]
		if absf(entrada.x) >= medidas.x / 2.0 or absf(entrada.z) >= medidas.y / 2.0:
			mal_situadas.append(fase)
	comprobar("se entra dentro de la sala", mal_situadas, [])


# --- Las acciones del día y lo que sobrevive a un despido --------------------

func _acciones_y_vuelta() -> void:
	var dia := Jornada.nueva()
	comprobar("el día empieza con sus acciones",
		dia["acciones"], Jornada.ACCIONES_POR_DIA)
	comprobar("y no está agotado", Jornada.jornada_agotada(dia), false)

	for i in Jornada.ACCIONES_POR_DIA:
		comprobar("queda acción %d" % (i + 1), Jornada.gastar_accion(dia), true)
	comprobar("agotadas, no se puede hacer nada más",
		Jornada.gastar_accion(dia), false)
	comprobar("y la jornada se declara agotada", Jornada.jornada_agotada(dia), true)

	# Fuera del archivo no se gastan acciones: andar a casa no es trabajar.
	var fuera := Jornada.nueva()
	fuera["fase"] = "trayecto"
	comprobar("fuera del archivo no se gastan acciones",
		Jornada.gastar_accion(fuera), false)
	comprobar("y no se descuenta nada", fuera["acciones"], Jornada.ACCIONES_POR_DIA)

	# El día siguiente devuelve las acciones.
	dia["fase"] = "sueño"
	Jornada.despertar(dia)
	comprobar("el día nuevo trae acciones otra vez",
		dia["acciones"], Jornada.ACCIONES_POR_DIA)

	# --- El despido ---
	var vida := Jornada.nueva()
	vida["dia"] = 12
	vida["dinero"] = 900
	vida["cerrados_hoy"] = 2
	vida["leido_hoy"] = ["MEMO-1999-088"]
	vida["gato"]["dias_sin_comer"] = 2
	Jornada.reiniciar_vuelta(vida)

	comprobar("tras el despido se empieza otra vida laboral",
		[vida["dia"], vida["cerrados_hoy"], vida["leido_hoy"]], [1, 0, []])
	comprobar("con el dinero de partida", vida["dinero"], Jornada.nueva()["dinero"])
	comprobar("pero el gato se queda como estaba",
		[vida["gato"]["presente"], vida["gato"]["dias_sin_comer"]], [true, 2])

	# Y si se había ido, no vuelve: es la única cosa que no da segundas
	# oportunidades, precisamente porque no es del trabajo.
	var sin_gato := Jornada.nueva()
	sin_gato["gato"]["presente"] = false
	Jornada.reiniciar_vuelta(sin_gato)
	comprobar("un gato que se fue no vuelve con la vuelta nueva",
		sin_gato["gato"]["presente"], false)


# --- Acusar y cerrar ---------------------------------------------------------

func _acusacion() -> void:
	var contenido := Contenido.new()
	contenido.cargar()
	var caso: Dictionary = contenido.casos[0]
	var todas_sus_pistas: Array = caso["pistas"].map(func(p): return p["id"])

	var estado := Partida.nueva()
	var dia := Jornada.nueva()

	comprobar("un expediente empieza abierto",
		Acusacion.esta_cerrado(estado, caso["id"]), false)

	# Acusar sin haber leído nada: se puede, y por eso duele.
	var precipitada := Acusacion.acusar(estado, dia, caso, caso["sospechosos"][0], [])
	comprobar("se puede firmar sin evidencia", precipitada["resultado"], "cerrado")
	comprobar("y el sistema lo apunta", precipitada["precipitada"], true)
	comprobar("cuesta una vida", precipitada["vida"], Partida.VIDA_MAXIMA - 1)
	comprobar("pero cuenta como cerrado igual: la nómina no distingue",
		dia["cerrados_hoy"], 1)
	comprobar("gasta una acción del día", dia["acciones"], Jornada.ACCIONES_POR_DIA - 1)
	comprobar("y trae el desenlace de ese sospechoso",
		precipitada["desenlace"] == caso["sospechosos"][0]["desenlace"], true)

	# Irreversible: no se firma dos veces.
	comprobar("el expediente queda cerrado",
		Acusacion.esta_cerrado(estado, caso["id"]), true)
	var repetida := Acusacion.acusar(estado, dia, caso, caso["sospechosos"][1], [])
	comprobar("no se puede volver a firmar", repetida["resultado"], "ya_cerrado")
	comprobar("y no gasta acción por intentarlo",
		dia["acciones"], Jornada.ACCIONES_POR_DIA - 1)
	comprobar("el veredicto sigue siendo el primero",
		Acusacion.veredicto_de(estado, caso["id"]), caso["sospechosos"][0]["id"])

	# Con la evidencia suficiente no hay castigo.
	var limpio := Partida.nueva()
	var dia2 := Jornada.nueva()
	var bien := Acusacion.acusar(limpio, dia2, caso, caso["sospechosos"][0], todas_sus_pistas)
	comprobar("con todas las pistas no es precipitada", bien["precipitada"], false)
	comprobar("y no cuesta vidas", bien["vida"], Partida.VIDA_MAXIMA)

	# Sin acciones no se puede acusar, y no se firma nada a medias.
	var agotado := Partida.nueva()
	var sin_dia := Jornada.nueva()
	sin_dia["acciones"] = 0
	var tarde := Acusacion.acusar(agotado, sin_dia, caso, caso["sospechosos"][0], todas_sus_pistas)
	comprobar("sin acciones no se acusa", tarde["resultado"], "sin_acciones")
	comprobar("y el expediente sigue abierto",
		Acusacion.esta_cerrado(agotado, caso["id"]), false)

	# --- El careo ---
	comprobar("un sospechoso sin réplicas no abre duelo", bien["duelo"], {})
	var caso6: Dictionary = contenido.casos.filter(
		func(c): return c["sospechosos"].any(
			func(s): return not s.get("ataques", []).is_empty()))[0]
	var con_replicas: Dictionary = caso6["sospechosos"].filter(
		func(s): return not s.get("ataques", []).is_empty())[0]
	var careo := Acusacion.acusar(Partida.nueva(), Jornada.nueva(), caso6, con_replicas, [])
	comprobar("uno con réplicas sí", careo["duelo"]["nombre"], con_replicas["nombre"])

	# El duelo no cambia el veredicto: ya está firmado. Perderlo cuesta una vida.
	var duelista := Partida.nueva()
	var dia3 := Jornada.nueva()
	Acusacion.acusar(duelista, dia3, caso6, con_replicas, [])
	var antes_de_perder: int = duelista["vida"]
	Acusacion.resolver_duelo(duelista, dia3, false)
	comprobar("perder el careo cuesta una vida", duelista["vida"], antes_de_perder - 1)
	comprobar("pero el expediente sigue cerrado con el mismo veredicto",
		Acusacion.veredicto_de(duelista, caso6["id"]), con_replicas["id"])
	var ganador := Partida.nueva()
	var vida_intacta: int = ganador["vida"]
	Acusacion.resolver_duelo(ganador, Jornada.nueva(), true)
	comprobar("ganarlo no cuesta nada", ganador["vida"], vida_intacta)

	# --- El despido ---
	var ultimo := Partida.nueva()
	var dia4 := Jornada.nueva()
	ultimo["vida"] = 1
	dia4["dia"] = 9
	dia4["gato"]["dias_sin_comer"] = 2
	var caida := Acusacion.perder_vida(ultimo, dia4, 1)
	comprobar("sin vidas, te reasignan", caida["despido"], true)
	comprobar("y empieza otra vida laboral", dia4["dia"], 1)
	comprobar("con las vidas de la dificultad",
		ultimo["vida"], Acusacion.DIFICULTADES["normal"]["vidas"])
	comprobar("el gato sigue siendo tuyo", dia4["gato"]["dias_sin_comer"], 2)

	comprobar("en fácil se exige menos evidencia",
		Acusacion.DIFICULTADES["facil"]["umbral"] < Acusacion.DIFICULTADES["dificil"]["umbral"],
		true)


# --- La cinemática del careo y el cuñado -------------------------------------

func _careo() -> void:
	var contenido := Contenido.new()
	contenido.cargar()
	var acusado: Dictionary = {}
	for c in contenido.casos:
		for s in c["sospechosos"]:
			if not s.get("ataques", []).is_empty():
				acusado = s
				break

	var rodaje := CareoCinematica.planos_de(acusado, "ACTA-1958-001")
	comprobar("la cinemática tiene sus cuatro planos", rodaje.size(), 4)
	comprobar("dura lo que dura", Cinematica.duracion(rodaje) > 0.0, true)
	comprobar("presenta al acusado por su nombre",
		rodaje[1]["rotulo"], acusado["nombre"])
	comprobar("y dice su cargo", rodaje[2]["rotulo"].is_empty(), false)
	comprobar("el último plano cita el expediente",
		rodaje[3]["rotulo"], "EXPEDIENTE ACTA-1958-001")

	# Sin folio no se inventa un número: se dice que no consta.
	comprobar("sin expediente lo dice",
		CareoCinematica.planos_de(acusado)[3]["rotulo"], "EXPEDIENTE SIN NÚMERO")

	# Rodar una no puede estropear la siguiente.
	rodaje[0]["rotulo"] = "ESTROPEADO"
	comprobar("los planos se entregan en copia",
		CareoCinematica.planos_de(acusado)[0]["rotulo"], "")

	# Un acusado sin descripción no se queda sin cartela: que no conste su
	# cargo es parte del problema, y se dice.
	comprobar("un acusado sin descripción tiene cartela igual",
		CareoCinematica.planos_de({"nombre": "Nadie"})[2]["rotulo"],
		TranslationServer.translate(CareoCinematica.CARGO_POR_DEFECTO))

	# --- El cuñado ---
	var azar := func(): return 0.0
	comprobar("llega diciendo algo",
		Cunado.comentario("llegada", azar).is_empty(), false)
	comprobar("comenta una ronda perdida",
		Cunado.comentario("gana_rival", azar).is_empty(), false)
	comprobar("un momento que no existe le deja callado",
		Cunado.comentario("no_existe", azar), "")

	# Si se ha gastado una habilidad, es de lo que habla: es lo que miraría.
	comprobar("comenta la habilidad antes que el resultado",
		Cunado.sobre_ronda({"habilidad": "comunismo", "veredicto": "gana_rival"}, azar)
			in Cunado.AL_GASTAR_HABILIDAD.map(TranslationServer.translate), true)
	comprobar("y si no hubo, el resultado",
		Cunado.sobre_ronda({"habilidad": "", "veredicto": "gana_jugador"}, azar)
			in Cunado.AL_GANAR_RONDA.map(TranslationServer.translate), true)

	# LA REGLA: no da información. Si nunca nombra una jugada, no puede estar
	# diciéndote qué hacer. Se comprueba sobre TODO lo que puede decir, no sobre
	# una muestra: una regla sobre lo que se dice solo vale así.
	var chivatazos := []
	for frase in Cunado.todas_las_frases():
		for prohibida in Cunado.palabras_prohibidas():
			if frase.contains(prohibida):
				chivatazos.append(frase)
	comprobar("el cuñado no nombra ninguna jugada", chivatazos, [])
	comprobar("y tiene algo que decir en cada momento",
		Cunado.POR_MOMENTO.values().all(func(f): return f.size() >= 3), true)


# --- El reproductor común de cinemáticas (#67) -------------------------------

func _cinematicas() -> void:
	var planos := [
		{"tipo": "3d", "camara": Vector3(0, 1, 3), "mira": Vector3.ZERO,
			"segundos": 2.0, "rotulo": "{quien}"},
		{"tipo": "2d", "figura": [{"rect": Rect2(0, 0, 10, 10)}],
			"segundos": 1.0, "voz": "dice {quien}"},
	]

	# Las plantillas se rellenan al reproducir, no al declarar.
	var rodaje := Cinematica.resolver(planos, {"quien": "El Comité"})
	comprobar("el rótulo se rellena", rodaje[0]["rotulo"], "El Comité")
	comprobar("y la voz también", rodaje[1]["voz"], "dice El Comité")
	comprobar("un dato que no se cita no estorba",
		Cinematica.resolver(planos, {"otro": "x"})[0]["rotulo"], "{quien}")

	# Se entregan copias: reproducir una no puede estropear la siguiente.
	rodaje[0]["rotulo"] = "ESTROPEADO"
	comprobar("los planos se entregan en copia",
		Cinematica.resolver(planos, {"quien": "El Comité"})[0]["rotulo"], "El Comité")

	# --- El acortado por repetición ---
	comprobar("la primera vez dura lo declarado",
		Cinematica.duracion(Cinematica.resolver(planos, {}, 0)), 3.0)
	var segunda := Cinematica.duracion(Cinematica.resolver(planos, {}, 1))
	comprobar("la segunda dura menos", segunda < 3.0, true)
	comprobar("y la quinta menos que la segunda",
		Cinematica.duracion(Cinematica.resolver(planos, {}, 4)) < segunda, true)

	# El suelo: por muy vista que esté, no desaparece sin avisar. Y el REMATE
	# tiene su propio suelo, más alto que el de los demás planos.
	var muy_vista := Cinematica.resolver(planos, {}, 99)
	comprobar("ningún plano baja de cero", Cinematica.duracion(muy_vista) > 0.0, true)
	comprobar("el remate conserva más que los demás",
		Cinematica.factor(99, true) > Cinematica.factor(99, false), true)
	comprobar("el remate no baja de su suelo",
		Cinematica.factor(99, true), Cinematica.SUELO_REMATE)
	comprobar("las vistas negativas no alargan nada",
		Cinematica.factor(-5, false), 1.0)

	# --- La validación, al construir y no a mitad ---
	comprobar("unos planos bien declarados no dan problemas",
		Cinematica.validar(planos), [])
	comprobar("una cinemática sin planos es un problema",
		Cinematica.validar([]), ["sin planos"])
	comprobar("un plano sin tipo se caza",
		Cinematica.validar([{"segundos": 1.0}]).size() > 0, true)
	comprobar("un plano sin duración se caza: se quedaría clavado en pantalla",
		"plano 0: sin duración" in Cinematica.validar(
			[{"tipo": "3d", "camara": Vector3.ZERO, "mira": Vector3.ZERO}]), true)
	comprobar("un 3d sin cámara se caza",
		"plano 0: 3d sin camara" in Cinematica.validar(
			[{"tipo": "3d", "mira": Vector3.ZERO, "segundos": 1.0}]), true)
	comprobar("un 2d sin figura se caza",
		"plano 0: 2d sin figura" in Cinematica.validar(
			[{"tipo": "2d", "segundos": 1.0}]), true)

	# La del careo tiene que pasar su propia validación: es la primera que se
	# declara en este formato y la que sirve de ejemplo a las otras nueve.
	comprobar("la cinemática del careo está bien declarada",
		Cinematica.validar(CareoCinematica.PLANOS), [])

	# --- La cuenta de vistas, que es estado de partida ---
	var estado := {}
	comprobar("una cinemática nunca vista está a cero",
		Cinematica.vistas_de(estado, "careo"), 0)
	Cinematica.anotar_vista(estado, "careo")
	Cinematica.anotar_vista(estado, "careo")
	comprobar("se lleva la cuenta", Cinematica.vistas_de(estado, "careo"), 2)
	comprobar("y cada una la suya", Cinematica.vistas_de(estado, "sello"), 0)

	# El reproductor anota la vista por su cuenta si se le da id y estado. Es lo
	# que evita que un llamante despistado deje su cinemática eterna mientras
	# las demás se acortan.
	var partida := Partida.nueva()
	comprobar("la partida guarda la cuenta de cinemáticas vistas",
		Cinematica.vistas_de(partida, "careo"), 0)
	Cinematica.anotar_vista(partida, "careo")
	var acortada := CareoCinematica.planos_de(
		{"nombre": "X"}, "F-1", Cinematica.vistas_de(partida, "careo"))
	comprobar("y la segunda vez el careo dura menos",
		Cinematica.duracion(acortada) < Cinematica.duracion(
			CareoCinematica.planos_de({"nombre": "X"}, "F-1", 0)), true)


# --- Plantas que no son una caja (#86) ---------------------------------------

func _plantas() -> void:
	# El caso fácil sigue saliendo igual: una sala rectangular tiene cuatro
	# muros, ni uno más. Si la generalización rompiera esto, habría cambiado
	# todos los sitios del día por el camino.
	var caja := [Rect2i(0, 0, 5, 4)]
	comprobar("una planta rectangular da cuatro muros",
		Planta.contorno(caja).size(), 4)
	comprobar("y una sola losa de suelo", Planta.rectangulos(caja), [Rect2i(0, 0, 5, 4)])

	# Una ele tiene seis: es la primera forma que una caja no puede declarar.
	var ele := [Rect2i(0, 0, 4, 2), Rect2i(0, 2, 2, 2)]
	comprobar("una ele da seis muros", Planta.contorno(ele).size(), 6)

	# Y un anillo, ocho: cuatro fuera y cuatro dentro. El patio no lo declara
	# nadie — sale de que también es contorno.
	var anillo := [
		Rect2i(0, 0, 5, 1), Rect2i(0, 4, 5, 1),
		Rect2i(0, 0, 1, 5), Rect2i(4, 0, 1, 5),
	]
	comprobar("un anillo da ocho muros (los cuatro del patio incluidos)",
		Planta.contorno(anillo).size(), 8)
	comprobar("y su patio no es suelo", Planta.contiene(anillo, Vector2i(2, 2)), false)

	# La invariante que de verdad importa: los muros tapan TODO el borde. Un
	# tramo que faltara es un hueco por el que se sale de la sala, y eso no se
	# ve en una captura sino andando hasta que te caes del mundo.
	for nombre in ["caja", "ele", "anillo"]:
		var bloques: Array = {"caja": caja, "ele": ele, "anillo": anillo}[nombre]
		var celdas := Planta.celdas(bloques)
		var expuestas := 0
		for celda in celdas:
			for lado in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if not celdas.has(celda + lado):
					expuestas += 1
		var cubiertas := 0
		for tramo in Planta.contorno(bloques):
			cubiertas += tramo["hasta"] - tramo["desde"]
		comprobar("los muros cubren todo el borde de %s" % nombre, cubiertas, expuestas)

	# El suelo se parte en rectángulos que no se pisan entre sí: dos losas en el
	# mismo plano son dos caras peleándose por el mismo píxel.
	var solapadas := [Rect2i(0, 0, 6, 3), Rect2i(2, 0, 6, 3)]
	var cubierto := 0
	var vistas := {}
	var repetidas := 0
	for rect in Planta.rectangulos(solapadas):
		cubierto += rect.size.x * rect.size.y
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			for z in range(rect.position.y, rect.position.y + rect.size.y):
				if vistas.has(Vector2i(x, z)):
					repetidas += 1
				vistas[Vector2i(x, z)] = true
	comprobar("bloques solapados se cubren enteros", cubierto, Planta.area(solapadas))
	comprobar("y sin poner dos losas en la misma celda", repetidas, 0)

	# La distancia es de camino, no en línea recta: en un anillo, la celda de
	# enfrente está al lado y a media vuelta de andar.
	var lejana := Planta.mas_lejana(anillo, Vector2i(0, 0))
	comprobar("la celda más lejana de un anillo está a media vuelta",
		lejana == Vector2i(0, 0), false)
	comprobar("y es una celda de la planta", Planta.contiene(anillo, lejana), true)

	# Las medidas: una celda son dos metros y la planta aparece centrada.
	comprobar("la planta se centra en el mundo",
		Planta.centro_en_metros([Rect2i(0, 0, 2, 2)], Vector2i(0, 0)),
		Vector3(-Planta.CELDA / 2.0, 0, -Planta.CELDA / 2.0))


# --- El esqueleto del sueño (#86) -------------------------------------------

func _sueno() -> void:
	# Las salas del sueño son pocas y GRANDES, de una pieza, y ninguna es un
	# rectángulo: una caja más grande no es una sala rara.
	var pequenas := []
	var partidas := []
	var cajas := []
	var entradas_fuera := []
	for id in SuenoFormas.ids():
		var forma := SuenoFormas.de(id)
		var bloques: Array = forma["bloques"]
		if Planta.area(bloques) < SuenoFormas.MINIMO_GRANDE:
			pequenas.append(id)
		if not Planta.conexa(bloques):
			partidas.append(id)
		if Planta.contorno(bloques).size() <= 4:
			cajas.append(id)
		if not Planta.contiene(bloques, forma["entrada"]):
			entradas_fuera.append(id)
	comprobar("ninguna sala del sueño es pequeña", pequenas, [])
	comprobar("ninguna está partida en dos", partidas, [])
	comprobar("ninguna es una caja", cajas, [])
	comprobar("se entra dentro de la sala", entradas_fuera, [])
	comprobar("hay salas de sobra para una noche",
		SuenoFormas.ids().size() >= Sueno.ESCENAS_POR_NOCHE, true)

	# Una noche son tres escenas distintas.
	var noche := Sueno.noche(1, ["MEMO-1999-088"], [])
	comprobar("una noche son tres escenas", noche.size(), Sueno.ESCENAS_POR_NOCHE)
	var sin_repetir := {}
	for id in noche:
		sin_repetir[id] = true
	comprobar("y no se repite ninguna dentro de la misma noche",
		sin_repetir.size(), noche.size())

	# El sueño es de su día: misma lectura, mismo sueño; otra lectura, otro.
	comprobar("el mismo día leyendo lo mismo sueña lo mismo",
		Sueno.noche(1, ["MEMO-1999-088"], []), noche)
	comprobar("leer otra cosa cambia la noche",
		Sueno.noche(1, ["FAC-1998-014"], []) == noche, false)
	comprobar("y otro día también",
		Sueno.noche(2, ["MEMO-1999-088"], []) == noche, false)

	# El mapa crece: mientras queden salas sin ver, se ven salas sin ver.
	var mapa := []
	for id in noche:
		Sueno.recordar(mapa, id)
	comprobar("el mapa crece de tres en tres", mapa.size(), Sueno.ESCENAS_POR_NOCHE)
	comprobar("y una sala ya vista no se apunta dos veces",
		Sueno.recordar(mapa, noche[0]), false)
	var segunda := Sueno.noche(2, ["FAC-1998-014"], mapa)
	var nuevas := segunda.filter(func(id): return not mapa.has(id))
	comprobar("la segunda noche enseña lo que queda sin ver",
		nuevas.size(), mini(Sueno.ESCENAS_POR_NOCHE,
			SuenoFormas.ids().size() - mapa.size()))

	# Solo la última escena despierta. Las otras dos llevan a la siguiente: un
	# sueño que devolviera al archivo en la primera sala no sería tres escenas.
	var destinos := []
	for i in noche.size():
		destinos.append(Sueno.espacio(noche[i], noche.size() - 1 - i)["salidas"][0]["destino"])
	comprobar("solo la última escena despierta", destinos,
		["sueño", "sueño", "archivo"])

	# La salida no está donde entras, y está dentro de la sala.
	var espacio := Sueno.espacio(noche[0], 2)
	comprobar("no se sale por donde se entra",
		espacio["salidas"][0]["pos"] - Vector3(0, 1.1, 0) == espacio["entrada"], false)

	# --- El mapa es de la vuelta, no de por vida ---
	var vida := Jornada.nueva()
	vida["fase"] = "casa"
	vida["leido_hoy"] = ["MEMO-1999-088"]
	Jornada.dormir(vida)
	comprobar("dormir compone la noche",
		vida["sueno_escenas"].size(), Sueno.ESCENAS_POR_NOCHE)
	Jornada.despertar(vida)
	comprobar("y despertar no deja media noche esperando",
		vida["sueno_escenas"], [])

	vida["mapa"] = ["patio", "peine"]
	Jornada.reiniciar_vuelta(vida)
	comprobar("el mapa del sueño no sobrevive al despido", vida["mapa"], [])


# --- Que el texto siga fuera del código (#105) -------------------------------

## Extraer el texto una vez no sirve de nada si la pantalla siguiente vuelve a
## escribirlo dentro. Estas tres comprobaciones son lo que impide que esto se
## deshaga solo: no revisan el español, revisan que el español no esté aquí.
func _traducciones() -> void:
	var claves := {}
	var csv := FileAccess.open("res://datos/textos.csv", FileAccess.READ)
	comprobar("hay fichero de traducción", csv != null, true)
	if csv == null:
		return
	var primera := true
	while not csv.eof_reached():
		var linea := csv.get_csv_line()
		if primera:
			comprobar("la cabecera declara clave e idioma", linea, ["clave", "es"])
			primera = false
			continue
		if linea.size() < 2 or linea[0].is_empty():
			continue
		claves[linea[0]] = linea[1]
	csv.close()

	var fuentes := PackedStringArray()
	for nombre in DirAccess.get_files_at("res://guion"):
		if nombre.ends_with(".gd"):
			fuentes.append(FileAccess.get_file_as_string("res://guion/" + nombre))
	var codigo := "\n".join(fuentes)

	# 1. Toda clave que el código nombra existe. Godot devuelve la clave tal
	#    cual cuando no la encuentra, así que una errata no revienta: se ve en
	#    pantalla como un grito en mayúsculas y nadie la nota hasta que alguien
	#    llega a esa esquina del juego. Pasó de verdad con los nombres de las
	#    jugadas, y por eso esto NO busca solo `tr("...")`: media docena de
	#    claves viven en tablas (`Combate.ETIQUETAS`, el cuñado, los rótulos de
	#    los sitios) y se traducen lejos de donde se escriben. Lo que se busca
	#    es la FORMA de una clave, que la convención hace inconfundible.
	var pedidas := RegEx.create_from_string('"([A-Z][A-Z0-9]*(?:_[A-Z0-9]+)+)"')
	var sin_texto := []
	for hallazgo in pedidas.search_all(codigo):
		if not claves.has(hallazgo.get_string(1)):
			sin_texto.append(hallazgo.get_string(1))
	comprobar("ninguna clave pedida se queda sin texto", sin_texto, [])

	# 2. Y ninguna sobra. Una clave que ya no pide nadie es texto que se sigue
	#    traduciendo —y pagando— para una pantalla que se quitó.
	var huerfanas := []
	for clave in claves:
		if not codigo.contains('"%s"' % clave):
			huerfanas.append(clave)
	comprobar("ninguna clave se queda sin quien la pida", huerfanas, [])

	# 3. Ninguna pantalla escribe texto a mano. Es la comprobación que de
	#    verdad sostiene esto: sin ella, la casa y el sueño llegan con el suyo
	#    dentro y en tres pantallas hemos vuelto al principio.
	# La letra tiene que ser letra de verdad: la "n" de un salto de línea y la
	# "s" de un "%s" no son texto, y sin descontarlas la guarda se dispara sobre
	# cadenas que no dicen nada.
	var literales := RegEx.create_from_string(
		'(\\.text|tooltip_text|placeholder_text)\\s*(=|\\+=)\\s*"[^"]*(?<![\\\\%])[a-zá-úA-ZÁ-Ú]')
	var escritos := []
	for nombre in DirAccess.get_files_at("res://guion"):
		if not nombre.ends_with(".gd"):
			continue
		var fuente := FileAccess.get_file_as_string("res://guion/" + nombre)
		for linea in fuente.split("\n"):
			if literales.search(linea) != null:
				escritos.append("%s: %s" % [nombre, linea.strip_edges()])
	comprobar("ninguna pantalla escribe texto a mano", escritos, [])
