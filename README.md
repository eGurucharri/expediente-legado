# SIGA-98 · Expediente Legado

Videojuego de investigación y horror burocrático: el jugador es un auditor que
accede a un backup restaurado de **SIGA**, un sistema de administración de
finales de los 90, para resolver ocho casos escondidos en facturas, memorandos
y expedientes de empleados. Detrás del sistema "roto" hay una segunda capa
(**Prometeo**) con logros, un tarot coleccionable, dificultad, un sistema de
vidas y varios finales.

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

El `--import` no es solo por los `class_name`: también compila `datos/textos.csv`
a la traducción que el juego carga. **Todo el texto vive en ese CSV** y el código
solo nombra claves (`tr("VISOR_ELIJA")`); una pantalla que escriba una cadena a
mano hace fallar la suite, que es lo que impide que esto se deshaga solo. El
texto de los ocho casos sigue en `datos/casos.json` y todavía no está traducido.

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
