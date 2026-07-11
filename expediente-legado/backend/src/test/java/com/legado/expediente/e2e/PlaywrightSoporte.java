package com.legado.expediente.e2e;

import com.microsoft.playwright.Browser;
import com.microsoft.playwright.BrowserContext;
import com.microsoft.playwright.BrowserType;
import com.microsoft.playwright.Page;
import com.microsoft.playwright.Playwright;

/**
 * Base para los E2E reales de navegador (issue #12): dirige un Chromium
 * headless contra la app ya desplegada (docker compose up / jar-swap),
 * en vez de levantar un contexto Spring propio — igual que Solid Snake
 * infiltra por curl, pero con foco, teclado y JS de verdad.
 *
 * <p>URL configurable con {@code -De2e.baseUrl=http://host:puerto}; por
 * defecto apunta al despliegue local de siempre.</p>
 */
public class PlaywrightSoporte implements AutoCloseable {

    public static final String BASE_URL = System.getProperty("e2e.baseUrl", "http://localhost:1998");

    private final Playwright playwright;
    private final Browser browser;
    private final BrowserContext contexto;
    private final Page pagina;

    public PlaywrightSoporte() {
        playwright = Playwright.create();
        browser = playwright.chromium().launch(new BrowserType.LaunchOptions().setHeadless(true));
        contexto = browser.newContext();
        pagina = contexto.newPage();
    }

    public Page pagina() {
        return pagina;
    }

    /** Cada sesión arranca con un contexto de navegador nuevo: sin localStorage ni cookies previas. */
    public void iniciarSesion(String usuario, String contrasena) {
        pagina.navigate(BASE_URL + "/login");
        pagina.fill("#login-usuario", usuario);
        pagina.fill("#login-password", contrasena);
        pagina.click("button[type=submit]");
        pagina.waitForURL(BASE_URL + "/");
    }

    @Override
    public void close() {
        contexto.close();
        browser.close();
        playwright.close();
    }
}
