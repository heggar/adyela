# Adyela

[![CI/CD](https://github.com/adyela/adyela/actions/workflows/ci.yml/badge.svg)](https://github.com/adyela/adyela/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/adyela/adyela/branch/main/graph/badge.svg)](https://codecov.io/gh/adyela/adyela)
[![License](https://img.shields.io/badge/license-UNLICENSED-blue.svg)](LICENSE)
[![Node Version](https://img.shields.io/badge/node-%3E%3D20.0.0-brightgreen.svg)](https://nodejs.org)
[![Python Version](https://img.shields.io/badge/python-3.12-blue.svg)](https://www.python.org)

Sistema de gestión de citas médicas con videollamadas, diseñado para clínicas y centros de salud.

## 🏗️ Arquitectura

Adyela es un monorepo que contiene:

- **apps/api**: Backend FastAPI con arquitectura hexagonal
- **apps/web**: Progressive Web App con React + TypeScript
- **apps/ops**: Observabilidad, monitoreo y tests end-to-end
- **packages/ui**: Biblioteca de componentes React reutilizables
- **packages/core**: SDK del cliente y contratos compartidos (TS/Python)
- **packages/config**: Configuraciones compartidas (ESLint, Prettier, TSConfig)
- **infra**: Infraestructura como código con Terraform
- **docs**: Documentación técnica, ADRs y RFCs

## 🚀 Stack Tecnológico

### Backend

- FastAPI (Python 3.12)
- Firestore (base de datos)
- Google Identity Platform (autenticación)
- Jitsi Meet (videollamadas)
- Twilio (SMS)
- SendGrid (email)

### Frontend

- React 18 + TypeScript
- Vite
- TailwindCSS
- Radix UI
- PWA con soporte offline

### DevOps

- Google Cloud Platform
- GitHub Actions (CI/CD)
- Terraform (IaC)
- Turbo (monorepo build system)
- pnpm (package manager)

## 📋 Requisitos Previos

- Node.js >= 20.0.0
- pnpm >= 9.0.0
- Python 3.12
- Google Cloud SDK (gcloud CLI)

## 🛠️ Instalación

```bash
# Instalar dependencias
pnpm install

# Configurar variables de entorno
cp .env.example .env

# Iniciar todos los servicios en modo desarrollo
pnpm dev
```

## 📦 Scripts Disponibles

```bash
pnpm dev              # Inicia todos los workspaces en modo desarrollo
pnpm build            # Construye todos los workspaces
pnpm test             # Ejecuta tests unitarios
pnpm test:e2e         # Ejecuta tests end-to-end
pnpm lint             # Ejecuta linters
pnpm lint:fix         # Corrige problemas de linting automáticamente
pnpm format           # Formatea el código con Prettier
pnpm type-check       # Verifica tipos TypeScript
pnpm commit           # Commit interactivo con Commitizen
pnpm clean            # Limpia node_modules y archivos de build
```

## 🏃 Desarrollo

### Estructura de Workspaces

```
adyela/
├── apps/
│   ├── api/           # Backend FastAPI
│   ├── web/           # Frontend React PWA
│   └── ops/           # Observability & E2E tests
├── packages/
│   ├── ui/            # Shared React components
│   ├── core/          # Client SDK & shared contracts
│   └── config/        # Shared configs (ESLint, TS, etc.)
└── infra/             # Terraform infrastructure
```

### Conventional Commits

Este proyecto utiliza [Conventional Commits](https://www.conventionalcommits.org/). Usa `pnpm commit` para crear commits siguiendo el estándar:

```bash
pnpm commit
```

### Git Hooks

Husky se configura automáticamente al instalar dependencias:

- **pre-commit**: Ejecuta lint-staged (format + lint)
- **commit-msg**: Valida formato de commits con commitlint

## 🎯 Multi-tenant & RBAC

El sistema soporta múltiples organizaciones (clínicas) con control de acceso basado en roles:

- **Super Admin**: Gestión global del sistema
- **Org Admin**: Gestión de la organización
- **Doctor**: Acceso a pacientes y citas
- **Receptionist**: Gestión de citas
- **Patient**: Acceso limitado a sus propias citas

## 🔐 Seguridad

- Autenticación con Google Identity Platform
- HTTPS obligatorio en producción
- Rate limiting en endpoints públicos
- Validación de entrada con Zod/Pydantic
- Secrets gestionados con Google Secret Manager

Para reportar vulnerabilidades, consulta [SECURITY.md](SECURITY.md)

## 🤝 Contribuir

Lee nuestra [guía de contribución](CONTRIBUTING.md) para conocer:

- Código de conducta
- Proceso de desarrollo
- Estándares de código
- Proceso de revisión de PRs

## 📄 Licencia

Este proyecto es privado y propietario. Todos los derechos reservados.

## 📞 Soporte

Para soporte técnico o preguntas:

- Crea un [issue](https://github.com/adyela/adyela/issues)
- Consulta la [documentación](./docs)
- Revisa los [ADRs](./docs/adrs) para decisiones arquitectónicas

## 🗺️ Roadmap

- [x] Configuración inicial del monorepo
- [ ] API backend con autenticación
- [ ] Frontend PWA básico
- [ ] Integración de videollamadas
- [ ] Sistema de notificaciones
- [ ] Tests E2E completos
- [ ] Despliegue en GCP
- [ ] Monitoreo y observabilidad

---

Hecho con ❤️ por el equipo de Adyela
