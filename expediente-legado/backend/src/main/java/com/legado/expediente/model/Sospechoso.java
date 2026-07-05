package com.legado.expediente.model;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OrderColumn;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

/**
 * Una persona (o entidad) a la que el jugador puede acusar al cerrar un
 * caso. No hay un culpable "correcto": cada sospechoso tiene su propio
 * desenlace narrativo, igual de válido.
 *
 * <p>Si tiene {@code ataques} definidos, acusarlo no resuelve el caso al
 * instante: primero hay que superar un pequeño enfrentamiento (una réplica
 * suya por cada ataque) antes de llegar al desenlace.</p>
 */
@Entity
@Table(name = "sospechosos")
@Getter
@Setter
public class Sospechoso {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "caso_id", nullable = false)
    private Caso caso;

    @Column(nullable = false, length = 150)
    private String nombre;

    @Column(nullable = false, length = 500)
    private String descripcion;

    @Column(nullable = false, length = 1500)
    private String desenlace;

    @ElementCollection
    @CollectionTable(name = "sospechoso_ataques", joinColumns = @JoinColumn(name = "sospechoso_id"))
    @OrderColumn(name = "orden")
    @Column(name = "texto", length = 500)
    private List<String> ataques = new ArrayList<>();
}
