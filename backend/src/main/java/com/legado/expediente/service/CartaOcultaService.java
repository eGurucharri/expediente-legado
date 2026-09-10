package com.legado.expediente.service;

import org.springframework.lang.NonNull;
import org.springframework.stereotype.Service;
import org.springframework.web.util.HtmlUtils;

import java.util.Map;

/**
 * Ocho de las veintidós cartas de tarot no se desbloquean por progreso:
 * están escondidas como una frase concreta dentro de un documento ya
 * existente de cada expediente, igual que las pistas, pero sin backend
 * detrás — al hacer clic, el cliente cuenta un pequeño relato y ofrece
 * cuatro salidas satíricas. Aquí solo se resalta la frase; el resto vive
 * en prometeo-ui.js.
 */
@Service
public class CartaOcultaService {

    private record Anzuelo(@NonNull String fraseGatillo, @NonNull String cartaId) {
    }

    private static final Map<String, Anzuelo> CARTAS_POR_FOLIO = Map.of(
            "ACTA-1999-014", new Anzuelo("cinco minutos después de la hora de registro", "la-justicia"),
            "OF-1990-114", new Anzuelo("para su valoración y trámite correspondiente", "la-rueda"),
            "MEMO-1993-201", new Anzuelo("Preséntese el día 05/07/1993 sin excepción", "el-juicio"),
            "F-1996-00187", new Anzuelo("es de color amarillo", "la-luna"),
            "ACTA-2007-002", new Anzuelo("aproximadamente cada quince años", "el-carro"),
            "FAX-1996-077", new Anzuelo("no corresponden a ningún alfabeto reconocido", "el-sol"),
            "OF-1998-077", new Anzuelo("no ha lugar", "la-emperatriz"),
            "ACTA-1998-427B", new Anzuelo("No hubo testigos", "la-sacerdotisa")
    );

    public String aplicar(String htmlProcesado, String folio) {
        if (htmlProcesado == null || folio == null) {
            return htmlProcesado;
        }
        Anzuelo anzuelo = CARTAS_POR_FOLIO.get(folio);
        if (anzuelo == null) {
            return htmlProcesado;
        }

        String fraseEscapada = HtmlUtils.htmlEscape(anzuelo.fraseGatillo());
        int idx = htmlProcesado.indexOf(fraseEscapada);
        if (idx < 0) {
            return htmlProcesado;
        }

        String antes = htmlProcesado.substring(0, idx);
        String despues = htmlProcesado.substring(idx + fraseEscapada.length());
        String centro = "<button type=\"button\" class=\"siga-hotspot\" data-carta-oculta=\"" + anzuelo.cartaId()
                + "\">" + fraseEscapada + "</button>";
        return antes + centro + despues;
    }
}
