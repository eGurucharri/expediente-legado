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
expediente-legado/
├── docker-compose.yml
├── .env                        # credenciales de desarrollo (no usar en producción)
├── dist/                       # empaquetado del build alpha standalone
│   └── empaquetar-alpha.sh
└── backend/
    ├── Dockerfile
    ├── pom.xml
    └── src/main/java/com/legado/expediente/
        ├── config/             # seguridad + datos semilla + build standalone
        ├── model/              # Usuario, Caso, RegistroLegado, Pista, Concepto...
        ├── repository/         # Spring Data JPA
        ├── service/            # progreso, hotspots, cartas ocultas, resumen
        └── controller/         # login, dashboard, casos, carpeta, menú
```

## Cómo levantarlo (desarrollo)

```bash
cp .env.example .env   # solo la primera vez
docker compose up --build
```

- App: http://localhost:8090 (usuario demo `auditor01` / `auditor-local-123`)
- Adminer: http://localhost:8081 (sistema: MySQL, servidor: `mysql`, usuario/clave según `.env`)

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
    -De2e.baseUrl=http://localhost:8090               # E2E (app ya levantada)
```
