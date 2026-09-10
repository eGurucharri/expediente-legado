package com.legado.expediente.controller;

import com.legado.expediente.model.Usuario;
import com.legado.expediente.repository.CombateEnCursoRepository;
import com.legado.expediente.repository.DescubrimientoRepository;
import com.legado.expediente.repository.UsuarioRepository;
import com.legado.expediente.repository.VeredictoRepository;
import com.legado.expediente.service.UsuarioContexto;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.lang.reflect.Proxy;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * "Nueva partida" debe borrar el progreso Y cerrar la sesión (issue #3):
 * antes solo reiniciaba el progreso y volvía a la misma ruta, dejando al
 * usuario todavía autenticado.
 */
class MenuControllerTest {

    private final Usuario usuario = new Usuario();
    private final Authentication authentication = new UsernamePasswordAuthenticationToken("auditor01", "n/a");
    private final List<Long> descubrimientosBorrados = new ArrayList<>();
    private final List<Long> veredictosBorrados = new ArrayList<>();
    private final List<Long> combatesBorrados = new ArrayList<>();
    private MenuController controller;

    @BeforeEach
    void configurar() {
        usuario.setId(1L);
        SecurityContextHolder.getContext().setAuthentication(authentication);

        UsuarioRepository usuarioRepository = fake(UsuarioRepository.class, Map.of(
                "findByUsername", args -> Optional.of(usuario)
        ));
        DescubrimientoRepository descubrimientoRepository = fake(DescubrimientoRepository.class, Map.of(
                "deleteByUsuarioId", args -> {
                    descubrimientosBorrados.add((Long) args[0]);
                    return null;
                }
        ));
        VeredictoRepository veredictoRepository = fake(VeredictoRepository.class, Map.of(
                "deleteByUsuarioId", args -> {
                    veredictosBorrados.add((Long) args[0]);
                    return null;
                }
        ));
        CombateEnCursoRepository combateEnCursoRepository = fake(CombateEnCursoRepository.class, Map.of(
                "deleteByUsuarioId", args -> {
                    combatesBorrados.add((Long) args[0]);
                    return null;
                }
        ));

        controller = new MenuController(usuarioRepository, descubrimientoRepository, veredictoRepository,
                combateEnCursoRepository, new UsuarioContexto(usuarioRepository));
    }

    @AfterEach
    void limpiar() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void nuevaPartidaBorraElProgresoYRedirigeALoginCerrandoSesion() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();
        org.springframework.mock.web.MockHttpSession session = new org.springframework.mock.web.MockHttpSession();
        request.setSession(session);

        String vista = controller.nuevaPartida(authentication, request, response);

        assertEquals("redirect:/login?reiniciado", vista);
        assertEquals(List.of(1L), descubrimientosBorrados);
        assertEquals(List.of(1L), veredictosBorrados);
        assertEquals(List.of(1L), combatesBorrados);
        assertTrue(session.isInvalid(), "la sesión debe invalidarse al reiniciar la partida");
        assertNull(SecurityContextHolder.getContext().getAuthentication());
    }

    @SuppressWarnings("unchecked")
    private <T> T fake(Class<T> tipo, Map<String, java.util.function.Function<Object[], Object>> handlers) {
        return (T) Proxy.newProxyInstance(tipo.getClassLoader(), new Class<?>[]{tipo}, (proxy, method, args) -> {
            if ("toString".equals(method.getName())) {
                return "Fake" + tipo.getSimpleName();
            }
            java.util.function.Function<Object[], Object> handler = handlers.get(method.getName());
            if (handler != null) {
                return handler.apply(args);
            }
            return defaultValue(method.getReturnType());
        });
    }

    private Object defaultValue(Class<?> returnType) {
        if (returnType == boolean.class) {
            return false;
        }
        if (returnType == int.class) {
            return 0;
        }
        if (returnType == long.class) {
            return 0L;
        }
        return null;
    }
}
