package com.legado.expediente.config;

import java.awt.Desktop;
import java.io.IOException;
import java.net.URI;
import java.util.Locale;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.annotation.Profile;
import org.springframework.context.event.EventListener;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

/**
 * Solo en el build standalone (alpha para betatesters, issue #36): abre el
 * navegador del jugador cuando la aplicación termina de arrancar, para que
 * el lanzador del zip sea una sola línea sin scripting frágil de "esperar
 * al puerto". Si no puede (entorno sin escritorio, Linux sin integración
 * AWT), lo dice por consola con la URL para abrirla a mano.
 */
@Component
@Profile("standalone")
public class NavegadorStandalone {

    private static final Logger LOG = LoggerFactory.getLogger(NavegadorStandalone.class);

    private final Environment environment;

    public NavegadorStandalone(Environment environment) {
        this.environment = environment;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void abrirNavegador() {
        String puerto = environment.getProperty("local.server.port",
                environment.getProperty("server.port", "1998"));
        String url = "http://localhost:" + puerto;
        LOG.info("SIGA-98 listo. Si el navegador no se abre solo, entre en {}", url);
        if (Desktop.isDesktopSupported() && Desktop.getDesktop().isSupported(Desktop.Action.BROWSE)) {
            try {
                Desktop.getDesktop().browse(URI.create(url));
                return;
            } catch (IOException e) {
                LOG.warn("No se pudo abrir el navegador via Desktop: {}", e.getMessage());
            }
        }
        // Plan B para Linux sin integración AWT de escritorio: xdg-open.
        String so = System.getProperty("os.name", "").toLowerCase(Locale.ROOT);
        if (so.contains("linux")) {
            try {
                // Descartar salida/errores: si xdg-open escribiese lo bastante
                // para llenar el buffer de una tubería sin drenar, se quedaría
                // bloqueado. No esperamos al proceso (abre y termina solo).
                new ProcessBuilder("xdg-open", url)
                        .redirectOutput(ProcessBuilder.Redirect.DISCARD)
                        .redirectError(ProcessBuilder.Redirect.DISCARD)
                        .start();
            } catch (IOException e) {
                LOG.info("Abra el juego a mano en {}", url);
            }
        }
    }
}
