# 🏥 Adyela - Medical Appointments Platform

**Project Type:** Full-Stack Healthcare Application (HIPAA-Compliant)
**Architecture:** Microservices (6 services in development) + PWA + Flutter
Native Apps **Tech Stack:** FastAPI (Python) + React (TypeScript) + Flutter +
Firestore **Infrastructure:** Google Cloud Platform **Development Environment:**
Docker Compose

---

## 🎯 Project Overview

Adyela is a comprehensive medical appointment management platform with
integrated video calling capabilities. The system enables healthcare providers
to manage appointments, patient records, and conduct telemedicine consultations
while maintaining HIPAA compliance.

### Key Features

- 📅 **Appointment Management**: Schedule, confirm, cancel appointments
- 👥 **Multi-Tenancy**: Support for multiple healthcare professionals
  (single-tenant → multi-tenant migration planned)
- 🎥 **Video Consultations**: Integrated Jitsi video calling
- 📱 **Flutter Native Apps**: iOS/Android apps for patients and professionals
  (85%+ code reuse)
- 🌐 **Progressive Web App**: React admin panel + Flutter Web support
- 🌍 **Internationalization**: Multi-language support (EN, ES)
- 🔒 **HIPAA Compliant**: Protected Health Information (PHI) handling

---

## 📁 Project Structure

### Monorepo Organization

```
adyela/
├── apps/
│   ├── api/                         # Legacy FastAPI Monolith (Python 3.12) - Being migrated
│   │   └── adyela_api/
│   │       ├── domain/              # Business entities & logic
│   │       ├── application/         # Use cases & ports
│   │       ├── infrastructure/      # Database & external services
│   │       ├── presentation/        # HTTP API & middleware
│   │       └── config/              # Configuration & settings
│   ├── api-auth/                    # 🔧 Auth Microservice (Python/FastAPI) - In Development
│   ├── api-appointments/            # 🔧 Appointments Microservice (Python/FastAPI) - In Development
│   ├── api-payments/                # 🔧 Payments Microservice (Node.js/Express) - In Development
│   ├── api-notifications/           # 🔧 Notifications Microservice (Node.js/Express) - In Development
│   ├── api-analytics/               # 🔧 Analytics Microservice (Python/FastAPI) - In Development
│   ├── api-admin/                   # 🔧 Admin Microservice (Python/FastAPI) - In Development
│   ├── web/                         # ✅ React Admin Panel (TypeScript)
│   │   └── src/
│   │       ├── features/            # Feature modules (auth, appointments, etc.)
│   │       ├── components/          # Shared UI components
│   │       ├── services/            # API clients
│   │       └── store/               # Global state (Zustand)
│   ├── mobile-patient/              # ✅ Flutter Patient App (iOS/Android/Web)
│   │   └── lib/
│   │       ├── features/            # Search, Appointments, Profile
│   │       ├── core/                # Theme, DI, Routing, Config
│   │       └── main.dart
│   └── mobile-professional/         # ✅ Flutter Professional App (iOS/Android/Web)
│       └── lib/
│           ├── features/            # Dashboard, Appointments, Patients, Profile
│           ├── core/                # Theme, DI, Routing, Config
│           └── main.dart
├── packages/
│   ├── flutter-core/                # ✅ Shared Flutter models & business logic
│   │   └── lib/src/
│   │       ├── models/              # Professional, Appointment entities
│   │       └── enums/               # Specialty, AppointmentStatus
│   ├── flutter-shared/              # ✅ Shared Flutter UI components
│   │   └── lib/src/widgets/        # ProfessionalCard, AppointmentCard, EmptyState
│   ├── types/                       # ⚠️ Shared TypeScript types (Empty - To be implemented)
│   ├── validation/                  # ⚠️ Shared validation schemas (Empty - To be implemented)
│   └── ui/                          # ⚠️ Shared UI components (Empty - To be implemented)
├── infra/                           # Infrastructure as Code
│   ├── environments/                # Terraform configurations
│   └── modules/                     # Reusable Terraform modules
├── tests/
│   └── e2e/                         # Playwright E2E tests
├── scripts/                         # Automation scripts
├── docs/                            # Comprehensive documentation
│   ├── architecture/                # Architecture docs
│   ├── planning/                    # PRD, Strategy, Compliance
│   ├── quality/                     # Testing strategy
│   └── finops/                      # Cost analysis
└── .claude/                         # Claude Code configuration
    └── agents/                      # Specialized SDLC agents
```

