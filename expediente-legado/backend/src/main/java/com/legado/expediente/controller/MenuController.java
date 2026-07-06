package com.legado.expediente.controller;

import com.legado.expediente.model.Usuario;
import com.legado.expediente.repository.CombateEnCursoRepository;
import com.legado.expediente.repository.DescubrimientoRepository;
import com.legado.expediente.repository.UsuarioRepository;
import com.legado.expediente.repository.VeredictoRepository;
import com.legado.expediente.service.UsuarioContexto;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.Authentication;
import org.springframework.security.web.authentication.logout.SecurityContextLogoutHandler;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.time.LocalDateTime;

/**
 * Acciones del menú "de verdad" (Prometeo): a diferencia de SIGA-98, esto no
 * finge estar accesible, lo está.
 */
@Controller
public class MenuController {

    private final UsuarioRepository usuarioRepository;
    private final DescubrimientoRepository descubrimientoRepository;
    private final VeredictoRepository veredictoRepository;
    private final CombateEnCursoRepository combateEnCursoRepository;
    private final UsuarioContexto usuarioContexto;

    public MenuController(UsuarioRepository usuarioRepository,
                           DescubrimientoRepository descubrimientoRepository,
                           VeredictoRepository veredictoRepository,
                           CombateEnCursoRepository combateEnCursoRepository,
                           UsuarioContexto usuarioContexto) {
        this.usuarioRepository = usuarioRepository;
        this.descubrimientoRepository = descubrimientoRepository;
        this.veredictoRepository = veredictoRepository;
        this.combateEnCursoRepository = combateEnCursoRepository;
        this.usuarioContexto = usuarioContexto;
    }

    @PostMapping("/menu/guardar")
    public String guardar(@RequestParam(defaultValue = "/") String volver,
                           Authentication authentication, RedirectAttributes redirectAttributes) {
        Usuario usuario = usuarioContexto.actual(authentication);
        usuario.setUltimoGuardado(LocalDateTime.now());
        usuarioRepository.save(usuario);
        redirectAttributes.addFlashAttribute("mensaje", "Progreso guardado.");
        return "redirect:" + rutaSegura(volver);
    }

    @PostMapping("/menu/nueva-partida")
    public String nuevaPartida(Authentication authentication, HttpServletRequest request, HttpServletResponse response) {
        Usuario usuario = usuarioContexto.actual(authentication);
        descubrimientoRepository.deleteByUsuarioId(usuario.getId());
        veredictoRepository.deleteByUsuarioId(usuario.getId());
        combateEnCursoRepository.deleteByUsuarioId(usuario.getId());
        new SecurityContextLogoutHandler().logout(request, response, authentication);
        return "redirect:/login?reiniciado";
    }

    private String rutaSegura(String ruta) {
        if (ruta == null || !ruta.startsWith("/") || ruta.startsWith("//")) {
            return "/";
        }
        return ruta;
    }
}
