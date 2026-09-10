/**
 * Lógica pura de Prometeo, sin acoplamiento al DOM ni a localStorage, para
 * poder testearla de forma aislada (issue #8). prometeo-ui.js consume estas
 * funciones vía window.PrometeoLogic; los tests (Vitest) las importan por
 * CommonJS. Cualquier cambio de comportamiento debe hacerse aquí, no
 * duplicarse en prometeo-ui.js.
 */
(function (root, factory) {
    if (typeof module === "object" && module.exports) {
        module.exports = factory();
    } else {
        root.PrometeoLogic = factory();
    }
})(typeof self !== "undefined" ? self : this, function () {
    "use strict";

    /**
     * Combina el estado guardado en este navegador con la lista actual de
     * logros/cartas: conserva el flag desbloqueado/collected de lo ya
     * guardado (buscando también por alias, para ids renombrados) y adopta
     * los metadatos y las entradas nuevas de la versión vigente.
     */
    function fusionarConGuardado(guardados, actuales, camposEstado, alias) {
        alias = alias || {};
        return actuales.map(function (item) {
            var idsBuscados = [item.id].concat(alias[item.id] ? [alias[item.id]] : []);
            var previo = guardados.find(function (g) {
                return idsBuscados.indexOf(g.id) !== -1;
            });
            var copia = Object.assign({}, item);
            if (previo) {
                camposEstado.forEach(function (campo) {
                    if (Object.prototype.hasOwnProperty.call(previo, campo)) {
                        copia[campo] = previo[campo];
                    }
                });
            }
            return copia;
        });
    }

    /**
     * Marca como recogida la carta con ese id dentro de la lista dada.
     * Devuelve true solo si esa carta existía y no estaba ya recogida
     * (es decir, si hubo novedad de verdad).
     */
    function desbloquearCartaEnLista(tarot, id) {
        var carta = tarot.find(function (c) {
            return c.id === id;
        });
        if (carta && !carta.collected) {
            carta.collected = true;
            return true;
        }
        return false;
    }

    /**
     * Una acusación se considera precipitada cuando se descubrió menos
     * proporción de pistas del caso que el umbral de la dificultad actual.
     * Sin pistas totales no hay ratio que evaluar, así que nunca es
     * precipitada (evita una división por cero).
     */
    function esAcusacionPrecipitada(pistasDescubiertas, totalPistas, umbralEvidencia) {
        if (!totalPistas) {
            return false;
        }
        return (pistasDescubiertas / totalPistas) < umbralEvidencia;
    }

    /**
     * Cuenta los votos por eje político de las historias de cartas
     * resueltas y devuelve el eje ganador. Empate a cero, o cualquier
     * empate entre ejes, lo gana el primero de ordenEjes (comunismo)
     * salvo que otro tenga estrictamente más votos.
     */
    function calcularEjeGanador(historiasCartas, idsHistorias, ordenEjes) {
        var conteo = {};
        ordenEjes.forEach(function (eje) {
            conteo[eje] = 0;
        });
        idsHistorias.forEach(function (id) {
            var eje = historiasCartas[id];
            if (Object.prototype.hasOwnProperty.call(conteo, eje)) {
                conteo[eje]++;
            }
        });

        var ganador = ordenEjes[0];
        var maxVotos = -1;
        ordenEjes.forEach(function (eje) {
            if (conteo[eje] > maxVotos) {
                maxVotos = conteo[eje];
                ganador = eje;
            }
        });
        return ganador;
    }

    /**
     * Issue #45: en cada historia política hay 2 opciones "útiles" (su
     * secuela apunta a una pista real todavía por descubrir de ese caso) y
     * 2 "de confusión" (pista falsa). La corrección es POR SITUACIÓN, no
     * por ideología: cada eje es útil exactamente en 4 de las 8 cartas
     * (invariante testeada), así que no se puede leer "el juego dice que X
     * es la ideología buena". El tally del final político (calcularEjeGanador)
     * es ortogonal a esto y sigue siendo 100% ideológico.
     */
    var UTILIDAD_CARTAS = {
        "la-justicia": ["comunismo", "socialdemocrata"],
        "la-rueda": ["centrista", "neoliberal"],
        "el-juicio": ["comunismo", "socialdemocrata"],
        "la-luna": ["centrista", "neoliberal"],
        "el-carro": ["comunismo", "centrista"],
        "el-sol": ["socialdemocrata", "neoliberal"],
        "la-emperatriz": ["socialdemocrata", "neoliberal"],
        "la-sacerdotisa": ["comunismo", "centrista"]
    };

    function clasificarEleccion(cartaId, eje) {
        var utiles = UTILIDAD_CARTAS[cartaId] || [];
        return utiles.indexOf(eje) !== -1 ? "pista" : "confusion";
    }

    /**
     * Cuenta las elecciones de esta partida por eje político. Es el mismo
     * conteo que decide el final político, expuesto como recuento: sirve de
     * "puntos de ideología" para las cargas de habilidad en combate
     * (issue #45) — la run política ES el equipamiento, sin asignación.
     */
    function contarPuntosPorEje(historiasCartas, idsHistorias, ordenEjes) {
        var conteo = {};
        ordenEjes.forEach(function (eje) {
            conteo[eje] = 0;
        });
        idsHistorias.forEach(function (id) {
            var eje = historiasCartas[id];
            if (Object.prototype.hasOwnProperty.call(conteo, eje)) {
                conteo[eje]++;
            }
        });
        return conteo;
    }

    /**
     * Índice de la jugada del rival para esta ronda de combate. El modo
     * "ciclo" reproduce el ritmo autorado del duelo del caso 6 (issue #21:
     * determinista, aprendible — es una escena, no un desafío repetible).
     * El modo "reactiva" es la Ventanilla de Reclamaciones (issue #43): el
     * rival tiende (70%) a jugar lo que vence la última jugada del jugador,
     * así que se le puede cebar — hay una decisión por ronda, no una tabla
     * que memorizar ni una moneda al aire. Asume la cadena circular de
     * tipos del juego (cada índice vence al siguiente, módulo el total),
     * por lo que "lo que vence a X" es el índice anterior a X.
     */
    function indiceJugadaRival(modo, ronda, totalTipos, random, indiceUltimoJugador) {
        var azar = random || Math.random;
        if (modo === "reactiva") {
            var sinUltima = indiceUltimoJugador === null || indiceUltimoJugador === undefined
                || indiceUltimoJugador < 0;
            if (sinUltima || azar() >= 0.7) {
                return Math.floor(azar() * totalTipos);
            }
            return (indiceUltimoJugador + totalTipos - 1) % totalTipos;
        }
        return ronda % totalTipos;
    }

    /**
     * Racha de la Ventanilla de Reclamaciones: ganar suma una, perder la
     * devuelve a cero; la mejor marca solo puede crecer. La racha en curso
     * es efímera (variable de sesión), la mejor marca es meta-progresión.
     */
    function actualizarRacha(racha, mejor, gano) {
        var nueva = gano ? racha + 1 : 0;
        return { racha: nueva, mejor: Math.max(mejor, nueva) };
    }

    /**
     * Issue #46: el borrado per-run — la frontera más delicada del estado.
     * Muta y devuelve el estado dejando SOLO lo per-run a cero: vida al
     * máximo, avisos de la vuelta re-armados, decisiones políticas vacías,
     * finales re-conquistables, tarot en posesión inicial (El Loco) y
     * logros de desempeño re-bloqueados. NO toca: cartasConocidas (memoria
     * fantasma), coliseoRachaMejor, dificultad, logros de vitrina
     * (porRun=false) ni los flags "algunaVez" de por vida.
     */
    function reiniciarEstadoPerRunEnEstado(estado, vidaMax) {
        estado.vida = vidaMax;
        estado.despidoShown = false;
        estado.epilogoAvisado = false;
        estado.historiasCartas = {};
        estado.finalPoliticoShown = false;
        estado.finalVerdaderoShown = false;
        estado.perdioVidaEnEstaVuelta = false;
        estado.tarot.forEach(function (carta) {
            carta.collected = carta.id === "el-loco";
            carta.gastada = false;
        });
        estado.logros.forEach(function (logro) {
            if (logro.porRun) {
                logro.desbloqueado = false;
            }
        });
        return estado;
    }

    return {
        fusionarConGuardado: fusionarConGuardado,
        desbloquearCartaEnLista: desbloquearCartaEnLista,
        esAcusacionPrecipitada: esAcusacionPrecipitada,
        calcularEjeGanador: calcularEjeGanador,
        indiceJugadaRival: indiceJugadaRival,
        actualizarRacha: actualizarRacha,
        UTILIDAD_CARTAS: UTILIDAD_CARTAS,
        clasificarEleccion: clasificarEleccion,
        contarPuntosPorEje: contarPuntosPorEje,
        reiniciarEstadoPerRunEnEstado: reiniciarEstadoPerRunEnEstado
    };
});
