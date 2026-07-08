package com.legado.expediente.controller;

import com.legado.expediente.model.Caso;
import com.legado.expediente.model.CombateEnCurso;
import com.legado.expediente.model.Sospechoso;
import com.legado.expediente.model.Usuario;
import com.legado.expediente.repository.CombateEnCursoRepository;
import com.legado.expediente.repository.SospechosoRepository;
import com.legado.expediente.repository.UsuarioRepository;
import com.legado.expediente.repository.VeredictoRepository;
import com.legado.expediente.service.UsuarioContexto;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.web.servlet.mvc.support.RedirectAttributesModelMap;

import java.lang.reflect.Proxy;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Cubre la lógica de acusar() que decide entre veredicto directo, combate,
 * y la señal "accionReciente" que el cliente usa para juzgar si la
 * acusación estuvo respaldada por evidencia suficiente.
 */
class CasoControllerTest {

    private static final Long CASO_ID = 10L;
    private static final Long USUARIO_ID = 1L;

    private final Map<Long, com.legado.expediente.model.Veredicto> veredictosPorCaso = new HashMap<>();
    private final Map<Long, CombateEnCurso> combatesPorCaso = new HashMap<>();
    private final Map<Long, Sospechoso> sospechosos = new HashMap<>();
    private final List<CombateEnCurso> combatesGuardados = new ArrayList<>();

    private final Usuario usuario = new Usuario();
    private final Authentication authentication = new UsernamePasswordAuthenticationToken("auditor01", "n/a");

    private CasoController controller;

    @BeforeEach
    void configurar() {
        usuario.setId(USUARIO_ID);

        UsuarioRepository usuarioRepository = fake(UsuarioRepository.class, Map.of(
                "findByUsername", args -> Optional.of(usuario)
        ));
        VeredictoRepository veredictoRepository = fake(VeredictoRepository.class, Map.of(
                "findByUsuarioIdAndCasoId", args -> Optional.ofNullable(veredictosPorCaso.get((Long) args[1])),
                "save", args -> {
                    com.legado.expediente.model.Veredicto v = (com.legado.expediente.model.Veredicto) args[0];
                    veredictosPorCaso.put(CASO_ID, v);
                    return v;
                }
        ));
        CombateEnCursoRepository combateEnCursoRepository = fake(CombateEnCursoRepository.class, Map.of(
                "findByUsuarioIdAndCasoId", args -> Optional.ofNullable(combatesPorCaso.get((Long) args[1])),
                "save", args -> {
                    CombateEnCurso c = (CombateEnCurso) args[0];
                    combatesPorCaso.put(CASO_ID, c);
                    combatesGuardados.add(c);
                    return c;
                },
                "delete", args -> {
                    combatesPorCaso.remove(CASO_ID);
                    return null;
                }
        ));
        SospechosoRepository sospechosoRepository = fake(SospechosoRepository.class, Map.of(
                "findById", args -> Optional.ofNullable(sospechosos.get((Long) args[0]))
        ));

        controller = new CasoController(null, null, null, null, sospechosoRepository, veredictoRepository,
                combateEnCursoRepository, null, null, new UsuarioContexto(usuarioRepository), null, null);
    }

    @Test
    void acusarSospechosoSinAtaquesRegistraVeredictoDirectoYMarcaAccionReciente() {
        sospechosos.put(5L, sospechoso(5L, Arrays.asList()));
        RedirectAttributesModelMap redirectAttributes = new RedirectAttributesModelMap();

        String vista = controller.acusar(CASO_ID, 5L, authentication, redirectAttributes);

        assertEquals("redirect:/casos/" + CASO_ID, vista);
        assertTrue(veredictosPorCaso.containsKey(CASO_ID));
        assertTrue(combatesGuardados.isEmpty());
        assertEquals("acusacion", redirectAttributes.getFlashAttributes().get("accionReciente"));
    }

    @Test
    void acusarSospechosoConAtaquesIniciaCombateEnLugarDeVeredicto() {
        sospechosos.put(6L, sospechoso(6L, Arrays.asList("Primer ataque", "Segundo ataque")));
        RedirectAttributesModelMap redirectAttributes = new RedirectAttributesModelMap();

        controller.acusar(CASO_ID, 6L, authentication, redirectAttributes);

        assertFalse(veredictosPorCaso.containsKey(CASO_ID));
        assertEquals(1, combatesGuardados.size());
        assertEquals("acusacion", redirectAttributes.getFlashAttributes().get("accionReciente"));
    }

    @Test
    void finalizarCombateRegistraVeredictoYBorraElCombateGaneOPierdaElJugador() {
        Sospechoso sospechoso = sospechoso(6L, Arrays.asList("Primer ataque", "Segundo ataque"));
        CombateEnCurso combate = new CombateEnCurso();
        combate.setUsuario(usuario);
        combate.setSospechoso(sospechoso);
        combatesPorCaso.put(CASO_ID, combate);

        String vista = controller.finalizarCombate(CASO_ID, authentication);

        assertEquals("redirect:/casos/" + CASO_ID, vista);
        assertTrue(veredictosPorCaso.containsKey(CASO_ID));
        assertEquals(sospechoso, veredictosPorCaso.get(CASO_ID).getSospechoso());
        assertFalse(combatesPorCaso.containsKey(CASO_ID));
    }

    @Test
    void acusarDeNuevoCuandoYaHayVeredictoNoHaceNadaNiMarcaAccionReciente() {
        com.legado.expediente.model.Veredicto existente = new com.legado.expediente.model.Veredicto();
        veredictosPorCaso.put(CASO_ID, existente);
        sospechosos.put(5L, sospechoso(5L, Arrays.asList()));
        RedirectAttributesModelMap redirectAttributes = new RedirectAttributesModelMap();

        controller.acusar(CASO_ID, 5L, authentication, redirectAttributes);

        assertEquals(existente, veredictosPorCaso.get(CASO_ID));
        assertTrue(combatesGuardados.isEmpty());
        assertNull(redirectAttributes.getFlashAttributes().get("accionReciente"));
    }

    private Sospechoso sospechoso(Long id, List<String> ataques) {
        Sospechoso sospechoso = new Sospechoso();
        sospechoso.setId(id);
        sospechoso.setCaso(new Caso());
        sospechoso.setAtaques(ataques);
        return sospechoso;
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
