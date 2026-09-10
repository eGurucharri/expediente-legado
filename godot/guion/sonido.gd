## Qué suena y cuándo.
##
## Un catálogo por NOMBRE, no rutas repartidas por las pantallas: quien quiere
## que suene un paso pide `"paso"` y no sabe qué fichero es. Cambiar el sonido
## de una cosa se hace aquí, y una sola vez.
##
## Todo lo que hay son assets **CC0 de Kenney**, con su ficha en
## `assets/procedencia.json` (autor, licencia, la página que declara la licencia
## y sha256) y con la prueba que lo exige en las dos direcciones. Nada entra sin
## ficha, y eso no es higiene: con destino comercial (#99) es lo que protege.
##
## **Lo que todavía NO hay es ambiente** —el zumbido del fluorescente del
## archivo, la calle de noche, el silencio raro del sueño—: Kenney no tiene
## ambientes, así que eso sigue esperando a #119. Lo que hay es lo que se toca
## y lo que se pisa.
class_name Sonido
extends RefCounted

const RUTA := "res://assets/audio/"

## Los pasos son varios a propósito: uno solo repetido a cada zancada deja de
## ser un paso y pasa a ser un tic.
const PASOS := ["footstep00.ogg", "footstep01.ogg", "footstep02.ogg", "footstep03.ogg"]

const CATALOGO := {
	"puerta_abre": "doorOpen_1.ogg",
	"puerta_cierra": "doorClose_1.ogg",
	"documento": "bookFlip1.ogg",
	"nomina": "handleCoins.ogg",
	"pulsar": "click_001.ogg",
	"error": "error_003.ogg",
	"firmar": "confirmation_001.ogg",
	"marcar": "switch_002.ogg",
}


static func stream(nombre: String) -> AudioStream:
	if not CATALOGO.has(nombre):
		return null
	return load(RUTA + CATALOGO[nombre])


## Un paso, el que toque. [param cual] hace la elección determinista para quien
## quiera repetirla; sin él, va sorteado.
static func paso(cual: int = -1) -> AudioStream:
	var i := cual if cual >= 0 else randi()
	return load(RUTA + PASOS[i % PASOS.size()])


## Suena una vez, en la pantalla que lo pide.
##
## El reproductor se crea y se tira solo: una pantalla que guarda su propio
## `AudioStreamPlayer` acaba con uno por cada sitio desde el que suena algo, y
## el primero que se olvida de pararlo se solapa con el siguiente.
static func sonar(nodo: Node, nombre: String) -> void:
	var pista := stream(nombre)
	if pista == null or nodo == null:
		return
	var voz := AudioStreamPlayer.new()
	voz.stream = pista
	voz.finished.connect(voz.queue_free)
	nodo.add_child(voz)
	voz.play()


## Todos los ficheros que el catálogo puede pedir. Para que una prueba
## compruebe que existen TODOS: un nombre que apunta a un fichero que no está
## no falla al arrancar, falla el día que alguien abre esa puerta.
static func ficheros() -> Array:
	var todos := PASOS.duplicate()
	for nombre in CATALOGO:
		todos.append(CATALOGO[nombre])
	return todos
