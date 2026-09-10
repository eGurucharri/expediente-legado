# addons/ffmpeg — EIRTeam.FFmpeg

Extensión (GDExtension) que le da a `VideoStreamPlayer` los formatos que Godot
no trae de serie: `.mp4`, `.mkv`, `.webm`, `.mov`. Se usa desde
`Cinematica.flujo_de()`, que es el único sitio del proyecto que la nombra.

| | |
|---|---|
| **Versión** | 1.1.4 (`autobuild-2025-11-12-13-44`) |
| **Origen** | https://github.com/EIRTeam/EIRTeam.FFmpeg |
| **Licencia del envoltorio** | MIT (© Álex Román / EIRTeam) |
| **Licencia de las bibliotecas FFmpeg** | **LGPL-3.0 o posterior** |

## Por qué se comprobó la licencia y no se dio por hecha

Este repositorio es MIT. FFmpeg se puede compilar en dos sabores y **la
diferencia importa**: una compilación con `--enable-gpl` obliga a que lo que se
distribuya con ella sea GPL, y eso se llevaría por delante la licencia del
proyecto.

Estas no lo son. Comprobado sobre los propios binarios:

```
strings addons/ffmpeg/linux64/libavcodec.so.60 | grep -i "license:"
libavcodec license: LGPL version 3 or later
```

Las seis (`avcodec`, `avformat`, `avfilter`, `avutil`, `swscale`, `swresample`)
dan LGPL-3.0+. La LGPL exige poder **sustituir** la biblioteca por otra versión,
y aquí se cumple sola porque van como ficheros dinámicos aparte (`.so` / `.dll`)
y no enlazadas dentro del ejecutable. **No las metas dentro de un binario
estático** sin volver a mirar esto.

## Qué plataformas trae

Solo **linux64** y **win64**. El `.gdextension` declara además rutas para macOS
y Android que **no están en este paquete**: en esas plataformas la extensión no
carga, `ClassDB.class_exists("FFmpegVideoStream")` da falso y
`Cinematica.flujo_de()` avisa y devuelve nulo en vez de reventar.

Consecuencia práctica: **un plano rodado en `.mp4` no se ve en macOS.** Los
`.ogv` sí, porque esos los reproduce Godot por su cuenta. Si algún día importa
macOS, o se añaden esos binarios o el metraje va en Ogg Theora.

## Actualizar

Descargar el zip de una release, descomprimir sobre `addons/`, volver a
comprobar la línea de licencia de arriba y actualizar la versión de esta tabla.
Se han quitado los `.exp` y `.lib` de win64: son artefactos del enlazador y no
hacen falta para ejecutar.
