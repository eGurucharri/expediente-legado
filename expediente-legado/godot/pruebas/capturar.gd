## Guarda una captura del visor, para poder MIRAR lo que dibuja en vez de
## deducirlo de las pruebas. Es herramienta, no juego: por eso vive aquí y el
## visor no sabe que existe.
##
##     xvfb-run -a godot4 --path godot --script pruebas/capturar.gd -- salida.png [documento] [descubrir]
##
## [param documento] es el índice del documento a abrir y [param descubrir]
## a "1" descubre sus pistas antes de capturar, para poder comparar el antes y
## el después de notar una frase.
extends SceneTree

func _init() -> void:
	var destino := "captura.png"
	var argumentos := OS.get_cmdline_user_args()
	if argumentos.size() > 0:
		destino = argumentos[0]

	# Qué escena capturar: por defecto el visor.
	var ruta := "res://escenas/visor.tscn"
	if destino.contains("ventanilla"):
		ruta = "res://escenas/ventanilla.tscn"
	var escena: Node = load(ruta).instantiate()
	root.add_child(escena)
	await process_frame

	if ruta.contains("ventanilla"):
		# Llamar al primer turno y jugar una ronda, para que la captura enseñe
		# un combate en marcha y no una cola vacía.
		escena.reduccion_movimiento = true
		escena._al_llamar(int(argumentos[1]) if argumentos.size() > 1 else 0)
		await process_frame
		escena._al_jugar("objecion")
		await process_frame
		var imagen_v := root.get_texture().get_image()
		imagen_v.save_png(destino)
		print("captura en %s" % destino)
		# quit() no interrumpe la función: sin este return se sigue ejecutando
		# el camino del visor y revienta al buscar un `caso` que aquí no hay.
		quit(0)
		return

	var indice := int(argumentos[1]) if argumentos.size() > 1 else 0
	if argumentos.size() > 2 and argumentos[2] == "1":
		# Por el mismo camino que un clic, no tocando el estado por detrás: si
		# esto escribiera en `descubiertas` directamente, la captura enseñaría
		# una pista descubierta que nunca llegó a guardarse.
		for pista in escena.contenido.pistas_de_registro(
				escena.caso, escena.caso["registros"][indice]["id"]):
			if pista.get("fraseGatillo") != null:
				escena._al_pulsar_marca("pista:%s" % pista["id"])
	escena._lista.select(indice)
	escena._mostrar_registro(escena.caso["registros"][indice])

	# Dos fotogramas: uno para que los contenedores repartan el espacio y otro
	# para que se dibuje con el reparto ya hecho.
	await process_frame
	await process_frame
	await process_frame

	var imagen := root.get_texture().get_image()
	var error := imagen.save_png(destino)
	if error != OK:
		printerr("No se pudo guardar %s (error %d)" % [destino, error])
	else:
		print("captura en %s (%dx%d)" % [destino, imagen.get_width(), imagen.get_height()])
	quit(0 if error == OK else 1)
