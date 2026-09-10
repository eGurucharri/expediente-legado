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

import java.time.LocalDateTime;

/**
 * La acusación que presentó un usuario en un caso: una decisión
 * permanente por partida (para volver a decidir, hay que empezar de
 * nuevo desde el menú).
 */
@Entity
@Table(name = "veredictos", uniqueConstraints = @UniqueConstraint(columnNames = {"usuario_id", "caso_id"}))
@Getter
@Setter
public class Veredicto {

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

    private LocalDateTime fecha = LocalDateTime.now();
}
