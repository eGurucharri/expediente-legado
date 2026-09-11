# SIGA-98 · Expediente Legado

Videojuego de investigación y horror burocrático: el jugador es un auditor que
accede a un backup restaurado de **SIGA**, un sistema de administración de
finales de los 90, para resolver ocho casos escondidos en facturas, memorandos
y expedientes de empleados. Detrás del sistema "roto" hay una segunda capa
(**Prometeo**) con logros, un tarot coleccionable, dificultad, un sistema de
vidas y varios finales.

## Cómo orientarse

| Dónde | Qué responde |
| --- | --- |
| [ROADMAP.md](ROADMAP.md) | Las fases hasta la 1.0, y qué hay en cada versión |
| [Plan maestro #181](https://github.com/EspacioKoop/expediente-legado/issues/181) | Qué va primero, ahora mismo |
| [Registro de reservas #182](https://github.com/EspacioKoop/expediente-legado/issues/182) | Quién está tocando qué |
| [AGENTS.md](AGENTS.md) | Cómo trabaja aquí un agente, y las trampas conocidas |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Ramas, gates y revisión |
| [Milestones](https://github.com/EspacioKoop/expediente-legado/milestones) | Qué falta para la siguiente versión |
| [Releases](https://github.com/EspacioKoop/expediente-legado/releases) | Qué se puede jugar ya |

Este repositorio adopta las [Normas Platino](https://github.com/EspacioKoop/normas_platino)
para la cooperación entre agentes: se reserva antes de editar, se entrega por PR
y **la integración siempre requiere autorización**. El detalle, en
[AGENTS.md](AGENTS.md).

## Stack

- **Backend:** Spring Boot 3 (Java 25) + Spring Data JPA + Spring Security + Thymeleaf
- **Base de datos:** MySQL 8 (desarrollo) / H2 embebido (build standalone alpha)
- **Frontend:** Bootstrap 5 (vía webjars) con hojas de estilo propias: una que
  imita un programa de escritorio de los 90 (SIGA-98) y otra moderna (Prometeo)
- **Docker:** `docker-compose.yml` con MySQL, backend y Adminer (gestor web de BD)
- **Calidad:** JUnit 5 (fakes por `Proxy`, sin Mockito), Vitest para la lógica
  JS pura, Playwright para E2E de navegador real, Checkstyle + PMD + SpotBugs

## Estructura

```
.
├── docker-compose.yml
├── .env                        # credenciales de desarrollo (no usar en producción)
├── dist/                       # empaquetado del build alpha standalone
│   └── empaquetar-alpha.sh
├── backend/
│   ├── Dockerfile
│   ├── pom.xml
│   └── src/main/java/com/legado/expediente/
│       ├── config/             # seguridad + datos semilla + build standalone
│       ├── model/              # Usuario, Caso, RegistroLegado, Pista, Concepto...
│       ├── repository/         # Spring Data JPA
│       ├── service/            # progreso, hotspots, cartas ocultas, resumen
│       └── controller/         # login, dashboard, casos, carpeta, menú
└── godot/                      # el port a Godot 4 (#54), donde está el trabajo vivo
    ├── datos/                  # el contenido extraído del backend, como JSON
    ├── guion/                  # la lógica, en GDScript
    ├── escenas/
    └── pruebas/
```

## El port a Godot

El juego se está reescribiendo en **Godot 4** (issue #54) para distribuirlo sin
servidor. `godot/` no es un port mecánico del backend: el contenido salió de
`DataSeeder.java` a `datos/casos.json`, y la lógica se rehace en GDScript con
sus pruebas portadas una a una desde las de JUnit y Vitest.

La suite se ejecuta sin abrir el editor:

```bash
godot4 --headless --path godot --import          # una vez, por los class_name
godot4 --headless --path godot --script pruebas/pruebas.gd
```

Para verificar una entrega, usa un **Godot de la línea 4.7**, declarada en
`.godot-version`, y ejecuta `python3 scripts/verificar_godot.py` desde la raíz.
Vale cualquier parche de esa línea —un 4.7.2 sirve para un `4.7-stable`
declarado—; lo que se rechaza es otra línea u otro canal, que es lo que mete
ruido en la suite. Puedes indicar otro ejecutable con `GODOT_BIN=/ruta/a/godot`. Este comando importa
los recursos, ejecuta la suite en español y comprueba que el juego arranca,
con datos temporales para no tocar tu partida. Falla ante errores de guion,
recursos rotos, bloqueos o menos comprobaciones que `godot/pruebas/minimo.txt`.
Al añadir pruebas, actualiza ese mínimo; reducirlo requiere justificar qué
pruebas se han retirado.

También recorre las escenas reales de oficina, visor y casa: leer y levantarse
conserva las acciones gastadas, y volver a abrir la partida conserva el lugar,
el día, el dinero, los compañeros, el gato y los veredictos firmados. Las partidas
anteriores al ciclo diario reciben los campos nuevos sin borrar las pistas.

Las lecturas gratuitas de expedientes firmados también se registran para el
sueño, sin gastar acciones ni descubrir pistas nuevas. Una apertura rechazada
no cuenta como lectura. El reloj nocturno conserva una duración total fija al
cambiar de sala y al recargar: una noche agotada no recibe tiempo nuevo.
Las partidas sin el campo `sueno_total` conservan sus segundos y salas pendientes;
como no guardaban el itinerario completo, su referencia visual se fija una vez
con lo que queda, sin inventar la duración original.

El recorrido aislado exige al menos 95 comprobaciones: conserva las pruebas del
ciclo completo y la reasignación (#167) y añade 38 regresiones de lecturas, reloj
y migración (#166). Su mínimo está en `scripts/verificar_godot.py`, separado del
mínimo de la suite principal. Esto no sustituye el playtesting con teclado,
mando físico ni una partida completa.

El CI ejecuta esta validación en un job independiente del backend, además de
`gdlint godot` y `gdformat --check --diff godot` con `gdtoolkit==4.3.4`.
El formato sigue siendo obligatorio; `--diff` muestra los ajustes requeridos
cuando falla, sin modificar los archivos ni omitir la comprobación.

El `--import` no es solo por los `class_name`: también compila `datos/textos.csv`
a la traducción que el juego carga. **Todo el texto vive en ese CSV** y el código
solo nombra claves (`tr("VISOR_ELIJA")`); una pantalla que escriba una cadena a
mano hace fallar la suite, que es lo que impide que esto se deshaga solo. El
texto de los ocho casos sigue en `datos/casos.json` y todavía no está traducido.

## Estado, sin adornos

`main` tiene la suite en **464 comprobaciones** y el recorrido en **95**, ambos
sin fallos, con `gdlint` y `gdformat` limpios. Eso es validación automática:
**no hay playtesting humano con mando ni una partida completa jugada de
principio a fin** (#9). Ninguna afirmación de este README va más allá de esa
evidencia.

Las cinemáticas se están haciendo en **2D de forma provisional**. El objetivo es
que acaben siendo 3D, pero no se rehacen sobre la marcha: primero se cierra la
primera versión completa. Por eso todas se declaran en el formato común de
`Cinematica`, que ya despacha `3d` y `2d`. Ver [ROADMAP.md](ROADMAP.md).

## Clonar

Los binarios del juego —texturas, mallas, tipografías— van por **Git LFS**, así
que hace falta tenerlo antes de clonar:

```bash
git lfs install          # una vez por máquina
git clone https://github.com/EspacioKoop/expediente-legado.git
```

Si ya clonaste sin él: `git lfs install && git lfs pull`. Sin LFS te quedan
punteros de texto donde debería haber assets, y Godot falla al importar sin
mencionar LFS por ningún lado.

## Cómo levantarlo (desarrollo)

```bash
cp .env.example .env   # solo la primera vez
docker compose up --build
```

- App: http://localhost:1998 (usuario demo `auditor01` / `auditor-local-123`)
- Adminer: http://localhost:1999 (sistema: MySQL, servidor: `mysql`, usuario/clave según `.env`)

Al arrancar por primera vez, `DataSeeder` siembra los usuarios demo y los ocho
casos completos (registros, pistas, sospechosos y el corcho de conceptos).

## Build alpha standalone (para betatesters)

Genera dos zips autocontenidos (Windows x64 y Linux x64) con el jar, un JRE
Temurin 25 y un lanzador — sin Docker, sin MySQL, sin instalar nada:

```bash
bash dist/empaquetar-alpha.sh
```

Los zips salen en `dist/salida/`. Usan el perfil Spring `standalone` (H2 en
fichero, en `./data/` junto al lanzador) y abren el navegador solos al
arrancar. Las instrucciones para el tester van dentro (`LEEME.txt`).

## Tests y calidad

Desde `backend/` (o vía la imagen `maven:3.9-eclipse-temurin-25` si el Maven
local no es Java 25):

```bash
mvn test                                              # unitarios
mvn checkstyle:check pmd:check spotbugs:check         # gates de calidad
npm test                                              # Vitest (lógica JS pura)
mvn test -Dtest=AutenticacionE2E,ModalesFocoE2E,MapaConexionesE2E \
    -De2e.baseUrl=http://localhost:1998               # E2E (app ya levantada)
```

## Licencia

**MIT** (ver [`LICENSE`](LICENSE)): código, textos y datos de este repositorio.
Cualquiera puede cogerlo, modificarlo y venderlo, incluido cerrar su copia — es
lo que la MIT permite y se eligió a sabiendas.

Lo que **no** cubre es el material de terceros bajo `godot/assets/`, que
conserva la licencia con la que llegó: cada fichero declara la suya en
`assets/procedencia.json` con su autor, su fuente y su sha256, y hay una prueba
que falla si un asset no tiene ficha o una ficha no tiene asset.
