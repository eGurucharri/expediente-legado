#!/bin/sh
# SIGA-98 · Expediente Legado — lanzador del build alpha (Linux).
# Ctrl+C (o cerrar la terminal) para parar el juego.
cd "$(dirname "$0")" || exit 1
echo "Arrancando SIGA-98... el navegador se abrirá solo en unos segundos."
echo "Si no se abre, entra en http://localhost:1998"
echo
# Los argumentos extra van directos a Spring Boot (p. ej. si el puerto
# 1998 está ocupado:  ./iniciar.sh --server.port=2098 ).
exec ./jre/bin/java -jar app.jar --spring.profiles.active=standalone "$@"
