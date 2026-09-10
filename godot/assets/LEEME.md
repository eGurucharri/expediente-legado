# Assets

Todo lo que vive aquí es material de terceros, y por eso **nada entra sin
ficha**. `procedencia.json` lleva una entrada por fichero:

```json
{
  "ruta": "modelos/silla.glb",
  "titulo": "Office chair",
  "autor": "Nombre de quien lo hizo",
  "licencia": "CC0-1.0",
  "fuente": "https://... (la página que declara la licencia, no el fichero)",
  "sha256": "..."
}
```

La prueba `_procedencia()` lo comprueba **en las dos direcciones**: un fichero
sin ficha rompe, y una ficha que apunta a un fichero que no existe también. El
`sha256` se compara con el fichero real, así que sustituir un asset por otro
sin actualizar su ficha se ve.

Tres reglas que no son burocracia:

1. **La fuente es la página que declara la licencia**, no el enlace de descarga
   directa. Un `.glb` suelto no dice bajo qué términos se publicó.
2. **`CC0-1.0` o compatible.** Este árbol es GPL-2.0; una licencia que exija
   atribución no es imposible, pero entonces la atribución tiene que aparecer
   en el juego, no solo aquí.
3. **Se apunta al bajarlo, no después.** La procedencia que se documenta «luego»
   es la que nadie documenta: dentro de seis meses nadie recuerda de dónde salió
   una malla.

Está vacío a propósito: la guarda existe desde antes que el primer asset.
