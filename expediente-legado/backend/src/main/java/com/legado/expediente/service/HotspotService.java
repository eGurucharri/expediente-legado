package com.legado.expediente.service;

import org.springframework.stereotype.Service;
import org.springframework.web.util.HtmlUtils;

/**
 * Convierte el contenido de un registro en HTML seguro donde la frase
 * gatillo de su pista queda resaltada: como botón clicable si aún no se
 * ha descubierto, o como una marca ya "leída" si ya se descubrió. Sin
 * esto, descubrir una pista era pulsar un botón genérico separado del
 * documento; con esto, es notar una frase concreta dentro del propio
 * documento.
 */
@Service
public class HotspotService {

    public String render(String contenido, String fraseGatillo, Long pistaId, boolean descubierta) {
        String textoSeguro = contenido == null ? "" : contenido;
        String escapado = HtmlUtils.htmlEscape(textoSeguro);
        if (fraseGatillo == null || fraseGatillo.trim().isEmpty()) {
            return escapado;
        }

        String fraseEscapada = HtmlUtils.htmlEscape(fraseGatillo);
        int idx = escapado.indexOf(fraseEscapada);
        if (idx < 0) {
            return escapado;
        }

        String antes = escapado.substring(0, idx);
        String despues = escapado.substring(idx + fraseEscapada.length());
        String centro = descubierta
                ? "<mark class=\"siga-hotspot-visto\">" + fraseEscapada + "</mark>"
                : "<button type=\"submit\" form=\"form-pista-" + pistaId + "\" class=\"siga-hotspot\">"
                        + fraseEscapada + "</button>";
        return antes + centro + despues;
    }
}
