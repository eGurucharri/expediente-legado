## Pruebas del tiempo de cada día (#143) y de los planos rodados (#66).
##
## Están aparte y no en `pruebas_espacios_y_sueno` porque aquel fichero llegó a
## su tope de mil líneas: partirlo por ÁREA y no por tamaño es lo que evita que
## la siguiente prueba de clima acabe en el fichero del sueño solo porque ahí
## cabía.
class_name PruebasClimaYVideo
extends RefCounted


static func todo(comprobar: Callable) -> void:
	# --- El tiempo de cada día (#143) ---

	comprobar.call("el primer día está despejado", Clima.id_de_dia(1), Clima.DESPEJADO)
	# Y el día cero o negativo también: una partida vieja sin día no puede dejar
	# el cielo en un tiempo que no existe.
	comprobar.call("un día raro no rompe el cielo", Clima.id_de_dia(0), Clima.DESPEJADO)

	# Sale del NÚMERO de día y de nada más, así que recargar devuelve el mismo
	# cielo. Sin esto, el día que te acuerdas de que llovía amanecería despejado.
	comprobar.call("el mismo día da el mismo tiempo", Clima.id_de_dia(7), Clima.id_de_dia(7))

	# Todo tiempo de la rueda existe en la tabla: uno que no esté deja el sitio
	# con el cielo por defecto y nadie se entera.
	var tiempos_rotos := []
	for cual in Clima.RUEDA:
		if not Clima.TIEMPOS.has(cual):
			tiempos_rotos.append(cual)
	comprobar.call("la rueda solo nombra tiempos que existen", tiempos_rotos, [])

	# Y hay más de uno de verdad: una rueda de un solo tiempo pasaría todas las
	# demás pruebas y no habría clima ninguno.
	var distintos := {}
	for dia in range(1, 12):
		distintos[Clima.id_de_dia(dia)] = true
	comprobar.call("los días no son todos iguales", distintos.size() > 2, true)

	# Solo se viste lo que se declara al aire libre. Teñir el archivo porque
	# fuera hay nubes sería afirmar que se ve algo que no se ve.
	var dentro := {"ambiente": Color.RED, "sol": 0.7}
	comprobar.call("un sitio cerrado no se entera del tiempo", Clima.vestir(dentro, 3), dentro)
	var fuera := Clima.vestir({"exterior": true, "ambiente": Color.RED, "sol": 0.7}, 3)
	comprobar.call("y uno al aire libre sí", fuera["ambiente"] != Color.RED, true)

	# En copia: el catálogo es una constante, y pintarle el tiempo encima dejaría
	# el martes lloviendo para el resto de la partida.
	var molde := {"exterior": true, "ambiente": Color.RED}
	Clima.vestir(molde, 3)
	comprobar.call("vestir el tiempo no estropea el catálogo", molde["ambiente"], Color.RED)

	# La calle es el sitio que lo declara.
	comprobar.call(
		"la calle está al aire libre", EspaciosCatalogo.CALLE.get("exterior", false), true
	)
	comprobar.call("y la oficina no", EspaciosCatalogo.OFICINA.get("exterior", false), false)

	# --- Planos rodados (#66) ---
	#
	# No hay ningún `.ogv` en el árbol todavía: esto comprueba las dos formas de
	# declararlo MAL, que es lo que de verdad hace falta. Un plano de vídeo que
	# falla se ve como unos segundos en negro, y eso no se distingue de un
	# cuelgue — por eso se caza al construir el catálogo y no al llegar a él.
	comprobar.call(
		"un plano de vídeo sin fichero se caza",
		"plano 0: video sin fichero" in Cinematica.validar([{"tipo": "video", "segundos": 1.0}]),
		true
	)
	comprobar.call(
		"y uno que apunta a un vídeo que no está, también",
		(
			"plano 0: no hay video nada.ogv"
			in Cinematica.validar([{"tipo": "video", "segundos": 1.0, "fichero": "nada.ogv"}])
		),
		true
	)
	comprobar.call("el vídeo es un tipo de plano más", "video" in Cinematica.TIPOS, true)
