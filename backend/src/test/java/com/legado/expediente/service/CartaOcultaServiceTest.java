package com.legado.expediente.service;

import org.junit.jupiter.api.Test;
import org.springframework.web.util.HtmlUtils;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * aplicar() siempre recibe HTML que ya pasó por HotspotService (y por
 * tanto ya está escapado con HtmlUtils.htmlEscape, que convierte acentos
 * en entidades como "&eacute;"). Los casos con acentos simulan ese
 * preescapado para reflejar el uso real desde CasoController.
 */
class CartaOcultaServiceTest {

    private final CartaOcultaService cartaOcultaService = new CartaOcultaService();

    @Test
    void aplicarResaltaLaFraseCuandoElFolioTieneUnaCartaAsignada() {
        String resultado = cartaOcultaService.aplicar(
                "Se determinó que #427 abandonó el inmueble. No hubo testigos. Cierre del expediente.",
                "ACTA-1998-427B");

        assertEquals("Se determinó que #427 abandonó el inmueble. "
                + "<button type=\"button\" class=\"siga-hotspot\" data-carta-oculta=\"la-sacerdotisa\">"
                + "No hubo testigos</button>. Cierre del expediente.", resultado);
    }

    @Test
    void aplicarResaltaFrasesConAcentosSobreHtmlYaEscapadoPorHotspotService() {
        String htmlYaEscapado = HtmlUtils.htmlEscape(
                "Firmada el mismo día, cinco minutos después de la hora de registro de la factura.");

        String resultado = cartaOcultaService.aplicar(htmlYaEscapado, "ACTA-1999-014");

        assertTrue(resultado.contains("data-carta-oculta=\"la-justicia\""));
        assertTrue(resultado.contains(HtmlUtils.htmlEscape("cinco minutos después de la hora de registro")));
    }

    @Test
    void aplicarDejaElHtmlSinCambiosCuandoElFolioNoTieneCartaAsignada() {
        String html = "Contenido de un documento cualquiera.";

        assertSame(html, cartaOcultaService.aplicar(html, "FOLIO-INEXISTENTE"));
    }

    @Test
    void aplicarDejaElHtmlSinCambiosCuandoLaFraseNoApareceEnElContenido() {
        String html = "Este documento no menciona nada relevante.";

        assertSame(html, cartaOcultaService.aplicar(html, "ACTA-1999-014"));
    }

    @Test
    void aplicarToleraFolioONulos() {
        assertEquals("texto", cartaOcultaService.aplicar("texto", null));
        assertNull(cartaOcultaService.aplicar(null, "ACTA-1999-014"));
    }
}
