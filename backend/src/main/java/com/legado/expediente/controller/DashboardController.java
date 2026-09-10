package com.legado.expediente.controller;

import com.legado.expediente.model.Rol;
import com.legado.expediente.model.Usuario;
import com.legado.expediente.repository.CasoRepository;
import com.legado.expediente.service.ProgresoService;
import com.legado.expediente.service.ResumenJuegoService;
import com.legado.expediente.service.UsuarioContexto;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import java.util.Set;

@Controller
public class DashboardController {

    private final CasoRepository casoRepository;
    private final ProgresoService progresoService;
    private final ResumenJuegoService resumenJuegoService;
    private final UsuarioContexto usuarioContexto;

    public DashboardController(CasoRepository casoRepository,
                                ProgresoService progresoService,
                                ResumenJuegoService resumenJuegoService,
                                UsuarioContexto usuarioContexto) {
        this.casoRepository = casoRepository;
        this.progresoService = progresoService;
        this.resumenJuegoService = resumenJuegoService;
        this.usuarioContexto = usuarioContexto;
    }

    @GetMapping("/")
    public String dashboard(Authentication authentication, Model model) {
        Usuario usuario = usuarioContexto.actual(authentication);
        Set<Long> descubiertas = progresoService.pistasDescubiertas(usuario);

        var casosVisibles = casoRepository.findAll().stream()
                .filter(c -> !c.isConfidencial() || usuario.getRol() == Rol.ADMIN)
                .toList();

        model.addAttribute("casos", progresoService.progreso(casosVisibles, descubiertas));
        model.addAttribute("rutaActual", "/");
        model.addAttribute("ultimoGuardado", usuario.getUltimoGuardado());
        model.addAttribute("estadoJuego", resumenJuegoService.calcular(usuario));
        return "dashboard";
    }
}