### Architecture Patterns

**Backend (Hexagonal/Clean Architecture):**

```
Domain Layer (Core Business Logic)
    ↓ defines ports (interfaces)
Application Layer (Use Cases)
    ↓ implements business rules
Infrastructure Layer (Technical Details)
    ↓ implements ports
Presentation Layer (HTTP API)
```

**Frontend Web (Feature-Based - React):**

```
Feature Module
├── components/     # UI components
├── hooks/          # React hooks
└── services/       # API calls
```

**Mobile Apps (Feature-Based - Flutter):**

```
Feature Module
├── presentation/
│   ├── pages/      # Screen widgets
│   ├── widgets/    # Feature-specific widgets
│   └── bloc/       # State management (BLoC pattern)
├── domain/
│   └── entities/   # Business entities
├── data/
│   └── repositories/ # Data access
└── core/
    ├── theme/      # App theming
    ├── routing/    # Navigation (GoRouter)
    └── di/         # Dependency injection (GetIt)
```

**Code Reuse Strategy:**

- **85%+ shared code** between mobile-patient and mobile-professional apps
- **flutter-core**: Shared domain models (Professional, Appointment)
- **flutter-shared**: Shared UI components (ProfessionalCard, AppointmentCard)
- **Core infrastructure**: Theme, DI, error handling patterns reused 100%

---

## 🛠️ Technology Stack

### Backend

**Monolith (Legacy - Being migrated):**

- **Framework**: FastAPI 0.115+
- **Language**: Python 3.12
- **Database**: Firestore (single-tenant)
- **Authentication**: Firebase Auth

**Microservices (In Development):**

- **api-auth, api-appointments, api-admin, api-analytics**: Python 3.12 +
  FastAPI
- **api-payments, api-notifications**: Node.js 20 + Express
- **Database**: Firestore (operational) + Cloud SQL PostgreSQL (analytics -
  planned)
- **Communication**: Cloud Pub/Sub (event-driven), REST APIs
- **Testing**: Pytest, Schemathesis (Python), Jest (Node.js)
- **Code Quality**: Ruff, Black, MyPy, Bandit (Python), ESLint, Prettier
  (Node.js)

### Frontend Web (Admin Panel)

- **Framework**: React 18
- **Language**: TypeScript 5
- **Build Tool**: Vite
- **Styling**: TailwindCSS + shadcn/ui
- **State Management**: Zustand
- **Data Fetching**: React Query
- **Forms**: React Hook Form + Zod
- **I18n**: i18next
- **Testing**: Vitest, Playwright
- **PWA**: Workbox
- **Accessibility**: WCAG 2.1 AA (100/100 Lighthouse score)

### Mobile (Native + Web)

- **Framework**: Flutter 3.24+
- **Language**: Dart 3.5+
- **Apps**:
  - mobile-patient (iOS/Android/Web)
  - mobile-professional (iOS/Android/Web)
- **State Management**: flutter_bloc, equatable
- **Networking**: dio, retrofit
- **Local Storage**: hive, shared_preferences
- **Firebase**: auth, messaging, analytics, crashlytics
- **Routing**: go_router
- **Testing**: flutter_test, integration_test
- **Code Reuse**: 85%+ shared code via flutter-core and flutter-shared packages
- **Platforms**: iOS 14+, Android API 24+, Web (PWA)

### Infrastructure

- **Cloud Platform**: Google Cloud Platform
- **Container Runtime**: Cloud Run (serverless)
- **Storage**: Cloud Storage
- **Secrets**: Secret Manager
- **Monitoring**: Cloud Monitoring + Logging
- **CDN**: Cloud CDN
- **WAF**: Cloud Armor
- **IaC**: Terraform (to be implemented)

### DevOps

- **CI/CD**: GitHub Actions
- **Containers**: Docker
- **Package Managers**:
  - pnpm (Web frontend)
  - Poetry (Python backend)
  - pub (Flutter/Dart)
- **Monorepo**: Turborepo
- **Version Control**: Git + Conventional Commits
- **Code Quality**: Pre-commit hooks, husky, lint-staged

---

## 🤖 Claude Code Integration

### MCP Servers Configured

This project uses 5 MCP (Model Context Protocol) servers:

1. **Playwright MCP** - Browser automation & E2E testing
2. **Filesystem MCP** - Advanced file operations
3. **GitHub MCP** - Repository management
4. **Sequential Thinking MCP** - Complex problem solving
5. **Taskmaster AI MCP** - Intelligent task & sprint management

