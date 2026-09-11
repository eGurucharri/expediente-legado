## Pantalla encendida del escaparate (#142).
##
## El contenido está separado de la geometría: una pantalla sin fichero muestra
## nieve, y añadir metraje después no cambia la calle ni su colisión.
class_name Pantalla
extends RefCounted

const SHADER_NIEVE := "res://arte/nieve.gdshader"
const RESOLUCION := Vector2i(256, 192)


static func montar(raiz: Node3D, declaracion: Dictionary) -> Node3D:
	var vista := SubViewport.new()
	vista.size = RESOLUCION
	vista.disable_3d = true
	vista.transparent_bg = false
	vista.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	raiz.add_child(vista)

	var lienzo := ColorRect.new()
	lienzo.size = Vector2(RESOLUCION)
	var material := ShaderMaterial.new()
	material.shader = load(SHADER_NIEVE)
	material.set_shader_parameter("semilla", float(declaracion.get("semilla", 0.0)))
	lienzo.material = material
	vista.add_child(lienzo)

	var cristal := MeshInstance3D.new()
	var plano := QuadMesh.new()
	plano.size = declaracion.get("tam", Vector2(0.5, 0.38))
	cristal.mesh = plano
	cristal.position = declaracion.get("pos", Vector3.ZERO)
	cristal.rotation_degrees.y = float(declaracion.get("giro", 0.0))
	var cristal_material := StandardMaterial3D.new()
	cristal_material.albedo_texture = vista.get_texture()
	cristal_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cristal_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	cristal.material_override = cristal_material
	raiz.add_child(cristal)
	return cristal
