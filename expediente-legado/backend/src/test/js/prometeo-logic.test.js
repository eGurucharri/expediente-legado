import { describe, it, expect } from "vitest";
import PrometeoLogic from "../../main/resources/static/js/prometeo-logic.js";

const { fusionarConGuardado, desbloquearCartaEnLista, esAcusacionPrecipitada, calcularEjeGanador, indiceJugadaRival, actualizarRacha, UTILIDAD_CARTAS, clasificarEleccion, contarPuntosPorEje, reiniciarEstadoPerRunEnEstado } = PrometeoLogic;

describe("fusionarConGuardado", () => {
    it("conserva los campos de estado del guardado y adopta los metadatos actuales", () => {
        const guardados = [{ id: "el-loco", collected: true, gastada: true }];
        const actuales = [{ id: "el-loco", nombre: "El Loco (texto nuevo)", collected: false, gastada: false }];

        const resultado = fusionarConGuardado(guardados, actuales, ["collected", "gastada"], {});

        expect(resultado).toEqual([
            { id: "el-loco", nombre: "El Loco (texto nuevo)", collected: true, gastada: true }
        ]);
    });

    it("deja los valores por defecto de lo actual cuando no hay guardado previo", () => {
        const resultado = fusionarConGuardado([], [{ id: "el-mago", collected: false }], ["collected"], {});
        expect(resultado).toEqual([{ id: "el-mago", collected: false }]);
    });

    it("encuentra el guardado por un id renombrado usando el alias", () => {
        const guardados = [{ id: "el-ojo", collected: true }];
        const actuales = [{ id: "la-sacerdotisa", collected: false }];

        const resultado = fusionarConGuardado(guardados, actuales, ["collected"], { "la-sacerdotisa": "el-ojo" });

        expect(resultado).toEqual([{ id: "la-sacerdotisa", collected: true }]);
    });

    it("no muta ni el guardado ni la lista actual de entrada", () => {
        const guardados = [{ id: "el-loco", collected: true }];
        const actuales = [{ id: "el-loco", collected: false }];

        fusionarConGuardado(guardados, actuales, ["collected"], {});

        expect(actuales[0].collected).toBe(false);
    });
});

describe("desbloquearCartaEnLista", () => {
    it("marca collected=true y devuelve true cuando la carta existe y no estaba recogida", () => {
        const tarot = [{ id: "el-mago", collected: false }];
        const resultado = desbloquearCartaEnLista(tarot, "el-mago");

        expect(resultado).toBe(true);
        expect(tarot[0].collected).toBe(true);
    });

    it("devuelve false sin tocar nada si ya estaba recogida", () => {
        const tarot = [{ id: "el-mago", collected: true }];
        const resultado = desbloquearCartaEnLista(tarot, "el-mago");

        expect(resultado).toBe(false);
        expect(tarot[0].collected).toBe(true);
    });

    it("devuelve false si el id no existe en la lista", () => {
        const tarot = [{ id: "el-mago", collected: false }];
        expect(desbloquearCartaEnLista(tarot, "no-existe")).toBe(false);
    });
});

describe("esAcusacionPrecipitada", () => {
    it("es precipitada cuando el ratio de pistas descubierto está por debajo del umbral", () => {
        expect(esAcusacionPrecipitada(1, 10, 0.6)).toBe(true);
    });

    it("no es precipitada cuando el ratio iguala o supera el umbral", () => {
        expect(esAcusacionPrecipitada(6, 10, 0.6)).toBe(false);
        expect(esAcusacionPrecipitada(10, 10, 0.6)).toBe(false);
    });

    it("nunca es precipitada si el caso no tiene pistas totales (evita dividir por cero)", () => {
        expect(esAcusacionPrecipitada(0, 0, 0.6)).toBe(false);
    });
});

