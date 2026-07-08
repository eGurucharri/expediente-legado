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

    return {
        fusionarConGuardado: fusionarConGuardado,
        desbloquearCartaEnLista: desbloquearCartaEnLista,
        esAcusacionPrecipitada: esAcusacionPrecipitada,
        calcularEjeGanador: calcularEjeGanador
    };
});
