// Saca los catálogos de logros y tarot de prometeo-ui.js, donde están escritos
// como literales dentro de una función. Mismo motivo que extraer.mjs con
// DataSeeder.java: es contenido, no código, y teclearlo a mano introduce
// erratas que nadie compara nunca con el original.
import {readFileSync, writeFileSync} from "node:fs";

const src = readFileSync(process.argv[2], "utf8");

function arrayLiteral(nombre) {
  const inicio = src.indexOf(`var ${nombre} = [`);
  if (inicio < 0) throw new Error(`no encuentro ${nombre}`);
  const abre = src.indexOf("[", inicio);
  let nivel = 0, fin = abre;
  for (let i = abre; i < src.length; i++) {
    if (src[i] === "[") nivel++;
    else if (src[i] === "]") { nivel--; if (nivel === 0) { fin = i; break; } }
  }
  // Los literales son JS válido y sin expresiones: se pueden evaluar tal cual.
  return JSON.parse(JSON.stringify(eval(src.slice(abre, fin + 1))));
}

// Los nombres de campo se traen al castellano del resto del port: `collected`
// era el único anglicismo del original y `porRun` mezcla los dos idiomas.
const renombres = {collected: "recogida", porRun: "por_vuelta"};
const traducir = o => Object.fromEntries(
  Object.entries(o).map(([k, v]) => [renombres[k] ?? k, v]));

const salida = {
  logros: arrayLiteral("logrosActuales").map(traducir),
  tarot: arrayLiteral("tarotActual").map(traducir),
};

writeFileSync(process.argv[3], JSON.stringify(salida, null, 2) + "\n");
console.log(`logros=${salida.logros.length} tarot=${salida.tarot.length}`);
