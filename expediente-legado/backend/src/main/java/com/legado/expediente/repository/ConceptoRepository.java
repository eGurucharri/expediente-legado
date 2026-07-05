package com.legado.expediente.repository;

import com.legado.expediente.model.Concepto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface ConceptoRepository extends JpaRepository<Concepto, Long> {

    @Query("select distinct c from Concepto c join c.pistas p where p.id in :pistaIds")
    List<Concepto> findByPistaIdIn(List<Long> pistaIds);

    List<Concepto> findByEpilogoTrue();
}
