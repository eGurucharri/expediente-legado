# Material para la página de itch.io (alpha para betatesters)

Complemento de `empaquetar-alpha.sh` (issue #36): todo lo necesario para montar
la página restringida de itch.io donde los amigos descargan los zips. El repo
es privado, así que la Release de GitHub no les sirve — itch.io hace de canal.

---

## 1. Texto de la página (copiar y pegar)

**Título:** SIGA-98 · Expediente Legado

**Descripción corta (tagline):**
Un juego de investigación y horror burocrático dentro de un sistema de gestión de 1998 que no debería seguir encendido.

**Descripción (cuerpo de la página):**

> Es 1998, o eso dice el sistema. Eres el nuevo auditor y te han dado acceso
> al backup restaurado de SIGA, el viejo programa de gestión de la oficina.
> Entre facturas, memorandos y expedientes de personal hay ocho casos
> esperando a que alguien tire del hilo.
>
> Lee despacio. Combina documentos. Acusa cuando tengas pruebas — o cuando no
> las tengas, pero eso tiene un precio. Y si en algún momento el sistema te
> parece raro... no mires lo que no debería estar donde está.
>
> **Esto es una ALPHA.** Habrá cosas raras, y justo por eso estás aquí: dentro
> del zip hay un LEEME.txt con las credenciales de acceso y cómo contarme lo
> que encuentres (bugs, pero también dónde te aburriste o te perdiste — eso
> vale más).
>
> **Cómo jugar:** descarga el zip de tu sistema, descomprímelo y haz doble
> clic en `INICIAR.bat` (Windows) o ejecuta `./iniciar.sh` (Linux). No hace
> falta instalar nada. Se abre en tu navegador; juega en un ordenador, no en
> el móvil.

**Metadatos sugeridos:**
- Classification: Games → Kind of project: Downloadable
- Genre: Puzzle / Interactive Fiction
- Tags: detective, horror, retro, spanish, mystery, 90s
- Release status: In development (Prototype/Alpha)
- Pricing: No payments (gratis, sin donaciones — es un playtest)

**Uploads:** los dos zips de `dist/salida/`, marcando la plataforma de cada
uno (Windows / Linux) para que itch muestre el icono correcto.

---

## 2. Montar la página (una vez, ~15 minutos)

1. Crear cuenta en https://itch.io (Register). Con confirmar el correo basta.
2. Menú de usuario → **Upload new project**.
3. Rellenar con el material del punto 1. En **Kind of project** elegir
   *Downloadable*; NO marcar "This file will be played in the browser".
4. Subir los dos zips (arrastrar y soltar) y marcar la plataforma de cada uno.
5. **Visibility & access: dejar la página en `Draft`.** Las páginas en
   borrador tienen un enlace secreto compartible: en la propia página de
   edición, itch muestra un aviso tipo *"This page is a draft — share it with
   this secret URL"*. Ese enlace es lo que se manda a los amigos: pueden ver
   la página y descargar SIN cuenta de itch.io, y la página no aparece en
   búsquedas ni en tu perfil.
   - (La alternativa `Restricted` exige que cada tester tenga cuenta de
     itch.io y darle acceso uno a uno — más fricción, no la usamos.)
6. Enviar a los amigos: el enlace secreto + una línea de contexto ("descarga
   el zip de tu sistema y lee el LEEME de dentro").

## 3. Canal de feedback (decidir ANTES de empaquetar la ronda)

La combinación que mejor funciona con un grupo pequeño de amigos:

1. **Grupo de mensajería dedicado** (WhatsApp/Telegram/Discord — grupo NUEVO,
   solo para el playtest): el canal por defecto. Cero fricción, capturas
   fáciles, y las conversaciones de "aquí me perdí" valen más que cualquier
   bug. Tú conviertes lo relevante en issues de GitHub.
2. **Google Form para bugs** (recomendado si hay más de 3-4 testers): campos
   fijos = triaje fácil, las respuestas caen en una hoja de cálculo. Campos
   sugeridos: build (texto corto), sistema operativo (choice), qué hiciste
   (párrafo), qué esperabas / qué pasó (párrafo), captura (texto con enlace —
   la subida de archivos de Forms obliga a iniciar sesión en Google, mejor
   que peguen la captura en el grupo y el enlace/descripción en el form).
3. **El propio juego ya apunta al form**: el manual de Mi carpeta tiene la
   sección "Parte de incidencias" con la receta del buen reporte. Si
   empaquetas con la URL del form, muestra además el botón que lo abre:

   ```bash
   SIGA98_FEEDBACK_URL="https://forms.gle/tu-form" bash dist/empaquetar-alpha.sh
   ```

   Sin la variable, la sección remite "al canal acordado" (el grupo).

Los comentarios de la propia página de itch.io exigen cuenta de itch — no
cuentes con ellos como canal.

Cada reporte que llegue → un issue con el número de build en el cuerpo (sale
en el pie del login y en el LEEME); lo cualitativo ("me aburrí en el caso 3")
→ issues de contenido o notas para la siguiente ronda.

## 4. Actualizar el build en rondas futuras

Manual: editar la página → borrar los zips viejos → subir los nuevos de
`dist/salida/`. Suficiente para rondas espaciadas.

Con `butler` (el CLI oficial de itch, mejor si habrá varias rondas — hace
diffs binarios y los testers descargan menos):

```bash
# una vez
curl -L -o butler.zip https://broth.itch.zone/butler/linux-amd64/LATEST/archive/default
unzip butler.zip && chmod +x butler && ./butler login

# cada release (sustituir <usuario> por la cuenta de itch)
./butler push dist/salida/siga98-<version>-windows.zip <usuario>/siga98-expediente-legado:windows --userversion <version>
./butler push dist/salida/siga98-<version>-linux.zip   <usuario>/siga98-expediente-legado:linux   --userversion <version>
```

## 5. Smoke test de Windows (antes de repartir NADA)

En una máquina Windows real, con el zip `siga98-<version>-windows.zip`
descargado de la Release de GitHub (o de la propia página de itch en draft):

1. Descomprimir el zip entero (no ejecutar desde dentro del explorador de
   zips) en una carpeta cualquiera, p. ej. el Escritorio.
2. Doble clic en `INICIAR.bat`. Si SmartScreen protesta ("Windows protegió
   tu PC"): *Más información → Ejecutar de todas formas* — apuntarlo si sale,
   para avisar a los testers en el mensaje de envío.
3. Debe quedarse abierta una consola y, en unos segundos, abrirse el
   navegador en la pantalla de acceso (pie: "build <version>").
4. Entrar con `auditor01 / auditor-local-123`, abrir un expediente, clicar
   una frase punteada (pista) y comprobar que queda subrayada.
5. Cerrar la consola (el juego se apaga), volver a doble clic en
   `INICIAR.bat`, entrar de nuevo: la pista debe seguir descubierta.
6. Comprobar que ha aparecido una carpeta `data/` junto al `.bat`.

Si los 6 pasos pasan, el build está listo para repartir. Si algo falla:
captura de la consola y de la pantalla, y se arregla antes de enviar nada.
