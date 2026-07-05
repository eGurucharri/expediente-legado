(function () {
    "use strict";

    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
        return;
    }

    var overlay = document.querySelector(".siga-flicker-overlay");
    if (!overlay) {
        return;
    }

    // Cada carga dura un poco distinto (500-900ms) para que la pantalla
    // nunca "respire" exactamente igual dos veces seguidas.
    var duracion = Math.round(500 + Math.random() * 400);
    document.documentElement.style.setProperty("--siga-flicker-duration", duracion + "ms");

    var quitar = function () {
        overlay.remove();
    };
    overlay.addEventListener("animationend", quitar, { once: true });
    // Red de seguridad por si el navegador no dispara animationend.
    window.setTimeout(quitar, duracion + 300);
})();
