const { defineConfig } = require("vitest/config");

module.exports = defineConfig({
    test: {
        include: ["src/test/js/**/*.test.js"],
        environment: "node"
    }
});
