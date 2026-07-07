import { describe, it, expect } from "vitest";
import PrometeoLogic from "../../main/resources/static/js/prometeo-logic.js";

const { fusionarConGuardado, desbloquearCartaEnLista, esAcusacionPrecipitada, calcularEjeGanador } = PrometeoLogic;

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