describe("calcularEjeGanador", () => {
    const ORDEN = ["comunismo", "centrista", "socialdemocrata", "neoliberal"];

    it("elige el eje con más votos", () => {
        const historias = { "carta-1": "neoliberal", "carta-2": "neoliberal", "carta-3": "centrista" };
        expect(calcularEjeGanador(historias, Object.keys(historias), ORDEN)).toBe("neoliberal");
    });

    it("en empate gana el primero de ordenEjes", () => {
        const historias = { "carta-1": "neoliberal", "carta-2": "comunismo" };
        expect(calcularEjeGanador(historias, Object.keys(historias), ORDEN)).toBe("comunismo");
    });

    it("sin ninguna historia resuelta, gana el primero de ordenEjes por defecto", () => {
        expect(calcularEjeGanador({}, [], ORDEN)).toBe("comunismo");
    });

    it("ignora ejes que no están en ordenEjes", () => {
        const historias = { "carta-1": "eje-desconocido", "carta-2": "socialdemocrata" };
        expect(calcularEjeGanador(historias, Object.keys(historias), ORDEN)).toBe("socialdemocrata");
    });
});

describe("indiceJugadaRival", () => {
    it("en modo ciclo reproduce el ritmo autorado del caso 6 (ronda % total)", () => {
        expect(indiceJugadaRival("ciclo", 0, 3)).toBe(0);
        expect(indiceJugadaRival("ciclo", 4, 3)).toBe(1);
        expect(indiceJugadaRival("ciclo", 5, 3)).toBe(2);
    });

    it("en modo reactiva, con tirada baja, contraataca la última jugada del jugador", () => {
        // La cadena de tipos es circular (cada índice vence al siguiente):
        // lo que vence a X es el índice anterior a X.
        const azarBajo = () => 0.1; // < 0.7: reacciona
        expect(indiceJugadaRival("reactiva", 3, 3, azarBajo, 0)).toBe(2);
        expect(indiceJugadaRival("reactiva", 3, 3, azarBajo, 1)).toBe(0);
        expect(indiceJugadaRival("reactiva", 3, 3, azarBajo, 2)).toBe(1);
    });

    it("en modo reactiva, con tirada alta, juega aleatorio en vez de reaccionar", () => {
        let llamadas = 0;
        const azar = () => {
            llamadas++;
            return llamadas === 1 ? 0.9 : 0.5; // 1ª tirada decide no reaccionar, 2ª elige jugada
        };
        expect(indiceJugadaRival("reactiva", 3, 3, azar, 0)).toBe(1);
    });

    it("en modo reactiva sin última jugada del jugador (primera ronda) juega aleatorio", () => {
        const azar = () => 0.99;
        expect(indiceJugadaRival("reactiva", 0, 3, azar, null)).toBe(2);
        expect(indiceJugadaRival("reactiva", 0, 3, azar, -1)).toBe(2);
    });
});

describe("actualizarRacha", () => {
    it("ganar suma una a la racha y puede batir la mejor marca", () => {
        expect(actualizarRacha(2, 2, true)).toEqual({ racha: 3, mejor: 3 });
    });

    it("ganar sin batir la marca conserva la mejor anterior", () => {
        expect(actualizarRacha(0, 5, true)).toEqual({ racha: 1, mejor: 5 });
    });

    it("perder devuelve la racha a cero sin tocar la mejor marca", () => {
        expect(actualizarRacha(4, 4, false)).toEqual({ racha: 0, mejor: 4 });
    });
});

describe("UTILIDAD_CARTAS / clasificarEleccion", () => {
    const EJES = ["comunismo", "centrista", "socialdemocrata", "neoliberal"];

    it("cubre las 8 historias con exactamente 2 ejes útiles cada una", () => {
        const ids = Object.keys(UTILIDAD_CARTAS);
        expect(ids.length).toBe(8);
        ids.forEach((id) => {
            expect(UTILIDAD_CARTAS[id].length).toBe(2);
        });
    });

    it("invariante anti-moralizante: cada ideología es útil exactamente en 4 de las 8 cartas", () => {
        const conteo = { comunismo: 0, centrista: 0, socialdemocrata: 0, neoliberal: 0 };
        Object.values(UTILIDAD_CARTAS).forEach((utiles) => {
            utiles.forEach((eje) => {
                expect(EJES).toContain(eje);
                conteo[eje]++;
            });
        });
        EJES.forEach((eje) => {
            expect(conteo[eje], `el eje ${eje} debe ser útil exactamente 4 veces`).toBe(4);
        });
    });

    it("clasifica como pista los ejes útiles de la carta y como confusión el resto", () => {
        expect(clasificarEleccion("la-justicia", "comunismo")).toBe("pista");
        expect(clasificarEleccion("la-justicia", "neoliberal")).toBe("confusion");
        expect(clasificarEleccion("carta-inexistente", "comunismo")).toBe("confusion");
    });
});