Configuration: `~/Library/Application Support/Claude/claude_desktop_config.json`

**Setup**: Run `bash scripts/setup-mcp-servers.sh` to configure all MCP servers
automatically.

### Specialized SDLC Agents

The project has 4 specialized agents for different aspects of the SDLC:

#### ☁️ Cloud Architecture Agent

**Location**: `.claude/agents/cloud-architect-agent.md` **Responsibilities**:

- Infrastructure as Code (Terraform)
- GCP resource management
- Cost optimization (target: $70-103/month)
- Disaster recovery (RTO <15min)
- Performance monitoring

**Invoke for**: Infrastructure changes, deployment issues, cost optimization,
performance problems

---

#### 🔒 Cybersecurity Agent

**Location**: `.claude/agents/cybersecurity-agent.md` **Responsibilities**:

- OWASP Top 10 compliance
- ISO 27001 controls
- NIST Cybersecurity Framework
- Security testing (SAST, DAST, SCA)
- Incident response

**Invoke for**: Security vulnerabilities, compliance questions, security
testing, threat modeling

---

#### 🧪 QA Automation Agent

**Location**: `.claude/agents/qa-automation-agent.md` **Responsibilities**:

- Test strategy & coverage (target: 80%+)
- E2E testing with Playwright
- Performance testing (Lighthouse, k6)
- Accessibility testing (WCAG 2.1 AA)
- Quality gates in CI/CD

**Invoke for**: Test creation, test failures, performance issues, accessibility
problems

---

#### 🏥 Healthcare Compliance Agent

**Location**: `.claude/agents/healthcare-compliance-agent.md`
**Responsibilities**:

- HIPAA compliance (Privacy & Security Rules)
- GDPR data protection
- PHI (Protected Health Information) handling
- Patient rights implementation
- Audit logging & breach notification

**Invoke for**: Compliance questions, PHI handling, audit requirements, patient
data access

---

## 🚀 Quick Start for Claude Code

### Understanding the Codebase

**Start with these files** (in order):

1. `CLAUDE.md` (this file) - Project overview
2. `docs/PROJECT_STRUCTURE_ANALYSIS.md` - Detailed structure analysis
3. `docs/PROJECT_COMMANDS_REFERENCE.md` - Command guide
4. `package.json` - Frontend dependencies
5. `apps/api/pyproject.toml` - Backend dependencies
6. `docker-compose.dev.yml` - Development environment

**Architecture validation**:

- Read `docs/deployment/architecture-validation.md` for infrastructure status
- Read `FINAL_QUALITY_REPORT.md` for quality assessment

### Common Tasks & Workflows

#### 1. Add New Feature

```bash
# Read feature-related files
Read("apps/web/src/features/appointments/")
Read("apps/api/adyela_api/domain/entities/appointment.py")

# Create new feature
# Follow hexagonal architecture pattern for backend
# Follow feature-based structure for frontend

# Add tests
# Backend: tests/unit/, tests/integration/
# Frontend: *.test.tsx (colocated)
# E2E: tests/e2e/*.spec.ts
```

#### 2. Fix Bug

```bash
# Use Grep to locate issue
Grep("function_name", path="apps/")

# Read relevant files with offset/limit
Read("file.py", offset=100, limit=50)

# Make targeted fix with Edit tool
Edit(file_path, old_string, new_string)

# Verify with tests
Bash("make test")
```

#### 3. Security Review

```bash
# Invoke Cybersecurity Agent
"Review this code for OWASP Top 10 vulnerabilities"

# Run security scans
Bash("make security-audit")

# Check for secrets
Bash("gitleaks detect --source . --verbose")
```

#### 4. Infrastructure Change

```bash
# Invoke Cloud Architecture Agent
"Deploy new Cloud Run service for prescription management"

# Use Terraform (when implemented)
Bash("cd infra/environments/staging && terraform plan")
```

---

## 📚 Key Documentation

### Primary Guides

- **[Project Structure Analysis](docs/PROJECT_STRUCTURE_ANALYSIS.md)** - Folder
  organization, architecture validation
- **[Project Commands Reference](docs/PROJECT_COMMANDS_REFERENCE.md)** - All CLI
  commands
- **[Token Optimization Strategy](docs/TOKEN_OPTIMIZATION_STRATEGY.md)** -
  Efficient Claude Code usage
- **[MCP Integration Matrix](docs/MCP_INTEGRATION_MATRIX.md)** - MCP server
  workflows
