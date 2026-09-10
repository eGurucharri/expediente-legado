package com.legado.expediente.repository;

import com.legado.expediente.model.Descubrimiento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

public interface DescubrimientoRepository extends JpaRepository<Descubrimiento, Long> {

    List<Descubrimiento> findByUsuarioId(Long usuarioId);

    boolean existsByUsuarioIdAndPistaId(Long usuarioId, Long pistaId);

    @Modifying
    @Transactional
    void deleteByUsuarioId(Long usuarioId);
}
