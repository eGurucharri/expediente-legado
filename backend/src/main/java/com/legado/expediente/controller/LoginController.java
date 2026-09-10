package com.legado.expediente.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class LoginController {

    private final String version;

    public LoginController(@Value("${siga98.version:dev}") String version) {
        this.version = version;
    }

    @GetMapping("/login")
    public String login(Model model) {
        model.addAttribute("versionBuild", version);
        return "login";
    }
}
