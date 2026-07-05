package com.legado.expediente.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "pistas")
@Getter
@Setter
public class Pista {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "caso_id", nullable = false)
    private Caso caso;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "registro_legado_id")
    private RegistroLegado registroOrigen;

    /** Si no es nula, esta pista solo se descubre combinando registroOrigen con este segundo registro. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "registro_legado_id_2")
    private RegistroLegado registroOrigen2;

    @Column(nullable = false, length = 500)
    private String descripcion;

    /**
     * Fragmento textual, literal, dentro del contenido de registroOrigen.
     * Se resalta como el punto que dispara el descubrimiento, en vez de un
     * botón genérico de "investigar" separado del documento.
     */
    @Column(length = 150)
    private String fraseGatillo;
}
