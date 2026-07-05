package com.legado.expediente.repository;

import com.legado.expediente.model.CombateEnCurso;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

public interface CombateEnCursoRepository extends JpaRepository<CombateEnCurso, Long> {

    Optional<CombateEnCurso> findByUsuarioIdAndCasoId(Long usuarioId, Long casoId);

    @Modifying
    @Transactional
    void deleteByUsuarioId(Long usuarioId);
}
