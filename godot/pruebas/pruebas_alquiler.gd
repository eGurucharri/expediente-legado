## Contrato económico del alquiler (#83/#85).
##
## Aquí se prueba el calendario y el registro puro. La ventanilla visual y la
## consecuencia de perder la casa pertenecen a #85 y #84 respectivamente.
class_name PruebasAlquiler
extends RefCounted


static func todo(comprobar: Callable) -> void:
	var pago := Jornada.nueva()
	pago["dia"] = 10
	pago["fase"] = "trayecto"
	pago["dinero"] = Jornada.PRECIO_ALQUILER + 100
	var acciones_antes: int = pago["acciones"]
	var resultado := Jornada.pagar_alquiler(pago)

	comprobar.call("el primer vencimiento cae en el día diez", Jornada.alquiler_vencimiento(1), 10)
	comprobar.call(
		"pagar el alquiler descuenta el importe y una acción",
		[resultado["importe"], pago["dinero"], pago["acciones"]],
		[Jornada.PRECIO_ALQUILER, 100, acciones_antes - 1]
	)
	comprobar.call("el pago queda registrado", pago["alquiler"]["pagados"], 1)
	comprobar.call("el vencimiento queda resuelto", Jornada.alquiler_pendiente(pago), false)

	var dinero_despues: int = pago["dinero"]
	var acciones_despues: int = pago["acciones"]
	comprobar.call("repetir el pago no cobra dos veces", Jornada.pagar_alquiler(pago), {})
	comprobar.call(
		"repetir conserva saldo y acciones",
		[pago["dinero"], pago["acciones"]],
		[dinero_despues, acciones_despues]
	)

	var siguiente := Jornada.nueva()
	siguiente["dia"] = 20
	siguiente["fase"] = "trayecto"
	siguiente["dinero"] = Jornada.PRECIO_ALQUILER + 100
	siguiente["alquiler"]["ultimo_resuelto"] = 10
	comprobar.call(
		"el segundo vencimiento cae en el día veinte", Jornada.alquiler_vencimiento(20), 20
	)
	comprobar.call(
		"el siguiente vencimiento sigue pendiente", Jornada.alquiler_pendiente(siguiente), true
	)
	comprobar.call(
		"el segundo pago también funciona", Jornada.pagar_alquiler(siguiente)["vencimiento"], 20
	)

	var impago := Jornada.nueva()
	impago["dia"] = 10
	impago["fase"] = "casa"
	var noche := Jornada.dormir(impago)
	comprobar.call("dormir sin pagar registra un impago", noche["alquiler_impago"], true)
	comprobar.call("el impago no crea deuda negativa", impago["dinero"] >= 0, true)
	comprobar.call("el impago se registra una sola vez", impago["alquiler"]["impagos"], 1)
	comprobar.call("la vivienda no cobra automáticamente", impago["alquiler"]["pagados"], 0)
