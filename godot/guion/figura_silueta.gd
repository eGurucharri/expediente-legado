## Una figura: tres cajas.
##
## No hay cara, y eso no es una limitación — a quien acusas nunca le ves la
## cara, porque es un comité, una empresa o un cargo. Estaba escrita dentro del
## careo (#61) y sale de ahí al llegar su segundo consumidor: el sueño (#87)
## puebla sus salas con los mismos sospechosos, y dos siluetas distintas para
## la misma persona serían dos personas.
##
## Es solo GEOMETRÍA. Ni sabe a quién representa ni de qué sala cuelga.
class_name FiguraSilueta
extends RefCounted

## Las piezas, de abajo arriba. La altura total sale de aquí y no de una
## constante aparte: una constante al lado se desincroniza del cuerpo.
const PIEZAS := [
	{"pos": Vector3(0, 0.45, 0), "tam": Vector3(0.5, 0.9, 0.35)},
	{"pos": Vector3(0, 1.25, 0), "tam": Vector3(0.7, 0.75, 0.4)},
	{"pos": Vector3(0, 1.78, 0), "tam": Vector3(0.3, 0.32, 0.3)},
]


## Lo alto que llega, para colgarle algo encima sin medirlo a ojo.
static func altura() -> float:
	var alto := 0.0
	for pieza in PIEZAS:
		alto = maxf(alto, pieza["pos"].y + pieza["tam"].y / 2.0)
	return alto


static func construir(raiz: Node3D, base: Vector3, color: Color) -> Node3D:
	var figura := Node3D.new()
	figura.position = base
	raiz.add_child(figura)
	for pieza in PIEZAS:
		var malla := MeshInstance3D.new()
		var caja := BoxMesh.new()
		caja.size = pieza["tam"]
		malla.mesh = caja
		malla.position = pieza["pos"]
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 1.0
		malla.material_override = material
		figura.add_child(malla)
	return figura
