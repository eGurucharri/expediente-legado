## Dónde vive una partida.
##
## En el original el estado estaba en `localStorage`, que es un almacén que no
## se corrompe a medias y del que no se puede perder el fichero. Un fichero sí,
## así que este módulo no es un port de `cargarEstado`/`guardarEstado`: es lo
## mismo hecho con las precauciones que un fichero exige.
##
## Tres decisiones que el original no tenía que tomar:
##
## 1. **La escritura es atómica.** Se escribe a un temporal y se renombra
##    encima. Renombrar en el mismo sistema de ficheros no deja estados
##    intermedios, así que un cierre a destiempo deja la partida anterior
##    entera en vez de media partida nueva.
## 2. **Una partida ilegible NO se pisa.** El original hacía `catch {}` y
##    seguía con el estado vacío, o sea que el primer guardado posterior
##    borraba para siempre lo que hubiera. Aquí se aparta con extensión
##    `.roto` y se empieza de cero al lado: si el fallo era del disco o de una
##    versión futura, lo que había sigue ahí para recuperarlo.
## 3. **El formato va versionado.** El original resolvía los ids renombrados
##    con una tabla de alias, que funciona pero no dice desde qué versión.
##    El alias se conserva (los ids ya renombrados siguen renombrados), pero
##    ahora hay un número al que colgar la próxima migración.
##
## Lo que NO se guarda es el contenido, solo ids y estado. Los documentos viven
## en `casos.json` y los títulos de logros y cartas en `prometeo.json`, así que
## reescribir una cartela o la descripción de un logro no invalida ninguna
## partida — y no deja partidas viejas mostrando el texto antiguo, que es lo
## que pasaría si el guardado se llevara una copia.
class_name Partida
extends RefCounted

const RUTA := "user://partida.json"
const CATALOGOS := "res://datos/prometeo.json"

## Se sube cuando un cambio de formato necesite migración. La partida que
## llegue con una versión MAYOR que esta es de un futuro que este binario no
## entiende, y se aparta en vez de interpretarse a medias.
const VERSION := 1

const VIDA_MAXIMA := 3

## Ids que cambiaron de nombre: clave la actual, valor la antigua.
const ALIAS := {}

## JSON no distingue un entero de un decimal, así que todo número vuelve como
## coma flotante: una racha de 4 se relee como 4.0, se muestra como "4.0" y
## deja de ser igual a 4 en cualquier comparación. Es el mismo fallo que puso
## "Expediente 1999.0" en la barra de título, y por eso no se arregla en el
## sitio donde se ve sino aquí, que es por donde entra.
const CAMPOS_ENTEROS := ["vida", "coliseo_racha_mejor"]

var estado: Dictionary = {}


## Una partida recién empezada, con los catálogos en su estado de serie.
static func nueva() -> Dictionary:
	var catalogos := _leer_json(CATALOGOS)
	return {
		"version": VERSION,
		"pistas_descubiertas": [],
		"logros": catalogos.get("logros", []),
		"tarot": catalogos.get("tarot", []),
		"vida": VIDA_MAXIMA,
		"dificultad": "normal",
		"historias_cartas": {},
		"cartas_conocidas": [],
		"coliseo_racha_mejor": 0,
		"despido_mostrado": false,
		"epilogo_avisado": false,
		"final_politico_mostrado": false,
		"final_verdadero_mostrado": false,
		"perdio_vida_en_esta_vuelta": false,
	}


## Carga la partida guardada, o empieza una nueva si no hay ninguna.
##
## Devuelve además qué pasó, porque la interfaz debe poder DECIRLO: que una
## partida no se haya podido leer no puede parecerse a no haber jugado nunca.
func cargar(ruta: String = RUTA) -> Dictionary:
	estado = nueva()

	if not FileAccess.file_exists(ruta):
		return {"resultado": "nueva"}

	var fichero := FileAccess.open(ruta, FileAccess.READ)
	if fichero == null:
		return _apartar(ruta, "ilegible")
	var crudo = JSON.parse_string(fichero.get_as_text())
	fichero.close()

	if typeof(crudo) != TYPE_DICTIONARY:
		return _apartar(ruta, "corrupta")

	var version := int(crudo.get("version", 0))
	if version > VERSION:
		return _apartar(ruta, "de una versión posterior")

	estado = _fusionar(crudo)
	return {"resultado": "cargada", "version": version}


