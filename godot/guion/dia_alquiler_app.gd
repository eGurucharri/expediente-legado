## Capa de #85 sobre el día completo.
##
## La economía del alquiler vive en Jornada. Esta capa solo hace visible el
## trámite en el trayecto del día de vencimiento y presenta el resultado: no
## calcula importes, no resuelve impagos y no decide consecuencias de vivienda.
extends "res://guion/dia_ascensor_app.gd"

const DESTINO_ALQUILER := "alquiler"


## La ventanilla existe físicamente solo cuando hoy toca pagar y el vencimiento
## sigue pendiente. En los demás días la calle conserva exactamente su planta.
func _espacio_de(fase: String) -> Dictionary:
	var sitio: Dictionary = super._espacio_de(fase)
	if fase != "trayecto" or not _alquiler_disponible_hoy():
		return sitio

	# Un mostrador pequeño metido en el lateral de la calle. Son cajas a
	# propósito: #85 prueba el trámite, no estrena un pack de mobiliario.
	sitio["bultos"].append(
		{
			"pos": Vector3(3.55, 1.1, 9.0),
			"tam": Vector3(1.35, 2.2, 2.4),
			"color": Color(0.31, 0.30, 0.29)
		}
	)
	sitio["bultos"].append(
		{
			"pos": Vector3(2.85, 0.65, 9.0),
			"tam": Vector3(0.55, 1.3, 1.8),
			"color": Color(0.47, 0.45, 0.41)
		}
	)
	sitio["salidas"].append(
		{
			"pos": Vector3(2.45, 1.1, 9.0),
			"destino": DESTINO_ALQUILER,
			# Es la MISMA ventanilla de #58: el rótulo común deja esa decisión
			# visible sin crear una segunda institución en la calle.
			"rotulo": "VENTANILLA_TITULO",
			"tam": Vector3(1.8, 2.2, 2.2)
		}
	)
	return sitio


func _alquiler_disponible_hoy() -> bool:
	var dia := int(jornada.get("dia", 1))
	return dia == Jornada.alquiler_vencimiento(dia) and Jornada.alquiler_pendiente(jornada)


## La salida especial no cambia de fase. Pisar el mostrador equivale a hacer
## cola y ser atendido: Jornada valida fase, vencimiento, acción y dinero.
func _al_pisar_salida(cuerpo: Node3D, salida: Area3D) -> void:
	if (
		cuerpo == _caminante
		and _pantalla == null
		and not partida.guardado_pendiente
		and String(salida.get_meta("destino", "")) == DESTINO_ALQUILER
	):
		_pagar_alquiler()
		return
	super._al_pisar_salida(cuerpo, salida)


func _pagar_alquiler() -> void:
	var resultado := Jornada.pagar_alquiler(jornada)
	_hablando = false
	if resultado.is_empty():
		_sonar("error")
		# El HUD ya expone día y dinero; repetir el trámite o llegar sin saldo
		# no inventa un cobro ni una explicación nueva. El sonido marca que la
		# operación no se produjo y Jornada conserva el estado intacto.
		_nomina.text = (
			tr("DIA_ROTULO")
			% [jornada["dia"], tr("VENTANILLA_TITULO"), jornada["dinero"], ""]
		)
		return

	_sonar("nomina")
	# Reutiliza el resumen económico existente: el alquiler forma parte del
	# coste de vivir y evita meter una segunda redacción provisional en el CSV.
	_nomina.text = tr("DIA_VIVIR") % [resultado["importe"], resultado["dinero"], ""]
	# El pago ya está aplicado en memoria. Si falla el disco, el mecanismo común
	# bloquea nuevas acciones y convierte la siguiente interacción en reintento.
	_guardar_o_avisar("")
