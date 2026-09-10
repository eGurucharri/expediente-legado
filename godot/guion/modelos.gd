## Los muebles que son malla de verdad y no una caja.
##
## `EspaciosCatalogo` ya lo había previsto: «una mesa es una caja **hasta que
## haya un asset con su ficha**; llamarla mesa aquí es lo que permite
## sustituirla luego sin tocar la geografía». Esto es ese *luego*. Un bulto
## declara `modelo` y le sale la malla encima; sin `modelo` sigue siendo la caja
## de siempre, así que ningún sitio existente cambia por esto.
##
## Tres reglas, y ninguna es de comodidad:
##
## 1. **La caja sigue mandando.** El modelo se ENCAJA en el `tam` declarado y la
##    colisión sigue siendo la del bulto. La geografía es del catálogo, no del
##    fichero que alguien descargó: si un `.glb` viniera con otra escala, lo que
##    no puede pasar es que la sala cambie de forma por debajo. Se puede
##    sustituir un modelo por otro y nadie se queda encerrado.
## 2. **Se viste con el mismo shader que todo lo demás.** `Espacio3D` dice que
##    un solo material es lo que hace que esto parezca una máquina y no un
##    render, y un mueble importado con su propio material sería justo eso: un
##    objeto de otro juego pegado en esta oficina. El modelo aporta la FORMA; el
##    color lo sigue declarando el catálogo, como el de cualquier bulto.
## 3. **Un modelo que falta no revienta la sala.** Se queda la caja. Un archivo
##    con un archivador cúbico es peor; un archivo que no abre es inaceptable.
class_name Modelos
extends RefCounted

const RUTA := "res://assets/modelos/"

## Lo que se carga una vez y se reusa. Las salas repiten mueble —seis
## archivadores, cuatro puestos— y volver a leer el `.glb` por cada uno es leer
## el mismo fichero seis veces para obtener seis cosas idénticas.
static var _cache := {}


## Mete el modelo [param nombre] dentro de [param cuerpo], encajado en
## [param tam] y teñido de [param color]. Devuelve si pudo.
##
## [param cuerpo] es el `StaticBody3D` del bulto, así que el modelo hereda su
## posición y su colisión sin saber que existen.
static func vestir(cuerpo: Node3D, nombre: String, tam: Vector3, color: Color) -> bool:
	var escena := cargar(nombre)
	if escena == null:
		return false

	var pieza: Node3D = escena.instantiate()
	cuerpo.add_child(pieza)
	_encajar(pieza, tam)
	_pintar(pieza, color)
	return true


## La escena del modelo, o nulo si no está. Cachea el recurso y NO la instancia:
## dos archivadores son dos nodos, no el mismo nodo en dos sitios.
static func cargar(nombre: String) -> PackedScene:
	if _cache.has(nombre):
		return _cache[nombre]
	var ruta := RUTA + nombre + ".glb"
	var escena: PackedScene = load(ruta) if ResourceLoader.exists(ruta) else null
	if escena == null:
		push_warning("No hay modelo %s en %s" % [nombre, RUTA])
	_cache[nombre] = escena
	return escena


## Existe para las pruebas: el catálogo puede comprobar que todo `modelo` que
## nombra está de verdad en el árbol, sin montar una escena 3D para verlo.
static func hay(nombre: String) -> bool:
	return ResourceLoader.exists(RUTA + nombre + ".glb")


## Escala el modelo para que quepa en [param tam] y lo APOYA en el suelo del
## bulto.
##
## La escala es **uniforme** y sale del eje que peor va: estirar una silla para
## llenar una caja que no tiene sus proporciones da una silla derretida, y la
## caja de un bulto es una medida de sitio ocupado, no un molde. Y se apoya en
## vez de centrarse porque un mueble descansa en el suelo — centrado por su caja,
## una silla más baja de lo declarado flotaría.
static func _encajar(pieza: Node3D, tam: Vector3) -> void:
	var caja := _limites(pieza)
	if caja.size.x <= 0.0 or caja.size.y <= 0.0 or caja.size.z <= 0.0:
		return

	var escala := minf(minf(tam.x / caja.size.x, tam.y / caja.size.y), tam.z / caja.size.z)
	pieza.scale = Vector3.ONE * escala

	# El centro del modelo no tiene por qué ser el de su malla, así que se
	# recoloca por sus límites REALES: primero se centra en horizontal y luego se
	# baja hasta que su base toque la del bulto.
	var centro := caja.get_center() * escala
	pieza.position = Vector3(-centro.x, -tam.y / 2.0 - caja.position.y * escala, -centro.z)


## Los límites de todo lo que cuelga de un nodo, en coordenadas del nodo. Godot
## da el AABB de UNA malla; un mueble suele ser varias.
static func _limites(nodo: Node3D) -> AABB:
	var total := AABB()
	var primero := true
	for hijo in _mallas(nodo):
		var malla: MeshInstance3D = hijo
		var caja: AABB = malla.get_aabb()
		# Del espacio de la malla al del nodo raíz, que es donde se encaja.
		var trans: Transform3D = nodo.global_transform.affine_inverse() * malla.global_transform
		caja = trans * caja
		if primero:
			total = caja
			primero = false
		else:
			total = total.merge(caja)
	return total


## Le pone a cada malla el material de la casa. El modelo pone la forma y el
## catálogo el color, que es lo que evita que un mueble importado se vea como
## de otro juego.
static func _pintar(nodo: Node3D, color: Color) -> void:
	var material := ShaderMaterial.new()
	material.shader = load(Espacio3D.SHADER_PSX)
	material.set_shader_parameter("color_base", color)
	for hijo in _mallas(nodo):
		var malla: MeshInstance3D = hijo
		malla.material_override = material


static func _mallas(nodo: Node) -> Array:
	var encontradas := []
	if nodo is MeshInstance3D:
		encontradas.append(nodo)
	for hijo in nodo.get_children():
		encontradas.append_array(_mallas(hijo))
	return encontradas