## Los campos de estado de cada catálogo: lo único suyo que la partida guarda.
## Todo lo demás (título, descripción, requisito) es contenido y se vuelve a
## leer de `prometeo.json` en cada arranque.
const ESTADO_LOGRO := ["desbloqueado"]
const ESTADO_CARTA := ["recogida", "gastada"]


## Guarda el estado actual. Devuelve true solo si la partida quedó escrita de
## verdad: quien llame puede avisar, en vez de dar por hecho que se guardó.
func guardar(ruta: String = RUTA) -> bool:
	estado["version"] = VERSION

	var temporal := ruta + ".nuevo"
	var fichero := FileAccess.open(temporal, FileAccess.WRITE)
	if fichero == null:
		push_error("No se pudo escribir %s" % temporal)
		return false
	fichero.store_string(JSON.stringify(_para_guardar(), "\t"))
	fichero.close()

	# El renombrado es lo que hace atómico el guardado: hasta esta línea, la
	# partida buena sigue siendo la de antes.
	var error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporal), ProjectSettings.globalize_path(ruta))
	if error != OK:
		push_error("No se pudo reemplazar %s (error %d)" % [ruta, error])
		return false
	return true


## El estado reducido a lo que es de la partida: los catálogos se quedan en sus
## ids y sus banderas.
func _para_guardar() -> Dictionary:
	var reducido := estado.duplicate()
	reducido["logros"] = _solo_estado(estado.get("logros", []), ESTADO_LOGRO)
	reducido["tarot"] = _solo_estado(estado.get("tarot", []), ESTADO_CARTA)
	return reducido


static func _solo_estado(entradas: Array, campos: Array) -> Array:
	var reducidas := []
	for entrada in entradas:
		var minima := {"id": entrada["id"]}
		for campo in campos:
			if entrada.has(campo):
				minima[campo] = entrada[campo]
		reducidas.append(minima)
	return reducidas


## Combina lo guardado con los catálogos vigentes: conserva lo conseguido y
## adopta los logros y cartas que la versión nueva haya añadido.
##
## Reutiliza `Prometeo.fusionar_con_guardado`, que es exactamente esto y ya
## está probado. Una segunda implementación aquí acabaría divergiendo de la que
## usa la interfaz, y entonces un logro estaría desbloqueado en una pantalla y
## bloqueado en otra.
func _fusionar(guardado: Dictionary) -> Dictionary:
	var fusionado := nueva()

	for clave in fusionado:
		if clave in ["version", "logros", "tarot"]:
			continue
		if guardado.has(clave):
			fusionado[clave] = int(guardado[clave]) if clave in CAMPOS_ENTEROS \
				else guardado[clave]

	fusionado["logros"] = Prometeo.fusionar_con_guardado(
		guardado.get("logros", []), fusionado["logros"], ESTADO_LOGRO, ALIAS)
	fusionado["tarot"] = Prometeo.fusionar_con_guardado(
		guardado.get("tarot", []), fusionado["tarot"], ESTADO_CARTA, ALIAS)
	return fusionado


## Aparta una partida que no se puede interpretar, en vez de pisarla.
func _apartar(ruta: String, motivo: String) -> Dictionary:
	var destino := ruta + ".roto"
	var error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(ruta), ProjectSettings.globalize_path(destino))
	push_warning("Partida %s; apartada en %s" % [motivo, destino])
	return {
		"resultado": "apartada",
		"motivo": motivo,
		"copia": destino if error == OK else "",
	}


static func _leer_json(ruta: String) -> Dictionary:
	var fichero := FileAccess.open(ruta, FileAccess.READ)
	if fichero == null:
		push_error("No se pudo abrir %s" % ruta)
		return {}
	var crudo = JSON.parse_string(fichero.get_as_text())
	fichero.close()
	return crudo if typeof(crudo) == TYPE_DICTIONARY else {}
