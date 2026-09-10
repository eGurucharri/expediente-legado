package com.legado.expediente.e2e;

import com.microsoft.playwright.Page;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * No termina en *Test a propósito: "mvn test" normal no la ejecuta (necesita
 * la app ya viva en PlaywrightSoporte.BASE_URL). Se lanza a mano con
 * "mvn test -Dtest=AutenticacionE2E".
 */
class AutenticacionE2E {

    private PlaywrightSoporte soporte;

    @AfterEach
    void parar() {
        if (soporte != null) {
            soporte.close();
        }
    }

    @Test
    void loginConCredencialesValidasLlevaAlDashboard() {
        soporte = new PlaywrightSoporte();
        soporte.iniciarSesion("auditor01", "auditor-local-123");

        Page pagina = soporte.pagina();
        assertTrue(pagina.title().contains("Expedientes"), "tras el login debería ver el dashboard de SIGA-98");
    }

    @Test
    void loginConCredencialesInvalidasMuestraError() {
        soporte = new PlaywrightSoporte();
        Page pagina = soporte.pagina();
        pagina.navigate(PlaywrightSoporte.BASE_URL + "/login");
        pagina.fill("#login-usuario", "auditor01");
        pagina.fill("#login-password", "contrasena-incorrecta");
        pagina.click("button[type=submit]");
        pagina.waitForURL("**/login?error");

        assertTrue(pagina.locator(".alert-danger").isVisible(), "debería avisar de usuario o contraseña incorrectos");
    }
}
