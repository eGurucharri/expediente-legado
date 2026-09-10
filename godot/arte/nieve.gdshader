// La nieve de un televisor sin señal.
//
// No es un adorno: es lo que se ve en un escaparate de televisores cuando
// ninguno tiene nada que dar. Y es el estado por DEFECTO de una pantalla de
// este juego, que es lo correcto — una tele encendida con imagen afirma que
// alguien está emitiendo algo, y eso es una decisión de contenido; una tele con
// nieve no afirma nada.
//
// Cada pantalla trae su `semilla`, así que seis televisores en fila no enseñan
// el mismo fotograma seis veces. Eso importa más de lo que parece: la nieve
// idéntica y sincronizada se lee como UNA imagen repetida, o sea como un error
// de dibujo, y no como seis aparatos.
shader_type canvas_item;

uniform float semilla = 0.0;
uniform float velocidad = 12.0;

// Y no es blanco y negro puro. Un tubo de la época tiraba a un gris con algo
// de temperatura, y el negro no llegaba a negro nunca — el cristal siempre
// devolvía algo de la luz de la habitación.
uniform vec4 claro : source_color = vec4(0.86, 0.86, 0.83, 1.0);
uniform vec4 oscuro : source_color = vec4(0.12, 0.12, 0.14, 1.0);

float ruido(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	// El grano va por BLOQUES y no por píxel de pantalla: la nieve de un tubo
	// tiene un tamaño físico, y a resolución alta un ruido por píxel se ve como
	// una superficie gris lisa en vez de como nieve.
	vec2 celda = floor(UV * vec2(96.0, 72.0));
	// El tiempo se escalona para que la nieve tenga fotogramas, no un barrido
	// continuo: un televisor refresca, no se desliza.
	float paso = floor(TIME * velocidad);
	float valor = ruido(celda + vec2(paso, semilla * 37.0));

	// Una banda que baja despacio, que es el defecto de sincronía vertical que
	// tenían estos aparatos. Sin ella la nieve es demasiado uniforme y deja de
	// parecer una señal: parece una textura.
	float banda = smoothstep(0.0, 0.08, abs(fract(UV.y + TIME * 0.12) - 0.5) - 0.42);
	valor = clamp(valor + banda * 0.35, 0.0, 1.0);

	COLOR = mix(oscuro, claro, valor);
}
