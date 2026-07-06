package com.legado.expediente.e2e;

import com.microsoft.playwright.Page;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * El mapa de conexiones (issue #11) es una simulación de fuerzas 100%
 * cliente (concept-graph.js): ningún curl puede confirmar que el SVG
 * termina relleno de nodos tras pulsar el botón.
 *
 * <p>Autocontenida a propósito: no asume progreso previo de auditor01 (que
 * "nueva partida" puede borrar en cualquier momento, incluido durante otros
 * E2E). Descubre dos pistas del caso 7 (herencia Karamázov), el único con
 * conceptos asociados a más de una pista, antes de comprobar el grafo.</p>
 */
class MapaConexionesE2E {

    private static final long CASO_CON_CONCEPTOS = 7L;

    private PlaywrightSoporte soporte;

    @BeforeEach
    void arrancar() {
        soporte = new PlaywrightSoporte();
        soporte.iniciarSesion("auditor01", "auditor-local-123");
    }

    @AfterEach
    void parar() {
        soporte.close();
    }

    @Test
    void elBotonDeMapaRellenaElSvgConNodos() {
        Page pagina = soporte.pagina();
        descubrirDosPistas(pagina);

        pagina.navigate(PlaywrightSoporte.BASE_URL + "/carpeta");
        pagina.waitForSelector("#prometeo-grafo-toggle:not([hidden])",
                new Page.WaitForSelectorOptions().setTimeout(3000));
        pagina.click("#prometeo-grafo-toggle");

        pagina.waitForSelector("#prometeo-grafo-svg .prometeo-grafo-nodo",
                new Page.WaitForSelectorOptions().setTimeout(3000));
        int nodos = pagina.locator("#prometeo-grafo-svg .prometeo-grafo-nodo").count();

        assertTrue(nodos > 0, "el SVG debería tener al menos un nodo tras pulsar el botón");
    }

    private void descubrirDosPistas(Page pagina) {
        pagina.navigate(PlaywrightSoporte.BASE_URL + "/casos/" + CASO_CON_CONCEPTOS);
        for (int i = 0; i < 2; i++) {
            pagina.locator(".siga-hotspot").first().click();
            pagina.waitForURL("**/casos/" + CASO_CON_CONCEPTOS);
        }
    }
}
