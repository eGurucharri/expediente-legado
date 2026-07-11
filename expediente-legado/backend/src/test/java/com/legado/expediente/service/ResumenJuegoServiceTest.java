package com.legado.expediente.service;

import com.legado.expediente.model.Caso;
import com.legado.expediente.model.Descubrimiento;
import com.legado.expediente.model.Pista;
import com.legado.expediente.model.RegistroLegado;
import com.legado.expediente.model.Rol;
import com.legado.expediente.model.Usuario;
import com.legado.expediente.model.Veredicto;
import com.legado.expediente.repository.CasoRepository;
import com.legado.expediente.repository.ConceptoRepository;
import com.legado.expediente.repository.DescubrimientoRepository;
import com.legado.expediente.repository.PistaRepository;
import com.legado.expediente.repository.VeredictoRepository;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Proxy;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * El resumen es la única fuente de verdad que la capa Prometeo (logros,
 * tarot, pistas del asistente) tiene sobre el progreso real del jugador,
 * así que sus números tienen que ser exactos: nada de progreso simulado.
 */
class ResumenJuegoServiceTest {

    private final List<Caso> casos = new ArrayList<>();
    private final Map<Long, List<Pista>> pistasPorCaso = new HashMap<>();
    private final List<Descubrimiento> descubrimientos = new ArrayList<>();
    private final List<Veredicto> veredictos = new ArrayList<>();

    private final CasoRepository casoRepository = fake(CasoRepository.class, Map.of(
            "findAll", args -> casos
    ));
    private final PistaRepository pistaRepository = fake(PistaRepository.class, Map.of(
            "findByCasoId", args -> pistasPorCaso.getOrDefault((Long) args[0], Collections.emptyList())
    ));
    private final DescubrimientoRepository descubrimientoRepository = fake(DescubrimientoRepository.class, Map.of(
            "findByUsuarioId", args -> descubrimientos
    ));
    private final VeredictoRepository veredictoRepository = fake(VeredictoRepository.class, Map.of(
            "findByUsuarioId", args -> veredictos
    ));
    private final ConceptoRepository conceptoRepository = fake(ConceptoRepository.class, Map.of(
            "findByPistaIdIn", args -> Collections.emptyList()
    ));

    private final ProgresoService progresoService = new ProgresoService(descubrimientoRepository, pistaRepository);
    private final ResumenJuegoService resumenJuegoService =
            new ResumenJuegoService(casoRepository, pistaRepository, veredictoRepository, conceptoRepository,
                    progresoService);

    @Test
    void calcularCuentaCasosResueltosPistasYVeredictosDeUnAuditorSinAccesoConfidencial() {
        Usuario auditor = usuario(Rol.AUDITOR);

        Caso resuelto = caso(1L, "Caso resuelto", true, false);
        Caso pendiente = caso(2L, "Caso pendiente", true, false);
        Caso confidencial = caso(3L, "Epílogo", false, true);
        casos.addAll(Arrays.asList(resuelto, pendiente, confidencial));

        pistasPorCaso.put(1L, Collections.singletonList(pista(100L, resuelto)));
        pistasPorCaso.put(2L, Arrays.asList(pista(200L, pendiente), pista(201L, pendiente)));
        pistasPorCaso.put(3L, Collections.singletonList(pista(300L, confidencial)));

        descubrimientos.add(descubrimiento(pista(100L, resuelto)));
        descubrimientos.add(descubrimiento(pista(200L, pendiente)));

        Veredicto veredicto = new Veredicto();
        veredicto.setCaso(resuelto);
        veredictos.add(veredicto);

        ResumenJuegoService.ResumenJuego resumen = resumenJuegoService.calcular(auditor);

        assertEquals(1, resumen.casosResueltos());
        assertEquals(2, resumen.totalCasosPrincipales());
        assertEquals(2, resumen.pistasDescubiertas());
        assertEquals(3, resumen.totalPistas(), "el caso confidencial no debe contarse para un auditor sin acceso");
        assertEquals(1, resumen.veredictosEmitidos());
        assertFalse(resumen.esAdmin());
        assertEquals(2, resumen.casos().size());
    }

    @Test
    void calcularIncluyeCasosConfidencialesYReflejaPistasPorCasoParaUnAdmin() {
        Usuario admin = usuario(Rol.ADMIN);

        Caso confidencial = caso(3L, "Epílogo", false, true);
        casos.add(confidencial);
        pistasPorCaso.put(3L, Arrays.asList(pista(300L, confidencial), pista(301L, confidencial)));
        descubrimientos.add(descubrimiento(pista(300L, confidencial)));

        ResumenJuegoService.ResumenJuego resumen = resumenJuegoService.calcular(admin);

        assertTrue(resumen.esAdmin());
        assertEquals(1, resumen.casos().size());
        ResumenJuegoService.CasoResumen resumenCaso = resumen.casos().get(0);
        assertEquals(1, resumenCaso.pistasDescubiertas());
        assertEquals(2, resumenCaso.totalPistas());
        assertFalse(resumenCaso.resuelto());
    }

    @Test
    void calcularMarcaConclusionesPendientesCuandoHayUnaCombinacionSinDescubrir() {
        Usuario auditor = usuario(Rol.AUDITOR);
        Caso caso = caso(1L, "Con combinación", true, false);
        casos.add(caso);

        RegistroLegado origen1 = new RegistroLegado();
        RegistroLegado origen2 = new RegistroLegado();
        Pista combinacion = pista(500L, caso);
        combinacion.setRegistroOrigen(origen1);
        combinacion.setRegistroOrigen2(origen2);
        pistasPorCaso.put(1L, Collections.singletonList(combinacion));

        ResumenJuegoService.ResumenJuego resumen = resumenJuegoService.calcular(auditor);

        assertTrue(resumen.casos().get(0).tieneConclusionesPendientes());
    }

    private Usuario usuario(Rol rol) {
        Usuario usuario = new Usuario();
        usuario.setId(1L);
        usuario.setRol(rol);
        return usuario;
    }

    private Caso caso(Long id, String titulo, boolean principal, boolean confidencial) {
        Caso caso = new Caso();
        caso.setId(id);
        caso.setTitulo(titulo);
        caso.setPrincipal(principal);
        caso.setConfidencial(confidencial);
        return caso;
    }

    private Pista pista(Long id, Caso caso) {
        Pista pista = new Pista();
        pista.setId(id);
        pista.setCaso(caso);
        return pista;
    }

    private Descubrimiento descubrimiento(Pista pista) {
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
