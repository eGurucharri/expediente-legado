package com.legado.expediente.repository;

import com.legado.expediente.model.Pista;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface PistaRepository extends JpaRepository<Pista, Long> {

    List<Pista> findByCasoId(Long casoId);

    @Query("select p from Pista p where p.caso.id = :casoId and p.registroOrigen2 is not null "
            + "and ((p.registroOrigen.id = :id1 and p.registroOrigen2.id = :id2) "
            + "or (p.registroOrigen.id = :id2 and p.registroOrigen2.id = :id1))")
    Optional<Pista> findCombinacion(@Param("casoId") Long casoId, @Param("id1") Long id1, @Param("id2") Long id2);
}
