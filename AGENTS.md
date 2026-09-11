# Notas para agentes (Claude Code y similares)

Este archivo orienta a un agente que trabaje en este repo. El flujo de
colaboración completo está en [CONTRIBUTING.md](CONTRIBUTING.md); léelo primero.
Aquí solo lo específico de trabajar como agente.

## Flujo de trabajo (resumen operativo)

1. Nunca edites sobre `main` ni `integracion`. Crea una rama
   `feature/NN-slug`, `fix/NN-slug` o `docs/NN-slug` ligada a un issue.
2. Haz el cambio con su test.
3. Pasa los gates de calidad (ver CONTRIBUTING) **antes** de considerar el
   trabajo terminado: `mvn test`, `mvn checkstyle:check pmd:check spotbugs:check`,
   `npm test`.
4. Abre un PR que referencie el issue. No mergees sin revisión ni con gates en
   rojo.

Para cambios en `godot/`, pasa también los gates del port en `CONTRIBUTING.md`:
`python3 scripts/verificar_godot.py`, las pruebas del verificador, `gdlint godot`
y `gdformat --check godot`. Usa el motor fijado en `.godot-version`.

## Archivos que no se versionan

- `CLAUDE.md` está en `.gitignore`: son notas locales del agente para sí mismo,
  no se comparten. No lo comitees ni asumas que otro colaborador lo tiene.
- `.env`, `target/`, `node_modules/`, `dist/.cache/`, `dist/salida/` tampoco.
  Trabaja siempre sobre `.env.example`.

## Convenciones del código

- **Tests sin Mockito**: dobles con `java.lang.reflect.Proxy`. Si amplías la
  interfaz de un repositorio, añade el método al handler de cada fake que lo
  necesite (patrón `fake(...)` / `repositoryConFindByCasoId(...)`).
- Comentarios y nombres en español, coherentes con el código existente.
- Respeta el análisis estático: Checkstyle, PMD y SpotBugs son gates. Evita
  campos/imports sin uso; máximo 7 parámetros por método (regla activa).

## Puntos delicados del dominio

- **Acceso a casos confidenciales** (`CasoController`): valida acceso al caso
  *y* pertenencia de la entidad hija (sospechoso/pista) a ese caso. Un `casoId`
  público en la ruta no debe permitir operar sobre entidades de otro caso.
- **Sembrado** (`config/DataSeeder`): cada caso debe fijar sus campos completos
  (título, descripción, `anioSuceso`, estado). Al añadir/editar un caso,
  compáralo con los hermanos para no dejar campos sin poblar.
- **Progreso** (`ProgresoService` / `ResumenJuegoService`): fuente de verdad del
  progreso; carga las pistas por lotes (`pistasPorCaso` / `findByCasoIdIn`) en
  vez de una consulta por caso, y mantén los totales independientes del rol
  salvo donde el diseño lo pida (p.ej. `totalCasosPrincipales`).
- **Cache Thymeleaf**: desactivada en dev (`application.yml`) y activada en el
  build repartido (`application-standalone.yml`). No la desactives globalmente.
