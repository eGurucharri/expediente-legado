#!/usr/bin/env bash
# Empaqueta el build alpha standalone (issue #36): dos zips autocontenidos
# (Windows x64 y Linux x64) con el jar, un JRE Temurin 25 y un lanzador.
# Se ejecuta entero desde Linux: el jar es multiplataforma y los JRE se
# descargan ya compilados de Adoptium (y se cachean en dist/.cache).
#
# Uso:  bash dist/empaquetar-alpha.sh
# Salida: dist/salida/siga98-<version>-windows.zip y ...-linux.zip
set -euo pipefail

DIST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$DIST_DIR/../backend"
CACHE_DIR="$DIST_DIR/.cache"
SALIDA_DIR="$DIST_DIR/salida"
PLANTILLAS_DIR="$DIST_DIR/plantillas"

VERSION="$(grep -A1 '<artifactId>expediente-legado</artifactId>' "$BACKEND_DIR/pom.xml" \
    | sed -n 's/.*<version>\(.*\)<\/version>.*/\1/p')"
if [ -z "$VERSION" ]; then
    echo "ERROR: no pude leer la versión del pom.xml" >&2
    exit 1
fi
echo "==> Empaquetando SIGA-98 $VERSION"

echo "==> Compilando el jar (Maven en Docker, como manda CLAUDE.md)"
docker run --rm -v "$BACKEND_DIR":/app -v /root/.m2:/root/.m2 -w /app \
    maven:3.9-eclipse-temurin-25 mvn -q package -DskipTests
JAR="$BACKEND_DIR/target/expediente-legado-$VERSION.jar"
if [ ! -f "$JAR" ]; then
    echo "ERROR: no existe $JAR tras el build" >&2
    exit 1
fi

mkdir -p "$CACHE_DIR" "$SALIDA_DIR"

# Descarga (con caché y verificación sha256) el JRE Temurin 25 de Adoptium
# para un SO dado. Deja en las variables globales JRE_PKG la ruta local.
descargar_jre() {
    local so="$1"          # windows | linux
    local api="https://api.adoptium.net/v3/assets/latest/25/hotspot?image_type=jre&os=$so&architecture=x64"
    local meta
    meta="$(curl -sf "$api")"
    local nombre link checksum
    nombre="$(echo "$meta" | python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["binary"]["package"]["name"])')"
    link="$(echo "$meta" | python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["binary"]["package"]["link"])')"
    checksum="$(echo "$meta" | python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["binary"]["package"]["checksum"])')"
    JRE_PKG="$CACHE_DIR/$nombre"
    if [ ! -f "$JRE_PKG" ]; then
        echo "==> Descargando $nombre"
        curl -sfL -o "$JRE_PKG" "$link"
    else
        echo "==> JRE en caché: $nombre"
    fi
    echo "$checksum  $JRE_PKG" | sha256sum -c --quiet
}

# Ensambla un zip para un SO: carpeta raíz con app.jar, jre/, lanzador y LEEME.
empaquetar() {
    local so="$1"
    descargar_jre "$so"

    local raiz="siga98-$VERSION-$so"
    local trabajo="$SALIDA_DIR/$raiz"
    rm -rf "$trabajo"
    mkdir -p "$trabajo"

    cp "$JAR" "$trabajo/app.jar"
    sed "s/@VERSION@/$VERSION/g" "$PLANTILLAS_DIR/LEEME.txt" > "$trabajo/LEEME.txt"

    echo "==> Extrayendo JRE ($so)"
    if [ "$so" = "windows" ]; then
        unzip -q "$JRE_PKG" -d "$trabajo"
        cp "$PLANTILLAS_DIR/INICIAR.bat" "$trabajo/INICIAR.bat"
    else
        tar -xzf "$JRE_PKG" -C "$trabajo"
        cp "$PLANTILLAS_DIR/iniciar.sh" "$trabajo/iniciar.sh"
        chmod +x "$trabajo/iniciar.sh"
    fi
    # El paquete de Adoptium trae una carpeta raíz tipo jdk-25.0.3+9-jre.
    local jredir
    jredir="$(find "$trabajo" -maxdepth 1 -type d -name 'jdk-*' | head -1)"
    if [ -z "$jredir" ]; then
        echo "ERROR: no encontré la carpeta del JRE extraído" >&2
        exit 1
    fi
    mv "$jredir" "$trabajo/jre"

    echo "==> Creando $raiz.zip"
    rm -f "$SALIDA_DIR/$raiz.zip"
    (cd "$SALIDA_DIR" && zip -qr "$raiz.zip" "$raiz")
    rm -rf "$trabajo"
}

empaquetar windows
empaquetar linux

echo "==> Listo:"
ls -lh "$SALIDA_DIR"/siga98-"$VERSION"-*.zip
