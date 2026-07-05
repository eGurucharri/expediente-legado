package com.legado.expediente.controller;

import com.legado.expediente.model.Caso;
import com.legado.expediente.model.Concepto;
import com.legado.expediente.model.Usuario;
import com.legado.expediente.repository.CasoRepository;
import com.legado.expediente.repository.ConceptoRepository;
import com.legado.expediente.service.ProgresoService;
import com.legado.expediente.service.ResumenJuegoService;
import com.legado.expediente.service.UsuarioContexto;
import com.legado.expediente.service.WikiLinkService;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Set;

@Controller
public class CarpetaController {

    private final CasoRepository casoRepository;
    private final ConceptoRepository conceptoRepository;
    private final ProgresoService progresoService;
    private final ResumenJuegoService resumenJuegoService;
    private final WikiLinkService wikiLinkService;
    private final UsuarioContexto usuarioContexto;

    public CarpetaController(CasoRepository casoRepository,
                              ConceptoRepository conceptoRepository,
                              ProgresoService progresoService,
                              ResumenJuegoService resumenJuegoService,
                              WikiLinkService wikiLinkService,
                              UsuarioContexto usuarioContexto) {
        this.casoRepository = casoRepository;
        this.conceptoRepository = conceptoRepository;
        this.progresoService = progresoService;
        this.resumenJuegoService = resumenJuegoService;
        this.wikiLinkService = wikiLinkService;
        this.usuarioContexto = usuarioContexto;
    }

    public record ConceptoVista(Concepto concepto, String resumenHtml) {
    }

    @GetMapping("/carpeta")
    public String carpeta(Authentication authentication, Model model) {
        Usuario usuario = usuarioContexto.actual(authentication);
        Set<Long> descubiertas = progresoService.pistasDescubiertas(usuario);

        var casosBase = casoRepository.findAll().stream()
                .filter(c -> !c.isConfidencial())
                .toList();
        var casosPrincipales = casosBase.stream().filter(Caso::isPrincipal).toList();
        boolean todosResueltos = progresoService.todosResueltos(casosPrincipales, descubiertas);

        List<Concepto> desbloqueados = new ArrayList<>(descubiertas.isEmpty()
                ? List.of()
                : conceptoRepository.findByPistaIdIn(new ArrayList<>(descubiertas)));
        if (todosResueltos) {
            desbloqueados.addAll(conceptoRepository.findByEpilogoTrue());
        }
        desbloqueados.sort(Comparator.comparing(Concepto::getTipo).thenComparing(Concepto::getNombre));

        List<ConceptoVista> conceptos = desbloqueados.stream()
                .map(c -> new ConceptoVista(c, wikiLinkService.render(c.getResumen(), desbloqueados)))
                .toList();

        model.addAttribute("conceptos", conceptos);
        model.addAttribute("progreso", progresoService.progreso(casosBase, descubiertas));
        model.addAttribute("todosResueltos", todosResueltos);
        model.addAttribute("rutaActual", "/carpeta");
        model.addAttribute("ultimoGuardado", usuario.getUltimoGuardado());
        model.addAttribute("estadoJuego", resumenJuegoService.calcular(usuario));
        return "carpeta";
    }
}
