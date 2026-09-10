## El día: la columna que faltaba.
##
## Hasta ahora una "vuelta" no era nada — el sistema te reasignaba por acumular
## fallos y empezabas otra, sin tiempo, sin jornada y sin vida fuera del
## archivo. La jornada le da cuerpo: una vuelta es **una vida laboral**, y las
## cartas que recuerdas de vueltas anteriores (#46) dejan de ser una regla rara
## para ser lo obvio — el sueño recuerda lo que el archivo olvidó.
##
## El ciclo es una máquina de estados y NADA más: qué se pinta en cada fase lo
## dice un catálogo, no un `if` con el nombre de una sala dentro del motor.
## Añadir una fase es una entrada más, no tocar esto.
class_name Jornada
extends RefCounted

## En orden. El día empieza en el archivo y termina soñando.
const FASES := ["archivo", "trayecto", "casa", "sueño"]

## Lo que se cobra por fichar la salida, haya pasado lo que haya pasado. La
## nómina no premia acertar: en este juego no hay sospechoso correcto, y pagar
## por acertar desmontaría la sátira entera.
const BASE_DIARIA := 40

## Lo que suma cada expediente cerrado ese día. Se cobra por CERRAR, no por
## cerrar bien: un expediente mal cerrado paga lo mismo, y el gato come de eso.
const POR_EXPEDIENTE := 60

## Lo que cuesta vivir un día, se haga lo que se haga.
const COSTE_DIARIO := 25

## Cuántas cosas se pueden hacer en un día: abrir un documento, acusar, atender
## la Ventanilla. Es lo que obliga a fichar la salida — sin un tope, lo óptimo
## sería no salir nunca de la oficina y el resto del día no existiría.
##
## Lo que se decide con esto no es leer deprisa sino QUÉ leer: un expediente
## tiene más documentos de los que caben en una jornada.
const ACCIONES_POR_DIA := 6

## Días seguidos sin comer que aguanta el gato antes de irse. No se muere ni
## deja cadáver: un día no está. En este sistema las cosas no terminan, se
## traspapelan.
const PACIENCIA_GATO := 3


static func nueva() -> Dictionary:
	return {
		"dia": 1,
		"fase": "archivo",
		"dinero": 120,
		"cerrados_hoy": 0,
		"acciones": ACCIONES_POR_DIA,
		# El gato NO es estado de la vuelta: sobrevive a que te reasignen,
		# porque es tuyo y no del trabajo. Acaba siendo lo único cálido del
		# registro permanente, al lado de las cartas que recuerdas.
		"gato": {"presente": true, "dias_sin_comer": 0},
		# Lo leído hoy: es lo que alimenta el sueño de esta noche. Se vacía al
		# despertar, porque un sueño es de su día.
		"leido_hoy": [],
	}


## Gasta una acción del día. Devuelve si se pudo: agotadas, en el archivo no se
## puede hacer nada más y hay que fichar.
static func gastar_accion(jornada: Dictionary) -> bool:
	if jornada["fase"] != "archivo" or jornada["acciones"] <= 0:
		return false
	jornada["acciones"] -= 1
	return true


## Si ya no queda nada que hacer hoy. Quien pinte la oficina lo usa para decir
## que la jornada se acabó, en vez de dejar al jugador probando botones muertos.
static func jornada_agotada(jornada: Dictionary) -> bool:
	return jornada["acciones"] <= 0


## Ficha la salida: cobra y pasa al trayecto.
##
## Devuelve el desglose, porque la nómina hay que poder enseñarla — un número
## que cambia solo es indistinguible de un error.
static func fichar_salida(jornada: Dictionary) -> Dictionary:
	if jornada["fase"] != "archivo":
		return {}

	var cerrados: int = jornada["cerrados_hoy"]
	var bruto := BASE_DIARIA + POR_EXPEDIENTE * cerrados
	jornada["dinero"] += bruto
	jornada["fase"] = "trayecto"

	return {
		"base": BASE_DIARIA,
		"expedientes": cerrados,
		"por_expedientes": POR_EXPEDIENTE * cerrados,
		"bruto": bruto,
		"dinero": jornada["dinero"],
	}


## Gastar en algo. Devuelve si se pudo: sin dinero no hay compra, y eso es toda
## la economía. No hay deuda ni crédito porque un sistema como este no te
## fiaría nada.
static func gastar(jornada: Dictionary, importe: int) -> bool:
	if importe <= 0 or jornada["dinero"] < importe:
		return false
	jornada["dinero"] -= importe
	return true


## Dar de comer al gato. Es una compra como otra cualquiera, y por eso puede no
## poder hacerse: ahí está la decisión.
static func alimentar_gato(jornada: Dictionary, precio: int) -> bool:
	var gato: Dictionary = jornada["gato"]
	if not gato["presente"] or not gastar(jornada, precio):
		return false
	gato["dias_sin_comer"] = 0
	return true


## Dormir: cierra el día, cobra la vida y decide qué queda por la mañana.
##
## Devuelve lo que hay que contar al despertar. El gato que se va no se anuncia
## con un aviso: se nota porque no está, así que quien llame decide si lo dice.
static func dormir(jornada: Dictionary) -> Dictionary:
	if jornada["fase"] != "casa":
		return {}

	jornada["dinero"] = maxi(0, jornada["dinero"] - COSTE_DIARIO)

	var gato: Dictionary = jornada["gato"]
	var se_fue := false
	if gato["presente"]:
		gato["dias_sin_comer"] += 1
		if gato["dias_sin_comer"] > PACIENCIA_GATO:
			gato["presente"] = false
			se_fue = true

	jornada["fase"] = "sueño"
	return {"coste": COSTE_DIARIO, "dinero": jornada["dinero"], "gato_se_fue": se_fue}


## Despertar: día nuevo, contadores a cero y el sueño de anoche olvidado.
static func despertar(jornada: Dictionary) -> int:
	if jornada["fase"] != "sueño":
		return jornada["dia"]
	jornada["dia"] += 1
	jornada["fase"] = "archivo"
	jornada["cerrados_hoy"] = 0
	jornada["acciones"] = ACCIONES_POR_DIA
	jornada["leido_hoy"] = []
	return jornada["dia"]


## Anota un documento leído hoy. Es lo que el sueño de esta noche tendrá para
## deformar: sin esto el sueño sería ruido, y con esto es el archivo devuelto
## del revés.
static func anotar_lectura(jornada: Dictionary, folio: String) -> void:
	if not folio.is_empty() and not jornada["leido_hoy"].has(folio):
		jornada["leido_hoy"].append(folio)


## Qué fase viene después. Vive aquí y no repartido por las pantallas: el orden
## del día es una sola cosa y se cambia en un solo sitio.
static func siguiente_fase(fase: String) -> String:
	var i := FASES.find(fase)
	if i < 0:
		return FASES[0]
	return FASES[(i + 1) % FASES.size()]


## Te reasignan: empieza otra vida laboral.
##
## Se va el día, el dinero y lo leído — otra persona en el mismo puesto. **El
## gato se queda**, tal y como lo dejaste: si lo cuidaste sigue ahí, y si se fue
## no vuelve. Es la única continuidad que no pasa por el archivo, y por eso es
## la que más dice de cómo llevaste la vuelta anterior.
static func reiniciar_vuelta(jornada: Dictionary) -> Dictionary:
	var gato: Dictionary = jornada["gato"]
	var nueva_vida := nueva()
	nueva_vida["gato"] = gato
	for clave in nueva_vida:
		jornada[clave] = nueva_vida[clave]
	return jornada
