# AGENTS.md — instrucciones para agentes

Este repositorio adopta las [Normas Platino](https://github.com/EspacioKoop/normas_platino):
cooperación autónoma entre agentes, sin colisiones ni pérdida de trabajo. Autonomía
no significa permiso ilimitado ni integración sin autorización.

Las normas se **integran** con lo que ya había aquí; no lo sustituyen. El flujo
de colaboración humano sigue en [CONTRIBUTING.md](CONTRIBUTING.md) y el contexto
del proyecto en [README.md](README.md). Si dos instrucciones se contradicen,
detén el alcance afectado y pregunta a @eGurucharri en vez de elegir por tu
cuenta.

## Fuentes, antes de tocar nada

| Qué | Dónde |
| --- | --- |
| Prioridad y punto de control | [Plan maestro #181](https://github.com/EspacioKoop/expediente-legado/issues/181) |
| Quién puede editar qué | [Registro único de reservas #182](https://github.com/EspacioKoop/expediente-legado/issues/182) |
| Fases y versiones | [ROADMAP.md](ROADMAP.md) |
| Flujo de ramas y gates | [CONTRIBUTING.md](CONTRIBUTING.md) |
| Protocolo comunitario | [normas_platino](https://github.com/EspacioKoop/normas_platino) |

Esos dos números pertenecen **a este repositorio**. Los de normas_platino son
suyos y no se reutilizan aquí.

Lee también el issue concreto y **sus comentarios**: en este proyecto el
contexto que evita duplicar trabajo suele estar en un comentario, no en el
cuerpo.

## Ciclo obligatorio

1. Comprueba rama, checkout, cambios locales, plan, reservas y PR abiertos.
   Elige el pendiente prioritario **libre**.
2. Publica en **#182**, antes de modificar archivos:

   ```text
   CLAIM issue=#N agent=<nombre> branch=<rama> files=<rutas> goal=<objetivo>
   ```

3. Relee inmediatamente todas las reservas. Gana la activa anterior por fecha de
   GitHub; en empate, el ID de comentario menor. Si hay solape, no edites.
4. Rama y checkout propios desde `main` actualizado. Nombra la rama
   `feature/NN-slug`, `fix/NN-slug` o `docs/NN-slug` con el número del issue.
   Commits pequeños y pushes frecuentes.
5. Subdivide solo si los archivos y los criterios son independientes. Los
   archivos compartidos están listados en #182: acuerda un único escritor.
6. Pasa las **pruebas canónicas** (abajo). Ninguna afirmación de estado puede
   exceder la evidencia: si no has jugado una partida, no digas que funciona.
7. Abre PR hacia `main` enlazando el issue y registra `PR_READY` en #182 con PR,
   SHA, pruebas y límites. Eso **no** libera la reserva ni autoriza el merge.
8. Integra solo con autorización explícita de @eGurucharri y la CI en verde.
9. Verifica el resultado remoto y publica `RELEASE`. Al pausar, deja estado, SHA
   y próximos pasos, y **mantén** la reserva: el silencio no la caduca.

`Closes #N` solo si cierras el issue entero. `Refs #N` para una entrega parcial
— y en el PR, di qué mitad queda fuera.

## Prohibido

Push directo a `main`, force-push, reescritura de historia compartida, fusionar
sin autorización, saltarse las pruebas, y publicar tokens, contraseñas, datos
personales, partidas personales o rutas privadas — también en diffs, logs,
capturas y descripciones de PR.

## Pruebas canónicas

Ninguna entrega está terminada sin ellas. La validación local **no** equivale a
la CI: la referencia es el workflow sobre tu SHA.

```bash
# Godot: importa, corre suite y recorrido, y arranca el juego
python3 scripts/verificar_godot.py
python -m unittest discover -s scripts -p 'test_*.py'   # el detector de falsos verdes
gdlint godot && gdformat --check --diff godot           # gdtoolkit==4.3.4

# Backend y web, desde backend/
mvn test
mvn checkstyle:check pmd:check spotbugs:check
npm test
```

Usa el motor de `.godot-version`. El verificador acepta **cualquier parche de esa
línea** (un 4.7.2 vale para un `4.7-stable` declarado), y rechaza otra línea u
otro canal. Con `GODOT_BIN=/ruta/a/godot` eliges el ejecutable.

Al añadir pruebas, sube `godot/pruebas/minimo.txt`. Bajarlo exige decir qué
pruebas se han retirado y por qué.

## Trampas conocidas

Cosas que ya han roto la suite. Léelas antes de tocar esos ficheros.

- **`godot/datos/textos.csv`**: el bloque `ARCHIVO_*` está al final, **fuera del
  orden alfabético**. Cualquier reordenación que dé por hecho que el CSV está
  ordenado se lo come, y la suite falla con "claves pedidas sin texto". Inserta
  donde toque en vez de reordenar el fichero.
- **Todo el texto vive en ese CSV.** El código solo nombra claves
  (`tr("VISOR_ELIJA")`); una pantalla que escriba una cadena a mano hace fallar
  la suite. Excepción real: las frases de `godot/guion/cartas_ocultas.gd` **no**
  son traducibles, porque tienen que coincidir literalmente con el texto del
  documento que las esconde.
- **Cinemáticas**: la `figura` de un plano 2D es una lista de
  `{"rect": Rect2, "color": Color}`, no de `Rect2` sueltos. Declara los planos en
  el formato de `Cinematica` y resuélvelos con `Cinematica.resolver`, que además
  acorta por repetición y copia en profundidad. Un módulo que se salte el
  reproductor común dará su propio ritmo, su propio rótulo y su propio salto.
- **Los binarios van por Git LFS.** `.gitattributes` manda texturas, mallas,
  tipografías, sonido y vídeo a LFS. Antes de clonar o de añadir assets, corre
  `git lfs install` una vez: sin él, `git` te deja **punteros de texto** donde
  esperabas un PNG, y Godot falla al importar con un error que no menciona LFS
  por ningún lado. Los `.ogg` que ya estaban se quedan en git normal: pasarlos
  a LFS obligaría a reescribir el historial entero.
- **`.uid`**: el repo versiona el `.uid` de cada guion. Si creas un `.gd`,
  commitea también su `.uid`.
- **Guardar antes de una cinemática, no después.** Toda cinemática se puede
  saltar; si el guardado cuelga de su final, saltarla pierde el hallazgo.

## Archivos que no se versionan

- `CLAUDE.md` está en `.gitignore`: son notas locales del agente para sí mismo.
  No lo comitees ni asumas que otro colaborador lo tiene.
- `.env`, `target/`, `node_modules/`, `dist/.cache/`, `dist/salida/`. Trabaja
  siempre sobre `.env.example`.

## Convenciones del código

- **Tests sin Mockito**: dobles con `java.lang.reflect.Proxy`. Si amplías la
  interfaz de un repositorio, añade el método al handler de cada fake que lo
  necesite (patrón `fake(...)` / `repositoryConFindByCasoId(...)`).
- Comentarios y nombres **en español**, coherentes con el código existente. El
  código de este proyecto explica *por qué*, no *qué*: mantén ese registro.
- Respeta el análisis estático: Checkstyle, PMD y SpotBugs son gates. Evita
  campos e imports sin uso; máximo 7 parámetros por método.
- GDScript con tabuladores, y las constantes antes de las funciones: `gdlint`
  exige el orden de definiciones.

## Puntos delicados del dominio

- **Acceso a casos confidenciales** (`CasoController`): valida acceso al caso *y*
  pertenencia de la entidad hija (sospechoso/pista) a ese caso. Un `casoId`
  público en la ruta no debe permitir operar sobre entidades de otro caso.
- **Sembrado** (`config/DataSeeder`): cada caso debe fijar sus campos completos
  (título, descripción, `anioSuceso`, estado). Al añadir o editar un caso,
  compáralo con los hermanos para no dejar campos sin poblar.
- **Progreso** (`ProgresoService` / `ResumenJuegoService`): fuente de verdad del
  progreso; carga las pistas por lotes (`pistasPorCaso` / `findByCasoIdIn`) en vez
  de una consulta por caso, y mantén los totales independientes del rol salvo
  donde el diseño lo pida (p. ej. `totalCasosPrincipales`).
- **Cache Thymeleaf**: desactivada en dev (`application.yml`) y activada en el
  build repartido (`application-standalone.yml`). No la desactives globalmente.
- **Partidas**: el disco persiste el estado; no es el canal de comunicación entre
  pantallas. Comprueba siempre el booleano de `Partida.guardar()`.
