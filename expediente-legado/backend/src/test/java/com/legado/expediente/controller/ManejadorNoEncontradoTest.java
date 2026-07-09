package com.legado.expediente.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.NoSuchElementException;
import org.junit.jupiter.api.Test;
import org.springframework.web.servlet.mvc.support.RedirectAttributesModelMap;

class ManejadorNoEncontradoTest {

    @Test
    void unIdInexistenteRedirigeAlIndiceConAvisoEnVezDe500() {
        ManejadorNoEncontrado manejador = new ManejadorNoEncontrado();
        RedirectAttributesModelMap redirectAttributes = new RedirectAttributesModelMap();

        String vista = manejador.registroNoLocalizado(
                new NoSuchElementException("No value present"), redirectAttributes);

        assertEquals("redirect:/", vista);
        assertEquals("Registro no localizado en el archivo. Verifique la signatura e inténtelo de nuevo.",
                redirectAttributes.getFlashAttributes().get("mensaje"));
    }
}
