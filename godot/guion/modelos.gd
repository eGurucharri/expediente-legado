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

## Las extensiones que puede tener un modelo, en orden de preferencia. Los
## muebles vienen en `.glb` y las personas en `.fbx`: el pack de figuras
## animadas no publica glTF, y Godot 4.7 importa FBX por su cuenta desde que
## lleva ufbx dentro. Quien pide un modelo no tiene por qué saber en qué formato
## lo publicó su autor.
const FORMATOS: Array[String] = [".glb", ".fbx"]

## Los retratos de quienes fueron alguien. Van aparte de los modelos porque no
## son un modelo: son una cara puesta sobre uno.
const RETRATOS := "res://assets/retratos/%s.jpg"

## Lo que se carga una vez y se reusa. Las salas repiten mueble —seis
## archivadores, cuatro puestos— y volver a leer el `.glb` por cada uno es leer
## el mismo fichero seis veces para obtener seis cosas idénticas.
static var _cache := {}


## Mete el modelo [param nombre] dentro de [param cuerpo], encajado en
## [param tam] y teñido de [param color]. Devuelve si pudo.
##
## [param cuerpo] es el `StaticBody3D` del bulto, así que el modelo hereda su
## posición y su colisión sin saber que existen.
static func vestir(
	cuerpo: Node3D,
	nombre: String,
	tam: Vector3,
	color: Color,
	por_alto: bool = false,
	retrato: String = ""
) -> bool:
	var escena := cargar(nombre)
	if escena == null:
		return false

	var pieza: Node3D = escena.instantiate()
	cuerpo.add_child(pieza)
	_encajar(pieza, tam, por_alto)
	_pintar(pieza, color)
	_animar(pieza)
	if not retrato.is_empty():
		_poner_cara(pieza, retrato)
	return true


## Que respiren.
##
## Estas figuras vienen con esqueleto, y un esqueleto SIN animación no se queda
## de pie: se queda en la pose de reposo con la que se modeló, brazos en cruz y
## rodillas rectas. Parece un maniquí caído, no un compañero de oficina — que es
## exactamente lo que se vio en la primera captura.
##
## `idle` está en los once modelos del pack. Se pone en bucle a mano porque el
## `.glb` no trae marcado el suyo: sin eso, cada uno respira una vez y se queda
## clavado en el último fotograma.
static func _animar(pieza: Node3D, cual: String = "idle") -> void:
	var reproductor := _reproductor(pieza)
	if reproductor == null:
		return

	# El nombre no es el mismo en todos los packs: uno la llama `idle` y otro
	# `CharacterArmature|Idle`, con el esqueleto por delante. Se busca por el
	# final y sin mayúsculas, que es lo único que comparten.
	var nombre := ""
	for candidata in reproductor.get_animation_list():
		if String(candidata).to_lower().ends_with(cual.to_lower()):
			nombre = candidata
			break
	if nombre.is_empty():
		return

	var animacion := reproductor.get_animation(nombre)
	animacion.loop_mode = Animation.LOOP_LINEAR
	# Cada uno por su sitio: once personas respirando al unísono son un coro, y
	# una oficina no lo es. El desfase sale del NOMBRE del modelo y no de
	# `randf()`: una partida se puede volver a ver (#147), y un sorteo sin raíz
	# haría que la misma vuelta no se repitiera igual. Además así cada compañero
	# respira siempre con su mismo compás.
	var desfase := float(absi(hash(pieza.name)) % 1000) / 1000.0
	reproductor.play(nombre)
	reproductor.seek(desfase * animacion.length, true)


## El reproductor de animaciones, esté donde esté: unos packs lo cuelgan de la
## raíz y otros lo meten bajo el nodo del modelo.
static func _reproductor(nodo: Node) -> AnimationPlayer:
	if nodo is AnimationPlayer:
		return nodo
	for hijo in nodo.get_children():
		var encontrado := _reproductor(hijo)
		if encontrado != null:
			return encontrado
	return null


