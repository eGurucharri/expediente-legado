package com.legado.expediente.controller;

import com.legado.expediente.model.Caso;
import com.legado.expediente.model.CombateEnCurso;
import com.legado.expediente.model.Descubrimiento;
import com.legado.expediente.model.Pista;
import com.legado.expediente.model.RegistroLegado;
import com.legado.expediente.model.Rol;
import com.legado.expediente.model.Sospechoso;
import com.legado.expediente.model.Usuario;
import com.legado.expediente.model.Veredicto;
import com.legado.expediente.repository.CasoRepository;
import com.legado.expediente.repository.CombateEnCursoRepository;
import com.legado.expediente.repository.DescubrimientoRepository;
import com.legado.expediente.repository.PistaRepository;
import com.legado.expediente.repository.RegistroLegadoRepository;
import com.legado.expediente.repository.SospechosoRepository;
import com.legado.expediente.repository.VeredictoRepository;
import com.legado.expediente.service.CartaOcultaService;
import com.legado.expediente.service.HotspotService;
import com.legado.expediente.service.ProgresoService;
import com.legado.expediente.service.ResumenJuegoService;
import com.legado.expediente.service.UsuarioContexto;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Controller
public class CasoController {

    private static final String ATRIBUTO_MENSAJE = "mensaje";
    private static final String RUTA_CASOS = "redirect:/casos/";
    private static final int PRIMERA_RONDA = 1;

    private final CasoRepository casoRepository;
    private final RegistroLegadoRepository registroLegadoRepository;
    private final PistaRepository pistaRepository;
    private final DescubrimientoRepository descubrimientoRepository;
    private final SospechosoRepository sospechosoRepository;
    private final VeredictoRepository veredictoRepository;
    private final CombateEnCursoRepository combateEnCursoRepository;
    private final ProgresoService progresoService;
    private final ResumenJuegoService resumenJuegoService;
    private final UsuarioContexto usuarioContexto;
    private final HotspotService hotspotService;
    private final CartaOcultaService cartaOcultaService;

    public CasoController(CasoRepository casoRepository,
                           RegistroLegadoRepository registroLegadoRepository,
                           PistaRepository pistaRepository,
                           DescubrimientoRepository descubrimientoRepository,
                           SospechosoRepository sospechosoRepository,
                           VeredictoRepository veredictoRepository,
                           CombateEnCursoRepository combateEnCursoRepository,
                           ProgresoService progresoService,
                           ResumenJuegoService resumenJuegoService,
                           UsuarioContexto usuarioContexto,
                           HotspotService hotspotService,
                           CartaOcultaService cartaOcultaService) {
        this.casoRepository = casoRepository;
        this.registroLegadoRepository = registroLegadoRepository;
        this.pistaRepository = pistaRepository;
        this.descubrimientoRepository = descubrimientoRepository;
        this.sospechosoRepository = sospechosoRepository;
        this.veredictoRepository = veredictoRepository;
        this.combateEnCursoRepository = combateEnCursoRepository;
        this.progresoService = progresoService;
        this.resumenJuegoService = resumenJuegoService;
        this.usuarioContexto = usuarioContexto;
        this.hotspotService = hotspotService;
        this.cartaOcultaService = cartaOcultaService;
    }

    public record PistaVista(Long id, String descripcion, boolean descubierta) {
    }

    public record RegistroVista(RegistroLegado registro, PistaVista pista, String contenidoHtml) {
    }

    public record CombateVista(String nombreSospechoso, String ataqueActual, int resistenciaPorcentaje,
                                String etiquetaAccion) {
    }

