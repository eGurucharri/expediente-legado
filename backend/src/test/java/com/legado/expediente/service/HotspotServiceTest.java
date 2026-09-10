package com.legado.expediente.service;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class HotspotServiceTest {

    private final HotspotService hotspotService = new HotspotService();

    @Test
    void renderReturnsEscapedContentWhenNoTriggerPhraseIsProvided() {
        String result = hotspotService.render("Texto <b>importante</b>", null, 7L, false);

        assertEquals("Texto &lt;b&gt;importante&lt;/b&gt;", result);
    }

    @Test
    void renderHighlightsPhraseAsButtonWhenNotDiscovered() {
        String result = hotspotService.render("Revisar el documento y encontrar la pista", "pista", 42L, false);

        assertEquals("Revisar el documento y encontrar la <button type=\"submit\" form=\"form-pista-42\" class=\"siga-hotspot\">pista</button>", result);
    }

    @Test
    void renderHighlightsPhraseAsReadMarkerWhenAlreadyDiscovered() {
        String result = hotspotService.render("La pista ya fue descubierta", "pista", 99L, true);

        assertEquals("La <mark class=\"siga-hotspot-visto\">pista</mark> ya fue descubierta", result);
    }

    @Test
    void renderLeavesContentUnchangedWhenTriggerPhraseIsNotFound() {
        String result = hotspotService.render("Contenido de ejemplo", "no-existe", 1L, true);

        assertEquals("Contenido de ejemplo", result);
    }
}
