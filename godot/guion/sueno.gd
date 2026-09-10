## La noche: qué se sueña y qué queda de ello.
##
## Tres cosas y ninguna más (#86): elegir las TRES escenas de esta noche,
## encadenarlas, y hacer crecer el mapa con lo que se va viendo. Lo que hay
## DENTRO de cada escena es #87, y de dónde se sale es #90 — aquí la salida es
## la celda más lejos de la entrada porque eso ya se puede calcular, no porque
## esté decidido cómo se busca.
##
## **El sueño no es aleatorio: es el archivo devuelto deforme** (#79). Aquí eso
## se cumple de la única forma que este issue puede cumplirlo todavía: la
## semilla sale de lo LEÍDO ese día, así que dos días distintos sueñan distinto
## y el mismo día repetido sueña lo mismo. Un sueño que cambiara al recargar la
## partida sería un generador de ruido con otro nombre.
##
## **El mapa vive en la vuelta y no en la memoria de por vida** (decidido en
## #86): cada vida laboral sueña lo suyo. No hace falta borrarlo en ningún
## sitio — está en `Jornada.nueva()`, que es lo que el despido vuelve a poner.
class_name Sueno
extends RefCounted

## Cuántas escenas tiene una noche. Ni una sala grande ni un recorrido largo:
## tres. Acota lo que dura una noche cuando se sueña diez o catorce veces por
## partida, y le da al mapa que crece una unidad de medida — crece de tres en
## tres, y por eso se nota cuál se repite.
const ESCENAS_POR_NOCHE := 3

## Cómo se ve un sospechoso, y cómo se ve el que firmaste. La diferencia es
## todo lo que hace falta: aparecen todos los del expediente que tocaste, pero
## haberle puesto el nombre a uno se nota (#87).
const COLOR_FIGURA := Color(0.30, 0.28, 0.34)
const COLOR_ACUSADO := Color(0.46, 0.20, 0.20)
const COLOR_TEXTO := Color(0.78, 0.77, 0.80)
const COLOR_ACUSADO_TEXTO := Color(0.86, 0.62, 0.58)

## Lo que se separa un cartel de su muro. Tiene que ser MAYOR que medio grosor
## de muro, y ese es el número que importa: un muro es una caja centrada en la
## línea de la planta, así que separarse seis centímetros de la línea deja el
## texto DENTRO de la pared y no se ve nada. No es un parpadeo que se note al
## pasar: la frase sencillamente no está. Hay prueba que lo exige.
const SEPARACION_PARED := 0.2

## A cuántas celdas de la entrada se planta la primera figura. Lo bastante
## lejos para que no te la encuentres encima, lo bastante cerca para verla al
## llegar.
const PASOS_PRIMERA_FIGURA := 5


## La semilla de esta noche: el día y lo que se leyó en él.
##
## El día entra para que dos noches con la misma lectura no sean la misma
## noche; lo leído entra para que la noche sea de su día. Sin lo leído, el
## sueño sería una función del calendario.
static func semilla(dia: int, leido_hoy: Array) -> int:
	var texto := str(dia)
	var folios := leido_hoy.duplicate()
	folios.sort()
	for folio in folios:
		texto += "|" + str(folio)
	return abs(hash(texto))


## Las tres escenas de esta noche, en orden.
##
## Lo NUEVO va primero: mientras queden salas sin ver se ven salas sin ver, y
## solo cuando el mapa ya las tiene todas se empiezan a repetir. Es lo que hace
## que el mapa crezca de verdad en vez de crecer de casualidad.
static func noche(dia: int, leido_hoy: Array, mapa: Array) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla(dia, leido_hoy)

	var nuevas := SuenoFormas.ids().filter(func(id): return not mapa.has(id))
	var vistas := SuenoFormas.ids().filter(func(id): return mapa.has(id))
	_barajar(nuevas, rng)
	_barajar(vistas, rng)

	var escenas := nuevas + vistas
	return escenas.slice(0, mini(ESCENAS_POR_NOCHE, escenas.size()))


## Anota una sala en el mapa. El mapa es lo que se ha visto, así que una sala
## repetida no se apunta dos veces: crecer es conocer sitios, no acumular
## noches.
static func recordar(mapa: Array, id: String) -> bool:
	if mapa.has(id):
		return false
	mapa.append(id)
	return true


## El espacio de una escena, listo para `Espacio3D`.
##
## [param quedan] es cuántas escenas faltan DESPUÉS de esta. La última lleva a
## despertar y las demás a la siguiente: el sueño se sale por donde se acaba,
## no por una tecla.
static func espacio(id: String, quedan: int, contenido: Dictionary = {}) -> Dictionary:
	var forma := SuenoFormas.de(id)
	var bloques: Array = forma["bloques"]
	var entrada: Vector2i = forma["entrada"]
	var salida := Planta.mas_lejana(bloques, entrada)

	# Las figuras se reparten por la sala, lejos entre sí y lejos de por donde
	# se entra y se sale: un sospechoso plantado en la puerta se ve antes de
	# haber entrado, y lo que hace el sueño es que te los encuentres.
	var figuras := []
	var quienes: Array = contenido.get("figuras", [])
	var celdas := []
	if not quienes.is_empty():
		# La primera, DELANTE: al llegar hay alguien. Las demás repartidas por
		# la sala. Todas lejos es lo mismo que ninguna en una nave de cuarenta
		# metros — se llega, no se ve nada, y el sueño parece vacío.
		celdas.append(Planta.a_la_vista(bloques, entrada, PASOS_PRIMERA_FIGURA))
		celdas.append_array(Planta.repartidas(
			bloques, quienes.size() - 1, [entrada, salida, celdas[0]]))
	for i in quienes.size():
		var quien: Dictionary = quienes[i]
		figuras.append({
			"pos": Planta.centro_en_metros(bloques, celdas[i]),
			"color": COLOR_ACUSADO if quien.get("acusado", false) else COLOR_FIGURA,
			"rotulo": quien.get("nombre", ""),
			"color_rotulo": COLOR_ACUSADO_TEXTO if quien.get("acusado", false) \
				else COLOR_TEXTO,
		})

	# Las frases van a los paños más anchos, y solo caben las que caben: un
	# muro por frase. Lo que sobra no se apila en el mismo sitio — se queda
	# fuera, que es lo que hace que una pared diga UNA cosa.
	var carteles := []
	var paredes := Planta.paredes(bloques)
	var frases: Array = contenido.get("frases", [])
	for i in mini(frases.size(), paredes.size()):
		var sitio := Planta.en_pared(bloques, paredes[i], SEPARACION_PARED)
		carteles.append({
			"texto": frases[i],
			"pos": sitio["pos"],
			"giro": sitio["giro"],
			"color": COLOR_TEXTO,
		})

	return {
		"rotulo": forma["rotulo"],
		"planta": bloques,
		"color_suelo": forma["color_suelo"],
		"color_muro": forma["color_muro"],
		"color_techo": forma["color_techo"],
		"entrada": Planta.centro_en_metros(bloques, entrada),
		"figuras": figuras,
		"carteles": carteles,
		"salidas": [{
			"pos": Planta.centro_en_metros(bloques, salida) + Vector3(0, 1.1, 0),
			"destino": "sueño" if quedan > 0 else "archivo",
			"rotulo": "SALIDA_DESPERTAR" if quedan == 0 else "SUENO_ROTULO",
		}],
	}


static func _barajar(lista: Array, rng: RandomNumberGenerator) -> void:
	for i in range(lista.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var guardado = lista[i]
		lista[i] = lista[j]
		lista[j] = guardado
