package com.legado.expediente.service;

import com.legado.expediente.model.Concepto;
import com.legado.expediente.model.ConceptoTipo;
import org.junit.jupiter.api.Test;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

class WikiLinkServiceTest {

    private final WikiLinkService wikiLinkService = new WikiLinkService();

    @Test
    void renderCreatesLinksForUnlockedConceptsAndLocksUnknownOnes() {
        Concepto unlocked = new Concepto();
        unlocked.setId(11L);
        unlocked.setNombre("Comité Ad Honorem");
        unlocked.setTipo(ConceptoTipo.PERSONA);
        unlocked.setResumen("Resumen");

        Concepto locked = new Concepto();
        locked.setId(12L);
        locked.setNombre("Documento secreto");
        locked.setTipo(ConceptoTipo.DOCUMENTO);
        locked.setResumen("Resumen");

        String result = wikiLinkService.render(
                "Revisar [[Comité Ad Honorem]] y [[Documento secreto]]",
                Collections.singletonList(unlocked)
        );

        assertEquals(
                "Revisar <span class=\"wiki-link-locked\" title=\"Expediente no localizado\">Comit&eacute; Ad Honorem</span> y <span class=\"wiki-link-locked\" title=\"Expediente no localizado\">Documento secreto</span>",
                result
        );
    }

    @Test
    void renderEscapesHtmlAndPreservesReferenceText() {
        Concepto concepto = new Concepto();
        concepto.setId(7L);
        concepto.setNombre("Contrato");
        concepto.setTipo(ConceptoTipo.DOCUMENTO);
        concepto.setResumen("Resumen");

        String result = wikiLinkService.render("[[Contrato]] <b>y</b>", Collections.singletonList(concepto));

        assertEquals("<a href=\"#concepto-7\" class=\"wiki-link\">Contrato</a> &lt;b&gt;y&lt;/b&gt;", result);
    }

    @Test
    void extraerReferenciasDevuelveLosNombresEnOrdenDeAparicion() {
        List<String> nombres = wikiLinkService.extraerReferencias(
                "Visto junto a [[I. Karamázov]] y también citado por [[P. Smerdiakov]].");

        assertEquals(Arrays.asList("I. Karamázov", "P. Smerdiakov"), nombres);
    }

    @Test
    void extraerReferenciasPreservaAcentosSinPasarPorEscapadoHtml() {
        List<String> nombres = wikiLinkService.extraerReferencias("[[Comité Ad Honorem]]");

        assertEquals(Collections.singletonList("Comité Ad Honorem"), nombres);
    }

    @Test
    void extraerReferenciasDevuelveListaVaciaSinReferenciasOTextoNulo() {
        assertEquals(Collections.emptyList(), wikiLinkService.extraerReferencias("Sin referencias aquí."));
        assertEquals(Collections.emptyList(), wikiLinkService.extraerReferencias(null));
    }
}
