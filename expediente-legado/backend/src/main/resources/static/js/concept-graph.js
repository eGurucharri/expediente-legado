/**
 * Mapa de conexiones del corcho de investigación: dibuja como grafo (nodos
 * = conceptos desbloqueados, aristas = referencias [[...]] entre ellos ya
 * resueltas) lo que la lista de abajo ya muestra en texto. Simulación de
 * fuerzas hecha a mano (repulsión + resorte por arista + centrado), sin
 * ninguna librería — coherente con el resto de "prometeo-ui.js".
 */
(function () {
    "use strict";

    var boton = document.getElementById("prometeo-grafo-toggle");
    var panel = document.getElementById("prometeo-grafo-panel");
    var svg = document.getElementById("prometeo-grafo-svg");
    var lista = document.getElementById("prometeo-grafo-lista");
    var datos = window.PROMETEO_GRAFO_CONCEPTOS;

    if (!boton || !panel || !svg || !lista || !datos || !datos.nodos || datos.nodos.length < 2) {
        return;
    }

    var SVG_NS = "http://www.w3.org/2000/svg";
    var ANCHO = 600;
    var ALTO = 380;
    var COLOR_POR_TIPO = {
        PERSONA: "#caa23c",
        EMPRESA: "#7fa8c9",
        COMITE: "#c96f6f",
        LUGAR: "#7fbf8a",
        DOCUMENTO: "#b79fe0"
    };

    var nodos = datos.nodos.map(function (n) {
        var angulo = Math.random() * Math.PI * 2;
        var radio = Math.min(ANCHO, ALTO) * 0.32;
        return {
            id: n.id,
            nombre: n.nombre,
            tipo: n.tipo,
            x: ANCHO / 2 + Math.cos(angulo) * radio,
            y: ALTO / 2 + Math.sin(angulo) * radio,
            vx: 0,
            vy: 0
        };
    });
    var nodoPorId = {};
    nodos.forEach(function (n) {
        nodoPorId[n.id] = n;
    });
    var aristas = datos.aristas
        .map(function (a) {
            return { origen: nodoPorId[a.origen], destino: nodoPorId[a.destino] };
        })
        .filter(function (a) {
            return a.origen && a.destino;
        });

    function simularPaso() {
        var i;
        var j;
        // Repulsión entre todos los pares (evita que se amontonen).
        for (i = 0; i < nodos.length; i++) {
            for (j = i + 1; j < nodos.length; j++) {
                var dx = nodos[i].x - nodos[j].x;
                var dy = nodos[i].y - nodos[j].y;
                var distancia2 = Math.max(dx * dx + dy * dy, 25);
                var fuerza = 1400 / distancia2;
                var distancia = Math.sqrt(distancia2);
                var fx = (dx / distancia) * fuerza;
                var fy = (dy / distancia) * fuerza;
                nodos[i].vx += fx;
                nodos[i].vy += fy;
                nodos[j].vx -= fx;
                nodos[j].vy -= fy;
            }
        }
        // Resorte a lo largo de cada arista (las mantiene cerca, no lejos).
        aristas.forEach(function (a) {
            var dx = a.destino.x - a.origen.x;
            var dy = a.destino.y - a.origen.y;
            var distancia = Math.max(Math.sqrt(dx * dx + dy * dy), 1);
            var objetivo = 130;
            var fuerza = (distancia - objetivo) * 0.02;
            var fx = (dx / distancia) * fuerza;
            var fy = (dy / distancia) * fuerza;
            a.origen.vx += fx;
            a.origen.vy += fy;
            a.destino.vx -= fx;
            a.destino.vy -= fy;
        });
        // Centrado suave, para que el conjunto no se escape del lienzo.
        nodos.forEach(function (n) {
            n.vx += (ANCHO / 2 - n.x) * 0.006;
            n.vy += (ALTO / 2 - n.y) * 0.006;
            n.vx *= 0.82;
            n.vy *= 0.82;
            n.x += n.vx;
            n.y += n.vy;
            n.x = Math.max(24, Math.min(ANCHO - 24, n.x));
            n.y = Math.max(24, Math.min(ALTO - 24, n.y));
        });
    }

    function crearElemento(tipo, atributos) {
        var el = document.createElementNS(SVG_NS, tipo);
        Object.keys(atributos).forEach(function (clave) {
            el.setAttribute(clave, atributos[clave]);
        });
        return el;
    }

    function dibujar() {
        svg.innerHTML = "";
        aristas.forEach(function (a) {
            svg.appendChild(crearElemento("line", {
                class: "prometeo-grafo-arista",
                x1: a.origen.x, y1: a.origen.y,
                x2: a.destino.x, y2: a.destino.y
            }));
        });
        nodos.forEach(function (n) {
            var grupo = crearElemento("g", { class: "prometeo-grafo-nodo", tabindex: "0", role: "button" });
            grupo.setAttribute("aria-label", "Ir a " + n.nombre + " en la lista");
            var circulo = crearElemento("circle", {
                cx: n.x, cy: n.y, r: 10,
                fill: COLOR_POR_TIPO[n.tipo] || "#caa23c"
            });
            var texto = crearElemento("text", { x: n.x, y: n.y - 14, "text-anchor": "middle" });
            texto.textContent = n.nombre;
            grupo.appendChild(circulo);
            grupo.appendChild(texto);
            grupo.addEventListener("click", function () {
                irAConcepto(n.id);
            });
            grupo.addEventListener("keydown", function (evento) {
                if (evento.key === "Enter" || evento.key === " ") {
                    evento.preventDefault();
                    irAConcepto(n.id);
                }
            });
            svg.appendChild(grupo);
        });
    }

    function irAConcepto(id) {
        var registro = document.getElementById("concepto-" + id);
        if (!registro) {
            return;
        }
        ocultarGrafo();
        registro.scrollIntoView({ behavior: "smooth", block: "center" });
        registro.classList.add("siga-revelado");
        window.setTimeout(function () {
            registro.classList.remove("siga-revelado");
        }, 1600);
    }

    function mostrarGrafo() {
        panel.hidden = false;
        lista.hidden = true;
        boton.textContent = "Ver lista";
        var pasos = 0;
        var animar = function () {
            simularPaso();
            dibujar();
            pasos++;
            if (pasos < 120) {
                window.requestAnimationFrame(animar);
            }
        };
        animar();
    }

    function ocultarGrafo() {
        panel.hidden = true;
        lista.hidden = false;
        boton.textContent = "Ver mapa de conexiones";
    }

    boton.hidden = false;
    boton.addEventListener("click", function () {
        if (panel.hidden) {
            mostrarGrafo();
        } else {
            ocultarGrafo();
        }
    });
})();
