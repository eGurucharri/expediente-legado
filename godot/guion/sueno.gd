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
static func espacio(id: String, quedan: int) -> Dictionary:
	var forma := SuenoFormas.de(id)
	var bloques: Array = forma["bloques"]
	var entrada: Vector2i = forma["entrada"]
	var salida := Planta.mas_lejana(bloques, entrada)

	return {
		"rotulo": forma["rotulo"],
		"planta": bloques,
		"color_suelo": forma["color_suelo"],
		"color_muro": forma["color_muro"],
		"color_techo": forma["color_techo"],
		"entrada": Planta.centro_en_metros(bloques, entrada),
		"salidas": [{
			"pos": Planta.centro_en_metros(bloques, salida) + Vector3(0, 1.1, 0),
			"destino": "sueño" if quedan > 0 else "archivo",
			"rotulo": "…" if quedan > 0 else "Despertar",
		}],
	}


static func _barajar(lista: Array, rng: RandomNumberGenerator) -> void:
	for i in range(lista.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var guardado = lista[i]
		lista[i] = lista[j]
		lista[j] = guardado
