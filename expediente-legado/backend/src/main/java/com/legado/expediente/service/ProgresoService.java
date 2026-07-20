package com.legado.expediente.service;

import com.legado.expediente.model.Caso;
import com.legado.expediente.model.Descubrimiento;
import com.legado.expediente.model.Pista;
import com.legado.expediente.model.Usuario;
import com.legado.expediente.repository.DescubrimientoRepository;
import com.legado.expediente.repository.PistaRepository;
import org.springframework.stereotype.Service;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Calcula, para el usuario autenticado, qué pistas ha descubierto y qué
 * expedientes ha resuelto (todas sus pistas descubiertas). Nada de esto se
 * almacena en el caso: se deriva siempre de {@link Descubrimiento}, así que
 * cada usuario avanza por su cuenta.
 */
@Service
public class ProgresoService {

    private final DescubrimientoRepository descubrimientoRepository;
    private final PistaRepository pistaRepository;

    public ProgresoService(DescubrimientoRepository descubrimientoRepository, PistaRepository pistaRepository) {
        this.descubrimientoRepository = descubrimientoRepository;
        this.pistaRepository = pistaRepository;
    }

    public Set<Long> pistasDescubiertas(Usuario usuario) {
        Set<Long> ids = new LinkedHashSet<>();
        for (Descubrimiento descubrimiento : descubrimientoRepository.findByUsuarioId(usuario.getId())) {
            if (descubrimiento != null && descubrimiento.getPista() != null) {
                Long id = descubrimiento.getPista().getId();
                if (id != null) {
                    ids.add(id);
                }
            }
        }
        return ids;
    }

    public boolean casoResuelto(Long casoId, Set<Long> pistasDescubiertas) {
        return resuelto(pistaRepository.findByCasoId(casoId), pistasDescubiertas);
    }

    public boolean todosResueltos(List<Caso> casosBase, Set<Long> pistasDescubiertas) {
        if (casosBase.isEmpty()) {
            return false;
        }
        // Una sola consulta para todas las pistas de los casos, en vez de una
        // por caso (findByCasoId dentro de un bucle): mismo resultado, N+1 menos.
        Map<Long, List<Pista>> pistasPorCaso = pistasPorCaso(casosBase);
        return casosBase.stream()
                .allMatch(c -> resuelto(pistasPorCaso.getOrDefault(c.getId(), List.of()), pistasDescubiertas));
    }

    private static boolean resuelto(List<Pista> pistas, Set<Long> pistasDescubiertas) {
        return !pistas.isEmpty() && pistas.stream().allMatch(p -> pistasDescubiertas.contains(p.getId()));
    }

    /**
     * Agrupa por caso, en una sola consulta, las pistas de los casos dados.
     * Pensado para que quien recorre varios casos en una petición
     * (dashboard, carpeta, resumen) no dispare una consulta por caso.
     */
    public Map<Long, List<Pista>> pistasPorCaso(List<Caso> casos) {
        if (casos.isEmpty()) {
            return Map.of();
        }
        List<Long> ids = casos.stream().map(Caso::getId).toList();
        return pistaRepository.findByCasoIdIn(ids).stream()
                .collect(Collectors.groupingBy(p -> p.getCaso().getId()));
    }

    public static class CasoProgreso {
        private final Caso caso;
        private final int totalPistas;
        private final int pistasDescubiertas;
        private final boolean resuelto;

        public CasoProgreso(Caso caso, int totalPistas, int pistasDescubiertas, boolean resuelto) {
            this.caso = caso;
            this.totalPistas = totalPistas;
            this.pistasDescubiertas = pistasDescubiertas;
            this.resuelto = resuelto;
        }

        public Caso caso() {
            return caso;
        }

        public int totalPistas() {
            return totalPistas;
        }

        public int pistasDescubiertas() {
            return pistasDescubiertas;
        }

        public boolean resuelto() {
            return resuelto;
        }
    }

    public List<CasoProgreso> progreso(List<Caso> casos, Set<Long> pistasDescubiertas) {
        return progreso(casos, pistasDescubiertas, pistasPorCaso(casos));
    }

    /**
     * Variante que reutiliza un mapa de pistas ya cargado (ver
     * {@link #pistasPorCaso}), para no repetir la consulta cuando quien llama
     * necesita las mismas pistas para otra cosa (p.ej. las combinaciones del
     * resumen).
     */
    public List<CasoProgreso> progreso(List<Caso> casos, Set<Long> pistasDescubiertas,
                                        Map<Long, List<Pista>> pistasPorCaso) {
        return casos.stream()
                .map(c -> {
                    List<Pista> pistas = pistasPorCaso.getOrDefault(c.getId(), List.of());
                    long encontradas = pistas.stream().filter(p -> pistasDescubiertas.contains(p.getId())).count();
                    boolean resuelto = !pistas.isEmpty() && encontradas == pistas.size();
                    return new CasoProgreso(c, pistas.size(), (int) encontradas, resuelto);
                })
                .collect(Collectors.toList());
    }
}
