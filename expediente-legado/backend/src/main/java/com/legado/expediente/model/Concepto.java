package com.legado.expediente.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

/**
 * Entrada del corcho de investigación: una persona, empresa, comité, lugar o
 * documento que el jugador desbloquea al descubrir las pistas asociadas.
 * El campo {@code resumen} puede citar otros conceptos entre dobles
 * corchetes, p. ej. {@code [[Comité Ad Honorem]]}, para generar hipervínculos.
 */
@Entity
@Table(name = "conceptos")
@Getter
@Setter
public class Concepto {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 120)
    private String nombre;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ConceptoTipo tipo;

    @Column(nullable = false, length = 2000)
    private String resumen;

    @Column(nullable = false)
    private boolean epilogo = false;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(name = "concepto_pistas",
            joinColumns = @JoinColumn(name = "concepto_id"),
            inverseJoinColumns = @JoinColumn(name = "pista_id"))
    private List<Pista> pistas = new ArrayList<>();
}
