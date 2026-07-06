package com.legado.expediente.controller;

import com.legado.expediente.model.Concepto;
import com.legado.expediente.model.ConceptoTipo;
import com.legado.expediente.model.Descubrimiento;
import com.legado.expediente.model.Pista;
import com.legado.expediente.model.Usuario;
import com.legado.expediente.repository.CasoRepository;
import com.legado.expediente.repository.ConceptoRepository;
import com.legado.expediente.repository.DescubrimientoRepository;
import com.legado.expediente.repository.PistaRepository;
import com.legado.expediente.repository.UsuarioRepository;
import com.legado.expediente.repository.VeredictoRepository;
import com.legado.expediente.service.ProgresoService;
import com.legado.expediente.service.ResumenJuegoService;
import com.legado.expediente.service.UsuarioContexto;
import com.legado.expediente.service.WikiLinkService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.ui.ExtendedModelMap;
import org.springframework.ui.Model;

import java.lang.reflect.Proxy;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Cubre construirGrafo() (privado, ejercitado a través de carpeta()): que
 * las aristas se deduplican independientemente del sentido de la cita, que
 * las auto-referencias se ignoran y que citar un concepto todavía bloqueado
 * no genera arista.
 */
class CarpetaControllerTest {

    private final Usuario usuario = new Usuario();
    private final Authentication authentication = new UsernamePasswordAuthenticationToken("auditor01", "n/a");
    private List<Concepto> conceptosDesbloqueados;
    private CarpetaController controller;

    @BeforeEach
    void configurar() {
        usuario.setId(1L);

        UsuarioRepository usuarioRepository = fake(UsuarioRepository.class, Map.of(
                "findByUsername", args -> Optional.of(usuario)
        ));
        CasoRepository casoRepository = fake(CasoRepository.class, Map.of(
                "findAll", args -> Collections.emptyList()
        ));
        ConceptoRepository conceptoRepository = fake(ConceptoRepository.class, Map.of(
                "findByPistaIdIn", args -> conceptosDesbloqueados,
                "findByEpilogoTrue", args -> Collections.emptyList()
        ));
        DescubrimientoRepository descubrimientoRepository = fake(DescubrimientoRepository.class, Map.of(
                "findByUsuarioId", args -> List.of(descubrimiento(100L))
        ));
        PistaRepository pistaRepository = fake(PistaRepository.class, Map.of());

        ProgresoService progresoService = new ProgresoService(descubrimientoRepository, pistaRepository);
        VeredictoRepository veredictoRepository = fake(VeredictoRepository.class, Map.of(
                "findByUsuarioId", args -> Collections.emptyList()
        ));
        ResumenJuegoService resumenJuegoService = new ResumenJuegoService(casoRepository, pistaRepository,
                veredictoRepository, progresoService);

        controller = new CarpetaController(casoRepository, conceptoRepository, progresoService,
                resumenJuegoService, new WikiLinkService(), new UsuarioContexto(usuarioRepository));
    }

    @Test
    void construirGrafoDeduplicaAristasBidireccionalesYExcluyeAutorreferencias() {
        Concepto a = concepto(1L, "A", "Ligado a [[B]] y también a sí mismo, [[A]].");
        Concepto b = concepto(2L, "B", "Menciona de vuelta a [[A]].");
        conceptosDesbloqueados = List.of(a, b);

        Model model = ejecutarCarpeta();

        CarpetaController.GrafoConceptos grafo = (CarpetaController.GrafoConceptos) model.getAttribute("grafoConceptos");
        assertEquals(2, grafo.nodos().size());
        assertEquals(1, grafo.aristas().size(), "A-B y B-A deben colapsar en una sola arista");
        assertEquals(new CarpetaController.AristaGrafo(1L, 2L), grafo.aristas().get(0));
    }

    @Test
    void construirGrafoNoCreaAristaHaciaUnConceptoTodaviaBloqueado() {
        Concepto a = concepto(1L, "A", "Cita a [[Fantasma]], que nadie ha desbloqueado todavía.");
        conceptosDesbloqueados = List.of(a);

        Model model = ejecutarCarpeta();

        CarpetaController.GrafoConceptos grafo = (CarpetaController.GrafoConceptos) model.getAttribute("grafoConceptos");
        assertEquals(1, grafo.nodos().size());
        assertTrue(grafo.aristas().isEmpty());
    }

    private Model ejecutarCarpeta() {
        Model model = new ExtendedModelMap();
        controller.carpeta(authentication, model);
        return model;
    }

    private Concepto concepto(Long id, String nombre, String resumen) {
        Concepto concepto = new Concepto();
        concepto.setId(id);
        concepto.setNombre(nombre);
        concepto.setTipo(ConceptoTipo.PERSONA);
        concepto.setResumen(resumen);
        return concepto;
    }

    private Descubrimiento descubrimiento(Long pistaId) {
        Pista pista = new Pista();
        pista.setId(pistaId);
        Descubrimiento descubrimiento = new Descubrimiento();
        descubrimiento.setPista(pista);
        return descubrimiento;
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
