# Investigación cinematográfica aplicada

Este documento versiona una **primera entrega parcial** de la investigación de #177. No pretende cerrar el issue ni implementar las cinemáticas pendientes: convierte el análisis del hilo en criterios reutilizables para futuros PR.

## Principios transferibles

| Referencia | Técnica útil | Aplicación en Expediente Legado | Riesgo a evitar |
| --- | --- | --- | --- |
| *Neon Genesis Evangelion* | Plano fijo, silencio y espacio negativo | Dar peso a acciones rutinarias y transiciones burocráticas con duración, encuadre y sonido ambiente | Que una pausa parezca un cuelgue; evitar planos largos sin microevento |
| *Serial Experiments Lain* | Repetición con alteración, interfaz narrativa y fragmentación | Deformar en sueño o montaje solo información ya conocida por el jugador | Introducir hechos nuevos o contradicciones que parezcan bugs |
| *Kingdom Hearts* | Objetos recurrentes como anclas emocionales | Reutilizar gato, expediente, sello, TV o espacios como motivos que acumulan significado | Convertirlos en coleccionables obligatorios o sentimentalizar fuera de tono |
| *Persona* | Ritmo de calendario y transiciones con identidad | Diferenciar oficina, trayecto, casa y sueño por luz, sonido, composición y ritmo | Copiar una gramática visual ajena a SIGA-98 o convertir el cierre en puntuación |
| *Steins;Gate* | Interfaz cotidiana como punto de decisión | Hacer que llamadas, avisos o mensajes modifiquen qué se muestra después sin abrir un menú abstracto | Ramificaciones que alteren veredicto/economía sin diseño explícito |
| *Metal Gear* / Kojima | Continuidad entre control y puesta en escena | Mantener el estado real del espacio y usar cámara en tiempo real cuando sea posible | Fingir continuidad al cargar otra escena o separar siempre jugar y mirar |

## Guardas de diseño

Toda escena derivada de esta investigación debería cumplir estas reglas:

- No revelar IDs, pistas, conceptos ni relaciones que el jugador no haya podido conocer.
- Si una escena deforma recuerdos o documentos, cada elemento debe ser rastreable a datos persistidos de la partida.
- La variación cinematográfica no cambia recompensas, acciones, economía ni desenlaces salvo que otro issue lo defina expresamente.
- El estado jugable debe resolverse y guardarse antes de una cinemática saltables; saltarla no puede perder progreso.
- Las transiciones deben ser saltables y tener una alternativa compatible con `reduce_motion` basada en cortes o fundidos simples.
- La información esencial debe seguir siendo legible sin audio mediante subtítulos, texto o señal visual equivalente.
- Las selecciones procedurales de elementos para una escena deben poder reproducirse de forma determinista en tests.

## Tres prototipos de bajo riesgo

### Oficina → trayecto

Plano fijo breve del espacio de salida, un microevento de luz o sonido y corte al exterior. El cambio de fluorescente a calle, de linóleo a asfalto y de zumbido a ambiente exterior debe comunicar el cambio de bloque sin añadir exposición.

No requiere decidir todavía la implementación de #72: este prototipo solo fija lenguaje de dirección.

### Casa → sueño

Repetir el mismo encuadre de casa y alterar únicamente parámetros de presentación ya disponibles: luz, niebla, sonido y, si procede, presencia o ausencia de un objeto persistido. La escena no inventa pistas; deforma lo conocido.

No sustituye #74 ni #87: sirve como criterio para sus futuras implementaciones.

### Cierre de jornada

Rematar el día con una pieza breve y fría: pantalla SIGA, sonido mecánico y un plano final del espacio u objeto recurrente. Debe registrar, no juzgar. Nada de notas, estrellas o clasificación moral.

## Matriz de riesgo

| Riesgo | Regla de contención |
| --- | --- |
| Dependencia del canon externo | La escena debe entenderse sin conocer ninguna obra de referencia |
| Exceso de exposición | Preferir gesto, encuadre, sonido u objeto antes que texto explicativo |
| Metanarrativa invasiva | No usar telemetría real ni romper privacidad para producir efectos narrativos |
| Repetición cansina | Mantener variaciones pequeñas y ligadas a estado real; acortar escenas repetidas cuando el sistema común lo permita |
| Ambigüedad confundida con bug | Toda deformación debe tener una fuente reconocible o una regla consistente |
| Parpadeos o movimiento problemático | `reduce_motion`, evitar flashes rápidos y ofrecer alternativa visual estable |
| Cinématica bloqueante | Saltable; el resultado jugable debe existir antes de reproducirla |

## Fronteras con otros issues

- #66: reproductor y reglas comunes de cinemáticas.
- #67: ritmo, salto y acortado reutilizable.
- #72 y #74: implementación concreta de transiciones 3D.
- #87: contenido y reglas de deformación del sueño.
- #92: uso del gato como elemento recurrente.
- #98, #100 y #140: finales, presentación de resultados y otros sistemas relacionados.

Esta entrega es deliberadamente documental. Los siguientes pasos de #177 pueden dividirse en PR independientes: fichas ampliadas por referencia, prototipo de una única transición y pruebas de accesibilidad.