## Le pone a alguien SU cara.
##
## Cinco de los compañeros son gente que existió y que acabó de oficinista: el
## último emperador de China ordenando papeles, el inspector de aduanas que
## escribió Moby Dick, el de la correspondencia comercial que era varios poetas,
## el del fielato que pintaba selvas que no había visto, el de la oficina de
## riegos de Alejandría. El chiste entero depende de que se les RECONOZCA, y una
## figura genérica lo borra: serían cinco oficinistas cualesquiera diciendo
## frases raras.
##
## Va como un plano delante de la cabeza y no como textura de la malla: la
## cabeza trae sus coordenadas para el atlas de su autor, y una fotografía
## encima saldría estirada por la nuca. Un plano con una foto es además
## exactamente como se resolvía una cara en 1998.
static func _poner_cara(pieza: Node3D, retrato: String) -> void:
	var ruta := RETRATOS % retrato
	if not ResourceLoader.exists(ruta):
		push_warning("No hay retrato %s" % ruta)
		return

	var esqueleto := _esqueleto(pieza)
	if esqueleto == null:
		return
	var hueso := esqueleto.find_bone("Head")
	if hueso < 0:
		return

	# Colgada del HUESO y no del modelo: así la cara acompaña a la cabeza cuando
	# la animación la mueve. Pegada a la raíz se quedaría flotando en el sitio
	# donde estaba la cabeza al empezar.
	var enganche := BoneAttachment3D.new()
	enganche.bone_idx = hueso
	esqueleto.add_child(enganche)

	# Lo que mide una cabeza: del hueso del cuello a la coronilla. Sale del
	# esqueleto y no de un número, para que valga si algún día cambia el modelo.
	var alto := 0.012
	var coronilla := esqueleto.find_bone("HeadTop_End")
	if coronilla >= 0:
		alto = absf(
			(
				esqueleto.get_bone_global_pose(coronilla).origin.y
				- esqueleto.get_bone_global_pose(hueso).origin.y
			)
		)

	var cara := MeshInstance3D.new()
	var plano := QuadMesh.new()
	plano.size = Vector2(alto, alto) * 1.35
	cara.mesh = plano
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(ruta)
	material.roughness = 1.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	cara.material_override = material
	# Delante de la cabeza y a la altura de la cara, que está por encima del
	# hueso del cuello.
	cara.position = Vector3(0.0, alto * 0.5, alto * 0.62)
	enganche.add_child(cara)


## El esqueleto de una figura, si lo tiene.
static func _esqueleto(nodo: Node) -> Skeleton3D:
	if nodo is Skeleton3D:
		return nodo
	for hijo in nodo.get_children():
		var encontrado := _esqueleto(hijo)
		if encontrado != null:
			return encontrado
	return null


## La escena del modelo, o nulo si no está. Cachea el recurso y NO la instancia:
## dos archivadores son dos nodos, no el mismo nodo en dos sitios.
static func cargar(nombre: String) -> PackedScene:
	if _cache.has(nombre):
		return _cache[nombre]
	var escena: PackedScene = null
	for formato in FORMATOS:
		var ruta := RUTA + nombre + formato
		if ResourceLoader.exists(ruta):
			escena = load(ruta)
			break
	if escena == null:
		push_warning("No hay modelo %s en %s" % [nombre, RUTA])
	_cache[nombre] = escena
	return escena


## Existe para las pruebas: el catálogo puede comprobar que todo `modelo` que
## nombra está de verdad en el árbol, sin montar una escena 3D para verlo.
static func hay(nombre: String) -> bool:
	for formato in FORMATOS:
		if ResourceLoader.exists(RUTA + nombre + formato):
			return true
	return false


## Escala el modelo para que quepa en [param tam] y lo APOYA en el suelo del
## bulto.
##
## La escala es **uniforme** y sale del eje que peor va: estirar una silla para
## llenar una caja que no tiene sus proporciones da una silla derretida, y la
## caja de un bulto es una medida de sitio ocupado, no un molde. Y se apoya en
## vez de centrarse porque un mueble descansa en el suelo — centrado por su caja,
## una silla más baja de lo declarado flotaría.
static func _encajar(pieza: Node3D, tam: Vector3, por_alto: bool = false) -> void:
	var caja := _limites(pieza)
	if caja.size.x <= 0.0 or caja.size.y <= 0.0 or caja.size.z <= 0.0:
		return

	# Un mueble se mide por el SITIO que ocupa, y por eso manda el eje peor. Una
	# persona se mide por lo ALTA que es: una figura con los brazos abiertos mide
	# más de ancho que de alto, así que encajarla por el eje peor la encogía
	# hasta dejarla del tamaño de una papelera. Se vio en una captura: los
	# rótulos con los nombres flotaban sobre mesas vacías.
	var escala := (
		tam.y / caja.size.y
		if por_alto
		else minf(minf(tam.x / caja.size.x, tam.y / caja.size.y), tam.z / caja.size.z)
	)
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
