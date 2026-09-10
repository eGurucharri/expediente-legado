package com.legado.expediente.e2e;

import com.microsoft.playwright.Page;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Confirma con un navegador real lo que arregló el issue #6: sin esto,
 * ningún test podía probar que Tab de verdad se quede dentro del modal
 * en vez de escaparse a la página de fondo. El modal del jefe aparece
 * solo (~400ms) en la primera visita de un contexto de navegador nuevo,
 * así que es el más determinista para esta prueba.
 */
class ModalesFocoE2E {

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
    void elModalDelJefeAtrapaElFocoConTab() {
        Page pagina = soporte.pagina();
        pagina.waitForSelector("#prometeo-jefe:not([hidden])",
                new Page.WaitForSelectorOptions().setTimeout(3000));

        Boolean focoInicialDentro = (Boolean) pagina.evaluate(
                "document.getElementById('prometeo-jefe').contains(document.activeElement)");
        assertTrue(focoInicialDentro, "al abrirse, el foco debería moverse dentro del modal");

        pagina.keyboard().press("Tab");

        Boolean focoTrasTabDentro = (Boolean) pagina.evaluate(
                "document.getElementById('prometeo-jefe').contains(document.activeElement)");
        assertTrue(focoTrasTabDentro, "Tab no debería sacar el foco del modal mientras está abierto");
    }
}
