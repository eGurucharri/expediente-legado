# SIGA-98 · Expediente Legado

Entorno base para un videojuego de investigación: el jugador es un auditor que
accede a un backup restaurado de **SIGA**, un sistema de administración de
finales de los 90, para resolver casos escondidos en facturas, memorandos y
expedientes de empleados.

## Stack

- **Backend:** Spring Boot 3 (Java 25) + Spring Data JPA + Spring Security + Thymeleaf
- **Base de datos:** MySQL 8
- **Frontend:** Bootstrap 5 (vía webjars) con una hoja de estilos que imita la
  estética de un programa de escritorio de los años 90
- **Docker:** `docker-compose.yml` con MySQL, backend y Adminer (gestor web de BD)

## Estructura

```
expediente-legado/
├── docker-compose.yml
├── .env                        # credenciales de desarrollo (no usar en producción)
└── backend/
    ├── Dockerfile
    ├── pom.xml
    └── src/main/java/com/legado/expediente/
        ├── config/             # seguridad + datos semilla
        ├── model/               # Usuario, Caso, RegistroLegado, Pista
        ├── repository/           # Spring Data JPA
        └── controller/           # login, dashboard, detalle de caso
```

## Cómo levantarlo

```bash
docker compose up --build
```

- App: http://localhost:8090 (usuario demo `auditor01` / `auditor123`)
- Adminer: http://localhost:8081 (sistema: MySQL, servidor: `mysql`, usuario/clave según `.env`)

Al arrancar por primera vez, `DataSeeder` crea el usuario demo y un caso de
ejemplo ("El cierre de caja de 1999") con registros y pistas para investigar.

## Siguientes pasos sugeridos

- Añadir más casos, tipos de registro y mecánicas de pistas (combinarlas,
  acusar a un sospechoso, finales según las pistas encontradas).
- Sustituir `ddl-auto: update` por migraciones versionadas (Flyway/Liquibase)
  cuando el esquema se estabilice.
- Añadir tests de integración para los controladores y repositorios.
