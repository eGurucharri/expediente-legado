package com.legado.expediente.service;

import com.legado.expediente.model.Caso;
import com.legado.expediente.model.Pista;
import com.legado.expediente.model.Rol;
import com.legado.expediente.model.Usuario;
import com.legado.expediente.repository.CasoRepository;
import com.legado.expediente.repository.PistaRepository;
import com.legado.expediente.repository.VeredictoRepository;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * El estado "de verdad" del jugador (casos resueltos, pistas encontradas,
 * veredictos emitidos...), pensado para que la capa Prometeo (logros,
 * tarot, las pistas del asistente) reaccione a progreso real y no a datos
 * simulados en el navegador.
 */
@Service
public class ResumenJuegoService {

    private final CasoRepository casoRepository;
    private final PistaRepository pistaRepository;
    private final VeredictoRepository veredictoRepository;
    private final ProgresoService progresoService;

    public ResumenJuegoService(CasoRepository casoRepository,
                                PistaRepository pistaRepository,
                                VeredictoRepository veredictoRepository,
                                ProgresoService progresoService) {
        this.casoRepository = casoRepository;
        this.pistaRepository = pistaRepository;
        this.veredictoRepository = veredictoRepository;
        this.progresoService = progresoService;
    }

    public record CasoResumen(String titulo, boolean resuelto, boolean tieneVeredicto,
                               boolean tieneConclusionesPendientes, int pistasDescubiertas, int totalPistas) {
    }

    public record ResumenJuego(int casosResueltos, int totalCasosPrincipales, int pistasDescubiertas,
                                int totalPistas, int veredictosEmitidos, boolean esAdmin,
                                List<CasoResumen> casos) {
    }

    public ResumenJuego calcular(Usuario usuario) {
        Set<Long> descubiertas = progresoService.pistasDescubiertas(usuario);
        boolean esAdmin = usuario.getRol() == Rol.ADMIN;

        List<Caso> casosVisibles = casoRepository.findAll().stream()
                .filter(c -> !c.isConfidencial() || esAdmin)
                .toList();

        List<ProgresoService.CasoProgreso> progreso = progresoService.progreso(casosVisibles, descubiertas);

        Set<Long> casosConVeredicto = veredictoRepository.findByUsuarioId(usuario.getId()).stream()
                .map(v -> v.getCaso().getId())
                .collect(Collectors.toSet());

        int casosResueltos = 0;
        int totalPistas = 0;
        int pistasDescubiertasTotal = 0;
        List<CasoResumen> casosResumen = new ArrayList<>();

        for (ProgresoService.CasoProgreso cp : progreso) {
            if (cp.resuelto()) {
                casosResueltos++;
            }
            totalPistas += cp.totalPistas();
            pistasDescubiertasTotal += cp.pistasDescubiertas();

            List<Pista> combinaciones = pistaRepository.findByCasoId(cp.caso().getId()).stream()
                    .filter(p -> p.getRegistroOrigen2() != null)
                    .toList();
            boolean pendientes = combinaciones.stream().anyMatch(p -> !descubiertas.contains(p.getId()));

            casosResumen.add(new CasoResumen(cp.caso().getTitulo(), cp.resuelto(),
                    casosConVeredicto.contains(cp.caso().getId()), pendientes,
                    cp.pistasDescubiertas(), cp.totalPistas()));
        }

        int totalCasosPrincipales = (int) casosVisibles.stream().filter(Caso::isPrincipal).count();

        return new ResumenJuego(casosResueltos, totalCasosPrincipales, pistasDescubiertasTotal, totalPistas,
                casosConVeredicto.size(), esAdmin, casosResumen);
    }
}
