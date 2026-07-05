package com.legado.expediente.service;

import com.legado.expediente.model.Usuario;
import com.legado.expediente.repository.UsuarioRepository;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;

@Service
public class UsuarioContexto {

    private final UsuarioRepository usuarioRepository;

    public UsuarioContexto(UsuarioRepository usuarioRepository) {
        this.usuarioRepository = usuarioRepository;
    }

    public Usuario actual(Authentication authentication) {
        if (authentication == null) {
            throw new IllegalArgumentException("No hay autenticación activa");
        }
        Usuario usuario = usuarioRepository.findByUsername(authentication.getName()).orElse(null);
        if (usuario == null) {
            throw new IllegalArgumentException("Usuario no encontrado");
        }
        return usuario;
    }
}
