package com.legado.expediente.repository;

import com.legado.expediente.model.RegistroLegado;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RegistroLegadoRepository extends JpaRepository<RegistroLegado, Long> {
    List<RegistroLegado> findByCasoId(Long casoId);
}