    @GetMapping("/casos/{id}")
    public String detalle(@PathVariable Long id, Authentication authentication,
                           RedirectAttributes redirectAttributes, Model model) {
        Usuario usuario = usuarioContexto.actual(authentication);
        Caso caso = casoRepository.findById(id).orElseThrow();

        if (caso.isConfidencial() && usuario.getRol() != Rol.ADMIN) {
            redirectAttributes.addFlashAttribute(ATRIBUTO_MENSAJE,
                    "Solicitud denegada. Nivel de acreditación insuficiente para este expediente.");
            return "redirect:/";
        }

        Set<Long> descubiertas = progresoService.pistasDescubiertas(usuario);
        List<Pista> pistas = pistaRepository.findByCasoId(id);
        Map<Long, Pista> pistaPorRegistro = pistas.stream()
                .filter(p -> p.getRegistroOrigen() != null && p.getRegistroOrigen2() == null)
                .collect(Collectors.toMap(p -> p.getRegistroOrigen().getId(), p -> p, (a, b) -> a));

        List<RegistroVista> registrosVista = registroLegadoRepository.findByCasoId(id).stream()
                .map(r -> {
                    Pista p = pistaPorRegistro.get(r.getId());
                    boolean descubierta = p != null && descubiertas.contains(p.getId());
                    PistaVista pv = p == null ? null : new PistaVista(p.getId(), p.getDescripcion(), descubierta);
                    String fraseGatillo = p == null ? null : p.getFraseGatillo();
                    Long pistaId = p == null ? null : p.getId();
                    String html = hotspotService.render(r.getContenido(), fraseGatillo, pistaId, descubierta);
                    html = cartaOcultaService.aplicar(html, r.getFolio());
                    return new RegistroVista(r, pv, html);
                })
                .toList();

        List<Pista> conclusionesPistas = pistas.stream()
                .filter(p -> p.getRegistroOrigen2() != null)
                .toList();
        List<PistaVista> conclusiones = conclusionesPistas.stream()
                .map(p -> new PistaVista(p.getId(), p.getDescripcion(), descubiertas.contains(p.getId())))
                .toList();
        long conclusionesEncontradas = conclusionesPistas.stream().filter(p -> descubiertas.contains(p.getId())).count();

        long encontradas = pistas.stream().filter(p -> descubiertas.contains(p.getId())).count();

        Veredicto veredicto = veredictoRepository.findByUsuarioIdAndCasoId(usuario.getId(), id).orElse(null);
        CombateEnCurso combate = veredicto == null
                ? combateEnCursoRepository.findByUsuarioIdAndCasoId(usuario.getId(), id).orElse(null)
                : null;

        model.addAttribute("caso", caso);
        model.addAttribute("registros", registrosVista);
        model.addAttribute("conclusiones", conclusiones);
        model.addAttribute("totalConclusiones", conclusionesPistas.size());
        model.addAttribute("conclusionesEncontradas", (int) conclusionesEncontradas);
        model.addAttribute("totalPistas", pistas.size());
        model.addAttribute("pistasEncontradas", (int) encontradas);
        model.addAttribute("sospechosos", sospechosoRepository.findByCasoId(id));
        model.addAttribute("veredicto", veredicto);
        model.addAttribute("combate", combate == null ? null : construirCombateVista(combate));
        model.addAttribute("rutaActual", "/casos/" + id);
        model.addAttribute("ultimoGuardado", usuario.getUltimoGuardado());
        model.addAttribute("estadoJuego", resumenJuegoService.calcular(usuario));
        return "caso";
    }

    private CombateVista construirCombateVista(CombateEnCurso combate) {
        List<String> ataques = combate.getSospechoso().getAtaques();
        int ronda = combate.getRonda();
        int total = ataques.size();
        int resistencia = Math.round(100f * (total - (ronda - 1)) / total);
        String etiqueta;
        if (ronda >= total) {
            etiqueta = "Presentar cierre";
        } else if (ronda == PRIMERA_RONDA) {
            etiqueta = "Objetar";
        } else {
            etiqueta = "Insistir";
        }
        return new CombateVista(combate.getSospechoso().getNombre(), ataques.get(ronda - 1), resistencia, etiqueta);
    }

    @PostMapping("/casos/{casoId}/pistas/{pistaId}/descubrir")
    public String descubrirPista(@PathVariable Long casoId, @PathVariable Long pistaId,
                                  Authentication authentication, RedirectAttributes redirectAttributes) {
        Usuario usuario = usuarioContexto.actual(authentication);
        Pista pista = pistaRepository.findById(pistaId).orElseThrow();

        if (pista.getCaso().isConfidencial() && usuario.getRol() != Rol.ADMIN) {
            redirectAttributes.addFlashAttribute(ATRIBUTO_MENSAJE,
                    "Solicitud denegada. Nivel de acreditación insuficiente para este expediente.");
            return "redirect:/";
        }

        if (!descubrimientoRepository.existsByUsuarioIdAndPistaId(usuario.getId(), pistaId)) {
            Descubrimiento descubrimiento = new Descubrimiento();
            descubrimiento.setUsuario(usuario);
            descubrimiento.setPista(pista);
            descubrimientoRepository.save(descubrimiento);
        }

        redirectAttributes.addFlashAttribute(ATRIBUTO_MENSAJE, "Pista añadida a tu carpeta.");
        redirectAttributes.addFlashAttribute("pistaDescubiertaId", pistaId);
        return RUTA_CASOS + casoId;
    }

