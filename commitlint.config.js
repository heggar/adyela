module.exports = {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "type-enum": [
      2,
      "always",
      [
        "feat", // Nueva funcionalidad
        "fix", // Corrección de bugs
        "docs", // Documentación
        "style", // Formato, sin cambios en código
        "refactor", // Refactorización
        "perf", // Mejoras de rendimiento
        "test", // Tests
        "build", // Sistema de build o dependencias
        "ci", // CI/CD
        "chore", // Tareas de mantenimiento
        "revert", // Revertir cambios
      ],
    ],
    "scope-enum": [
      2,
      "always",
      [
        "api",
        "web",
        "ops",
        "ui",
        "core",
        "config",
        "infra",
        "docs",
        "deps",
        "release",
      ],
    ],
    "subject-case": [2, "never", ["upper-case"]],
    "subject-full-stop": [2, "never", "."],
    "header-max-length": [2, "always", 100],
    "body-leading-blank": [2, "always"],
    "footer-leading-blank": [2, "always"],
  },
};
