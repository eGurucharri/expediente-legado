package com.legado.expediente.controller;

import java.util.NoSuchElementException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

/**
 * Issue #39: los controladores usan el idioma findById(...).orElseThrow()
 * — correcto para el flujo normal, pero un id inexistente (URL manipulada,
 * enlace viejo, doble envío) acababa en el JSON de error 500 por defecto
 * de Spring, que rompe la ficción y asusta al betatester. Aquí se convierte
 * en una respuesta del propio sistema: de vuelta al índice con un aviso
 * en el registro burocrático de SIGA-98.
 */
@ControllerAdvice
public class ManejadorNoEncontrado {

    private static final Logger LOG = LoggerFactory.getLogger(ManejadorNoEncontrado.class);

    @ExceptionHandler(NoSuchElementException.class)
    public String registroNoLocalizado(NoSuchElementException excepcion,
                                       RedirectAttributes redirectAttributes) {
        LOG.debug("Búsqueda sobre id inexistente convertida en aviso: {}", excepcion.getMessage());
        redirectAttributes.addFlashAttribute("mensaje",
                "Registro no localizado en el archivo. Verifique la signatura e inténtelo de nuevo.");
        return "redirect:/";
    }
}
