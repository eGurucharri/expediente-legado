## El cuerpo que anda. Primera persona, sin correr y sin saltar.
##
## Las dos ausencias son deliberadas: esto no es un juego de movimiento, es el
## rato entre el trabajo y la cama. Ir despacio es parte de lo que se cuenta, y
## un salto convertiría cualquier sitio en un sitio para trepar.
extends CharacterBody3D

const VELOCIDAD := 2.6
const SENSIBILIDAD := 0.0022

## Cuánto se puede mirar arriba y abajo. Sin tope, la cámara se da la vuelta.
const TOPE_VERTICAL := deg_to_rad(85.0)

@onready var _camara: Camera3D = $Camara


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-evento.relative.x * SENSIBILIDAD)
		_camara.rotation.x = clampf(
			_camara.rotation.x - evento.relative.y * SENSIBILIDAD,
			-TOPE_VERTICAL, TOPE_VERTICAL)
	# Soltar el ratón: sin esto, una ventana que captura el puntero y no lo
	# devuelve se siente como un programa colgado.
	elif evento.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if \
			Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var entrada := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direccion := (transform.basis * Vector3(entrada.x, 0, entrada.y)).normalized()
	velocity.x = direccion.x * VELOCIDAD
	velocity.z = direccion.z * VELOCIDAD
	move_and_slide()


## Deja el cuerpo en un sitio, mirando al frente. Se usa al cambiar de espacio:
## conservar la posición anterior te dejaría dentro de un muro del sitio nuevo.
func situar(donde: Vector3) -> void:
	position = donde + Vector3(0, 1.0, 0)
	velocity = Vector3.ZERO
