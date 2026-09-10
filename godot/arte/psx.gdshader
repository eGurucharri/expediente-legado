// El aspecto de una consola de 32 bits, en un solo sitio.
//
// Tres cosas y ninguna es un filtro de pantalla: son cómo dibujaba aquella
// máquina, y por eso van en el material y no encima de la imagen ya hecha.
//
// 1. TEMBLOR DE VÉRTICES. Aquella consola no tenía coma flotante para las
//    posiciones en pantalla: los vértices caían en una rejilla y las aristas
//    bailaban al mover la cámara. Se imita redondeando la posición ya
//    proyectada. Es lo que más se nota de los tres.
// 2. LUZ POR VÉRTICE (`vertex_lighting`). La luz se calculaba en las esquinas
//    y se interpolaba, así que un muro grande cerca de una lámpara se ilumina
//    a bandas y no en círculo. Es también mucho más barato, que es la razón
//    por la que se hacía.
// 3. COLOR CORTADO. Sin miles de tonos: el color se escalona, que es lo que
//    produce las bandas de las paredes en penumbra.
//
// Lo que NO hace es el mapeado AFÍN —esa deformación de las texturas al girar
// una pared—, y es una renuncia consciente: exige coordenadas por cara, y aquí
// la textura se pega en coordenadas del mundo (triplanar) para que un muro de
// catorce metros y uno de dos tengan el mismo grano. Se puede tener una cosa o
// la otra, y la escala consistente vale más.
shader_type spatial;
render_mode vertex_lighting, diffuse_lambert, specular_disabled;

uniform vec4 color_base : source_color = vec4(1.0);
uniform sampler2D textura : source_color, filter_nearest, repeat_enable, hint_default_white;
uniform bool con_textura = false;
uniform float escala_textura = 1.0;
uniform vec4 emision : source_color = vec4(0.0);
uniform float emision_fuerza = 0.0;

// Lo fina que es la rejilla donde caen los vértices. Más alto es más limpio;
// por debajo de ~120 el temblor deja de leerse como una máquina y empieza a
// leerse como un fallo.
uniform float rejilla = 190.0;
// Cuántos escalones de color. 32 por canal es aproximadamente lo que daba un
// framebuffer de 15 bits.
uniform float tonos = 32.0;

varying vec3 mundo;

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec4 proyectado = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	// Se redondea en coordenadas normalizadas y se devuelve a las de recorte,
	// que es donde la rejilla es la de la pantalla y no la del modelo.
	vec2 normalizado = proyectado.xy / max(abs(proyectado.w), 0.0001);
	normalizado = round(normalizado * rejilla) / rejilla;
	proyectado.xy = normalizado * abs(proyectado.w);
	POSITION = proyectado;
}

// Triplanar a mano: tres muestras y mezcla por la normal. Lo hace el material
// estándar, pero al escribir un shader propio hay que traérselo.
vec3 muestra_triplanar(vec3 punto, vec3 normal) {
	vec3 peso = abs(normal);
	peso /= max(peso.x + peso.y + peso.z, 0.0001);
	vec3 p = punto * escala_textura;
	return texture(textura, p.zy).rgb * peso.x
		+ texture(textura, p.xz).rgb * peso.y
		+ texture(textura, p.xy).rgb * peso.z;
}

void fragment() {
	vec3 color = color_base.rgb;
	if (con_textura) {
		color = muestra_triplanar(mundo, NORMAL);
	}
	ALBEDO = floor(color * tonos) / tonos;
	EMISSION = emision.rgb * emision_fuerza;
}
