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
		"gato": {"presente": true, "dias_sin_comer": 0},
		# Lo leído hoy: es lo que alimenta el sueño de esta noche. Se vacía al
		# despertar, porque un sueño es de su día.
		"leido_hoy": [],
	}


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