- **[Taskmaster AI Guide](docs/TASKMASTER_AI_GUIDE.md)** - Intelligent task
  management & sprint planning
- **[Comprehensive Optimization Plan](docs/COMPREHENSIVE_OPTIMIZATION_PLAN.md)** -
  Implementation roadmap

### Quality & Testing

- **[Quality Automation Guide](docs/QUALITY_AUTOMATION.md)** - Quality tools
  setup
- **[MCP Servers Guide](docs/MCP_SERVERS_GUIDE.md)** - MCP configuration
- **[Final Quality Report](FINAL_QUALITY_REPORT.md)** - Current quality status
  (A: 93/100)
- **[Cross-Browser Testing Report](CROSS_BROWSER_TESTING_REPORT.md)** - E2E
  testing guide

### Deployment & Infrastructure

- **[GCP Setup Guide](docs/deployment/gcp-setup.md)** - Complete GCP
  configuration
- **[Architecture Validation](docs/deployment/architecture-validation.md)** -
  Infrastructure gaps analysis
- **[Deployment Strategy](DEPLOYMENT_STRATEGY.md)** - Environment strategy

---

## 🎯 Current Status & Priorities

### Quality Metrics (as of 2025-10-05)

- **Overall Grade**: A (93/100) ⭐
- **E2E Tests**: 16/16 passing (100%) ✅
- **Code Quality**: 100% (linting, type safety, security) ✅
- **Accessibility**: 100/100 (Lighthouse) ✅
- **Performance**: 59/100 (dev) → Target: 90+ (production)
- **Infrastructure as Code**: 0% → **Critical Priority**

### Priority Gaps (P0 - Blocking Production)

1. **Infrastructure as Code** (F: 20/100)
   - ❌ No Terraform modules
   - ❌ Manual GCP configuration
   - **Impact**: Cannot reliably reproduce infrastructure
   - **Owner**: Cloud Architecture Agent

2. **Budget Alerts** (Not Implemented)
   - ❌ No cost monitoring
   - ❌ No spend alerts
   - **Impact**: Risk of cost overruns
   - **Owner**: Cloud Architecture Agent

3. **Security Headers** (Partially Implemented)
   - ⚠️ Missing CSP, X-Frame-Options, etc.
   - **Impact**: Security vulnerabilities
   - **Owner**: Cybersecurity Agent

### Medium Priority (P1)

1. **Shared Packages** (D: 40/100)
   - ❌ No @adyela/types
   - ❌ No @adyela/validation
   - **Impact**: Code duplication, type safety gaps

2. **Test Coverage** (Unknown → Target: 80%)
   - E2E: ✅ Excellent
   - Unit: ⚠️ Needs expansion
   - Integration: ⚠️ Needs creation

3. **Documentation** (C+: 78/100)
   - ✅ Deployment docs excellent
   - ❌ Missing architecture diagrams
   - ❌ Missing API documentation

---

## 💡 Working with This Project

### Token Optimization Tips

**Before Reading Files:**

1. Use `Grep` to find exact location
2. Use `Glob` to discover file patterns
3. Read with `offset` and `limit` for large files
4. Reference documentation before code

**Example - Efficient Approach:**

```bash
# Instead of reading entire file (800 tokens)
Grep("create_appointment", path="apps/api/")
# Returns: apps/api/adyela_api/application/use_cases/appointments/create_appointment.py:22

# Read only relevant section (150 tokens)
Read("apps/api/adyela_api/application/use_cases/appointments/create_appointment.py", offset=15, limit=50)
```

**Savings: 81%** (650 tokens saved)

### MCP Usage Patterns

**For Large Analysis:**

```
Instead of reading 50 files manually,
use Task Agent with "general-purpose" type:

"Analyze security vulnerabilities across the entire backend codebase"

Agent reads files internally, returns summary.
Savings: 90-95% tokens
```

**For E2E Testing:**

```
Use Playwright MCP for browser automation:
- Navigate to pages
- Take screenshots
- Run accessibility scans
- Execute E2E tests
```

### Code Style & Conventions

**Python (Backend):**

- Follow PEP 8 + Black formatting (100 char line length)
- Type hints required (enforced by MyPy)
- Docstrings for public APIs
- Domain-Driven Design patterns

**TypeScript (Frontend):**

- Functional components with hooks
- Strict TypeScript mode
- ESLint + Prettier
- Feature-based organization

**Commits:**

