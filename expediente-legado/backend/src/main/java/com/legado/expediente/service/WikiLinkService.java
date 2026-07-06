package com.legado.expediente.service;

import com.legado.expediente.model.Concepto;
import org.springframework.stereotype.Service;
import org.springframework.web.util.HtmlUtils;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Convierte las referencias {@code [[Nombre del concepto]]} dentro del
 * resumen de un {@link Concepto} en hipervínculos del corcho de
 * investigación. Si el concepto citado todavía no lo ha desbloqueado el
 * usuario, el nombre se muestra sin enlazar, como una entrada pendiente.
 */
@Service
public class WikiLinkService {

    private static final Pattern REFERENCIA = Pattern.compile("\\[\\[([^\\[\\]]+)]]");

    /**
     * Nombres citados entre dobles corchetes en el texto crudo (sin escapar
     * ni resolver si están desbloqueados), en el orden en que aparecen.
     * Sirve para construir el grafo de conexiones del corcho.
     */
    public List<String> extraerReferencias(String textoCrudo) {
        String texto = textoCrudo == null ? "" : textoCrudo;
        Matcher matcher = REFERENCIA.matcher(texto);
        List<String> nombres = new ArrayList<>();
        while (matcher.find()) {
            nombres.add(matcher.group(1));
        }
        return nombres;
    }

    public String render(String textoCrudo, List<Concepto> conceptosDesbloqueados) {
        String textoSeguro = textoCrudo == null ? "" : textoCrudo;
        Map<String, Long> idsPorNombre = new HashMap<>();
        for (Concepto concepto : conceptosDesbloqueados) {
            if (concepto != null && concepto.getNombre() != null) {
                // La clave debe estar escapada igual que el texto en el que se busca
                // (más abajo): si no, un nombre con tilde (é → &eacute;) nunca coincide
                // y el concepto se muestra siempre como bloqueado aunque esté desbloqueado.
                idsPorNombre.putIfAbsent(HtmlUtils.htmlEscape(concepto.getNombre()), concepto.getId());
            }
        }

        String textoEscapado = HtmlUtils.htmlEscape(textoSeguro);
        Matcher matcher = REFERENCIA.matcher(textoEscapado);
        StringBuffer resultado = new StringBuffer();
        while (matcher.find()) {
            String nombre = matcher.group(1);
            Long id = idsPorNombre.get(nombre);
            String reemplazo = id != null
                    ? "<a href=\"#concepto-" + id + "\" class=\"wiki-link\">" + nombre + "</a>"
                    : "<span class=\"wiki-link-locked\" title=\"Expediente no localizado\">" + nombre + "</span>";
            matcher.appendReplacement(resultado, Matcher.quoteReplacement(reemplazo));
        }
        matcher.appendTail(resultado);
        return resultado.toString();
    }
}
