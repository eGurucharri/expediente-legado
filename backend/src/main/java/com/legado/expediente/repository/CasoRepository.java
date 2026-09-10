package com.legado.expediente.repository;

import com.legado.expediente.model.Caso;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CasoRepository extends JpaRepository<Caso, Long> {
}
