package com.legado.expediente.model;

import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.Setter;

/**
 * El enfrentamiento contra un sospechoso con {@code ataques}, mientras
 * está en curso: en qué ronda va. Al terminar la última ronda se borra y
 * se convierte en un {@link Veredicto} permanente.
 */
@Entity
@Table(name = "combates_en_curso", uniqueConstraints = @UniqueConstraint(columnNames = {"usuario_id", "caso_id"}))
@Getter
@Setter
public class CombateEnCurso {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_id", nullable = false)
    private Usuario usuario;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "caso_id", nullable = false)
    private Caso caso;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sospechoso_id", nullable = false)
    private Sospechoso sospechoso;

    /** Ronda actual, 1-indexada: corresponde a ataques.get(ronda - 1). */
    private int ronda = 1;
}
