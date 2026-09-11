## Costura de #70 sobre el visor existente.
##
## El visor base conserva toda la lógica de lectura, firma y persistencia. Esta
## capa solo inserta la cinemática declarativa del sello entre una firma ya
## guardada y su consecuencia posterior (careo o cierre textual).
extends "res://guion/visor_expediente.gd"


func _al_firmar(resultado: Dictionary, formulario: Control) -> void:
	formulario.queue_free()
	if not _guardar_o_avisar():
		return
	_reproducir_sello(resultado)


func _reproducir_sello(resultado: Dictionary) -> void:
	_imputar.disabled = true
	var reproductor: Node = load("res://escenas/cinematica.tscn").instantiate()
	add_child(reproductor)
	reproductor.terminada.connect(_al_terminar_sello.bind(reproductor, resultado))
	reproductor.reproducir(
		SelloCinematica.planos_de(
			bool(resultado.get("precipitada", false)),
			Cinematica.vistas_de(partida.estado, SelloCinematica.ID)
		),
		SelloCinematica.ID,
		partida.estado
	)


## Terminar y saltar comparten exactamente esta salida. La animación no decide
## nada: la firma ya estaba guardada antes de entrar aquí.
func _al_terminar_sello(reproductor: Node, resultado: Dictionary) -> void:
	reproductor.queue_free()
	if not resultado.get("duelo", {}).is_empty():
		_abrir_careo_firmado(resultado)
		return
	_mostrar_cierre(resultado)


func _abrir_careo_firmado(resultado: Dictionary) -> void:
	var careo: Node3D = load("res://escenas/careo.tscn").instantiate()
	careo.acusado = resultado["duelo"]
	careo.folio = registro_actual.get("folio", caso.get("titulo", ""))
	careo.cargas = historias.cargas(partida.estado)
	careo.estado = partida.estado
	careo.semilla_tiradas = _raiz()
	careo.terminado.connect(_al_terminar_careo.bind(careo, resultado))
	add_child(careo)
