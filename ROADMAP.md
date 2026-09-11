# Roadmap

Plan de fases hasta la primera versión completa. **La prioridad vigente la fija
el [plan maestro #181](https://github.com/EspacioKoop/expediente-legado/issues/181)**;
este documento es el mapa de fondo y cambia menos a menudo.

Cada fase es un **milestone** de GitHub y termina en una **release**. El día a
día se sigue en los Projects. Nada de esto sustituye a los issues: un criterio
de aceptación vive en su issue, no aquí.

| Dónde se mira | Qué responde |
| --- | --- |
| [Plan maestro #181](https://github.com/EspacioKoop/expediente-legado/issues/181) | Qué va primero, ahora mismo |
| [Registro de reservas #182](https://github.com/EspacioKoop/expediente-legado/issues/182) | Quién está tocando qué |
| [Milestones](https://github.com/EspacioKoop/expediente-legado/milestones) | Qué falta para la siguiente versión |
| [Cola de entrega](https://github.com/orgs/EspacioKoop/projects/1) | Lo que está en marcha esta semana |
| [Roadmap vivo](https://github.com/orgs/EspacioKoop/projects/2) | Todo el backlog, por estado |
| [Releases](https://github.com/EspacioKoop/expediente-legado/releases) | Qué se puede jugar ya |

## Dónde estamos

El juego nació como aplicación web con Spring Boot y **se está reescribiendo en
Godot 4** (#54) para distribuirlo sin servidor. Las dos versiones conviven: el
backend es la fuente del contenido y sigue siendo jugable; `godot/` es donde
está el trabajo vivo.

La última release publicada es [`v0.6.0-alpha.1`](https://github.com/EspacioKoop/expediente-legado/releases),
una instantánea del código: recoge los 90 commits que separan al proyecto de la
`v0.5.0-alpha.1` de julio, que fue la última que llevó binarios. El port a Godot
todavía no puede tener binarios propios porque le falta la exportación
automatizada (#112).

Lo que hay hoy en `main`, sin adornos: suite de **464 comprobaciones** y
recorrido de **95**, ambos sin fallos, con `gdlint` y `gdformat` limpios. Eso es
validación automática. **No hay playtesting humano con mando ni una partida
completa jugada de principio a fin** (#9).

## Fases

### v0.6.0 · El recorrido completo

Que se pueda jugar una jornada entera sin que nada se pierda por el camino. Es
la fase de **fiabilidad**, y va primero porque todo lo demás se apoya en ella.

- Conservar el estado si falla un guardado entre oficina y visor — #163 H1
- Validar la estructura de una partida al cargarla — #163 H5
- Enchufar el careo al formulario A-7 — #75
- La historia política de una carta, en Godot — #176, que cierra la mitad que
  le falta a #71

**Se cierra cuando** el punto de control del #181 se recorre entero con escenas
reales: leer, firmar, carear, cobrar, volver a casa, decidir, dormir, reconocer
algo leído y despertar, conservándolo todo al cerrar y reabrir.

### v0.7.0 · Todas las cinemáticas

La épica #66. El reproductor común ya existe y la primera cinemática 2D (#71) ya
está dentro: falta el resto.

- El principio del juego — #68
- El inicio de cada día — #69
- Cerrar un expediente, el sello — #70
- Los finales de duelo — #72
- El despido / reasignación — #73
- Dormir y entrar en el sueño — #74

**Nota de dirección:** las cinemáticas 2D de esta fase son **provisionales**. El
objetivo es que acaben siendo 3D, pero no se rehacen sobre la marcha: primero se
cierra la primera versión completa y después se migran. Por eso todas se
declaran en el formato de `Cinematica`, que ya despacha `3d` y `2d` — el salto
será cambiar los datos del plano, no el reproductor ni sus llamantes.

### v0.8.0 · Que se vea y se pueda jugar con mando

Presentación, accesibilidad e idioma. Aquí están las piezas cortas y cerradas,
buenas para entrar al proyecto.

- Foco de teclado y mando en el A-7 — #174, dentro de la regresión #98
- Menús, opciones y remapeo — #113
- Empaquetar una tipografía libre — #172, dentro de #110
- Traducir el catálogo — #173 y #107
- El caso 8 sin año, y la prueba que debió cazarlo — #171 y #53

### v0.9.0 · Vida cotidiana

Que el dinero, la casa y el gato signifiquen algo.

- Calibrar la economía — #83, con simulación antes de tocar valores
- La casa, el gato y los trabajillos — #78, #92, #93, #94
- Alquiler y sus consecuencias — #84, #85
- El sueño alimentado por el archivo — #79, #86, #87

### v1.0.0 · Primera versión completa

- Exportar y publicar desde CI — #112
- Publicar en itch.io y Steam, con lo que eso implica — #99
- **Playtesting real de principio a fin** — #9

### Después de la 1.0

Lo opcional, que espera a que el recorrido aguante entero: minijuegos y
colecciones (#157–#162 y sus sub-issues), el emulador de Game Boy (#124), los
logros de Steam (#114) — y la **migración de las cinemáticas a 3D**.

## Cómo se usan milestones, projects y releases

Tres herramientas, tres preguntas distintas. Si dos dicen cosas contradictorias,
manda el plan maestro.

- **Milestone** = una versión. Un issue lleva milestone cuando está decidido que
  entra en esa versión; sin milestone significa "todavía no está decidido", no
  "no importa". El milestone se cierra cuando se publica su release.
- **Projects**: [Cola de entrega](https://github.com/orgs/EspacioKoop/projects/1)
  es lo que está en marcha, con su `Status` (Todo / In Progress / Done);
  [Roadmap vivo](https://github.com/orgs/EspacioKoop/projects/2) es el backlog
  completo. Un issue reservado en #182 debería estar *In Progress*: si no lo
  está, uno de los dos miente.
- **Release**: se corta al cerrar un milestone, con etiqueta `vMAJOR.MINOR.PATCH`.
  Mientras el juego no esté completo van marcadas como **pre-release** con
  sufijo (`-alpha.N`, `-beta.N`), como ya se hizo con `v0.5.0-alpha.1`. Las notas
  dicen **qué se ha probado y qué no**: una release no afirma que algo funciona
  porque la CI esté verde.

Una release del port a Godot necesita antes la exportación de #112. Hasta
entonces, lo publicable es la web.
