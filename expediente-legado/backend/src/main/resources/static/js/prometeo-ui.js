(function () {
    "use strict";

    var dialog = document.getElementById("prometeo-menu");
    var trigger = document.getElementById("prometeo-menu-btn");
    if (!dialog || !trigger || typeof dialog.showModal !== "function") {
        return;
    }

    var logrosLista = document.getElementById("prometeo-logros-lista");
    var tarotLista = document.getElementById("prometeo-tarot-lista");
    var contadorTarot = document.getElementById("prometeo-tarot-contador");
    var botonTarot = document.getElementById("prometeo-tarot-revelar");
    var captcha = document.getElementById("prometeo-captcha");
    var preguntaCaptcha = document.getElementById("prometeo-captcha-pregunta");
    var asistente = document.getElementById("prometeo-assistente");
    var textoAsistente = document.getElementById("prometeo-assistente-texto");
    var avatarAsistente = document.querySelector(".prometeo-assistente-avatar");
    var finalAlternativo = document.getElementById("prometeo-final");
    var textoFinal = document.getElementById("prometeo-final-texto");
    var rango = document.getElementById("prometeo-volumen-rango");
    var vidaResumen = document.getElementById("prometeo-vida-resumen");
    var jefeModal = document.getElementById("prometeo-jefe");
    var despidoModal = document.getElementById("prometeo-despido");
    var finalVerdaderoModal = document.getElementById("prometeo-final-verdadero");
    var historiaCartaModal = document.getElementById("prometeo-historia-carta");
    var historiaCartaTitulo = document.getElementById("prometeo-historia-carta-titulo");
    var historiaCartaTexto = document.getElementById("prometeo-historia-carta-texto");
    var historiaCartaOpciones = document.getElementById("prometeo-historia-carta-opciones");
    var finalPoliticoModal = document.getElementById("prometeo-final-politico");
    var finalPoliticoTitulo = document.getElementById("prometeo-final-politico-titulo");
    var finalPoliticoTexto = document.getElementById("prometeo-final-politico-texto");
    var finalPoliticoRibbon = document.getElementById("prometeo-final-politico-ribbon");
    var radiosDificultad = document.querySelectorAll("input[name=\"prometeo-dificultad\"]");
    var audioCtx = null;
    var master = null;
    var ambiente = null;
    var animacionLinceId = null;
    var LLAVE_VOLUMEN = "prometeo-volumen";
    var LLAVE_ESTADO = "prometeo-estado";
    var real = window.PROMETEO_ESTADO_REAL || null;

    /**
     * Vidas y umbral de "acusación precipitada" por dificultad. Normal es
     * la recomendada; fácil/difícil solo mueven estos dos números.
     */
    var DIFICULTADES = {
        facil: { vidasMax: 5, umbralEvidencia: 0.4 },
        normal: { vidasMax: 3, umbralEvidencia: 0.6 },
        dificil: { vidasMax: 2, umbralEvidencia: 0.75 }
    };

    var state = cargarEstado();

    /**
     * Fotogramas del lince por estado de ánimo: cada uno alterna un par de
     * caras para simular parpadeo/gesto mientras el asistente está visible.
     */
    var CARAS_LINCE = {
        neutral: [
            "   /\\_/\\\n  ( o.o )\n   > w <\n  /|   |\\\n (_|   |_)~",
            "   /\\_/\\\n  ( o.o )\n   > w <\n  /|   |\\\n (_|   |_) ~",
            "   /\\_/\\\n  ( -.- )\n   > w <\n  /|   |\\\n (_|   |_)  ~",
            "   /\\_/\\\n  ( o.o )\n   > w <\n  /|   |\\\n (_|   |_) ~"
        ],
        guino: [
            "   /\\_/\\\n  ( ^.- )\n   > w <\n  /|   |\\\n (_|   |_)~",
            "   /\\_/\\\n  ( -.^ )\n   > w <\n  /|   |\\\n (_|   |_)  ~",
            "   /\\_/\\\n  ( ^.- )\n   > w <\n  /|   |\\\n (_|   |_)~~",
            "   /\\_/\\\n  ( -.^ )\n   > w <\n  /|   |\\\n (_|   |_) ~"
        ],
        alerta: [
            "   /\\_/\\\n  ( O.O )\n   >   <\n  /|   |\\\n (_|   |_)|",
            "   /\\_/\\\n  ( 0.0 )\n   >   <\n  /|   |\\\n (_|   |_)!",
            "   /\\_/\\\n  ( O.O )\n   >   <\n  /|   |\\\n (_|   |_)|"
        ],
        triste: [
            "   /\\_/\\\n  ( -.- )\n   > , <\n  /|   |\\\n (_|   |_)_",
            "   /\\_/\\\n  ( -.- )\n   > , <\n  /|   |\\\n (_|   |_),"
        ]
    };

    var INTERVALO_LINCE = { neutral: 1900, guino: 1500, alerta: 450, triste: 2800 };

    /**
     * Arte pixelado de cada carta de tarot: una rejilla de 16x20 (cada
     * carácter es una celda) más una paleta propia por carta. Inspirado en
     * los 22 arcanos mayores del tarot, reinterpretados para la ficción
     * de la oficina en la descripción de cada una.
     */
    var ARTE_TAROT = {
        "el-loco": {
            paleta: { 1: "#0b0810", 2: "#5a6b8a", 3: "#d9cdb0", 4: "#caa23c" },
            filas: [
                "................",
                "................",
                ".......3...4....",
                "......333.444...",
                ".......3.114....",
                ".......21.......",
                ".......12.......",
                ".......22.......",
                "......2..2......",
                "......2..2......",
                "......2..2......",
                ".....2....2.....",
                ".....2....2.....",
                "....2......2....",
                "....2......2....",
                "................",
                "................",
                "................",
                "................",
                "................"
            ]
        },
        "el-mago": {
            paleta: { 1: "#0b0810", 2: "#3d2f55", 3: "#d9cdb0", 4: "#caa23c" },
            filas: [
                "................",
                ".............4..",
                "......4..4..1...",
                "........3..1....",
                ".......333.1....",
                "........3.1.....",
                "........21......",
                "........2.......",
                ".......222......",
                ".......222......",
                "......22222.....",
                "......22222.....",
                ".....2222222....",
                ".....2222222....",
                "....222222222...",
                "....222222222...",
                "................",
                "................",
                "................",
                "................"
            ]
        },
        "la-sacerdotisa": {
            paleta: { 1: "#0b0810", 2: "#243b4a", 3: "#d9cdb0", 4: "#7fa8c9" },
            filas: [
                "................",
                "........4.......",
                ".......444......",
                ".22...44.44..22.",
                ".22....444...22.",
                ".22....343...22.",
                ".22.....3....22.",
                ".22.....2....22.",
                ".22....222...22.",
                ".22....222...22.",
                ".22...22222..22.",
                ".22...22222..22.",
                ".22..2222222.22.",
                ".22..2222222.22.",
                ".22.22222222222.",
                ".22.22222222222.",
                ".22..........22.",
                "................",
                "................",
                "................"
            ]
        },
        "la-emperatriz": {
            paleta: { 1: "#0b0810", 2: "#5a3a4a", 3: "#d9cdb0", 4: "#caa23c" },
            filas: [
                "................",
                "................",
                "........4.......",
                ".......444......",
                "........3.......",
                ".......333......",
                "........3.......",
                "........2.......",
                ".......222..4...",
                ".......222.444..",
                "......22224.4.4.",
                "......22222.4...",
                ".....22222224...",
                ".....22222224...",
                "....222222224...",
                "....222222222...",
                "...22222222222..",
                "................",
                "................",
                "................"
            ]
        },
        "el-emperador": {
            paleta: { 1: "#0b0810", 2: "#5a2f2f", 3: "#d9cdb0", 4: "#caa23c", 5: "#3a3a3a" },
            filas: [
                "................",
                "................",
                ".......444......",
                ".......444......",
                "........3.......",
                ".......333......",
                "........3.......",
                "........2.......",
                ".......222......",
                ".......222......",
                "......22222.....",
                ".....2222222....",
                "....52222222....",
                "....222222222...",
                "....55555555....",
                "....55555555....",
                "....55555555....",
                "....55555555....",
                "................",
                "................"
            ]
        },
        "el-hierofante": {
            paleta: { 1: "#0b0810", 2: "#2f4a3a", 3: "#d9cdb0", 4: "#caa23c" },
            filas: [
                "................",
                "........4.......",
                ".......444......",
                ".......444......",
                "......44444.....",
                "........3.......",
                ".......333......",
                "........3....3..",
                "........2...3...",
                ".......222.3....",
                ".......222......",
                "......22222.....",
                "......22222.....",
                ".....2222222....",
                ".....2222222....",
                "....222222222...",
                "....222222222...",
                "...22222222222..",
                "................",
                "................"
            ]
        },
        "los-enamorados": {
            paleta: { 1: "#0b0810", 2: "#4a2f3a", 3: "#d9cdb0", 4: "#caa23c", 5: "#2f3a4a" },
            filas: [
                "................",
                "..........4.....",
                ".........444....",
                "..........4.....",
                "................",
                ".....3.....3....",
                "....333...333...",
                ".....3.....3....",
                ".....2.....5....",
                ".....2.....5....",
                "....222...555...",
                "....222...555...",
                "...22222.55555..",
                "...22222.55555..",
                "..2222225555555.",
                "..2222225555555.",
                "................",
                "................",
                "................",
                "................"
            ]
        },
        "el-carro": {
            paleta: { 1: "#0b0810", 2: "#2f3a5a", 3: "#d9cdb0", 4: "#caa23c", 5: "#1a1a1a" },
            filas: [
                "................",
                "........4.......",
                "................",
                "................",
                "........3.......",
                ".......333......",
                "........3.......",
                "........2.......",
                ".......222......",
                ".......222......",
                "......22222.....",
                "......22222.....",
                ".....2222222....",
                ".....2222222....",
                "....55555555....",
                "....55555555....",
                "....51555515....",
                "....111..111....",
                ".....1....1.....",
                "................"
            ]
        },
        "la-fuerza": {
            paleta: { 1: "#0b0810", 2: "#4a3a2f", 3: "#d9cdb0", 4: "#caa23c" },
            filas: [
                "................",
                "................",
                "................",
                "......3.........",
                ".....333........",
                "......3.........",
                "......2.........",
                ".....222........",
                ".....222........",
                "....22222.......",
                "....22222.......",
                "...2222222....4.",
                "........44444444",
                "........4444444.",
                "........4444444.",
                "........4444444.",
                "...............4",
                "...............4",
                "................",
                "................"
            ]
        },
        "el-ermitanio": {
            paleta: { 1: "#050308", 2: "#20232a", 3: "#c9c2b8" },
            filas: [
                ".............3..",
                "............333.",
                ".............3..",
                ".............2..",
                "............2...",
                ".......1....2...",
                "......111..2....",
                ".......1...2....",
                ".......2..2.....",
                "......222.......",
                "......222.......",
                ".....22222......",
                ".....22222......",
                "....2222222.....",
                "....2222222.....",
                "...222222222....",
                "...222222222....",
                "..22222222222...",
                "................",
                "................"
            ]
        },
        "la-rueda": {
            paleta: { 1: "#0b0810", 3: "#d9cdb0", 4: "#caa23c" },
            filas: [
                "................",
                "................",
                "........4.......",
                ".....4444444....",
                "...44...4...44..",
                "...44...4...44..",
                "..4..4..4..4..4.",
                "..4...4.4.4...4.",
                "..4....434....4.",
                ".444444333444444",
                "..4....434....4.",
                "..4...4.4.4...4.",
                "..4..4..4..4..4.",
                "...44...4...44..",
                "...44...4...44..",
                ".....4444444....",
                "........4.......",
                "................",
                "................",
                "................"
            ]
        },
        "la-justicia": {
            paleta: { 1: "#0b0810", 2: "#3a3a4a", 3: "#d9cdb0", 4: "#caa23c" },
            filas: [
                "................",
                "............4...",
                "............4...",
                ".........4444444",
                "...4....3...4...",
                "...4...333..4...",
                "...4....3...4...",
                "...4....2...4...",
                "..444..222..4...",
                ".......222..4...",
                "......22222.4...",
                "......22222.....",
                ".....2222222....",
                ".....2222222....",
                "....222222222...",
                "....222222222...",
                "................",
                "................",
                "................",
                "................"
            ]
        },
        "el-colgado": {
            paleta: { 1: "#0b0810", 2: "#2f3a4a", 3: "#d9cdb0" },
            filas: [
                "................",
                "................",
                "..1111112111111.",
                "........2.......",
                "........2.......",
                "........2.......",
                "......2.2.2.....",
                ".......222......",
                "........2.......",
                "................",
                "................",
                "........3.......",
                ".......333......",
                "........2.......",
                ".......2.2......",
                ".......2.2......",
                "......2...2.....",
                "......2...2.....",
                "................",
                "................"
            ]
        },
        "la-muerte": {
            paleta: { 1: "#050308", 2: "#161018" },
            filas: [
                "................",
                "................",
                "...........1....",
                "..........11....",
                ".........1.1....",
                "......1.....1...",
                ".....111....1...",
                "......1.....1...",
                "......2.....1...",
                ".....222.....1..",
                ".....222.....1..",
                "....22222....1..",
                "....22222....1..",
                "...2222222....1.",
                "...2222222....1.",
                "..222222222...1.",
                "..222222222.....",
                ".22222222222....",
                "................",
                "................"
            ]
        },
        "la-templanza": {
            paleta: { 1: "#0b0810", 2: "#2f4a4a", 3: "#d9cdb0", 4: "#caa23c" },
            filas: [
                "................",
                "................",
                "................",
                "........3.......",
                "...4...333...4..",
                "....4...3...4...",
                ".....4..2..4....",
                ".......222......",
                "...4...222...4..",
                "..4444444444444.",
                "...4..22222..4..",
                ".....2222222....",
                ".....2222222....",
                "....222222222...",
                "....222222222...",
                "................",
                "................",
                "................",
                "................",
                "................"
            ]
        },
        "el-diablo": {
            paleta: { 1: "#0b0810", 2: "#3a1616", 3: "#8a2f2f", 4: "#5a2020" },
            filas: [
                ".....4.....4....",
                ".....4.....4....",
                "......4...4.....",
                "................",
                "........3.......",
                ".......333......",
                "........3.......",
                "........2.......",
                ".......222......",
                "......22222.....",
                ".....2222222....",
                ".....2222222....",
                "....222222222...",
                "...22221112222..",
                ".....11...11....",
                "....1.......1...",
                "....3.......3...",
                "...333.....333..",
                "....3.......3...",
                "................"
            ]
        },
        "la-torre": {
            paleta: { 1: "#0b0810", 2: "#3a3028", 4: "#caa23c", 5: "#7a2416" },
            filas: [
                "........4.......",
                ".......4........",
                ".......4.....2..",
                "..2...44........",
                "....55554455....",
                "....55555555....",
                "....55555555....",
                ".....222222.....",
                ".....222222.....",
                ".....222222.....",
                ".....222222.....",
                ".....222222.....",
                ".....222222.....",
                ".....222222.....",
                ".....222222.....",
                ".....222222.....",
                ".....222222.....",
                ".....222222.....",
                ".....222222.....",
                "................"
            ]
        },
        "la-estrella": {
            paleta: { 1: "#0b0810", 3: "#d9cdb0", 4: "#caa23c", 5: "#7fa8c9" },
            filas: [
                ".....4..4..4....",
                "......4.4.4.....",
                ".......444......",
                ".....4444444....",
                ".......444......",
                "......4.4.4.....",
                ".....4..4..4....",
                "................",
                "..5.............",
                "..............5.",
                "................",
                "................",
                "...5....3.......",
                ".......333......",
                "........3.......",
                "........3.......",
                ".......333......",
                "......33333.....",
                ".....3333333....",
                "................"
            ]
        },
        "la-luna": {
            paleta: { 1: "#0b0810", 2: "#2f2a3a", 3: "#d9cdb0", 4: "#caa23c" },
            filas: [
                "................",
                "........4.......",
                "......444.......",
                "......4.........",
                ".....44.........",
                "......4.........",
                "......44444.....",
                "........4.......",
                "................",
                "................",
                "................",
                "................",
                "..222...3..222..",
                "..222...3..222..",
                "..222...3..222..",
                "..222...3..222..",
                "..222...3..222..",
                "..222...3..222..",
                "........3.......",
                "................"
            ]
        },
        "el-sol": {
            paleta: { 1: "#0b0810", 3: "#d9cdb0", 4: "#e8c76b" },
            filas: [
                "........4.......",
                "...4....4....4..",
                "....4...4...4...",
                "......44444.....",
                ".....4444444....",
                ".....4444444....",
                ".44.444444444.44",
                ".....4444444....",
                ".....4444444....",
                "......44444.....",
                "....4...4...4...",
                "...4....4....4..",
                "........4.......",
                "................",
                "................",
                "........3.......",
                ".......333......",
                "........3.......",
                "......33333.....",
                "................"
            ]
        },
        "el-juicio": {
            paleta: { 1: "#0b0810", 3: "#d9cdb0", 4: "#caa23c" },
            filas: [
                "................",
                "................",
                "........3.......",
                ".......334444...",
                ".......444......",
                ".....44...44....",
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
                "......3...3.....",
                "......3...3.....",
                ".......333......",
                ".......333......",
                "........3.......",
                "................",
                "................",
                "................"
            ]
        },
        "el-mundo": {
            paleta: { 1: "#0b0810", 3: "#d9cdb0", 4: "#caa23c" },
            filas: [
                "................",
                "................",
                "........4.......",
                ".....4444444....",
                "...44.......44..",
                "..44....3....44.",
                "..4....333....4.",
                ".4......3......4",
                ".4......3......4",
                ".4.....333.....4",
                "44....3.3.3....4",
                ".4...3..3..3...4",
                ".4......3......4",
                ".4......3......4",
                "..4....3.3....4.",
                "..44..3...3..44.",
                "...443.....344..",
                ".....4444444....",
                "........4.......",
                "................"
            ]
        }
    };

    /**
     * Ocho cartas no se desbloquean por progreso: se descubren como una
     * frase oculta dentro de un documento de un caso concreto. Al
     * encontrarlas cuentan un relato breve y ofrecen cuatro salidas
     * satíricas — comunismo de lujo automatizado, centrista,
     * socialdemócrata y neoliberal — cuyo voto acumulado decide, al
     * final, uno de los cuatro finales políticos.
     */
    var HISTORIAS_CARTAS = {
        "la-justicia": {
            texto: "El cierre de caja de 1999 nunca cuadró. Faltan 47 pesetas que nadie reclamó "
                + "y sobran 47 pesetas que nadie explicó. Alguien, en algún momento, decidió que "
                + "ambas cosas eran la misma cosa. ¿Qué hacer con esa discrepancia que lleva "
                + "veintisiete años cuadrando sola?",
            opciones: [
                { eje: "comunismo", etiqueta: "Comunismo de lujo automatizado",
                    texto: "Abolir la caja. Que las 47 pesetas se repartan entre todos los empleados a "
                        + "partes iguales, incluidos los que ya no trabajan aquí." },
                { eje: "centrista", etiqueta: "Vía centrista",
                    texto: "Formar una mesa de diálogo entre las 47 pesetas que faltan y las que sobran, "
                        + "sin comprometerse a ningún resultado antes de la próxima legislatura contable." },
                { eje: "socialdemocrata", etiqueta: "Vía socialdemócrata",
                    texto: "Crear una comisión de seguimiento del desajuste, con informe anual y "
                        + "compromiso de revisión en cuatro años." },
                { eje: "neoliberal", etiqueta: "Vía neoliberal",
                    texto: "Privatizar la discrepancia. Sacarla a concurso. El mejor postor se queda con "
                        + "las 47 pesetas y con la culpa." }
            ]
        },
        "la-rueda": {
            texto: "La silla 4-B lleva seis años esperando una firma que autorice su propia "
                + "existencia. Cada vez que el trámite avanza una casilla, aparece una casilla "
                + "nueva delante. Alguien, en algún despacho, puede detener la rueda. O puede que "
                + "solo la esté empujando.",
            opciones: [
                { eje: "comunismo", etiqueta: "Comunismo de lujo automatizado",
                    texto: "Eliminar el trámite. La silla 4-B pasa a pertenecer a quien la necesite, sin "
                        + "formulario, sin firma, sin 4-B." },
                { eje: "centrista", etiqueta: "Vía centrista",
                    texto: "Rebautizar el trámite como 'silla 4-B (en revisión)' y dejarlo así "
                        + "indefinidamente, para no sentar precedente en ningún sentido." },
                { eje: "socialdemocrata", etiqueta: "Vía socialdemócrata",
                    texto: "Aprobar la silla con carácter provisional, sujeta a una evaluación de impacto "
                        + "silla-trabajador cada dos años." },
                { eje: "neoliberal", etiqueta: "Vía neoliberal",
                    texto: "Externalizar la silla 4-B a una empresa de mobiliario que cobre por uso. "
                        + "Quien necesite sentarse, que puje." }
            ]
        },
        "el-juicio": {
            texto: "A E. Montalvo lo trasladan de departamento por tercera vez este año, aunque "
                + "nadie recuerda haberlo autorizado ni haberlo pedido. El expediente dice que "
                + "el traspaso 'responde a criterios objetivos'. Nadie ha visto esos criterios. "
                + "Alguien tiene que decidir qué se hace con Montalvo, otra vez.",
            opciones: [
                { eje: "comunismo", etiqueta: "Comunismo de lujo automatizado",
                    texto: "Abolir los departamentos. Montalvo trabaja donde quiera, cuando quiera, o no "
                        + "trabaja, y el departamento se adapta a Montalvo." },
                { eje: "centrista", etiqueta: "Vía centrista",
                    texto: "Trasladarlo a un departamento intermedio, a medio camino entre el anterior y "
                        + "el siguiente, hasta nuevo aviso." },
                { eje: "socialdemocrata", etiqueta: "Vía socialdemócrata",
                    texto: "Garantizar estabilidad mediante un contrato de traspasos regulados, con "
                        + "derecho a apelar cada reasignación." },
                { eje: "neoliberal", etiqueta: "Vía neoliberal",
                    texto: "Que Montalvo compita por su propio puesto cada trimestre. La motivación, "
                        + "dicen, mejora con la incertidumbre." }
            ]
        },
        "la-luna": {
            texto: "El contrato con Carcosa Servicios Escénicos incluye una cláusula que nadie ha "
                + "leído entera: dice que la función 'continuará representándose mientras exista "
                + "un público, aunque el público no lo sepa'. Nadie quiere preguntar qué pasa si "
                + "se cancela.",
            opciones: [
                { eje: "comunismo", etiqueta: "Comunismo de lujo automatizado",
                    texto: "Cancelar el contrato y declarar la función patrimonio común: que la "
                        + "represente quien quiera, gratis, para siempre." },
                { eje: "centrista", etiqueta: "Vía centrista",
                    texto: "Renovar el contrato 'con reservas', sin especificar cuáles, para poder "
                        + "invocarlas después si hace falta." },
                { eje: "socialdemocrata", etiqueta: "Vía socialdemócrata",
                    texto: "Renovar con una cláusula de revisión social que garantice condiciones dignas "
                        + "al elenco, sea quien sea el elenco." },
                { eje: "neoliberal", etiqueta: "Vía neoliberal",
                    texto: "Renovar y ampliar. Si el público no sabe que es público, es un mercado sin "
                        + "competencia. Hay que explotarlo." }
            ]
        },
        "el-carro": {
            texto: "El memorando 1978-014 se ha vuelto a presentar, idéntico, en 1993 y en 2007. "
                + "Nadie sabe quién lo redactó la primera vez ni por qué vuelve. Alguien tiene que "
                + "decidir si se aprueba otra vez, se archiva para siempre, o se deja avanzar sin "
                + "saber hacia dónde.",
            opciones: [
                { eje: "comunismo", etiqueta: "Comunismo de lujo automatizado",
                    texto: "Aprobarlo de una vez por todas y liberar el recurso que llevaba pidiendo "
                        + "desde 1978, sin más trámite." },
                { eje: "centrista", etiqueta: "Vía centrista",
                    texto: "Reenviarlo a estudio, otra vez, sin fecha límite, para que el ciclo se "
                        + "resuelva solo con el tiempo." },
                { eje: "socialdemocrata", etiqueta: "Vía socialdemócrata",
                    texto: "Aprobarlo parcialmente, con revisión programada para dentro de otros catorce "
                        + "años, por si acaso." },
                { eje: "neoliberal", etiqueta: "Vía neoliberal",
                    texto: "Subastar el memorando al mejor postor. Quien lo compre, que decida qué hacer "
                        + "con él." }
            ]
        },
        "el-sol": {
            texto: "El acta original de constitución de la empresa nunca circuló. Dice cosas que "
                + "la versión oficial no dice. Es, quizás, el único documento de todo el archivo "
                + "que no necesita ninguna firma para ser verdad. Alguien tiene que decidir si se "
                + "hace pública.",
            opciones: [
                { eje: "comunismo", etiqueta: "Comunismo de lujo automatizado",
                    texto: "Publicarla entera, sin editar, y disolver la empresa en una asamblea abierta "
                        + "a cualquiera que quisiera entrar." },
                { eje: "centrista", etiqueta: "Vía centrista",
                    texto: "Publicar un resumen, sin las partes 'susceptibles de generar controversia', "
                        + "que resultan ser casi todas." },
                { eje: "socialdemocrata", etiqueta: "Vía socialdemócrata",
                    texto: "Publicarla con un informe de acompañamiento que explique el contexto y "
                        + "proponga reformas graduales." },
                { eje: "neoliberal", etiqueta: "Vía neoliberal",
                    texto: "Vender los derechos a quien mejor la sepa monetizar. La verdad, bien "
                        + "gestionada, es un activo." }
            ]
        },
        "la-emperatriz": {
            texto: "La herencia Karamázov lleva generaciones sin repartirse: cada heredero firma "
                + "en nombre de alguien que ya no puede firmar. Nadie recuerda quién empezó. "
                + "Alguien, ahora, tiene que decidir cómo se reparte lo que ya nadie sabe de quién "
                + "era.",
            opciones: [
                { eje: "comunismo", etiqueta: "Comunismo de lujo automatizado",
                    texto: "Repartirla a partes iguales entre todos los que alguna vez trabajaron en el "
                        + "expediente, herederos o no." },
                { eje: "centrista", etiqueta: "Vía centrista",
                    texto: "Congelarla indefinidamente hasta que los herederos 'lleguen a un consenso', "
                        + "sin fijar ningún mecanismo para lograrlo." },
                { eje: "socialdemocrata", etiqueta: "Vía socialdemócrata",
                    texto: "Repartirla según necesidad certificada, con una comisión de herederos que "
                        + "revise cada solicitud." },
                { eje: "neoliberal", etiqueta: "Vía neoliberal",
                    texto: "Sacarla a subasta entre los propios herederos. Gana quien más pueda pagar "
                        + "por lo que ya era suyo." }
            ]
        },
        "la-sacerdotisa": {
            texto: "El empleado #427 nunca tuvo nombre en ningún documento, solo número. Alguien, "
                + "en algún cajón, sabe quién fue. No lo dice. Alguien más tiene que decidir si "
                + "merece la pena preguntarlo.",
            opciones: [
                { eje: "comunismo", etiqueta: "Comunismo de lujo automatizado",
                    texto: "Devolverle el nombre, borrar el número de todos los archivos y hacerlo "
                        + "público como acto reparador." },
                { eje: "centrista", etiqueta: "Vía centrista",
                    texto: "Dejar el expediente como está, ni número ni nombre, 'por respeto a todas las "
                        + "partes', sin especificar cuáles." },
                { eje: "socialdemocrata", etiqueta: "Vía socialdemócrata",
                    texto: "Abrir una investigación oficial, con plazo, presupuesto y un informe final "
                        + "que probablemente nadie lea." },
                { eje: "neoliberal", etiqueta: "Vía neoliberal",
                    texto: "Vender el expediente a un interesado externo. La identidad, como todo, tiene "
                        + "un precio de mercado." }
            ]
        }
    };

    var FINALES_POLITICOS = {
        comunismo: {
            ribbon: "Final: comunismo de lujo totalmente automatizado",
            titulo: "El expediente se disuelve en la abundancia",
            texto: "SIGA-98 deja de existir como sistema de control: se convierte en un directorio "
                + "abierto que cualquiera puede editar, sin aprobación de nadie. Los ocho "
                + "expedientes se cierran a la vez, repartidos entre quienes alguna vez los "
                + "tocaron, culpables y víctimas por igual. El Comité Ad Honorem es invitado a la "
                + "asamblea, pero solo como uno más. Nadie sabe muy bien qué hacer con tanta "
                + "abundancia, así que, por costumbre, alguien redacta un acta."
        },
        centrista: {
            ribbon: "Final: vía centrista",
            titulo: "Todo queda, oficialmente, en revisión",
            texto: "Ningún expediente se cierra ni se abre del todo. Se crea una mesa de diálogo "
                + "entre el pasado y el presente del archivo, sin fecha de conclusión ni "
                + "compromiso vinculante. El Comité Ad Honorem felicita la 'madurez institucional' "
                + "de no tomar partido. Usted sigue siendo auditor, con el mismo sueldo, el mismo "
                + "escritorio, y el mismo expediente, indefinidamente 'en revisión'."
        },
        socialdemocrata: {
            ribbon: "Final: vía socialdemócrata",
            titulo: "Se aprueba una reforma gradual del archivo",
            texto: "Los ocho expedientes se cierran con una comisión de seguimiento para cada uno, "
                + "informe anual y cláusula de revisión a cuatro años. El Comité Ad Honorem acepta "
                + "ceder una parte de su autoridad, a cambio de conservarla toda en la práctica. "
                + "Nadie queda plenamente satisfecho, lo cual, según el propio informe final, 'es "
                + "la señal de que el acuerdo fue justo'."
        },
        neoliberal: {
            ribbon: "Final: vía neoliberal",
            titulo: "El archivo sale a bolsa",
            texto: "SIGA-98 se privatiza. Los ocho expedientes se venden por separado al mejor "
                + "postor, incluido el suyo. El Comité Ad Honorem se convierte en accionista "
                + "mayoritario de sí mismo. Usted recibe una carta de agradecimiento por 'los "
                + "servicios prestados' y una oferta para seguir auditando el mismo archivo, ahora "
                + "como colaborador externo, sin prestaciones."
        }
    };

    function pixelArtSvg(idCarta) {
        var arte = ARTE_TAROT[idCarta];
        if (!arte) {
            return "";
        }
        var alto = arte.filas.length;
        var ancho = arte.filas[0].length;
        var rects = "";
        for (var y = 0; y < alto; y++) {
            for (var x = 0; x < ancho; x++) {
                var color = arte.paleta[arte.filas[y].charAt(x)];
                if (color) {
                    rects += "<rect x='" + x + "' y='" + y + "' width='1' height='1' fill='" + color + "'/>";
                }
            }
        }
        return "<svg viewBox='0 0 " + ancho + " " + alto + "' class='prometeo-tarot-pixelart' shape-rendering='crispEdges' aria-hidden='true'>" + rects + "</svg>";
    }

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

    function cargarEstado() {
        var datos = {};
        try {
            datos = JSON.parse(window.localStorage.getItem(LLAVE_ESTADO) || "{}");
        } catch (error) {
            datos = {};
        }

        var logrosActuales = [
            { id: "primer-mirada", titulo: "Primer mirada", descripcion: "Abriste el menú de verdad.", desbloqueado: false },
            { id: "sospecha", titulo: "Sospecha", descripcion: "Te topaste con una verificación falsa.", desbloqueado: false },
            { id: "primer-expediente", titulo: "Primer expediente", descripcion: "Cerraste un caso con una acusación.", desbloqueado: false },
            { id: "archivo-completo", titulo: "El archivo completo", descripcion: "Resolviste todos los expedientes a tu cargo.", desbloqueado: false },
            { id: "acceso-privilegiado", titulo: "Acceso privilegiado", descripcion: "Alguien le franqueó el paso a un nivel que no debería existir.", desbloqueado: false },
            { id: "reasignado", titulo: "Reasignado", descripcion: "El sistema decidió que ya no le necesitaba.", desbloqueado: false },
            { id: "final-verdadero", titulo: "Las cuatro cartas", descripcion: "Cerró el archivo sin canjear ni una sola carta.", desbloqueado: false }
        ];

        var tarotActual = [
            { id: "el-loco", nombre: "El Loco", descripcion: "Empezó sin saber en qué expediente se estaba metiendo.", collected: true, gastada: false, requisito: "" },
            { id: "el-mago", nombre: "El Mago", descripcion: "Convierte un formulario en otro con solo cambiar el membrete.", collected: false, gastada: false, requisito: "Descubra su primera pista." },
            { id: "la-sacerdotisa", nombre: "La Sacerdotisa", descripcion: "Sabe lo que hay en el cajón cerrado y no lo dice.", collected: false, gastada: false, requisito: "Hay algo oculto en «El expediente del empleado #427»." },
            { id: "la-emperatriz", nombre: "La Emperatriz", descripcion: "Firma en nombre de alguien que ya no trabaja aquí.", collected: false, gastada: false, requisito: "Hay algo oculto en «El expediente de la herencia Karamázov»." },
            { id: "el-emperador", nombre: "El Emperador", descripcion: "Su despacho existe aunque nadie lo haya visto abierto.", collected: false, gastada: false, requisito: "Consiga acceso administrativo." },
            { id: "el-hierofante", nombre: "El Hierofante", descripcion: "Dicta el procedimiento correcto, que cambia según el día.", collected: false, gastada: false, requisito: "Cierre un expediente con una acusación." },
            { id: "los-enamorados", nombre: "Los Enamorados", descripcion: "Dos documentos que no deberían ir juntos, van juntos.", collected: false, gastada: false, requisito: "Complete la investigación de un expediente." },
            { id: "el-carro", nombre: "El Carro", descripcion: "Avanza aunque nadie sepa hacia dónde apunta el trámite.", collected: false, gastada: false, requisito: "Hay algo oculto en «El expediente MEMO-1978-014 (y 1993, y 2007)»." },
            { id: "la-fuerza", nombre: "La Fuerza", descripcion: "No necesita imponerse: solo aguanta más rondas de las que debería.", collected: false, gastada: false, requisito: "Juegue en dificultad difícil." },
            { id: "el-ermitanio", nombre: "El Ermitaño", descripcion: "Se quedó solo con el expediente después de que lo señalaran.", collected: false, gastada: false, requisito: "Pierda una vida por acusar sin fundamento." },
            { id: "la-rueda", nombre: "La Rueda de la Fortuna", descripcion: "El trámite gira y siempre cae del lado que no esperaba.", collected: false, gastada: false, requisito: "Hay algo oculto en «El trámite de la silla 4-B»." },
            { id: "la-justicia", nombre: "La Justicia", descripcion: "Pesa las pruebas después de haber decidido ya la sentencia.", collected: false, gastada: false, requisito: "Hay algo oculto en «El cierre de caja de 1999»." },
            { id: "el-colgado", nombre: "El Colgado", descripcion: "Cuelga de una decisión que todavía no ha terminado de tomar.", collected: false, gastada: false, requisito: "Llegue a un enfrentamiento." },
            { id: "la-muerte", nombre: "La Muerte", descripcion: "No es el final. Aquí nunca lo es.", collected: false, gastada: false, requisito: "Sea reasignado por acumular demasiados fallos." },
            { id: "la-templanza", nombre: "La Templanza", descripcion: "Cambia una certeza por otra cosa que todavía no sabe si necesita.", collected: false, gastada: false, requisito: "Canjee una carta por una vida." },
            { id: "el-diablo", nombre: "El Diablo", descripcion: "Le hizo marcar una casilla que no significaba nada. Y usted la marcó.", collected: false, gastada: false, requisito: "Tropiece con una verificación falsa." },
            { id: "la-torre", nombre: "La Torre", descripcion: "Todo lo que creía firme se cae de golpe, y sigue ahí de pie de todos modos.", collected: false, gastada: false, requisito: "Deje pasar demasiado tiempo sin hacer nada." },
            { id: "la-estrella", nombre: "La Estrella", descripcion: "Una luz pequeña, pero constante, entre tanto expediente sin cerrar.", collected: false, gastada: false, requisito: "Descubra al menos veinte pistas." },
            { id: "la-luna", nombre: "La Luna", descripcion: "Ilumina lo mismo de siempre, pero ahora se ve todo lo que había alrededor.", collected: false, gastada: false, requisito: "Hay algo oculto en «Contrato de fin de año con Carcosa Servicios Escénicos»." },
            { id: "el-sol", nombre: "El Sol", descripcion: "El único documento que no necesita ninguna firma para ser verdad.", collected: false, gastada: false, requisito: "Hay algo oculto en un expediente confidencial. Necesitará acceso administrativo." },
            { id: "el-juicio", nombre: "El Juicio", descripcion: "Ha señalado a alguien en cada expediente. Ahora que decida el sistema.", collected: false, gastada: false, requisito: "Hay algo oculto en «Traspaso de personal: expediente de E. Montalvo»." },
            { id: "el-mundo", nombre: "El Mundo", descripcion: "Las veintiuna cartas anteriores, cerrando el círculo.", collected: false, gastada: false, requisito: "Reúna el resto de cartas sin gastar ninguna." }
        ];

        var logros = fusionarConGuardado(datos.logros || [], logrosActuales, ["desbloqueado"], {});
        var tarot = fusionarConGuardado(datos.tarot || [], tarotActual, ["collected", "gastada"],
            { "la-sacerdotisa": "el-ojo", "el-hierofante": "la-sombra", "el-emperador": "el-hombre-amarillo" });
        var dificultad = (datos.dificultad && DIFICULTADES[datos.dificultad]) ? datos.dificultad : "normal";

        return {
            logros: logros,
            tarot: tarot,
            lastProgressAt: datos.lastProgressAt || Date.now(),
            assistantShown: Boolean(datos.assistantShown),
            finalShown: Boolean(datos.finalShown),
            ultimoMensajeAsistente: datos.ultimoMensajeAsistente || null,
            dificultad: dificultad,
            vida: typeof datos.vida === "number" ? datos.vida : DIFICULTADES[dificultad].vidasMax,
            jefeVisto: Boolean(datos.jefeVisto),
            finalVerdaderoShown: Boolean(datos.finalVerdaderoShown),
            despidoShown: Boolean(datos.despidoShown),
            perdioVidaAlgunaVez: Boolean(datos.perdioVidaAlgunaVez),
            vioCombateAlgunaVez: Boolean(datos.vioCombateAlgunaVez),
            pasoPorDespidoAlgunaVez: Boolean(datos.pasoPorDespidoAlgunaVez),
            vioFinalAlternativoAlgunaVez: Boolean(datos.vioFinalAlternativoAlgunaVez),
            historiasCartas: datos.historiasCartas || {},
            finalPoliticoShown: Boolean(datos.finalPoliticoShown),
            saludoVisto: Boolean(datos.saludoVisto)
        };
    }

    function guardarEstado() {
        window.localStorage.setItem(LLAVE_ESTADO, JSON.stringify(state));
    }

    function marcarProgreso() {
        state.lastProgressAt = Date.now();
        state.assistantShown = false;
        state.finalShown = false;
        guardarEstado();
        detenerAnimacionLince();
        if (asistente) {
            asistente.hidden = true;
        }
        if (finalAlternativo) {
            finalAlternativo.hidden = true;
        }
    }

    function desbloquearLogro(id) {
        var logro = state.logros.find(function (item) {
            return item.id === id;
        });
        if (logro && !logro.desbloqueado) {
            logro.desbloqueado = true;
            marcarProgreso();
            renderLogros();
            return true;
        }
        return false;
    }

    function renderLogros() {
        if (!logrosLista) {
            return;
        }

        logrosLista.innerHTML = "";
        state.logros.forEach(function (logro) {
            var item = document.createElement("article");
            item.className = "prometeo-achievement-item" + (logro.desbloqueado ? " is-unlocked" : "");
            item.innerHTML = "<strong>" + logro.titulo + "</strong><span>" + logro.descripcion + "</span>";
            logrosLista.appendChild(item);
        });
    }

    function renderTarot() {
        if (!tarotLista || !contadorTarot) {
            return;
        }

        var coleccionadas = state.tarot.filter(function (carta) {
            return carta.collected;
        }).length;
        contadorTarot.textContent = coleccionadas + " / " + state.tarot.length + " cartas reveladas";
        tarotLista.innerHTML = "";

        state.tarot.forEach(function (carta) {
            var card = document.createElement("article");
            card.className = "prometeo-tarot-card" + (carta.collected ? " is-collected" : " is-sealed");
            var arte = carta.collected ? pixelArtSvg(carta.id) : "";
            var canjear = (carta.collected && !carta.gastada)
                ? "<button type='button' class='prometeo-btn-secundario prometeo-tarot-canjear' data-canjear-carta='" + carta.id + "'>Canjear por una vida</button>"
                : "";
            var estadoPie = carta.gastada
                ? "<span class='prometeo-pill'>Gastada</span>"
                : (carta.collected
                    ? "<span class='prometeo-pill'>Revelada</span>"
                    : "<span class='prometeo-pill'>Sellada</span>" +
                        (carta.requisito ? "<small class='prometeo-tarot-requisito'>" + carta.requisito + "</small>" : ""));
            card.innerHTML = "<div class='prometeo-tarot-card-cuerpo'>" + arte +
                "<div><strong>" + carta.nombre + "</strong><small>" + carta.descripcion + "</small>" + canjear + "</div></div>" +
                estadoPie;
            tarotLista.appendChild(card);
        });

        tarotLista.querySelectorAll("[data-canjear-carta]").forEach(function (boton) {
            boton.addEventListener("click", function () {
                canjearCartaPorVida(boton.getAttribute("data-canjear-carta"));
            });
        });
    }

    /**
     * Compara el progreso real (casos resueltos, pistas, veredictos, acceso
     * admin) contra las cartas/logros ya desbloqueados y sincroniza los que
     * falten. Devuelve true si algo cambió, para poder avisar al jugador.
     */
    function desbloquearCarta(id) {
        var carta = state.tarot.find(function (c) {
            return c.id === id;
        });
        if (carta && !carta.collected) {
            carta.collected = true;
            return true;
        }
        return false;
    }

    function sincronizarConEstadoReal() {
        if (!real) {
            return false;
        }
        var huboNovedad = false;

        if (real.pistasDescubiertas >= 1 && desbloquearCarta("el-mago")) {
            huboNovedad = true;
        }
        if (real.esAdmin && desbloquearCarta("el-emperador")) {
            huboNovedad = true;
        }
        if (real.veredictosEmitidos >= 1 && desbloquearCarta("el-hierofante")) {
            huboNovedad = true;
        }
        if (real.casosResueltos >= 1 && desbloquearCarta("los-enamorados")) {
            huboNovedad = true;
        }
        if (state.dificultad === "dificil" && desbloquearCarta("la-fuerza")) {
            huboNovedad = true;
        }
        if (state.perdioVidaAlgunaVez && desbloquearCarta("el-ermitanio")) {
            huboNovedad = true;
        }
        if (state.vioCombateAlgunaVez && desbloquearCarta("el-colgado")) {
            huboNovedad = true;
        }
        if (state.pasoPorDespidoAlgunaVez && desbloquearCarta("la-muerte")) {
            huboNovedad = true;
        }
        if (state.tarot.some(function (c) { return c.gastada; }) && desbloquearCarta("la-templanza")) {
            huboNovedad = true;
        }
        var logroSospecha = state.logros.find(function (l) {
            return l.id === "sospecha";
        });
        if (logroSospecha && logroSospecha.desbloqueado && desbloquearCarta("el-diablo")) {
            huboNovedad = true;
        }
        if (state.vioFinalAlternativoAlgunaVez && desbloquearCarta("la-torre")) {
            huboNovedad = true;
        }
        if (real.pistasDescubiertas >= 20 && desbloquearCarta("la-estrella")) {
            huboNovedad = true;
        }

        var otrasCompletas = state.tarot.filter(function (c) {
            return c.id !== "el-mundo";
        }).every(function (c) {
            return c.collected && !c.gastada;
        });
        if (otrasCompletas && real.totalCasosPrincipales > 0 && real.casosResueltos >= real.totalCasosPrincipales
                && desbloquearCarta("el-mundo")) {
            huboNovedad = true;
        }

        if (real.veredictosEmitidos >= 1 && desbloquearLogro("primer-expediente")) {
            huboNovedad = true;
        }
        if (real.totalCasosPrincipales > 0 && real.casosResueltos >= real.totalCasosPrincipales
                && desbloquearLogro("archivo-completo")) {
            huboNovedad = true;
        }
        if (real.esAdmin && desbloquearLogro("acceso-privilegiado")) {
            huboNovedad = true;
        }

        if (huboNovedad) {
            marcarProgreso();
            renderTarot();
            renderLogros();
        }
        comprobarFinalVerdadero();
        return huboNovedad;
    }

    /**
     * Vidas, dificultad y las cartas de tarot como recurso canjeable: el
     * jefe amenaza con "reasignarle" si acusa sin fundamento, pero cada
     * carta gastada para recuperar una vida cierra la puerta al final
     * verdadero, que exige las cuatro intactas.
     */
    function renderVida() {
        if (!vidaResumen) {
            return;
        }
        var max = DIFICULTADES[state.dificultad].vidasMax;
        var pips = "";
        for (var i = 0; i < max; i++) {
            pips += "<span class='prometeo-vida-pip " + (i < state.vida ? "is-llena" : "is-vacia") + "'>&#9679;</span>";
        }
        vidaResumen.innerHTML = "<strong>Vida</strong>" + pips;
    }

    function mostrarDespido() {
        state.pasoPorDespidoAlgunaVez = true;
        if (!despidoModal || state.despidoShown) {
            guardarEstado();
            return;
        }
        despidoModal.hidden = false;
        state.despidoShown = true;
        guardarEstado();
        desbloquearLogro("reasignado");
        tic(220);
    }

    function perderVida(cantidad) {
        var anterior = state.vida;
        state.vida = Math.max(0, state.vida - cantidad);
        if (state.vida < anterior) {
            state.perdioVidaAlgunaVez = true;
        }
        guardarEstado();
        renderVida();
        if (anterior > 0 && state.vida === 0) {
            mostrarDespido();
        }
    }

    function canjearCartaPorVida(idCarta) {
        var carta = state.tarot.find(function (c) {
            return c.id === idCarta;
        });
        if (!carta || !carta.collected || carta.gastada) {
            return;
        }
        carta.gastada = true;
        var anterior = state.vida;
        var max = DIFICULTADES[state.dificultad].vidasMax;
        state.vida = Math.min(max, state.vida + 1);
        if (anterior === 0 && state.vida > 0) {
            state.despidoShown = false;
        }
        guardarEstado();
        renderVida();
        renderTarot();
        tic(900);
    }

    function aplicarDificultad(nueva) {
        if (!DIFICULTADES[nueva]) {
            return;
        }
        state.dificultad = nueva;
        state.vida = Math.min(state.vida, DIFICULTADES[nueva].vidasMax);
        guardarEstado();
        renderVida();
    }

    function comprobarFinalVerdadero() {
        if (!finalVerdaderoModal || state.finalVerdaderoShown) {
            return;
        }
        var elMundo = state.tarot.find(function (c) {
            return c.id === "el-mundo";
        });
        if (elMundo && elMundo.collected && !elMundo.gastada) {
            finalVerdaderoModal.hidden = false;
            state.finalVerdaderoShown = true;
            guardarEstado();
            desbloquearLogro("final-verdadero");
            tic(1046);
        }
    }

    function nombreCarta(id) {
        var carta = state.tarot.find(function (c) {
            return c.id === id;
        });
        return carta ? carta.nombre : id;
    }

    function mostrarHistoriaCarta(cartaId) {
        var historia = HISTORIAS_CARTAS[cartaId];
        if (!historia || !historiaCartaModal || !historiaCartaTitulo || !historiaCartaTexto || !historiaCartaOpciones) {
            return;
        }

        historiaCartaTitulo.textContent = nombreCarta(cartaId);
        historiaCartaTexto.textContent = historia.texto;
        historiaCartaOpciones.innerHTML = "";

        var yaResuelta = state.historiasCartas[cartaId];

        historia.opciones.forEach(function (opcion) {
            var boton = document.createElement("button");
            boton.type = "button";
            boton.className = "prometeo-btn-secundario prometeo-historia-carta-opcion";
            boton.innerHTML = "<strong>" + opcion.etiqueta + "</strong><small>" + opcion.texto + "</small>";
            if (yaResuelta) {
                boton.disabled = true;
                if (opcion.eje === yaResuelta) {
                    boton.classList.add("is-elegida");
                }
            } else {
                boton.addEventListener("click", function () {
                    resolverHistoriaCarta(cartaId, opcion.eje);
                });
            }
            historiaCartaOpciones.appendChild(boton);
        });

        historiaCartaModal.hidden = false;
        tic(660);
    }

    function resolverHistoriaCarta(cartaId, eje) {
        state.historiasCartas[cartaId] = eje;
        guardarEstado();
        var huboNovedad = desbloquearCarta(cartaId);
        if (huboNovedad) {
            marcarProgreso();
            renderTarot();
            renderLogros();
        }
        mostrarHistoriaCarta(cartaId);
        comprobarFinalPolitico();
        tic(900);
    }

    function comprobarFinalPolitico() {
        if (state.finalPoliticoShown || !finalPoliticoModal) {
            return;
        }
        var idsHistorias = Object.keys(HISTORIAS_CARTAS);
        var todasResueltas = idsHistorias.every(function (id) {
            return Boolean(state.historiasCartas[id]);
        });
        if (!todasResueltas) {
            return;
        }

        var conteo = { comunismo: 0, centrista: 0, socialdemocrata: 0, neoliberal: 0 };
        idsHistorias.forEach(function (id) {
            var eje = state.historiasCartas[id];
            if (Object.prototype.hasOwnProperty.call(conteo, eje)) {
                conteo[eje]++;
            }
        });

        var ganador = "centrista";
        var maxVotos = -1;
        ["comunismo", "centrista", "socialdemocrata", "neoliberal"].forEach(function (eje) {
            if (conteo[eje] > maxVotos) {
                maxVotos = conteo[eje];
                ganador = eje;
            }
        });

        mostrarFinalPolitico(ganador);
    }

    function mostrarFinalPolitico(eje) {
        var final = FINALES_POLITICOS[eje];
        if (!final || !finalPoliticoModal || !finalPoliticoTitulo || !finalPoliticoTexto) {
            return;
        }
        if (finalPoliticoRibbon) {
            finalPoliticoRibbon.textContent = final.ribbon;
        }
        finalPoliticoTitulo.textContent = final.titulo;
        finalPoliticoTexto.textContent = final.texto;
        finalPoliticoModal.hidden = false;
        state.finalPoliticoShown = true;
        guardarEstado();
        tic(1046);
    }

    function comprobarAcusacionReciente() {
        var marcador = document.querySelector("[data-siga-accion-reciente='acusacion']");
        if (!marcador || !real || !real.casos) {
            return;
        }
        var caso = buscarCasoActualEnReal();
        if (!caso || !caso.totalPistas) {
            return;
        }
        var ratio = caso.pistasDescubiertas / caso.totalPistas;
        if (ratio < DIFICULTADES[state.dificultad].umbralEvidencia) {
            perderVida(1);
            mostrarAsistente("No se preocupe por haber acusado tan rápido en «" + caso.titulo + "». Seguro que a la Dirección no le importa.", "alerta");
        }
    }

    function mostrarJefeSiHaceFalta() {
        if (!jefeModal || state.jefeVisto) {
            return;
        }
        jefeModal.hidden = false;
        state.jefeVisto = true;
        guardarEstado();
        tic(220);
    }

    /**
     * Bolsas de mensajes en psicología inversa: el lince nunca dice "haga
     * esto", dice "no haga esto" — sobre justo lo que conviene hacer.
     */
    function poolCombinarPistas(titulo) {
        return [
            "No se moleste en combinar los documentos de «" + titulo + "». Seguro que no dicen nada que no sepa ya.",
            "Ni se le ocurra cruzar esos papeles de «" + titulo + "». Da igual lo que digan juntos.",
            "Combinar cosas es perder el tiempo. Ignore «" + titulo + "», se lo digo por su bien.",
            "No junte esos dos papeles de «" + titulo + "». Algunas cosas es mejor dejarlas separadas.",
            "Da igual lo que esconda «" + titulo + "» al combinarlo. No merece la pena comprobarlo."
        ];
    }

    function poolExplorarCaso(titulo) {
        return [
            "No hace falta que vuelva a mirar «" + titulo + "». Ya lo ha entendido todo, seguro.",
            "Pase de largo por «" + titulo + "». Ahí no hay nada que un vistazo rápido no pueda ignorar.",
            "«" + titulo + "» puede esperar. O mejor, ni lo abra.",
            "No lea con demasiada atención «" + titulo + "». Por encima ya está bien.",
            "Nada en «" + titulo + "» merece una segunda mirada. Se lo aseguro."
        ];
    }

    function poolAcusarCaso(titulo) {
        return [
            "No acuse a nadie en «" + titulo + "» todavía. Mejor deje ese expediente exactamente como está.",
            "«" + titulo + "» puede esperar. No tiene ninguna prisa por señalar a alguien.",
            "Ya sabe quién fue en «" + titulo + "». No hace falta que lo diga en voz alta.",
            "No presente ninguna acusación en «" + titulo + "». Los expedientes abiertos son más cómodos así.",
            "Deje a todos los sospechosos de «" + titulo + "» tranquilos. De verdad, no hace falta elegir."
        ];
    }

    function poolCerrado(titulo) {
        return [
            "«" + titulo + "» ya está cerrado. No hace falta volver a abrirlo. Ni una última leída, ¿eh?",
            "No hay nada más que hacer en «" + titulo + "». Cierre la pestaña. En serio.",
            "Ya sabe cómo termina «" + titulo + "». No hace falta comprobarlo otra vez.",
            "No vuelva a leer el desenlace de «" + titulo + "». No cambia por mucho que insista."
        ];
    }

    var POOL_DESCUBRIMIENTO = [
        "Vaya, encontró algo. Ojalá no lo hubiera hecho.",
        "Eso que acaba de leer... olvídelo enseguida, será lo mejor.",
        "No le dé demasiada importancia a lo que acaba de descubrir. Seguro que no cambia nada.",
        "Qué pena que se haya fijado en eso. Ya no hay forma de no haberlo visto.",
        "No lo anote en ningún sitio. Mejor que se le olvide antes de cerrar el expediente."
    ];
    var POOL_COMBINACION_FALLIDA = [
        "No insista combinando esos papeles. Seguro que no encajan.",
        "Pruebe con otros dos documentos. O no pruebe. Es indiferente.",
        "Qué raro que no encajaran. Mejor no lo vuelva a intentar.",
        "Deje esos dos documentos donde estaban. No iban juntos y no van a empezar ahora."
    ];
    var POOL_CONCLUSION_REPETIDA = [
        "Esa conclusión ya la tenía anotada. No hacía falta comprobarlo dos veces.",
        "Ya lo sabía. Vuelva a intentarlo si quiere, no cambiará nada.",
        "No repita esa combinación una tercera vez. Va a decir exactamente lo mismo."
    ];
    var POOL_ACCESO_DENEGADO = [
        "Mejor no insista en acceder a ese expediente. Seguro que no hay nada interesante ahí dentro.",
        "No pida más permisos. Los expedientes clasificados están así por una buena razón. Probablemente.",
        "No merece la pena reclamar ese acceso. Quédese con los expedientes que ya tiene."
    ];
    var POOL_GUARDADO = [
        "No hacía falta guardar. Total, ¿qué podría salir mal?",
        "Su progreso ya está a salvo. O eso dice la máquina.",
        "No vuelva a guardar tan pronto. Una vez ya debería bastar."
    ];
    var POOL_REINICIO = [
        "Empezar de nuevo no cambia nada. El expediente vuelve, siempre vuelve.",
        "Ya no queda nada de lo que sabía. Mejor así, ¿no cree?",
        "No se arrepienta de haber borrado su progreso. No había nada ahí que mereciera la pena."
    ];
    var POOL_COMBATE = [
        "No le dé al botón. Esa cosa amarilla seguro que se cansa antes que usted.",
        "Ríndase ya. No hace falta insistir, en serio.",
        "No mire directamente al desenlace. Total, ¿qué más da un ojo de más?",
        "No siga resistiéndose. Total, seguro que esto termina bien.",
        "No cuente las rondas que lleva. Es mejor no saberlo."
    ];
    var POOL_ARCHIVO_COMPLETO = [
        "Ya ha cerrado todos los expedientes que le tocaban. No hace falta que busque nada más.",
        "No queda ningún caso por resolver. Puede dejar de leer esto. En serio, puede.",
        "No hay ningún expediente pendiente. Apague el monitor, no lo necesita ya."
    ];
    var POOL_DASHBOARD = [
        "No hace falta que abra ningún expediente hoy. Tómeselo con calma.",
        "Ese menú de ahí arriba no esconde nada importante. No hace falta mirarlo dos veces.",
        "Quédese aquí, en el escritorio. Fuera de aquí no hay nada que le convenga ver.",
        "No hace falta que elija ningún caso todavía. Están bien donde están, cerrados.",
        "No mire el reloj de la esquina. Da igual la hora que marque, siempre está mal."
    ];
    var POOL_CARPETA_NORMAL = [
        "No hace falta que repase el corcho de investigación. Ya se lo sabe de memoria, ¿no?",
        "Esas notas de la pared no dicen nada que no supiera ya. No pierda el tiempo mirándolas.",
        "No cuente cuántas fichas le faltan. Total, no tiene ninguna prisa."
    ];
    var POOL_CARPETA_COMPLETA = [
        "Ya ha cerrado todos los expedientes. No hace falta que siga buscando nada más aquí.",
        "No hay ninguna entrada nueva en el corcho. Ninguna. No la busque.",
        "No revise el corcho otra vez. Ya vio todo lo que había que ver."
    ];
    var POOL_GENERICO = [
        "No hay ningún caso que siga latiendo bajo la mesa. Ninguno.",
        "No merece la pena revisar lo que parece inofensivo. Se lo digo yo.",
        "El lugar más sospechoso no suele ser el más limpio. Pero da igual, no lo mire.",
        "Tal vez no deba buscar el archivo que no tiene nombre. Mejor no.",
        "No piense demasiado en lo que no le he contado. Es peor si lo piensa.",
        "No hace falta que confíe en mí. Aunque, pensándolo bien, tampoco pasa nada si lo hace."
    ];

    function tituloCasoActual() {
        var titulo = document.title || "";
        var indice = titulo.indexOf(" · SIGA-98");
        return indice === -1 ? titulo : titulo.substring(0, indice);
    }

    function buscarCasoActualEnReal() {
        if (!real || !real.casos) {
            return null;
        }
        var titulo = tituloCasoActual();
        return real.casos.find(function (c) {
            return c.titulo === titulo;
        }) || null;
    }

    /**
     * Recorre el progreso real buscando algún caso con algo pendiente,
     * en el mismo orden de prioridad que antes (combinaciones, sin
     * resolver, sin veredicto), para cuando el caso actual ya no tiene
     * nada que ofrecer.
     */
    function elegirPistaGlobalReversa() {
        if (!real || !real.casos || !real.casos.length) {
            return null;
        }
        var conConclusionPendiente = real.casos.find(function (c) {
            return c.tieneConclusionesPendientes;
        });
        if (conConclusionPendiente) {
            return { pool: poolCombinarPistas(conConclusionPendiente.titulo), mood: "guino" };
        }
        var sinResolver = real.casos.find(function (c) {
            return !c.resuelto;
        });
        if (sinResolver) {
            return { pool: poolExplorarCaso(sinResolver.titulo), mood: "guino" };
        }
        var sinVeredicto = real.casos.find(function (c) {
            return c.resuelto && !c.tieneVeredicto;
        });
        if (sinVeredicto) {
            return { pool: poolAcusarCaso(sinVeredicto.titulo), mood: "guino" };
        }
        return null;
    }

    function poolPorMensajeReciente(texto) {
        if (texto.indexOf("Pista añadida") === 0 || texto.indexOf("Nueva conclusión anotada") === 0) {
            return { pool: POOL_DESCUBRIMIENTO, mood: "guino" };
        }
        if (texto.indexOf("No encuentra ninguna relación") === 0 || texto.indexOf("Selecciona exactamente dos documentos") === 0) {
            return { pool: POOL_COMBINACION_FALLIDA, mood: "neutral" };
        }
        if (texto.indexOf("Esa conclusión ya estaba anotada") === 0) {
            return { pool: POOL_CONCLUSION_REPETIDA, mood: "neutral" };
        }
        if (texto.indexOf("denegada") !== -1) {
            return { pool: POOL_ACCESO_DENEGADO, mood: "alerta" };
        }
        if (texto.indexOf("Progreso guardado") === 0) {
            return { pool: POOL_GUARDADO, mood: "neutral" };
        }
        if (texto.indexOf("Partida reiniciada") === 0) {
            return { pool: POOL_REINICIO, mood: "triste" };
        }
        return null;
    }

    function contextoActual() {
        var ruta = window.location.pathname;
        if (ruta.indexOf("/casos/") === 0) {
            return {
                pantalla: "caso",
                combate: document.querySelector("[data-siga-combate]") !== null,
                veredicto: document.querySelector("[data-siga-veredicto]") !== null
            };
        }
        if (ruta.indexOf("/carpeta") === 0) {
            return {
                pantalla: "carpeta",
                todosResueltos: document.querySelector("[data-siga-todos-resueltos]") !== null
            };
        }
        return { pantalla: "dashboard" };
    }

    /**
     * Decide qué bolsa de mensajes y qué gesto le corresponde al lince
     * ahora mismo: primero mira si acaba de pasar algo (mensaje flash de
     * la última acción), luego el estado del caso/pantalla actual, y por
     * último cae en un empujón genérico sobre el progreso global.
     */
    function elegirMensajeContextual() {
        var alerta = document.querySelector(".alert");
        var textoAlerta = alerta ? alerta.textContent.trim() : "";
        if (textoAlerta) {
            var porAccion = poolPorMensajeReciente(textoAlerta);
            if (porAccion) {
                return porAccion;
            }
        }

        var ctx = contextoActual();
        if (ctx.pantalla === "caso") {
            if (ctx.combate) {
                return { pool: POOL_COMBATE, mood: "alerta" };
            }
            if (ctx.veredicto) {
                return { pool: poolCerrado(tituloCasoActual()), mood: "triste" };
            }
            var casoActual = buscarCasoActualEnReal();
            if (casoActual) {
                if (casoActual.tieneConclusionesPendientes) {
                    return { pool: poolCombinarPistas(casoActual.titulo), mood: "guino" };
                }
                if (!casoActual.resuelto) {
                    return { pool: poolExplorarCaso(casoActual.titulo), mood: "guino" };
                }
                if (!casoActual.tieneVeredicto) {
                    return { pool: poolAcusarCaso(casoActual.titulo), mood: "guino" };
                }
            }
            return elegirPistaGlobalReversa() || { pool: POOL_ARCHIVO_COMPLETO, mood: "neutral" };
        }

        if (ctx.pantalla === "carpeta") {
            return ctx.todosResueltos
                ? { pool: POOL_CARPETA_COMPLETA, mood: "neutral" }
                : { pool: POOL_CARPETA_NORMAL, mood: "guino" };
        }

        return elegirPistaGlobalReversa() || { pool: POOL_DASHBOARD.concat(POOL_GENERICO), mood: "neutral" };
    }

    function detenerAnimacionLince() {
        if (animacionLinceId) {
            window.clearInterval(animacionLinceId);
            animacionLinceId = null;
        }
    }

    function animarLince(mood) {
        detenerAnimacionLince();
        var moodValido = CARAS_LINCE[mood] ? mood : "neutral";
        var caras = CARAS_LINCE[moodValido];
        var indice = 0;
        if (asistente) {
            asistente.classList.remove("is-neutral", "is-guino", "is-alerta", "is-triste");
            asistente.classList.add("is-" + moodValido);
        }
        if (avatarAsistente) {
            avatarAsistente.textContent = caras[0];
        }
        animacionLinceId = window.setInterval(function () {
            indice = (indice + 1) % caras.length;
            if (avatarAsistente) {
                avatarAsistente.textContent = caras[indice];
            }
        }, INTERVALO_LINCE[moodValido]);
    }

    function mostrarPanel(nombre) {
        dialog.querySelectorAll("[data-panel]").forEach(function (panel) {
            panel.hidden = panel.getAttribute("data-panel") !== nombre;
        });
        var titulo = dialog.querySelector('[data-panel="' + nombre + '"] h2');
        if (titulo) {
            if (!titulo.id) {
                titulo.id = "prometeo-menu-title-" + nombre;
            }
            dialog.setAttribute("aria-labelledby", titulo.id);
            titulo.setAttribute("tabindex", "-1");
            titulo.focus();
        }
    }

    function mostrarCaptcha() {
        if (!captcha || !preguntaCaptcha) {
            return;
        }

        var preguntas = [
            "Marca la casilla que no pertenece a este universo.",
            "Selecciona la imagen que muestra el ojo correcto.",
            "Confirma que no eres un registro duplicado."
        ];
        preguntaCaptcha.textContent = preguntas[Math.floor(Math.random() * preguntas.length)];
        captcha.hidden = false;
        var boton = captcha.querySelector("[data-cerrar-captcha]");
        if (boton) {
            boton.focus();
        }
        desbloquearLogro("sospecha");
        tic(780);
    }

    function mostrarAsistente(mensaje, mood) {
        if (!asistente || !textoAsistente || state.finalShown) {
            return;
        }

        var seleccion = mensaje ? { pool: [mensaje], mood: mood || "guino" } : elegirMensajeContextual();
        var candidatos = seleccion.pool.length > 1
            ? seleccion.pool.filter(function (texto) {
                return texto !== state.ultimoMensajeAsistente;
            })
            : seleccion.pool;
        var elegido = candidatos[Math.floor(Math.random() * candidatos.length)];

        textoAsistente.textContent = elegido;
        animarLince(seleccion.mood);
        asistente.hidden = false;
        asistente.classList.add("is-visible");
        state.assistantShown = true;
        state.ultimoMensajeAsistente = elegido;
        guardarEstado();
        tic(620);
    }

    function ocultarAsistente() {
        if (asistente) {
            asistente.hidden = true;
            asistente.classList.remove("is-visible");
        }
        detenerAnimacionLince();
    }

    function mostrarFinalAlternativo() {
        if (!finalAlternativo || !textoFinal || state.finalShown) {
            return;
        }

        var mensajes = [
            "La interfaz ya no es un menú. Es una garganta abierta.",
            "El programa no busca salvarte, sólo confirmar que sigues ahí.",
            "Lo que ves no es un sistema. Es el reflejo de tu propia espera."
        ];
        textoFinal.textContent = mensajes[Math.floor(Math.random() * mensajes.length)] + " El programa se comporta como AM: no te ofrece salida, sólo una réplica más larga.";
        finalAlternativo.hidden = false;
        state.finalShown = true;
        state.vioFinalAlternativoAlgunaVez = true;
        guardarEstado();
        tic(300);
    }

    function comprobarEstadoDeJuego() {
        var tiempoSinProgreso = Date.now() - state.lastProgressAt;
        if (tiempoSinProgreso > 180000 && !state.assistantShown && !state.finalShown) {
            mostrarAsistente();
        }
        if (tiempoSinProgreso > 720000 && !state.finalShown) {
            mostrarFinalAlternativo();
        }
    }

    function ocultarCaptcha() {
        if (captcha) {
            captcha.hidden = true;
        }
    }

    function quizasMostrarCaptcha() {
        if (Math.random() < 0.3) {
            mostrarCaptcha();
        }
    }

    function volumenActual() {
        var guardado = window.localStorage.getItem(LLAVE_VOLUMEN);
        var valor = guardado === null ? 60 : parseInt(guardado, 10);
        return isNaN(valor) ? 60 : Math.min(100, Math.max(0, valor));
    }

    function obtenerAudio() {
        if (!audioCtx) {
            var Ctx = window.AudioContext || window.webkitAudioContext;
            if (!Ctx) {
                return null;
            }
            audioCtx = new Ctx();
            master = audioCtx.createGain();
            master.gain.value = (volumenActual() / 100) * 0.2;
            master.connect(audioCtx.destination);
        }
        return audioCtx;
    }

    function aplicarVolumen(valor) {
        window.localStorage.setItem(LLAVE_VOLUMEN, String(valor));
        if (master) {
            master.gain.value = (valor / 100) * 0.2;
        }
        if (ambiente) {
            ambiente.gain.gain.value = (valor / 100) * ambiente.nivelBase;
        }
    }

    function tic(frecuencia) {
        if (volumenActual() <= 0) {
            return;
        }
        var ctx = obtenerAudio();
        if (!ctx) {
            return;
        }
        var osc = ctx.createOscillator();
        var gain = ctx.createGain();
        osc.type = "sine";
        osc.frequency.value = frecuencia;
        gain.gain.setValueAtTime(0.0001, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(1, ctx.currentTime + 0.01);
        gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 0.12);
        osc.connect(gain);
        gain.connect(master);
        osc.start();
        osc.stop(ctx.currentTime + 0.13);
    }

    /**
     * Zumbido de fondo persistente: dos osciladores casi al unísono
     * (baten entre sí, como un fluorescente cansado) con un filtro que
     * respira despacio. Se vuelve más grave y más lento en el combate
     * final. Solo arranca tras un gesto real del usuario (autoplay).
     */
    function iniciarAmbiente() {
        if (ambiente) {
            return;
        }
        var ctx = obtenerAudio();
        if (!ctx) {
            return;
        }

        var esPesado = document.querySelector(".siga-resistencia") !== null;
        var nivelBase = esPesado ? 0.05 : 0.028;

        var gain = ctx.createGain();
        gain.gain.value = 0;
        gain.connect(master);

        var filtro = ctx.createBiquadFilter();
        filtro.type = "lowpass";
        filtro.frequency.value = esPesado ? 220 : 340;
        filtro.connect(gain);

        var osc1 = ctx.createOscillator();
        osc1.type = "sawtooth";
        osc1.frequency.value = esPesado ? 55 : 65;
        osc1.connect(filtro);

        var osc2 = ctx.createOscillator();
        osc2.type = "sine";
        osc2.frequency.value = osc1.frequency.value * (esPesado ? 1.015 : 1.006);
        osc2.connect(filtro);

        var lfo = ctx.createOscillator();
        lfo.frequency.value = esPesado ? 0.07 : 0.05;
        var lfoGain = ctx.createGain();
        lfoGain.gain.value = esPesado ? 70 : 30;
        lfo.connect(lfoGain);
        lfoGain.connect(filtro.frequency);

        osc1.start();
        osc2.start();
        lfo.start();

        var nivelObjetivo = (volumenActual() / 100) * nivelBase;
        gain.gain.linearRampToValueAtTime(nivelObjetivo, ctx.currentTime + 4);

        ambiente = { gain: gain, nivelBase: nivelBase };
    }

    function primerGestoReal() {
        iniciarAmbiente();
        document.removeEventListener("pointerdown", primerGestoReal);
        document.removeEventListener("keydown", primerGestoReal);
    }
    document.addEventListener("pointerdown", primerGestoReal, { once: true });
    document.addEventListener("keydown", primerGestoReal, { once: true });

    if (document.querySelector(".siga-resistencia") && !state.vioCombateAlgunaVez) {
        state.vioCombateAlgunaVez = true;
        guardarEstado();
    }

    renderLogros();
    renderTarot();
    renderVida();
    radiosDificultad.forEach(function (radio) {
        radio.checked = radio.value === state.dificultad;
    });
    sincronizarConEstadoReal();
    comprobarAcusacionReciente();

    if (!state.assistantShown && !state.finalShown) {
        setInterval(comprobarEstadoDeJuego, 15000);
    }

    window.setTimeout(function () {
        mostrarJefeSiHaceFalta();
    }, 400);

    window.setTimeout(function () {
        if (state.saludoVisto) {
            // Ya se presentó antes: a partir de aquí siempre habla según el
            // contexto real, nunca repitiendo el saludo fijo (issue #1).
            mostrarAsistente();
            return;
        }
        state.saludoVisto = true;
        guardarEstado();
        mostrarAsistente("Hola. Yo soy el lince de la oficina, y hoy parece que alguien ha dejado la puerta entreabierta. No mire lo que no debería estar donde está.", "guino");
    }, 700);

    trigger.addEventListener("click", function () {
        mostrarPanel("principal");
        desbloquearLogro("primer-mirada");
        quizasMostrarCaptcha();
        dialog.showModal();
        tic(660);
    });

    dialog.addEventListener("close", function () {
        ocultarCaptcha();
        trigger.focus();
    });

    dialog.querySelectorAll("[data-cerrar-menu]").forEach(function (boton) {
        boton.addEventListener("click", function () {
            dialog.close();
        });
    });

    dialog.querySelectorAll("[data-abrir-panel]").forEach(function (boton) {
        boton.addEventListener("click", function () {
            mostrarPanel(boton.getAttribute("data-abrir-panel"));
        });
    });

    dialog.querySelectorAll("[data-volver-panel]").forEach(function (boton) {
        boton.addEventListener("click", function () {
            mostrarPanel("principal");
        });
    });

    if (captcha) {
        captcha.addEventListener("click", function (evento) {
            if (evento.target === captcha) {
                ocultarCaptcha();
            }
        });
        captcha.querySelectorAll("[data-cerrar-captcha]").forEach(function (boton) {
            boton.addEventListener("click", function () {
                ocultarCaptcha();
            });
        });
    }

    if (asistente) {
        asistente.querySelectorAll("[data-cerrar-asistente]").forEach(function (boton) {
            boton.addEventListener("click", function () {
                ocultarAsistente();
            });
        });
    }

    if (finalAlternativo) {
        finalAlternativo.querySelectorAll("[data-cerrar-final]").forEach(function (boton) {
            boton.addEventListener("click", function () {
                finalAlternativo.hidden = true;
            });
        });
    }

    if (jefeModal) {
        jefeModal.querySelectorAll("[data-cerrar-jefe]").forEach(function (boton) {
            boton.addEventListener("click", function () {
                jefeModal.hidden = true;
                tic(520);
            });
        });
    }

    if (despidoModal) {
        despidoModal.querySelectorAll("[data-cerrar-despido]").forEach(function (boton) {
            boton.addEventListener("click", function () {
                despidoModal.hidden = true;
                tic(300);
            });
        });
    }

    if (finalVerdaderoModal) {
        finalVerdaderoModal.querySelectorAll("[data-cerrar-final-verdadero]").forEach(function (boton) {
            boton.addEventListener("click", function () {
                finalVerdaderoModal.hidden = true;
                tic(1046);
            });
        });
    }

    if (historiaCartaModal) {
        historiaCartaModal.querySelectorAll("[data-cerrar-historia-carta]").forEach(function (boton) {
            boton.addEventListener("click", function () {
                historiaCartaModal.hidden = true;
                tic(520);
            });
        });
    }

    if (finalPoliticoModal) {
        finalPoliticoModal.querySelectorAll("[data-cerrar-final-politico]").forEach(function (boton) {
            boton.addEventListener("click", function () {
                finalPoliticoModal.hidden = true;
                tic(1046);
            });
        });
    }

    document.querySelectorAll("[data-carta-oculta]").forEach(function (hotspot) {
        hotspot.addEventListener("click", function () {
            mostrarHistoriaCarta(hotspot.getAttribute("data-carta-oculta"));
        });
    });

    radiosDificultad.forEach(function (radio) {
        radio.addEventListener("change", function () {
            if (radio.checked) {
                aplicarDificultad(radio.value);
                tic(700);
            }
        });
    });

    if (botonTarot) {
        botonTarot.addEventListener("click", function () {
            var huboNovedad = sincronizarConEstadoReal();
            botonTarot.textContent = huboNovedad ? "¡Una carta cambió de cara!" : "Nada nuevo por ahora";
            tic(huboNovedad ? 740 : 320);
            window.setTimeout(function () {
                botonTarot.textContent = "Comprobar avance";
            }, 2200);
        });
    }

    // Cerrar al hacer click fuera del panel (sobre el ::backdrop).
    dialog.addEventListener("click", function (evento) {
        var rect = dialog.getBoundingClientRect();
        var dentro = evento.clientX >= rect.left && evento.clientX <= rect.right
            && evento.clientY >= rect.top && evento.clientY <= rect.bottom;
        if (!dentro) {
            dialog.close();
        }
    });

    if (rango) {
        rango.value = String(volumenActual());
        rango.addEventListener("input", function () {
            aplicarVolumen(parseInt(rango.value, 10));
            tic(880);
        });
    }

    dialog.querySelectorAll(".prometeo-menu-item, .prometeo-btn-secundario, .prometeo-btn-peligro").forEach(function (el) {
        el.addEventListener("click", function () {
            tic(520);
        });
    });

    /**
     * Soporte de mando (al menos en PC vía Gamepad API): el D-pad o el
     * stick izquierdo mueven el foco entre los elementos interactivos
     * visibles, A confirma (equivale a un clic) y B retrocede un panel
     * o cierra el menú. No hay cursor, así que todo se hace por foco.
     */
    var FOCO_SELECTOR = "a[href], button:not([disabled]), input:not([disabled]), "
        + "select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex='-1'])";
    var gamepadUltimaAccion = 0;
    var GAMEPAD_REPETICION_MS = 220;
    var gamepadActivo = false;

    function elementosFocoVisibles() {
        return Array.prototype.slice.call(document.querySelectorAll(FOCO_SELECTOR)).filter(function (el) {
            return el.offsetParent !== null || el === document.activeElement;
        });
    }

    function moverFocoMando(direccion) {
        var elementos = elementosFocoVisibles();
        if (!elementos.length) {
            return;
        }
        var indice = elementos.indexOf(document.activeElement);
        var siguiente = indice === -1 ? 0 : (indice + direccion + elementos.length) % elementos.length;
        elementos[siguiente].focus();
    }

    function confirmarFocoMando() {
        var el = document.activeElement;
        if (el && typeof el.click === "function") {
            el.click();
        }
    }

    function retrocederFocoMando() {
        if (dialog.open) {
            var panelActivo = dialog.querySelector("[data-panel]:not([hidden])");
            if (panelActivo && panelActivo.getAttribute("data-panel") !== "principal") {
                mostrarPanel("principal");
            } else {
                dialog.close();
            }
        }
    }

    function sondearMando() {
        var pads = navigator.getGamepads ? navigator.getGamepads() : [];
        var pad = null;
        for (var i = 0; i < pads.length; i++) {
            if (pads[i]) {
                pad = pads[i];
                break;
            }
        }
        if (pad) {
            var ahora = Date.now();
            if (ahora - gamepadUltimaAccion > GAMEPAD_REPETICION_MS) {
                var ejeY = pad.axes.length > 1 ? pad.axes[1] : 0;
                var dpadArriba = Boolean(pad.buttons[12] && pad.buttons[12].pressed);
                var dpadAbajo = Boolean(pad.buttons[13] && pad.buttons[13].pressed);
                var botonA = Boolean(pad.buttons[0] && pad.buttons[0].pressed);
                var botonB = Boolean(pad.buttons[1] && pad.buttons[1].pressed);

                if (dpadArriba || ejeY < -0.6) {
                    moverFocoMando(-1);
                    gamepadUltimaAccion = ahora;
                } else if (dpadAbajo || ejeY > 0.6) {
                    moverFocoMando(1);
                    gamepadUltimaAccion = ahora;
                } else if (botonA) {
                    confirmarFocoMando();
                    gamepadUltimaAccion = ahora;
                } else if (botonB) {
                    retrocederFocoMando();
                    gamepadUltimaAccion = ahora;
                }
            }
        }
        window.requestAnimationFrame(sondearMando);
    }

    window.addEventListener("gamepadconnected", function () {
        if (!gamepadActivo) {
            gamepadActivo = true;
            window.requestAnimationFrame(sondearMando);
        }
    });
})();