- Conventional Commits format
- Use `pnpm commit` for guided commits
- Include issue references

**Testing:**

- Unit tests: `test_<function>_<scenario>_<expected>`
- E2E tests: `<role> <action> <object> <result>`
- 100% coverage for business logic

---

## 🔐 Security & Compliance

### HIPAA Compliance Requirements

**Protected Health Information (PHI) includes:**

- Patient names, emails, phones
- Medical record numbers
- Appointment reasons/notes
- Any health-related data

**Key Rules:**

1. **Minimum Necessary**: Only access PHI needed for task
2. **Audit Logging**: ALL PHI access must be logged
3. **Encryption**: TLS in transit, CMEK at rest
4. **Access Control**: Role-based permissions
5. **Patient Rights**: Access, amendment, accounting of disclosures

**When handling PHI:**

```python
# Always log PHI access
await audit_log.log_phi_access(
    user_id=current_user.id,
    patient_id=patient_id,
    action="VIEW",
    reason="Appointment scheduling"
)

# Check permissions
if not await rbac.can_access_phi(user, patient_id):
    raise HTTPException(403, "Insufficient permissions")
```

### Security Best Practices

1. **Never commit secrets** - Use Secret Manager
2. **Validate all inputs** - Use Pydantic/Zod
3. **Sanitize outputs** - Prevent XSS
4. **Use data-testid** - For E2E test selectors (not text)
5. **Test security** - Include security test cases

---

## 🎨 Development Workflow

### Daily Workflow

```bash
# 1. Start services
make start

# 2. Check health
make health

# 3. Make changes
# ... code ...

# 4. Run tests
make test
make e2e

# 5. Quality checks
make lint
make type-check

# 6. Commit
pnpm commit

# 7. Stop services
make stop
```

### Creating a Pull Request

```bash
# 1. Create feature branch
git checkout -b feature/prescription-management

# 2. Make changes and commit
# ... work ...
pnpm commit

# 3. Push
git push -u origin feature/prescription-management

# 4. Create PR
gh pr create

# GitHub Actions will automatically:
# - Run linting
# - Run type checking
# - Run unit tests
# - Run E2E tests
# - Run security scans
# - Build containers
```

### Code Review Checklist

- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No hardcoded secrets
- [ ] PHI access logged (if applicable)
- [ ] Security considerations addressed
- [ ] Accessibility tested (for UI changes)
- [ ] Performance impact considered

---

## 🐛 Troubleshooting

### Common Issues

**Port already in use:**

```bash
lsof -i :3000  # Find process
kill -9 <PID>  # Kill it
```

**Docker issues:**

```bash
make clean     # Remove all containers/volumes
make build     # Rebuild
make start     # Start fresh
```

**Tests failing:**

```bash
# Ensure services are running
make health

# Run specific test
pnpm playwright test tests/e2e/auth.spec.ts --headed

# Check logs
make logs
```

**TypeScript errors:**

```bash
# Clear cache
rm -rf node_modules/.cache

# Reinstall
pnpm install

# Type check
pnpm type-check
```

---

## 📞 Getting Help

### When to Use Which Agent

| Issue Type                | Agent                    | Example                                             |
| ------------------------- | ------------------------ | --------------------------------------------------- |
| Infrastructure deployment | ☁️ Cloud Architecture    | "Deploy to staging", "Optimize costs"               |
| Security vulnerability    | 🔒 Cybersecurity         | "Fix XSS vulnerability", "Run security scan"        |
| Test failures             | 🧪 QA Automation         | "E2E test failing", "Improve coverage"              |
| PHI handling question     | 🏥 Healthcare Compliance | "Is this HIPAA compliant?", "How to log PHI access" |
| General coding            | Claude Code              | "Add new feature", "Fix bug"                        |

### Documentation Quick Reference

- **Commands**: `docs/PROJECT_COMMANDS_REFERENCE.md`
- **Structure**: `docs/PROJECT_STRUCTURE_ANALYSIS.md`
- **Quality**: `FINAL_QUALITY_REPORT.md`
- **Deployment**: `docs/deployment/gcp-setup.md`
- **MCP Guide**: `docs/MCP_SERVERS_GUIDE.md`

---

## 🎯 Next Steps & Roadmap

### Immediate (This Week)

1. Implement Terraform modules (Cloud Architecture Agent)
2. Add security headers (Cybersecurity Agent)
3. Expand E2E test coverage (QA Automation Agent)
4. Complete HIPAA compliance checklist (Healthcare Compliance Agent)

