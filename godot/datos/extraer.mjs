import {readFileSync, writeFileSync} from "node:fs";

const MESES = {JANUARY:1,FEBRUARY:2,MARCH:3,APRIL:4,MAY:5,JUNE:6,JULY:7,AUGUST:8,
  SEPTEMBER:9,OCTOBER:10,NOVEMBER:11,DECEMBER:12};

const src = readFileSync(process.argv[2], "utf8");

// Constantes del seeder (p.ej. CARCOSA_SERVICIOS_ESCENICOS), que aparecen
// tanto solas como concatenadas dentro de un texto.
const constantes = new Map(
  [...src.matchAll(/static final String (\w+) = "((?:[^"\\]|\\.)*)"/g)]
    .map(m => [m[1], m[2]]));

// Une las sentencias: el fuente parte cadenas con " + " entre lineas.
const fuente = src
  .replace(/\/\*[\s\S]*?\*\//g, "")
  .split("\n")
  .filter(l => !/^\s*\/\//.test(l))
  .join(" ");

// Partir por ";" a secas cortaria dentro de las cadenas: el texto de los
// expedientes lleva punto y coma ("esa semana; es tambien el unico...").
function partirSentencias(codigo) {
  const fuera = [];
  let actual = "", enCadena = false, escapado = false;
  for (const ch of codigo) {
    if (escapado) { actual += ch; escapado = false; continue; }
    if (ch === "\\" && enCadena) { actual += ch; escapado = true; continue; }
    if (ch === '"') { enCadena = !enCadena; actual += ch; continue; }
    if (ch === ";" && !enCadena) { fuera.push(actual); actual = ""; continue; }
    actual += ch;
  }
  if (actual.trim()) fuera.push(actual);
  return fuera;
}
const sentencias = partirSentencias(fuente);

// "a" + "b"  ->  "ab"
function texto(bruto) {
  const partes = [...bruto.matchAll(/"((?:[^"\\]|\\.)*)"/g)].map(m => m[1]);
  if (!partes.length) return null;
  return partes.join("").replace(/\\"/g,'"').replace(/\\n/g,"\n").replace(/\\\\/g,"\\");
}

// Parte una lista de argumentos por las comas de PRIMER nivel, sin cortar
// dentro de una cadena ni dentro de una llamada anidada.
function partirPorComas(texto) {
  const partes = [];
  let actual = "", enCadena = false, escapado = false, nivel = 0;
  for (const ch of texto) {
    if (escapado) { actual += ch; escapado = false; continue; }
    if (ch === "\\" && enCadena) { actual += ch; escapado = true; continue; }
    if (ch === '"') { enCadena = !enCadena; actual += ch; continue; }
    if (!enCadena) {
      if (ch === "(") nivel++;
      else if (ch === ")") nivel--;
      else if (ch === "," && nivel === 0) { partes.push(actual); actual = ""; continue; }
    }
    actual += ch;
  }
  if (actual.trim()) partes.push(actual);
  return partes.map(x => x.trim()).filter(Boolean);
}

function valor(bruto) {
  let s = bruto.trim();
  if (s === "null") return null;
  for (const [nombre, texto2] of constantes) {
    s = s.split(nombre).join(JSON.stringify(texto2));
  }
  if (/^Arrays\.asList\(/.test(s) || /^List\.of\(/.test(s)) {
    const dentro = s.slice(s.indexOf("(") + 1, s.lastIndexOf(")"));
    // Los elementos pueden ser textos (los ataques de un sospechoso) o
    // REFERENCIAS a otra entidad (las pistas que cita un concepto). Tratar
    // ambos como texto perdía los enlaces del corcho en silencio, que es
    // justo el fallo que esto viene a no repetir.
    //
    // Y se parte respetando las comillas: los ataques llevan comas DENTRO
    // ("Vengo por lo del expediente, señorita"), igual que los expedientes
    // llevaban punto y coma.
    return partirPorComas(dentro).map(valor);
  }
  if (/^".*"|^".*"\s*\+/.test(s) || s.includes('"')) return texto(s);
  let m = s.match(/LocalDate\.of\(\s*(\d+)\s*,\s*Month\.(\w+)\s*,\s*(\d+)\s*\)/);
  if (m) return `${m[1]}-${String(MESES[m[2]]).padStart(2,"0")}-${m[3].padStart(2,"0")}`;
  m = s.match(/^(?:EstadoCaso|TipoRegistro|ConceptoTipo|Rol)\.(\w+)$/);
  if (m) return m[1];
  if (/^-?\d+$/.test(s)) return Number(s);
  if (s === "true" || s === "false") return s === "true";
  // `caso2Pistas.pista3()` es el accesor que el seeder usa para pasar una
  // pista de un caso al corcho, que se siembra después. El id que le puso el
  // extractor a esa pista es `pista3@2`, así que la referencia se resuelve
  // sin tener que interpretar los records intermedios.
  m = s.match(/^caso(\d+)Pistas\.(\w+)\(\)$/);
  if (m) return {ref: `${m[2]}@${m[1]}`, directa: true};

  return {ref: s};                       // referencia a otra entidad
}

let ambito = 0;
const objetos = new Map();               // nombreVar -> {__tipo, campos...}
const orden = [];
const TIPOS = /^(Caso|RegistroLegado|Pista|Sospechoso|Concepto|Usuario)$/;

for (const bruta of sentencias) {
  // Tras partir por ";" arrastra el cierre/apertura de bloque anterior.
  const s = bruta.replace(/^[^"]*[{}](?=[^"]*(?:"[^"]*"[^"]*)*$)/, "").trim();
  let m = s.match(/^(?:final\s+)?(\w+)\s+(\w+)\s*=\s*new\s+\1\s*\(\s*\)$/);
  if (m && TIPOS.test(m[1])) {
    if (m[1] === "Caso") ambito += 1;
    const obj = {__tipo: m[1], __var: m[2], __id: m[2] + "@" + ambito};
    objetos.set(m[2], obj); orden.push(obj);
    continue;
  }
  m = s.match(/^(\w+)\.(set|add)(\w+)\s*\(([\s\S]*)\)$/);
  if (m && objetos.has(m[1])) {
    const obj = objetos.get(m[1]);
    const campo = m[3][0].toLowerCase() + m[3].slice(1);
    const v = valor(m[4]);
    if (m[2] === "add") (obj[campo + "s"] ??= []).push(v);
    else obj[campo] = v;
  }
}

// Resuelve referencias a la variable citada.
const idDe = o => o.__id;
for (const o of orden) {
  for (const [k, v] of Object.entries(o)) {
    const res = x => {
      if (!x || !x.ref) return x;
      if (x.directa) return x.ref;       // ya viene con la forma del id
      return objetos.has(x.ref) ? idDe(objetos.get(x.ref)) : x;
    };
    o[k] = Array.isArray(v) ? v.map(res) : res(v);
  }
}

// Agrupa por caso.
const casos = orden.filter(o => o.__tipo === "Caso").map(c => ({
  id: c.__id, titulo: c.titulo, descripcion: c.descripcion,
  anioSuceso: c.anioSuceso, estado: c.estado ?? "ABIERTO",
  confidencial: c.confidencial ?? false, principal: c.principal ?? true,
  registros: [], pistas: [], sospechosos: []
}));
const porId = new Map(casos.map(c => [c.id, c]));
const hijos = {RegistroLegado: "registros", Pista: "pistas", Sospechoso: "sospechosos"};
for (const o of orden) {
  const lista = hijos[o.__tipo];
  if (!lista || !porId.has(o.caso)) continue;
  const {__tipo, __var, __id, caso, ...resto} = o;
  porId.get(o.caso)[lista].push({id: __id, ...resto});
}
const conceptos = orden.filter(o => o.__tipo === "Concepto").map(({__tipo, __var, __id, ...r}) => ({id: __id, ...r}));

writeFileSync(process.argv[3], JSON.stringify({casos, conceptos}, null, 2) + "\n");
const n = o => o.reduce((a,c)=>a+c.registros.length+c.pistas.length+c.sospechosos.length,0);
console.log(`casos=${casos.length} hijos=${n(casos)} conceptos=${conceptos.length}`);