    @PostMapping("/casos/{casoId}/combinar")
    public String combinar(@PathVariable Long casoId,
                            @RequestParam(required = false) List<Long> registroIds,
                            Authentication authentication, RedirectAttributes redirectAttributes) {
        Usuario usuario = usuarioContexto.actual(authentication);

        if (registroIds == null || registroIds.size() != 2) {
            redirectAttributes.addFlashAttribute(ATRIBUTO_MENSAJE, "Selecciona exactamente dos documentos para combinarlos.");
            return RUTA_CASOS + casoId;
        }

        Pista pista = pistaRepository.findCombinacion(casoId, registroIds.get(0), registroIds.get(1)).orElse(null);
        if (pista == null) {
            redirectAttributes.addFlashAttribute(ATRIBUTO_MENSAJE, "No encuentra ninguna relación entre esos documentos.");
            return RUTA_CASOS + casoId;
        }

        if (!descubrimientoRepository.existsByUsuarioIdAndPistaId(usuario.getId(), pista.getId())) {
            Descubrimiento descubrimiento = new Descubrimiento();
            descubrimiento.setUsuario(usuario);
            descubrimiento.setPista(pista);
            descubrimientoRepository.save(descubrimiento);
            redirectAttributes.addFlashAttribute(ATRIBUTO_MENSAJE, "Nueva conclusión anotada al expediente.");
            redirectAttributes.addFlashAttribute("pistaDescubiertaId", pista.getId());
        } else {
            redirectAttributes.addFlashAttribute(ATRIBUTO_MENSAJE, "Esa conclusión ya estaba anotada.");
        }
        return RUTA_CASOS + casoId;
    }

    @PostMapping("/casos/{casoId}/acusar")
    public String acusar(@PathVariable Long casoId, @RequestParam Long sospechosoId, Authentication authentication,
                          RedirectAttributes redirectAttributes) {
        Usuario usuario = usuarioContexto.actual(authentication);

        boolean yaHayVeredicto = veredictoRepository.findByUsuarioIdAndCasoId(usuario.getId(), casoId).isPresent();
        boolean yaHayCombate = combateEnCursoRepository.findByUsuarioIdAndCasoId(usuario.getId(), casoId).isPresent();

        if (!yaHayVeredicto && !yaHayCombate) {
            Sospechoso sospechoso = sospechosoRepository.findById(sospechosoId).orElseThrow();
            if (sospechoso.getAtaques().isEmpty()) {
                registrarVeredicto(usuario, sospechoso);
            } else {
                CombateEnCurso combate = new CombateEnCurso();
                combate.setUsuario(usuario);
                combate.setCaso(sospechoso.getCaso());
                combate.setSospechoso(sospechoso);
                combate.setRonda(PRIMERA_RONDA);
                combateEnCursoRepository.save(combate);
            }
            redirectAttributes.addFlashAttribute("accionReciente", "acusacion");
        }

        return RUTA_CASOS + casoId;
    }

    @PostMapping("/casos/{casoId}/combate/avanzar")
    public String avanzarCombate(@PathVariable Long casoId, Authentication authentication) {
        Usuario usuario = usuarioContexto.actual(authentication);
        CombateEnCurso combate = combateEnCursoRepository.findByUsuarioIdAndCasoId(usuario.getId(), casoId)
                .orElseThrow();

        int total = combate.getSospechoso().getAtaques().size();
        if (combate.getRonda() < total) {
            combate.setRonda(combate.getRonda() + 1);
            combateEnCursoRepository.save(combate);
        } else {
            registrarVeredicto(usuario, combate.getSospechoso());
            combateEnCursoRepository.delete(combate);
        }
        return RUTA_CASOS + casoId;
    }

    private void registrarVeredicto(Usuario usuario, Sospechoso sospechoso) {
        Veredicto veredicto = new Veredicto();
        veredicto.setUsuario(usuario);
        veredicto.setCaso(sospechoso.getCaso());
        veredicto.setSospechoso(sospechoso);
        veredictoRepository.save(veredicto);
    }
}
