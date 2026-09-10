# Port a Godot 4

Primer corte de la migración (#54). **No sustituye todavía a nada**: la app
Spring de `backend/` sigue funcionando igual, y esta carpeta no depende de ella.

```
godot/
├── datos/casos.json      los 8 casos, extraídos de DataSeeder.java
├── datos/extraer.mjs     el extractor, para repetirlo si el seeder cambia
├── guion/                lógica pura portada de service/
└── pruebas/pruebas.gd    la suite, ejecutable sin abrir el editor
```

## Correr las pruebas

```bash
godot4 --headless --path godot --import          # solo la primera vez
godot4 --headless --path godot --script pruebas/pruebas.gd
```

Sale `0` si todo pasa. Los casos están portados uno a uno de `WikiLinkServiceTest`,
`HotspotServiceTest`, `CartaOcultaServiceTest` y `ProgresoServiceTest`, con el
nombre del test Java en un comentario: si el port cambia una decisión del
original, se ve cuál.

## Qué cambia respecto al backend Java

**El contenido deja de ser código.** `DataSeeder.java` eran 1.443 líneas de
setters; ahora es `casos.json`, y escribir un caso nuevo no recompila nada. La
extracción está verificada contra las llamadas `.save()` del original: 8 casos,
32 registros, 35 pistas, 27 sospechosos, 16 conceptos, 0 referencias sin
resolver.

**Los tres servicios de texto se funden en uno.** `HotspotService`,
`CartaOcultaService` y `WikiLinkService` hacían lo mismo —encontrar una frase y
envolverla en marcado— y se encadenaban, cada uno sobre la salida del anterior.
`CartaOcultaService` llegaba a hacer `indexOf` sobre HTML ya generado, así que
una frase que cayera dentro del marcado lo partía. Aquí `marcas.gd` devuelve
*dónde* están las marcas y `bbcode.gd` decide *cómo* se pintan, así que el
solapamiento se resuelve una vez y explícitamente (gana la que empieza antes).

**`ProgresoService` adelgaza.** `pistasPorCaso` y la variante de `progreso` que
reutilizaba el mapa existían para evitar un N+1 de consultas SQL. Sin base de
datos no hay consulta que evitar. La regla que sí se conserva: el progreso no se
guarda en el caso, se deriva de las pistas descubiertas.

**El escapado cambia de carácter y de sitio.** En HTML el peligro era `<` y cada
servicio escapaba por su cuenta; en BBCode es `[`, y se escapa una sola vez,
solo en el texto plano.

## Lo que este corte NO incluye

- Ninguna escena ni interfaz. La pieza de riesgo es el visor de expedientes
  (`RichTextLabel` con texto largo y frases pulsables) y quiere probarse antes
  de comprometerse.
- `prometeo-ui.js` (3.181 líneas: logros, tarot, vidas, finales) sigue sin portar.
- La persistencia. Un `Descubrimiento` era una fila; aquí habrá que decidir
  dónde vive la partida guardada.
