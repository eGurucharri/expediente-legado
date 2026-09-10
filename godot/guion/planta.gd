## Plantas que no son una caja.
##
## `Espacio3D` sabía construir un sitio a partir de lo que MIDE su suelo: un
## rectángulo y cuatro muros derivados de él. Eso vale para una oficina y para
## una calle, y no vale para el sueño, donde se decidió que hay pocas salas
## GRANDES y raras (#86) — y una sala rara no es una caja más grande.
##
## Una planta es un conjunto de BLOQUES de celdas. Los muros no se escriben uno
## a uno: se derivan del contorno del conjunto, que es la misma regla de antes
## («un espacio no puede quedarse con un lado abierto por un descuido»)
## generalizada a cualquier forma. Un anillo, por eso, sale con sus ocho muros
## sin que nadie declare el patio: los cuatro de dentro son el contorno también.
##
## Todo se declara en CELDAS y no en metros. La celda es el mando de escala de
## la planta entera: cambiarla cambia lo que mide todo a la vez, y ninguna
## medida escrita a mano se queda a medio convertir.
class_name Planta
extends RefCounted

## Lado de una celda, en metros. Una sala del sueño se declara en unas pocas
## decenas de celdas, así que este número es lo que decide si «grande» quiere
## decir un despacho o una nave.
const CELDA := 2.0


## Todas las celdas de una planta, como diccionario-conjunto.
##
## Los bloques pueden solaparse: es la forma natural de declarar una cruz (dos
## barras) o un anillo (cuatro tiras), y contar dos veces una celda pondría un
## muro en mitad de la sala.
static func celdas(bloques: Array) -> Dictionary:
	var conjunto := {}
	for bloque in bloques:
		var rect: Rect2i = bloque
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			for z in range(rect.position.y, rect.position.y + rect.size.y):
				conjunto[Vector2i(x, z)] = true
	return conjunto


static func contiene(bloques: Array, celda: Vector2i) -> bool:
	return celdas(bloques).has(celda)


static func area(bloques: Array) -> int:
	return celdas(bloques).size()


## Los muros: toda arista de celda que no tenga celda al otro lado.
##
## Se devuelven ya FUNDIDOS en tramos, no arista a arista. No es una
## optimización posterior sino la condición de que esto se pueda usar: una sala
## de veinte por veinte tiene ochenta aristas de borde, y ochenta cajas de dos
## metros donde caben cuatro muros es lo que convierte una sala grande en una
## sala cara.
##
## Cada tramo es `{"eje", "linea", "desde", "hasta"}` en celdas: `eje` "x" es un
## muro que corre a lo largo de x sobre la línea z = `linea`, y "z" al revés.
static func contorno(bloques: Array) -> Array:
	var dentro := celdas(bloques)
	var aristas := {"x": {}, "z": {}}

	for celda in dentro:
		# Norte y sur: muros que corren a lo largo de x.
		if not dentro.has(celda + Vector2i(0, -1)):
			_anotar(aristas["x"], celda.y, celda.x)
		if not dentro.has(celda + Vector2i(0, 1)):
			_anotar(aristas["x"], celda.y + 1, celda.x)
		# Oeste y este: muros que corren a lo largo de z.
		if not dentro.has(celda + Vector2i(-1, 0)):
			_anotar(aristas["z"], celda.x, celda.y)
		if not dentro.has(celda + Vector2i(1, 0)):
			_anotar(aristas["z"], celda.x + 1, celda.y)

	var tramos := []
	for eje in ["x", "z"]:
		var lineas: Dictionary = aristas[eje]
		for linea in lineas.keys():
			var posiciones: Array = lineas[linea]
			posiciones.sort()
			var desde: int = posiciones[0]
			var ultima: int = posiciones[0]
			for i in range(1, posiciones.size()):
				if posiciones[i] == ultima + 1:
					ultima = posiciones[i]
					continue
				tramos.append({"eje": eje, "linea": linea, "desde": desde, "hasta": ultima + 1})
				desde = posiciones[i]
				ultima = posiciones[i]
			tramos.append({"eje": eje, "linea": linea, "desde": desde, "hasta": ultima + 1})
	tramos.sort_custom(func(a, b): return str(a) < str(b))
	return tramos


static func _anotar(lineas: Dictionary, linea: int, posicion: int) -> void:
	if not lineas.has(linea):
		lineas[linea] = []
	lineas[linea].append(posicion)


## Si la planta es una sola pieza. Una planta partida en dos deja media sala
## inalcanzable, y eso no se ve en una captura: se ve andando hasta que no se
## puede.
static func conexa(bloques: Array) -> bool:
	var dentro := celdas(bloques)
	if dentro.is_empty():
		return false
	var vistas := {}
	var cola := [dentro.keys()[0]]
	while not cola.is_empty():
		var celda: Vector2i = cola.pop_back()
		if vistas.has(celda):
			continue
		vistas[celda] = true
		for lado in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if dentro.has(celda + lado) and not vistas.has(celda + lado):
				cola.append(celda + lado)
	return vistas.size() == dentro.size()


