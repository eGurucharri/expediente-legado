package com.legado.expediente.repository;

import com.legado.expediente.model.Sospechoso;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SospechosoRepository extends JpaRepository<Sospechoso, Long> {
    List<Sospechoso> findByCasoId(Long casoId);
}
