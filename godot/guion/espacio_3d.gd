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

## A qué altura se escribe en una pared: a la de los ojos, que es donde se lee
## sin levantar la cabeza.
const ALTURA_CARTEL := 1.7


## Monta el espacio bajo [param raiz] y devuelve las salidas creadas, para que
## quien orquesta el día pueda escucharlas.
static func construir(raiz: Node3D, espacio: Dictionary) -> Array:
	var color_suelo: Color = espacio.get("color_suelo", Color(0.35, 0.34, 0.32))
	var color_techo: Color = espacio.get("color_techo", Color(0.28, 0.28, 0.27))
	var color_muro: Color = espacio.get("color_muro", Color(0.55, 0.54, 0.5))

	# Dos formas de declarar un sitio, y la caja es el caso fácil de la otra:
	# un espacio con `planta` es un conjunto de celdas de cualquier forma, y uno
	# con `suelo` es el rectángulo de siempre. Lo que NO hay es un sitio con
	# nombre: el motor sigue sin saber si esto es una oficina o un sueño.
	if espacio.has("planta"):
		_por_planta(raiz, espacio["planta"], color_suelo, color_techo, color_muro)
	else:
		_suelo(raiz, espacio.get("suelo", Vector2(10, 10)), color_suelo)
		_techo(raiz, espacio.get("suelo", Vector2(10, 10)), color_techo)
		_muros(raiz, espacio.get("suelo", Vector2(10, 10)), color_muro)

	for bulto in espacio.get("bultos", []):
		_caja(raiz, bulto["pos"], bulto["tam"], bulto.get("color", Color(0.45, 0.44, 0.42)))

	# Las figuras y los carteles son del sueño (#87), pero este módulo sigue sin
	# saberlo: aquí solo hay una silueta en un sitio y un texto contra un muro.
	for figura in espacio.get("figuras", []):
		var cuerpo := FiguraSilueta.construir(
			raiz, figura["pos"], figura.get("color", Color(0.30, 0.28, 0.34)))
		if not figura.get("rotulo", "").is_empty():
			_cartel(cuerpo, figura["rotulo"],
				Vector3(0, FiguraSilueta.altura() + 0.35, 0), 0.0,
				figura.get("color_rotulo", Color(0.75, 0.74, 0.78)), true)

	for cartel in espacio.get("carteles", []):
		_cartel(raiz, cartel["texto"], cartel["pos"] + Vector3(0, ALTURA_CARTEL, 0),
			cartel.get("giro", 0.0), cartel.get("color", Color(0.75, 0.74, 0.78)), false)

	var salidas := []
	for salida in espacio.get("salidas", []):
		salidas.append(_salida(raiz, salida))
	return salidas


## Un texto en el mundo, no en la interfaz.
##
## Lo que se escribe en una pared del sueño está EN la pared: hay que acercarse
## y hay que mirar. Puesto en la interfaz sería una nota al margen, y una frase
## que te sigue por la pantalla no es lo mismo que una frase que está escrita
## en un sitio.
##
## [param sigue] hace que el texto mire siempre al jugador. Lo lleva el nombre
## de una figura —que se lee desde donde sea— y NO un texto de pared, que si
## girase dejaría de estar escrito en la pared.
static func _cartel(raiz: Node3D, texto: String, pos: Vector3, giro: float,
		color: Color, sigue: bool) -> Label3D:
	var cartel := Label3D.new()
	cartel.text = texto
	cartel.position = pos
	cartel.rotation.y = giro
	cartel.modulate = color
	# En la letra del archivo, sin suavizar: una frase gatillo en el sueño es la
	# MISMA frase del documento, y en otra tipografía sería una cita.
	cartel.font = EstiloSiga.fuente_mono()
	cartel.font_size = 48
	cartel.pixel_size = 0.006
	cartel.outline_size = 12
	cartel.outline_modulate = Color(0, 0, 0, 0.85)
	cartel.width = 1400
	cartel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cartel.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y if sigue \
		else BaseMaterial3D.BILLBOARD_DISABLED
	# Se lee de noche: sin esto la letra queda tan a oscuras como el muro que
	# tiene detrás, y una frase que no se lee no está escrita.
	cartel.shaded = false
	raiz.add_child(cartel)
	return cartel


## Una planta cualquiera: losas donde hay celda y muros donde no hay vecina.
##
## Nada de esto conoce la forma que está montando. El anillo del sueño sale con
## el muro de su patio porque el patio es contorno igual que el borde de fuera,
## no porque nadie haya declarado un patio.
static func _por_planta(raiz: Node3D, bloques: Array, color_suelo: Color,
		color_techo: Color, color_muro: Color) -> void:
	for rect in Planta.rectangulos(bloques):
		var esquina := Planta.esquina_en_metros(bloques, rect.position)
		var tam := Vector3(rect.size.x * Planta.CELDA, GROSOR_MURO, rect.size.y * Planta.CELDA)
		var centro := esquina + Vector3(tam.x / 2.0, 0, tam.z / 2.0)
		_caja(raiz, centro + Vector3(0, -GROSOR_MURO / 2.0, 0), tam, color_suelo)
		var techo := _caja(raiz, centro + Vector3(0, ALTURA_MURO + GROSOR_MURO / 2.0, 0),
			tam, color_techo)
		_emisivo(techo, color_techo)

	for tramo in Planta.contorno(bloques):
		var largo: float = (tramo["hasta"] - tramo["desde"]) * Planta.CELDA
		var a: Vector2i
		var tam: Vector3
		if tramo["eje"] == "x":
			a = Vector2i(tramo["desde"], tramo["linea"])
			tam = Vector3(largo, ALTURA_MURO, GROSOR_MURO)
		else:
			a = Vector2i(tramo["linea"], tramo["desde"])
			tam = Vector3(GROSOR_MURO, ALTURA_MURO, largo)
		var esquina := Planta.esquina_en_metros(bloques, a)
		var centro := esquina + Vector3(
			tam.x / 2.0 if tramo["eje"] == "x" else 0.0, ALTURA_MURO / 2.0,
			0.0 if tramo["eje"] == "x" else tam.z / 2.0)
		_caja(raiz, centro, tam, color_muro)


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
	_emisivo(cuerpo, color)


static func _emisivo(cuerpo: StaticBody3D, color: Color) -> void:
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
