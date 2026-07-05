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
        List<Pista> pistas = pistaRepository.findByCasoId(casoId);
        return !pistas.isEmpty() && pistas.stream().allMatch(p -> pistasDescubiertas.contains(p.getId()));
    }

    public boolean todosResueltos(List<Caso> casosBase, Set<Long> pistasDescubiertas) {
        return !casosBase.isEmpty() && casosBase.stream()
                .allMatch(c -> casoResuelto(c.getId(), pistasDescubiertas));
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
        return casos.stream()
                .map(c -> {
                    List<Pista> pistas = pistaRepository.findByCasoId(c.getId());
                    long encontradas = pistas.stream().filter(p -> pistasDescubiertas.contains(p.getId())).count();
                    boolean resuelto = !pistas.isEmpty() && encontradas == pistas.size();
                    return new CasoProgreso(c, pistas.size(), (int) encontradas, resuelto);
                })
                .collect(Collectors.toList());
    }
}