## La celda más lejana de [param origen] ANDANDO, no en línea recta. En un
## anillo la de enfrente está a cuatro metros y a media vuelta de camino, y es
## la distancia de camino la que decide si algo está escondido.
##
## Se usa para poner la salida sin escribirla a mano en cada forma: donde más
## cuesta llegar. Ante empate gana la primera en orden de recorrido, que es
## determinista porque el recorrido lo es.
static func mas_lejana(bloques: Array, origen: Vector2i) -> Vector2i:
	var dentro := celdas(bloques)
	if not dentro.has(origen):
		return origen
	var distancias := {origen: 0}
	var cola := [origen]
	var lejana := origen
	var i := 0
	while i < cola.size():
		var celda: Vector2i = cola[i]
		i += 1
		if distancias[celda] > distancias[lejana]:
			lejana = celda
		for lado in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var vecina: Vector2i = celda + lado
			if dentro.has(vecina) and not distancias.has(vecina):
				distancias[vecina] = distancias[celda] + 1
				cola.append(vecina)
	return lejana


## El rectángulo de celdas que abarca la planta. De aquí sale el centro, y del
## centro salen los metros: una planta se declara con coordenadas cómodas
## (desde el cero, hacia arriba) y aparece centrada en el mundo, que es lo que
## el resto del juego espera de un espacio.
static func envolvente(bloques: Array) -> Rect2i:
	var dentro := celdas(bloques)
	if dentro.is_empty():
		return Rect2i()
	var minimo: Vector2i = dentro.keys()[0]
	var maximo: Vector2i = minimo
	for celda in dentro:
		minimo = Vector2i(mini(minimo.x, celda.x), mini(minimo.y, celda.y))
		maximo = Vector2i(maxi(maximo.x, celda.x), maxi(maximo.y, celda.y))
	return Rect2i(minimo, maximo - minimo + Vector2i.ONE)


## Dónde cae el CENTRO de una celda, en metros y ya centrado.
static func centro_en_metros(bloques: Array, celda: Vector2i) -> Vector3:
	var punto := esquina_en_metros(bloques, celda)
	return punto + Vector3(CELDA / 2.0, 0, CELDA / 2.0)


## Dónde cae la esquina baja de una celda, en metros. Las aristas de los muros
## son esquinas, no centros, así que las dos conversiones hacen falta y
## confundirlas desplaza cada muro media celda.
static func esquina_en_metros(bloques: Array, celda: Vector2i) -> Vector3:
	var caja := envolvente(bloques)
	var centro := Vector2(caja.position) + Vector2(caja.size) / 2.0
	return Vector3((celda.x - centro.x) * CELDA, 0, (celda.y - centro.y) * CELDA)


## La planta partida en rectángulos DISJUNTOS que la cubren entera.
##
## Los bloques declarados se solapan a propósito, y un suelo por bloque
## pondría dos losas en el mismo plano — que en un motor 3D no es un detalle
## invisible sino el parpadeo de dos caras peleándose por el mismo píxel. Aquí
## se funden por filas y luego las filas iguales entre sí, que es lo mismo que
## se hace en el otro repositorio con las chapas de un muro y por el mismo
## motivo: el suelo de una sala grande son cientos de celdas.
static func rectangulos(bloques: Array) -> Array:
	var dentro := celdas(bloques)
	var filas := {}
	for celda in dentro:
		if not filas.has(celda.y):
			filas[celda.y] = []
		filas[celda.y].append(celda.x)

	# Cada fila, en tramos horizontales.
	var tramos_por_fila := {}
	for z in filas:
		var xs: Array = filas[z]
		xs.sort()
		var tramos := []
		var desde: int = xs[0]
		var ultima: int = xs[0]
		for i in range(1, xs.size()):
			if xs[i] == ultima + 1:
				ultima = xs[i]
				continue
			tramos.append(Vector2i(desde, ultima + 1))
			desde = xs[i]
			ultima = xs[i]
		tramos.append(Vector2i(desde, ultima + 1))
		tramos_por_fila[z] = tramos

	var zs := tramos_por_fila.keys()
	zs.sort()
	var salida := []
	var pendientes := {}  # tramo -> z en que empezó
	for z in zs:
		var actuales := {}
		for tramo in tramos_por_fila[z]:
			actuales[tramo] = true
		# Los que ya no siguen se cierran; los nuevos empiezan aquí.
		for tramo in pendientes.keys():
			if not actuales.has(tramo) or pendientes[tramo][1] != z:
				salida.append(Rect2i(tramo.x, pendientes[tramo][0],
					tramo.y - tramo.x, z - pendientes[tramo][0]))
				pendientes.erase(tramo)
		for tramo in actuales:
			if pendientes.has(tramo):
				pendientes[tramo][1] = z + 1
			else:
				pendientes[tramo] = [z, z + 1]
	for tramo in pendientes:
		salida.append(Rect2i(tramo.x, pendientes[tramo][0],
			tramo.y - tramo.x, pendientes[tramo][1] - pendientes[tramo][0]))
	salida.sort_custom(func(a, b): return str(a) < str(b))
	return salida
