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
 * está en curso. El combate de cartas en sí (issue #21) lo juega el
 * cliente de principio a fin con los {@code ataques} del sospechoso como
 * dato de partida — esta fila solo marca que hay uno pendiente de
 * resolver; al terminar (gane o pierda el jugador) se borra y se
 * convierte en un {@link Veredicto} permanente, igual que antes.
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
}
