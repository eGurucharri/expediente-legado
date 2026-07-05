package com.legado.expediente.service;

import com.legado.expediente.model.Caso;
import com.legado.expediente.model.Descubrimiento;
import com.legado.expediente.model.Pista;
import com.legado.expediente.model.Usuario;
import com.legado.expediente.repository.DescubrimientoRepository;
import com.legado.expediente.repository.PistaRepository;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Proxy;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;


import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ProgresoServiceTest {

    private final Map<Long, List<Descubrimiento>> descubrimientosByUser = new HashMap<>();
    private final Map<Long, List<Pista>> pistasPorCaso = new HashMap<>();
    private final DescubrimientoRepository descubrimientoRepository = repositoryConFindByUsuarioId(descubrimientosByUser);
    private final PistaRepository pistaRepository = repositoryConFindByCasoId(pistasPorCaso);
    private final ProgresoService progresoService = new ProgresoService(descubrimientoRepository, pistaRepository);

    @Test
    void pistasDescubiertasReturnsOnlyDiscoveredIds() {
        Usuario usuario = new Usuario();
        usuario.setId(4L);

        Descubrimiento descubrimiento = new Descubrimiento();
        Pista pista = new Pista();
        pista.setId(11L);
        descubrimiento.setPista(pista);
        descubrimientosByUser.put(4L, Collections.singletonList(descubrimiento));

        assertEquals(new HashSet<>(Collections.singletonList(11L)), progresoService.pistasDescubiertas(usuario));
    }

    @Test
    void casoResueltoReturnsTrueOnlyWhenAllPistasAreDiscovered() {
        Pista pista1 = new Pista();
        pista1.setId(1L);
        Pista pista2 = new Pista();
        pista2.setId(2L);

        pistasPorCaso.put(10L, Arrays.asList(pista1, pista2));

        assertTrue(progresoService.casoResuelto(10L, new HashSet<>(Arrays.asList(1L, 2L))));
        assertFalse(progresoService.casoResuelto(10L, new HashSet<>(Collections.singletonList(1L))));
    }

    @Test
    void todosResueltosRequiresNonEmptyCaseListAndAllCasesClosed() {
        Caso caso1 = new Caso();
        caso1.setId(1L);
        Caso caso2 = new Caso();
        caso2.setId(2L);

        pistasPorCaso.put(1L, Collections.singletonList(pista(1L)));
        pistasPorCaso.put(2L, Collections.singletonList(pista(2L)));

        assertTrue(progresoService.todosResueltos(Arrays.asList(caso1, caso2), new HashSet<>(Arrays.asList(1L, 2L))));
        assertFalse(progresoService.todosResueltos(Collections.emptyList(), new HashSet<>(Arrays.asList(1L, 2L))));
        assertTrue(progresoService.todosResueltos(Collections.singletonList(caso1), new HashSet<>(Collections.singletonList(1L))));
    }

    @Test
    void progresoBuildsCaseProgressSummary() {
        Caso caso = new Caso();
        caso.setId(5L);

        pistasPorCaso.put(5L, Arrays.asList(pista(1L), pista(2L)));

        List<ProgresoService.CasoProgreso> result = progresoService.progreso(Collections.singletonList(caso), new HashSet<>(Collections.singletonList(1L)));

        assertEquals(1, result.size());
        assertEquals(2, result.get(0).totalPistas());
        assertEquals(1, result.get(0).pistasDescubiertas());
        assertFalse(result.get(0).resuelto());
    }

    private Pista pista(Long id) {
        Pista pista = new Pista();
        pista.setId(id);
        return pista;
    }

    private DescubrimientoRepository repositoryConFindByUsuarioId(Map<Long, List<Descubrimiento>> data) {
        return (DescubrimientoRepository) Proxy.newProxyInstance(
                DescubrimientoRepository.class.getClassLoader(),
                new Class<?>[]{DescubrimientoRepository.class},
                (proxy, method, args) -> {
                    if ("findByUsuarioId".equals(method.getName())) {
                        return data.getOrDefault((Long) args[0], Collections.emptyList());
                    }
                    if ("toString".equals(method.getName())) {
                        return "FakeDescubrimientoRepository";
                    }
                    return defaultValue(method.getReturnType());
                }
        );
    }

    private PistaRepository repositoryConFindByCasoId(Map<Long, List<Pista>> data) {
        return (PistaRepository) Proxy.newProxyInstance(
                PistaRepository.class.getClassLoader(),
                new Class<?>[]{PistaRepository.class},
                (proxy, method, args) -> {
                    if ("findByCasoId".equals(method.getName())) {
                        return data.getOrDefault((Long) args[0], Collections.emptyList());
                    }
                    if ("toString".equals(method.getName())) {
                        return "FakePistaRepository";
                    }
                    return defaultValue(method.getReturnType());
                }
        );
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
        if (returnType == double.class) {
            return 0.0;
        }
        if (returnType == float.class) {
            return 0.0f;
        }
        return null;
    }
}