describe("contarPuntosPorEje", () => {
    const EJES = ["comunismo", "centrista", "socialdemocrata", "neoliberal"];

    it("cuenta las elecciones de la partida por eje", () => {
        const historias = { a: "comunismo", b: "comunismo", c: "neoliberal" };
        expect(contarPuntosPorEje(historias, ["a", "b", "c"], EJES))
            .toEqual({ comunismo: 2, centrista: 0, socialdemocrata: 0, neoliberal: 1 });
    });

    it("ignora historias sin resolver y ejes desconocidos", () => {
        const historias = { a: "eje-fantasma" };
        expect(contarPuntosPorEje(historias, ["a", "b"], EJES))
            .toEqual({ comunismo: 0, centrista: 0, socialdemocrata: 0, neoliberal: 0 });
    });
});

describe("reiniciarEstadoPerRunEnEstado", () => {
    const estadoDeEjemplo = () => ({
        vida: 0,
        despidoShown: true,
        epilogoAvisado: true,
        historiasCartas: { "la-justicia": "comunismo" },
        finalPoliticoShown: true,
        finalVerdaderoShown: true,
        perdioVidaEnEstaVuelta: true,
        dificultad: "dificil",
        coliseoRachaMejor: 7,
        cartasConocidas: { "el-mago": true, "la-muerte": true },
        pasoPorDespidoAlgunaVez: true,
        tarot: [
            { id: "el-loco", collected: true, gastada: false },
            { id: "el-mago", collected: true, gastada: false },
            { id: "la-muerte", collected: true, gastada: true }
        ],
        logros: [
            { id: "archivo-completo", desbloqueado: true, porRun: true },
            { id: "final-verdadero", desbloqueado: true, porRun: false }
        ]
    });

    it("borra SOLO lo per-run: vida, avisos, decisiones, finales, tarot y logros de desempeño", () => {
        const e = reiniciarEstadoPerRunEnEstado(estadoDeEjemplo(), 3);

        expect(e.vida).toBe(3);
        expect(e.despidoShown).toBe(false);
        expect(e.epilogoAvisado).toBe(false);
        expect(e.historiasCartas).toEqual({});
        expect(e.finalPoliticoShown).toBe(false);
        expect(e.finalVerdaderoShown).toBe(false);
        expect(e.perdioVidaEnEstaVuelta).toBe(false);
        expect(e.tarot.find(c => c.id === "el-loco").collected).toBe(true);
        expect(e.tarot.find(c => c.id === "el-mago").collected).toBe(false);
        expect(e.tarot.find(c => c.id === "la-muerte").collected).toBe(false);
        expect(e.tarot.find(c => c.id === "la-muerte").gastada).toBe(false);
        expect(e.logros.find(l => l.id === "archivo-completo").desbloqueado).toBe(false);
    });

    it("NO toca la memoria de por vida: fantasmas, mejor racha, dificultad, vitrina y flags algunaVez", () => {
        const e = reiniciarEstadoPerRunEnEstado(estadoDeEjemplo(), 3);

        expect(e.cartasConocidas).toEqual({ "el-mago": true, "la-muerte": true });
        expect(e.coliseoRachaMejor).toBe(7);
        expect(e.dificultad).toBe("dificil");
        expect(e.logros.find(l => l.id === "final-verdadero").desbloqueado).toBe(true);
        expect(e.pasoPorDespidoAlgunaVez).toBe(true);
    });
});
