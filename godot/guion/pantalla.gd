## Una pantalla encendida dentro del mundo.
##
## Es la otra mitad de los planos rodados: `cinematica_app` los pone a pantalla
## completa para un momento, y esto los pone en un aparato que está AHÍ, en una
## sala por la que se anda. La diferencia no es técnica, es de autoridad: una
## cinemática la mira el juego por ti, y una tele en un escaparate la miras tú
## si te da la gana.
##
## Un `SubViewport` con lo que sea dentro, y su textura pegada a un plano. Es el
## único camino en Godot para llevar algo que se mueve a una superficie 3D.
##
## **Sin fichero se ve nieve**, y ese es el estado por defecto a propósito. Una
## tele encendida con imagen afirma que alguien está emitiendo; una con nieve no
## afirma nada, así que un escaparate entero funciona antes de que exista un
## solo plano rodado — y cada aparato con su semilla, o seis televisores
## enseñando el mismo fotograma se leen como una imagen repetida y no como seis
## aparatos.
class_name Pantalla
extends RefCounted

const SHADER_NIEVE := "res://arte/nieve.gdshader"

## Lo que mide por dentro la imagen de una pantalla. No es la resolución del
## juego: es cuánto se dibuja para luego pegarlo en un plano de medio metro, así
## que subirlo no se ve y sí se paga — y son varias a la vez en un escaparate.
const RESOLUCION := Vector2i(256, 192)


## Monta una pantalla bajo [param raiz] y devuelve su nodo.
##
## Declaración: `pos`, `tam` (ancho y alto del cristal, en metros), `giro` en
## grados sobre Y, `fichero` (opcional, bajo `Cinematica.RUTA_VIDEO`) y
## `semilla` para que su nieve no sea la del vecino.
static func montar(raiz: Node3D, declaracion: Dictionary) -> Node3D:
	var vista := SubViewport.new()
	vista.size = RESOLUCION
	vista.disable_3d = true
	vista.transparent_bg = false
	# Se dibuja siempre, también cuando la pantalla queda fuera de cuadro: una
	# tele que se queda congelada al mirar a otro lado y arranca al volver a
	# mirarla es peor que una que gasta lo que gasta.
	vista.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	raiz.add_child(vista)

	var fichero: String = declaracion.get("fichero", "")
	if fichero.is_empty():
		_nieve(vista, float(declaracion.get("semilla", 0.0)))
	else:
		_video(vista, fichero, float(declaracion.get("semilla", 0.0)))

	var cristal := MeshInstance3D.new()
	var plano := QuadMesh.new()
	var tam: Vector2 = declaracion.get("tam", Vector2(0.5, 0.38))
	plano.size = tam
	cristal.mesh = plano
	cristal.position = declaracion.get("pos", Vector3.ZERO)
	cristal.rotation_degrees = Vector3(0, float(declaracion.get("giro", 0.0)), 0)

	# El cristal se pinta SIN sombreado y sin recibir luz. Una pantalla encendida
	# no se oscurece porque la calle esté oscura — al revés, es lo único que
	# alumbra ahí. Con un material normal, el escaparate se apagaría de noche,
	# que es justo cuando se pasa por delante.
	var material := StandardMaterial3D.new()
	material.albedo_texture = vista.get_texture()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	cristal.material_override = material
	raiz.add_child(cristal)
	return cristal


static func _nieve(vista: SubViewport, semilla: float) -> void:
	var lienzo := ColorRect.new()
	lienzo.size = Vector2(RESOLUCION)
	var material := ShaderMaterial.new()
	material.shader = load(SHADER_NIEVE)
	material.set_shader_parameter("semilla", semilla)
	lienzo.material = material
	vista.add_child(lienzo)


static func _video(vista: SubViewport, fichero: String, semilla: float) -> void:
	var flujo := Cinematica.flujo_de(Cinematica.RUTA_VIDEO + fichero)
	if flujo == null:
		# Un plano que falta deja el aparato con nieve, no en negro: una tele
		# apagada en un escaparate encendido se lee como que ESA está rota, y
		# eso es afirmar algo que nadie ha decidido.
		_nieve(vista, semilla)
		return

	var reproductor := VideoStreamPlayer.new()
	reproductor.size = Vector2(RESOLUCION)
	reproductor.expand = true
	reproductor.loop = true
	# Sin sonido. Seis teles sonando a la vez desde un escaparate es ruido, y el
	# sonido de la calle ya lo pone la calle.
	reproductor.volume_db = -80.0
	reproductor.stream = flujo
	vista.add_child(reproductor)
	reproductor.play()
