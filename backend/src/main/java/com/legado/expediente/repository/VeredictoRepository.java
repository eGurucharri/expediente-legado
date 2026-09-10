package com.legado.expediente.repository;

import com.legado.expediente.model.Veredicto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

public interface VeredictoRepository extends JpaRepository<Veredicto, Long> {

    Optional<Veredicto> findByUsuarioIdAndCasoId(Long usuarioId, Long casoId);

    List<Veredicto> findByUsuarioId(Long usuarioId);

    @Modifying
    @Transactional
    void deleteByUsuarioId(Long usuarioId);
}
