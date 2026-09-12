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
backend es la fuente histórica del contenido y `godot/` es donde está el trabajo
vivo.

La última release publicada sigue siendo
[`v0.6.0-alpha.1`](https://github.com/EspacioKoop/expediente-legado/releases).
El port a Godot todavía no publica binarios propios automáticamente porque falta
la exportación de #112. La CI valida el código y el recorrido automatizado, pero
**no sustituye un playtesting humano de principio a fin con mando y táctil** (#9).

### Estado de integración — 2026-09-12

La referencia operativa es `main`, no la existencia de ramas o PR antiguos.
Durante la última tanda de integración se han cerrado o absorbido varias piezas
que el roadmap anterior seguía contando como pendientes:

- **Recorrido y persistencia:** #163 está cerrado; H2/H3 quedaron resueltos por
  #166 y el resto del endurecimiento se integró después. #75 también está
  cerrado: el A-7 ya conecta con el careo. #176 quedó integrado por #198.
- **Cinemáticas:** #68, #69, #70, #72, #73 y #74 están cerrados. #71 ya estaba
  cubierto por #175. El núcleo de la épica #66 está por tanto implementado; lo
  que queda es remate e integración de presentación, no construir las
  cinemáticas base.
- **Personajes:** #199 integró la malla humana común de Quaternius. #248 avanzó
  #80 usando esa malla para el cuñado del careo y manteniendo al acusado como
  silueta sin rostro.
- **Investigación cinematográfica:** #246 y #247 versionaron en documentación
  los criterios de dirección, referencias interactivas, riesgos y guardas de
  accesibilidad de #177. El issue sigue abierto para prototipos posteriores.
- **Higiene v0.8:** #171 y #173 están cerrados. Siguen abiertos #172 y #174,
  además de las piezas mayores #113 y #107.
- **Sueño y casa:** #127, #126 y #125 están cerrados; #88 está integrado por
  #202 y #92 tiene ya una primera pieza jugable. La economía #83 sigue siendo
  el bloqueo principal antes de profundizar en alquiler, compras y trabajillos.

Los PR cerrados sin merge no cuentan como integración. Si una rama antigua y
`main` discrepan, manda `main`.

El trabajo abierto con milestone representa lo que aún falta para cada versión.
Los issues de ideas y el trabajo posterior a 1.0 quedan sin milestone hasta que
el plan maestro decida incorporarlos.

## Fases

### v0.6.0 · El recorrido completo

El trabajo de implementación que bloqueaba el recorrido principal está
esencialmente cerrado: #163, #75 y #176 ya no deben tratarse como tareas abiertas.

La fase queda ahora como **punto de control de integración**:

**Leer en SIGA → firmar → careo cuando corresponda → cobrar → volver a casa →
una decisión doméstica → dormir → reconocer algo leído → despertar.**

**Se cierra cuando:**

- cerrar y reabrir en puntos clave conserva día, dinero, acciones, firmas y
  consecuencias;
- el sueño no introduce información desconocida para el jugador;
- el recorrido se prueba como secuencia real, no solo mediante llamadas aisladas;
- se documentan pruebas ejecutadas y limitaciones de interacción pendientes.

No añadir aquí sistemas opcionales para “rellenar” el milestone: si aparece un
fallo nuevo del recorrido, se abre como regresión concreta.

### v0.7.0 · Todas las cinemáticas

La infraestructura y los momentos principales de la épica #66 ya están
implementados: #67 y #68–#74 están cerrados, y #71 quedó integrado por #175.

El cierre de esta fase debe concentrarse en los **bordes que aún quedan abiertos**:

- #81 — llevar al cuñado también a la oficina y al despido, manteniendo la guarda
  de que nunca da información accionable;
- #80 — terminar de revisar qué personajes concretos deben usar la malla humana
  común y qué apariciones deben seguir siendo siluetas deliberadas; #248 ya
  resolvió el cuñado del careo;
- #66 — actualizar y cerrar la épica cuando sus criterios estén realmente
  cubiertos por los sub-issues;
- #135 — tratarlo como diseño de espacio/transición, no como bloqueo para cerrar
  las cinemáticas base. Puede continuar después si no afecta al recorrido.

**Se cierra cuando** no quede ninguna cinemática necesaria dependiendo de una
implementación paralela o provisional no documentada, y #66 refleje el estado
real del árbol de sub-issues.

### v0.8.0 · Que se vea y se pueda jugar con mando

Presentación, accesibilidad e idioma. El orden recomendado es cerrar primero las
regresiones pequeñas y después abordar las superficies amplias:

1. #174 — foco de teclado y mando en el A-7.
2. #172 — empaquetar una tipografía libre y fijarla como fuente por defecto.
3. #113 — menús, opciones y remapeo de teclado/mando.
4. #107 — completar la traducción del catálogo más allá del corte de #173.

Ya resueltos en esta fase:

- #171 — dato del caso 8 y guarda de regresión;
- #173 — primera rebanada de traducción del catálogo.

#98 sigue siendo la regresión paraguas de accesibilidad y debe cerrarse solo
cuando sus superficies pendientes estén cubiertas o explícitamente divididas.

### v0.9.0 · Vida cotidiana

Que el dinero, la casa, el gato y el sueño signifiquen algo como conjunto.

El bloqueo de diseño es **#83**: calibrar acciones por día, coste de vivir y
alquiler mediante simulación antes de cambiar valores. A partir de esa decisión:

- economía doméstica y compras — #78, #93 y #94;
- alquiler y sus consecuencias — #84 y #85;
- gato observable y compartido entre casa/SIGA/sueño — #92 y #132;
- sueño alimentado por el archivo — #79, #86, #87 y #90; #88 ya está integrado.

No conviene implementar primero los minijuegos domésticos: deben asentarse sobre
la economía y el ciclo de vida, no definirlos por accidente.

### v1.0.0 · Primera versión completa

- Exportar y publicar desde CI — #112.
- Publicar en itch.io y preparar el marco para Steam — #99.
- **Playtesting real de principio a fin** — #9; la automatización no sustituye
  mando físico, táctil ni una partida humana completa.

La 1.0 debe salir del recorrido completo y de la accesibilidad mínima, no de
haber agotado todas las ideas del backlog.

### Después de la 1.0

Lo opcional espera a que el recorrido aguante entero:

- minijuegos y colecciones (#148–#162 y sus sub-issues);
- emulador de Game Boy Color (#124, #244, #245);
- logros externos de Steam (#114);
- arte, ambientación y espacio no imprescindibles para el recorrido (#133–#135,
  #141, #216 y sus sub-issues);
- migración o expansión de cinemáticas a 3D cuando aporte algo más que sustituir
  una representación ya funcional.

#169 y #170 son cortes técnicos de #157 y #159: no constituyen por sí solos los
minijuegos completos y no deben adelantar el trabajo estructural.

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
  sufijo (`-alpha.N`, `-beta.N`). Las notas dicen **qué se ha probado y qué no**:
  una release no afirma que algo funciona porque la CI esté verde.

Una release del port a Godot necesita antes la exportación de #112. Hasta
entonces, lo publicable sigue siendo la web.