### Short-term (2-4 Weeks)

1. Create shared packages (@adyela/types, validation, ui)
2. Increase unit test coverage to 80%
3. Complete architecture documentation
4. Setup visual regression testing

### Long-term (1-3 Months)

1. Multi-region deployment
2. Load testing & performance optimization
3. External security audit
4. SOC 2 Type II certification preparation

---

## 📊 Key Metrics Dashboard

### Current State

```
Code Quality:     █████████░ 90% (A-)
Test Coverage:    ██████░░░░ 60% (B)
Infrastructure:   ░░░░░░░░░░  0% (F) ⚠️
Security:         ████████░░ 80% (B+)
Documentation:    ███████░░░ 70% (C+)
HIPAA Compliance: ████████░░ 75% (B)
Overall:          ███████░░░ 75% (B)
```

### Targets (3 Months)

```
Code Quality:     ██████████ 95% (A)
Test Coverage:    ████████░░ 80% (A-)
Infrastructure:   █████████░ 90% (A-)
Security:         █████████░ 95% (A)
Documentation:    █████████░ 90% (A-)
HIPAA Compliance: ██████████ 100% (A+)
Overall:          █████████░ 95% (A)
```

---

## 🌟 Best Practices Summary

### Do ✅

- Use data-testid for E2E tests
- Log all PHI access
- Follow hexagonal architecture (backend)
- Use feature-based structure (frontend)
- Write comprehensive tests
- Document architectural decisions (ADRs)
- Use conventional commits
- Invoke specialized agents for their domains

### Don't ❌

- Hardcode secrets
- Commit node_modules or **pycache**
- Skip tests
- Access PHI without logging
- Make infrastructure changes without Terraform (when implemented)
- Use text-based selectors in E2E tests
- Deploy to production without approval

---

## 🔗 Important Links

### External Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [React Documentation](https://react.dev/)
- [Playwright Documentation](https://playwright.dev/)
- [GCP Documentation](https://cloud.google.com/docs)
- [HIPAA Compliance Guide](https://www.hhs.gov/hipaa/index.html)
- [OWASP Top 10](https://owasp.org/Top10/)

### Project Resources

- **Repository**: https://github.com/adyela/adyela (if public)
- **API Docs**: http://localhost:8000/docs (when running)
- **Staging**: https://staging.adyela.com (when deployed)
- **Production**: https://adyela.com (when deployed)

---

## 📝 Version Information

- **Project Version**: 0.1.0
- **Node**: >=20.0.0
- **pnpm**: >=9.0.0
- **Python**: 3.12
- **Flutter**: >=3.24.0
- **Dart**: >=3.5.0
- **CLAUDE.md Version**: 2.0.0
- **Last Updated**: 2025-10-18

---

## ✨ Conclusion

This is a **multi-platform, HIPAA-compliant healthcare platform** in active
development with:

**✅ Completed:**

- Excellent architecture (hexagonal backend, feature-based frontend/mobile)
- Flutter native apps for iOS/Android/Web (mobile-patient, mobile-professional)
- 85%+ code reuse strategy with shared packages (flutter-core, flutter-shared)
- React admin panel with 100% accessibility score (WCAG 2.1 AA)
- Comprehensive quality automation (93/100 grade)
- 100% passing E2E tests (Playwright)

**🔧 In Development:**

- 6 microservices (api-auth, api-appointments, api-payments, api-notifications,
  api-analytics, api-admin)
- Strangler Fig Pattern migration from monolith to microservices
- Multi-tenancy architecture (currently single-tenant, migration planned)

**⚠️ Critical Priorities:**

- Infrastructure as Code (Terraform) implementation
- Multi-tenant Firestore migration
- Microservices integration and deployment
- Budget alerts and cost monitoring

**The codebase demonstrates** best practices in multi-platform development with
Flutter, clean architecture patterns, and comprehensive code reuse strategies.
The project is well-positioned for scaling once microservices migration and
infrastructure gaps are addressed.

**For Claude Code users:** This project is optimized for AI-assisted development
with specialized agents, MCP integration, and comprehensive documentation.
Follow the token optimization strategies and invoke the appropriate agents for
best results.

---

**Status**: 🟡 **Active Development** | Microservices Migration in Progress

**Contact**: dev@adyela.com (if applicable)

**License**: UNLICENSED (Private)

---

_This document is maintained by the Adyela development team and should be
updated when significant project changes occur._
