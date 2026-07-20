@echo off
rem SIGA-98 · Expediente Legado — lanzador del build alpha (Windows).
rem Cierra esta ventana para parar el juego.
title SIGA-98 - Expediente Legado (cierra esta ventana para salir)
cd /d "%~dp0"
echo Arrancando SIGA-98... el navegador se abrira solo en unos segundos.
echo Si no se abre, entra en http://localhost:1998
echo.
rem Los argumentos extra van directos a Spring Boot (p. ej. si el puerto
rem 1998 esta ocupado:  INICIAR.bat --server.port=2098 ).
"jre\bin\java.exe" -jar app.jar --spring.profiles.active=standalone %*
pause
