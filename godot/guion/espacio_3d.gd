## Construye un espacio andable a partir de su declaración.
##
## Un espacio es DATOS: suelo, muros, bultos y salidas. Este módulo los
## convierte en malla y colisión, y no conoce el nombre de ninguna sala — igual
## que `Marcas` no sabe pintar y `Combate` no sabe de pantallas. Añadir la
## oficina, la calle o la casa es una entrada más del catálogo; si para meter un
## sitio hiciera falta un `if` con su nombre aquí dentro, el diseño se ha roto.
##
## La geometría es deliberadamente pobre: cajas y planos, con la paleta de
## SIGA-98. No es un placeholder a la espera de arte — es el mismo argumento que
## la tipografía sin suavizar, que una oficina de 1998 se parece más a esto que
## a un render.
class_name Espacio3D
extends RefCounted

const ALTURA_MURO := 2.8
const GROSOR_MURO := 0.2


## Monta el espacio bajo [param raiz] y devuelve las salidas creadas, para que
## quien orquesta el día pueda escucharlas.
static func construir(raiz: Node3D, espacio: Dictionary) -> Array:
	_suelo(raiz, espacio.get("suelo", Vector2(10, 10)), espacio.get("color_suelo", Color(0.35, 0.34, 0.32)))
	_techo(raiz, espacio.get("suelo", Vector2(10, 10)), espacio.get("color_techo", Color(0.28, 0.28, 0.27)))
	_muros(raiz, espacio.get("suelo", Vector2(10, 10)), espacio.get("color_muro", Color(0.55, 0.54, 0.5)))

	for bulto in espacio.get("bultos", []):
		_caja(raiz, bulto["pos"], bulto["tam"], bulto.get("color", Color(0.45, 0.44, 0.42)))

	var salidas := []
	for salida in espacio.get("salidas", []):
		salidas.append(_salida(raiz, salida))
	return salidas


static func _suelo(raiz: Node3D, medidas: Vector2, color: Color) -> void:
	_caja(raiz, Vector3(0, -GROSOR_MURO / 2.0, 0),
		Vector3(medidas.x, GROSOR_MURO, medidas.y), color)


## El techo va EMISIVO, no solo claro. La luz del motor viene de arriba, así
## que la cara de abajo de un techo está siempre en el mínimo y sale negra por
## construcción — mirar arriba en cualquiera de estas salas era mirar a un
## agujero. Un techo que se pinta a sí mismo es además lo que hay: en 1998 esa
## superficie eran paneles de fluorescente.
static func _techo(raiz: Node3D, medidas: Vector2, color: Color) -> void:
	var cuerpo := _caja(raiz, Vector3(0, ALTURA_MURO + GROSOR_MURO / 2.0, 0),
		Vector3(medidas.x, GROSOR_MURO, medidas.y), color)
	var malla: MeshInstance3D = cuerpo.get_child(0)
	var material: StandardMaterial3D = malla.material_override
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.9


## Los cuatro muros salen de lo que mide el suelo, no escritos uno a uno: un
## espacio no puede quedarse con un lado abierto por un descuido.
static func _muros(raiz: Node3D, medidas: Vector2, color: Color) -> void:
	var mitad_x := medidas.x / 2.0
	var mitad_z := medidas.y / 2.0
	var alto := ALTURA_MURO / 2.0
	_caja(raiz, Vector3(0, alto, -mitad_z), Vector3(medidas.x, ALTURA_MURO, GROSOR_MURO), color)
	_caja(raiz, Vector3(0, alto, mitad_z), Vector3(medidas.x, ALTURA_MURO, GROSOR_MURO), color)
	_caja(raiz, Vector3(-mitad_x, alto, 0), Vector3(GROSOR_MURO, ALTURA_MURO, medidas.y), color)
	_caja(raiz, Vector3(mitad_x, alto, 0), Vector3(GROSOR_MURO, ALTURA_MURO, medidas.y), color)


static func _caja(raiz: Node3D, pos: Vector3, tam: Vector3, color: Color) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.position = pos

	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	# Sin brillo: una oficina de 1998 no tiene reflejos especulares.
	material.roughness = 1.0
	material.metallic = 0.0
	malla.material_override = material
	cuerpo.add_child(malla)

	var forma := CollisionShape3D.new()
	var caja_col := BoxShape3D.new()
	caja_col.size = tam
	forma.shape = caja_col
	cuerpo.add_child(forma)

	raiz.add_child(cuerpo)
	return cuerpo


## Una salida es una zona que se pisa, no un botón: en un walking simulator lo
## que decide es dónde estás.
static func _salida(raiz: Node3D, salida: Dictionary) -> Area3D:
	var zona := Area3D.new()
	zona.position = salida["pos"]
	zona.set_meta("destino", salida["destino"])
	zona.set_meta("rotulo", salida.get("rotulo", ""))

	var forma := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = salida.get("tam", Vector3(1.4, 2.2, 1.4))
	forma.shape = caja
	zona.add_child(forma)

	# Se ve: una salida invisible es una trampa. Va en el color de lo accionable
	# y no en el del mobiliario.
	var marca := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = salida.get("tam", Vector3(1.4, 2.2, 1.4))
	marca.mesh = malla
	var material := StandardMaterial3D.new()
	# Se ve pero no tapa: una marca opaca sobre la cama escondería la cama.
	material.albedo_color = Color(0.15, 0.2, 0.75, 0.16)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 1.0
	marca.material_override = material
	zona.add_child(marca)

	raiz.add_child(zona)
	return zona
