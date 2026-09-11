# Cómo colaborar en SIGA-98 · Expediente Legado

Gracias por sumarte. Estas son las pautas de trabajo del proyecto. Son las que
ya seguimos de facto (mira el historial de commits); aquí quedan escritas para
que cualquiera —persona o agente— pueda incorporarse sin adivinar.

## Regla de oro: nunca se empuja a la rama de integración

Nada se hace directamente sobre `main`. **Todo cambio va
en su propia rama y entra por Pull Request.**

- Nombra la rama según el tipo de trabajo y el issue asociado:
  - `feature/NN-slug-corto` para funcionalidad nueva.
  - `fix/NN-slug-corto` para correcciones.
  - `docs/NN-slug-corto` para documentación.

  donde `NN` es el número del issue de GitHub. Ejemplos reales del historial:
  `feature/49-pulido-pre-betatest`, `fix/44-canje-solo-a-cero`.
- Abre un issue antes si el cambio no tiene uno; el PR debe referenciarlo (`#NN`).
- El PR lo revisa y mergea otra persona (o tú tras revisión), nunca se saltan
  los gates de calidad de abajo.

## Mensajes de commit

En español, con prefijo de tipo y el issue entre paréntesis al final:

```
feat: los reclamantes de la Ventanilla salen del corcho (#48)
fix: puertos menos comunes y tematicos — app 1998, adminer 1999 (#42)
```

Usa `feat:` para funcionalidad, `fix:` para correcciones, `docs:` para docs.

## Entorno de desarrollo

Ver el [README](README.md) para el detalle. En resumen:

```bash
cp .env.example .env      # solo la primera vez (credenciales de desarrollo)
docker compose up --build
```

- App: http://localhost:1998 (demo `auditor01` / `auditor-local-123`)
- Adminer: http://localhost:1999

Nunca comitees `.env` (ya está en `.gitignore`): solo `.env.example` con valores
de relleno.

## Gates de calidad — nada se da por terminado sin pasarlos

Para el port a Godot, usa la versión de `.godot-version` y ejecuta desde la raíz:

```bash
python3 -m unittest discover -s scripts -p 'test_*.py'
python3 scripts/verificar_godot.py
gdlint godot
gdformat --check godot
```

El lint usa `gdtoolkit==4.3.4`. El verificador aísla las partidas de prueba,
limita el tiempo de cada etapa y rechaza errores aunque Godot devuelva cero.
`godot/pruebas/minimo.txt` registra el mínimo de comprobaciones: se aumenta
con la suite, y no se reduce para esconder un fallo. Godot aún no tiene
instrumentación de cobertura ni E2E de interacción automatizados.

Antes de abrir o mergear un PR, desde `backend/` (o vía la imagen
`maven:3.9-eclipse-temurin-25` si tu Maven local no es Java 25):

```bash
mvn test                                            # unitarios (JUnit 5)
mvn checkstyle:check pmd:check spotbugs:check        # análisis estático
npm test                                            # Vitest (lógica JS pura)
```

Los E2E de navegador real (Playwright) corren con la app ya levantada:

```bash
mvn test -Dtest=AutenticacionE2E,ModalesFocoE2E,MapaConexionesE2E \
    -De2e.baseUrl=http://localhost:1998
```

Convenciones de test del repo:

- **Sin Mockito**: los dobles se hacen con `java.lang.reflect.Proxy` (ver
  `CasoControllerTest`, `ResumenJuegoServiceTest`). Si añades un método a un
  repositorio y un fake lo usa, impleméntalo en el handler del proxy.
- Los `*E2E` se excluyen de `mvn test` por convención de nombre (ver `pom.xml`),
  no están deshabilitados.
- Todo cambio de comportamiento lleva su test.

## Mantener la documentación viva

Cuando cambies build, dependencias, puertos, variables de entorno o el
sembrado de datos (`DataSeeder`), actualiza en el mismo PR:

- El [README](README.md).
- Este `CONTRIBUTING.md` y `AGENTS.md` si cambian las pautas o el flujo.
- Las plantillas de empaquetado en `dist/` si afecta al build alpha.

## Antes de tocar zonas sensibles

- **Acceso a casos confidenciales**: el control de acceso vive en
  `CasoController` (`sinAcceso`). Cualquier endpoint que actúe sobre un caso o
  sobre una entidad hija (sospechoso, pista) debe validar *tanto* el acceso al
  caso *como* que la entidad pertenece a ese caso. No te fíes solo del `casoId`
  de la ruta.
- **Progreso y resumen**: `ProgresoService` / `ResumenJuegoService` son la
  única fuente de verdad del progreso real del jugador (la capa Prometeo del
  navegador reacciona a ellos). Sus números deben ser exactos e independientes
  del rol salvo donde el diseño lo exija.
