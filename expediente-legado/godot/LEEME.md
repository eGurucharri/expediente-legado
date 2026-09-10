# Port a Godot 4

Primer corte de la migración (#54). **No sustituye todavía a nada**: la app
Spring de `backend/` sigue funcionando igual, y esta carpeta no depende de ella.

```
godot/
├── datos/casos.json      los 8 casos, extraídos de DataSeeder.java
├── datos/extraer.mjs     el extractor, para repetirlo si el seeder cambia
├── guion/                lógica pura portada de service/
└── pruebas/pruebas.gd    la suite, ejecutable sin abrir el editor
```

## Correr las pruebas

```bash
godot4 --headless --path godot --import          # solo la primera vez
godot4 --headless --path godot --script pruebas/pruebas.gd
```

Sale `0` si todo pasa. Los casos están portados uno a uno de `WikiLinkServiceTest`,
`HotspotServiceTest`, `CartaOcultaServiceTest` y `ProgresoServiceTest`, con el
nombre del test Java en un comentario: si el port cambia una decisión del
original, se ve cuál.

## La partida guardada

`guion/partida.gd`, en `user://partida.json`. No es un port de
`cargarEstado`/`guardarEstado`: `localStorage` no se corrompe a medias y no se
puede perder, y un fichero sí. De ahí tres precauciones que el original no
tenía que tomar:

1. **La escritura es atómica** — a un temporal y renombrado encima, así que un
   cierre a destiempo deja la partida anterior entera y no media nueva.
2. **Una partida ilegible no se pisa** — se aparta como `.roto` y se empieza de
   cero al lado. El original hacía `catch {}` y seguía con el estado vacío, o
   sea que el siguiente guardado borraba para siempre lo que hubiera.
3. **El formato va versionado** — una partida de una versión posterior se
   aparta en vez de interpretarse a medias.

Y **solo se guardan ids y banderas**, nunca el texto de los catálogos: si el
guardado se llevara una copia, reescribir la descripción de un logro dejaría
las partidas viejas mostrando la antigua. Bajó de 9.188 a 3.268 bytes al
arreglarlo.

Los catálogos (20 logros, 22 cartas) salen de `datos/prometeo.json`, extraídos
de `prometeo-ui.js` con `datos/extraer-prometeo.mjs` por el mismo motivo que
los casos: es contenido, y teclearlo introduce erratas que nadie compara con el
original.

## Qué cambia respecto al backend Java

**El contenido deja de ser código.** `DataSeeder.java` eran 1.443 líneas de
setters; ahora es `casos.json`, y escribir un caso nuevo no recompila nada. La
extracción está verificada contra las llamadas `.save()` del original: 8 casos,
32 registros, 35 pistas, 27 sospechosos, 16 conceptos, 0 referencias sin
resolver.

**Los tres servicios de texto se funden en uno.** `HotspotService`,
`CartaOcultaService` y `WikiLinkService` hacían lo mismo —encontrar una frase y
envolverla en marcado— y se encadenaban, cada uno sobre la salida del anterior.
`CartaOcultaService` llegaba a hacer `indexOf` sobre HTML ya generado, así que
una frase que cayera dentro del marcado lo partía. Aquí `marcas.gd` devuelve
*dónde* están las marcas y `bbcode.gd` decide *cómo* se pintan, así que el
solapamiento se resuelve una vez y explícitamente (gana la que empieza antes).

**`ProgresoService` adelgaza.** `pistasPorCaso` y la variante de `progreso` que
reutilizaba el mapa existían para evitar un N+1 de consultas SQL. Sin base de
datos no hay consulta que evitar. La regla que sí se conserva: el progreso no se
guarda en el caso, se deriva de las pistas descubiertas.

**El escapado cambia de carácter y de sitio.** En HTML el peligro era `<` y cada
servicio escapaba por su cuenta; en BBCode es `[`, y se escapa una sola vez,
solo en el texto plano.

## El visor

`escenas/visor.tscn` + `guion/visor_expediente.gd` es la pantalla que decide si
Godot sirve para este juego: un `RichTextLabel` con BBCode donde la frase
gatillo es pulsable dentro del texto corrido, y queda resaltada al descubrirse.
Sustituye a `caso.html` + `documento-viewer.js` + `legacy-documentos.js`.

El aspecto de los 90 es `guion/estilo_siga.gd`, port de `legacy-theme.css`. Lo
que en CSS eran `border-style: outset` e `inset` aquí se DIBUJA, porque un
`StyleBoxFlat` solo admite un color de borde y el bisel necesita dos: la luz
arriba y a la izquierda, la sombra abajo y a la derecha. Invertirlas es toda la
diferencia entre un botón y un hueco.

Lo que más delata la época no es la forma de la letra sino el **suavizado**:
con antialiasing y posicionamiento subpíxel el texto se ve contemporáneo aunque
el marco sea gris con biseles. `EstiloSiga.tema()` los apaga y fuerza el
hinting, así que los trazos caen en la rejilla de píxeles. Las fuentes se piden
al sistema por nombre y con degradación (`MS Sans Serif` → `Tahoma` → lo que
haya), para no traer al repositorio ni un fichero de fuente. El cuerpo de un
documento va monoespaciado: es el volcado de un sistema de texto, no una página
maquetada.

Para verlo sin abrir el editor:

```bash
xvfb-run -a godot4 --path godot --script pruebas/capturar.gd -- visor.png 1     # sin descubrir
xvfb-run -a godot4 --path godot --script pruebas/capturar.gd -- visto.png 1 1   # descubierta
```

Mirar la captura ya ha pagado su coste: encontró que el año salía como
"Expediente 1999.0" (los números del JSON llegan en coma flotante) y que el
documento abierto quedaba en blanco sobre blanco en la lista. Ninguna prueba de
las 44 veía ninguno de los dos.

## Lo que este corte NO incluye

- La **interfaz** de Prometeo. Sus reglas sí están portadas (`guion/prometeo.gd`,
  port de `prometeo-logic.js`: fusión con lo guardado, tarot, acusación
  precipitada, ejes políticos, el rival del duelo, rachas y el borrado de una
  vuelta), con sus 33 comprobaciones traídas del Vitest — incluida la invariante
  anti-moralizante de #45, que exige que cada ideología sea útil en exactamente
  4 de las 8 cartas. Lo que falta son las 3.181 líneas de DOM de `prometeo-ui.js`.
- El corcho de conceptos, la acusación y el combate: sin pantalla todavía.
- El relato de las cartas ocultas: el visor acusa el hallazgo y nada más.
- La persistencia. Un `Descubrimiento` era una fila; aquí habrá que decidir
  dónde vive la partida guardada.
