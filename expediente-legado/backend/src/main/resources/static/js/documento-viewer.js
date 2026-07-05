(function () {
    "use strict";

    document.querySelectorAll(".siga-abrir-documento").forEach(function (boton) {
        boton.addEventListener("click", function () {
            var id = boton.getAttribute("data-documento");
            var dialogo = id && document.getElementById(id);
            if (dialogo && typeof dialogo.showModal === "function") {
                dialogo.showModal();
            }
        });
    });

    document.querySelectorAll(".documento-dialog").forEach(function (dialogo) {
        var cerrar = dialogo.querySelector("[data-cerrar-documento]");
        if (cerrar) {
            cerrar.addEventListener("click", function () {
                dialogo.close();
            });
        }
        // Cerrar al hacer click fuera del papel (sobre el ::backdrop).
        dialogo.addEventListener("click", function (evento) {
            var rect = dialogo.getBoundingClientRect();
            var dentro = evento.clientX >= rect.left && evento.clientX <= rect.right
                && evento.clientY >= rect.top && evento.clientY <= rect.bottom;
            if (!dentro) {
                dialogo.close();
            }
        });
    });
})();
