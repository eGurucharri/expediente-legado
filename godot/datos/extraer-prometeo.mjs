// Saca los catálogos de logros y tarot de prometeo-ui.js, donde están escritos
// como literales dentro de una función. Mismo motivo que extraer.mjs con
// DataSeeder.java: es contenido, no código, y teclearlo a mano introduce
// erratas que nadie compara nunca con el original.
import {readFileSync, writeFileSync} from "node:fs";

const src = readFileSync(process.argv[2], "utf8");

// Recorta el literal (array u objeto) que sigue a `var <nombre> =` contando
// llaves o corchetes, y lo evalúa. Es `eval` a propósito y sin reparo: corre
// en una herramienta local sobre un fichero del propio repositorio, no sobre
// nada que llegue de fuera, y estos literales son JS sin una sola expresión.
function literal(nombre, apertura, cierre) {
  const inicio = src.indexOf(`var ${nombre} = ${apertura}`);
  if (inicio < 0) throw new Error(`no encuentro ${nombre}`);
  const abre = src.indexOf(apertura, inicio);
  let nivel = 0, fin = abre, enCadena = null, escapado = false;
  for (let i = abre; i < src.length; i++) {
    const ch = src[i];
    if (escapado) { escapado = false; continue; }
    if (ch === "\\") { escapado = true; continue; }
    // Las llaves y corchetes DENTRO de una cadena no cuentan: el texto de las
    // historias lleva comillas y signos de todo tipo.
    if (enCadena) { if (ch === enCadena) enCadena = null; continue; }
    if (ch === '"' || ch === "'") { enCadena = ch; continue; }
    if (ch === apertura) nivel++;
    else if (ch === cierre) { nivel--; if (nivel === 0) { fin = i; break; } }
  }
  return JSON.parse(JSON.stringify(eval(`(${src.slice(abre, fin + 1)})`)));
}

const arrayLiteral = nombre => literal(nombre, "[", "]");
const objetoLiteral = nombre => literal(nombre, "{", "}");

// Los nombres de campo se traen al castellano del resto del port: `collected`
// era el único anglicismo del original y `porRun` mezcla los dos idiomas.
const renombres = {collected: "recogida", porRun: "por_vuelta"};
const traducir = o => Object.fromEntries(
  Object.entries(o).map(([k, v]) => [renombres[k] ?? k, v]));

const salida = {
  logros: arrayLiteral("logrosActuales").map(traducir),
  tarot: arrayLiteral("tarotActual").map(traducir),
  historias: objetoLiteral("HISTORIAS_CARTAS"),
};

writeFileSync(process.argv[3], JSON.stringify(salida, null, 2) + "\n");
const historias = Object.entries(salida.historias);
console.log(`logros=${salida.logros.length} tarot=${salida.tarot.length} `
  + `historias=${historias.length}`);

// Cada historia debe traer sus cuatro salidas, una por eje: si una se queda
// con tres, ese eje deja de poder puntuar y el final político se desequilibra
// sin que nada avise.
const EJES = ["comunismo", "socialdemocrata", "centrista", "neoliberal"];
for (const [id, h] of historias) {
  const ejes = h.opciones.map(o => o.eje).sort();
  if (JSON.stringify(ejes) !== JSON.stringify([...EJES].sort())) {
    throw new Error(`${id} no tiene una opción por eje: ${ejes}`);
  }
  for (const campo of ["texto", "secuelaUtil", "secuelaConfusion"]) {
    if (!h[campo]) throw new Error(`${id} sin ${campo}`);
  }
}
