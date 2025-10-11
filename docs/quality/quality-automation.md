# Quality Automation & MCP Integration

## Overview

This project now includes comprehensive quality automation tools and MCP (Model Context Protocol) server integrations to enhance development workflow, testing, and code quality.

## 🎯 Features Implemented

### 1. MCP Server Integration

#### Available MCP Servers

- **Playwright MCP** ✅ - Browser automation and E2E testing
- **Filesystem MCP** - Advanced file operations
- **GitHub MCP** - Repository and PR management
- **Sequential Thinking MCP** - Complex problem solving

#### Setup

```bash
# Configure MCP servers
make mcp-setup

# Or manually
./scripts/setup-mcp-servers.sh
```

Configuration will be created at:

- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Linux: `~/.config/claude/claude_desktop_config.json`

### 2. End-to-End Testing with Playwright

#### Test Files Created

- `tests/e2e/auth.spec.ts` - Authentication flow tests
- `tests/e2e/api-health.spec.ts` - API health and contract validation

#### Running E2E Tests

```bash
# Run all E2E tests
make e2e
# or
pnpm test:e2e

# Run with UI (interactive mode)
make e2e-ui
pnpm test:e2e:ui

# Run in debug mode
make e2e-debug
pnpm test:e2e:debug

# Run in headed mode (see browser)
make e2e-headed
pnpm test:e2e:headed

# View test report
make e2e-report
```

#### E2E Test Coverage

- ✅ Login page display and validation
- ✅ Authentication flow
- ✅ Form validation
- ✅ Accessibility checks
- ✅ Mobile responsiveness
- ✅ Session persistence
- ✅ API health checks
- ✅ CORS validation
- ✅ Security headers
- ✅ Response time validation

### 3. Performance & Accessibility Audits

#### Lighthouse Integration

```bash
# Run Lighthouse audit
make lighthouse

# Run with specific URL
./scripts/lighthouse-audit.sh http://localhost:3000
```

#### Thresholds

- Performance: 80/100
- Accessibility: 90/100
- Best Practices: 85/100
- SEO: 90/100

Reports are generated in `lighthouse-reports/`

### 4. API Contract Testing

#### Schemathesis Integration

```bash
# Run API contract tests
make api-contract

# Or directly
./scripts/api-contract-tests.sh
```

Validates your API against the OpenAPI specification with:

- Schema validation
- Response format checking
- Status code verification
- Content-type validation
- Hypothesis-based fuzzing

### 5. Quality Checks Automation

#### Comprehensive Quality Script

```bash
# Run all quality checks
make quality

# Run quality checks with auto-fix
make quality-fix
```

The quality check includes:

1. **ESLint** - JavaScript/TypeScript linting
2. **TypeScript** - Type checking
3. **Ruff** - Python linting (API)
4. **MyPy** - Python type checking
5. **Unit Tests** - Frontend & backend
6. **Build Validation** - Ensures project builds
7. **Security Audit** - NPM & Python security scan
8. **Bundle Size Analysis** - Track bundle sizes

### 6. Enhanced Makefile Commands

#### New Commands Added

**Quality & Testing**

```bash
make quality          # Run all quality checks
make quality-fix      # Run quality checks with auto-fix
make type-check       # TypeScript & Python type checking
make security-audit   # Security vulnerability scan
```

**E2E Testing**

```bash
make e2e             # Run E2E tests
make e2e-ui          # Interactive UI mode
make e2e-debug       # Debug mode
make e2e-headed      # Headed mode (visible browser)
make e2e-report      # View test report
```

**Performance**

```bash
make lighthouse      # Run Lighthouse audit
make lighthouse-ci   # CI mode with thresholds
```

**API Testing**

```bash
make api-contract    # API contract tests
make api-load        # Load testing (placeholder)
```

**MCP**

```bash
make mcp-setup       # Setup MCP servers
make mcp-test        # Test MCP integration
```

**CI/CD**

```bash
make ci-local        # Simulate full CI pipeline
make reports         # Generate all reports
```

## 📊 Test Reports

After running tests, reports are available at:

- **E2E Tests**: `playwright-report/index.html`
- **API Coverage**: `apps/api/htmlcov/index.html`
- **Web Coverage**: `apps/web/coverage/index.html`
- **Lighthouse**: `lighthouse-reports/report-[timestamp].report.html`
- **API Contract**: `schemathesis-reports/report-[timestamp].html`

## 🔄 CI/CD Integration

### Local CI Simulation

```bash
make ci-local
```

This runs the complete pipeline:

1. Quality checks (lint, type-check, security)
2. E2E tests
3. Performance audit
4. API contract tests

### Recommended CI Pipeline

**Pre-Commit** (via Husky)

- Code formatting (Prettier)
- Linting (ESLint, Ruff)

**Pre-Push**

- Type checking
- Unit tests
- Basic quality checks

**CI Pipeline**

```yaml
stages:
  - lint
  - test
  - build
  - audit

lint:
  - make quality

test:
  - make test
  - make e2e

audit:
  - make lighthouse
  - make api-contract
  - make security-audit
```

## 🛠️ Configuration Files

### Playwright Configuration

- `playwright.config.ts` - E2E test configuration
- Supports multiple browsers: Chrome, Firefox, Safari
- Mobile viewports: Pixel 5, iPhone 12
- Tablet viewport: iPad Pro

### MCP Configuration

- `.claude/mcp-config.json` - Project-specific MCP settings
- Defines workflows and automation rules

## 📝 Usage Examples

### Example 1: Pre-Deployment Checks

```bash
# Run full quality suite before deploying
make quality
make e2e
make lighthouse
make api-contract
```

### Example 2: Feature Development Workflow

```bash
# 1. Start development
make start

# 2. Make changes...

# 3. Run quality checks
make quality-fix

# 4. Run E2E tests for affected features
make e2e-ui  # Interactive mode

# 5. Check performance
make lighthouse

# 6. Commit changes
git add .
git commit -m "feat: your feature"  # Pre-commit hooks run automatically
```

### Example 3: Debugging Test Failures

```bash
# Run E2E tests in debug mode
make e2e-debug

# Or use Playwright UI for visual debugging
make e2e-ui
```

## 🚀 Next Steps

### Immediate Actions

1. **Install Playwright browsers**:

   ```bash
   pnpm playwright install
   ```

2. **Setup MCP servers**:

   ```bash
   make mcp-setup
   ```

3. **Run initial quality check**:
   ```bash
   make quality
   ```

### Recommended Enhancements

1. **Visual Regression Testing**
   - Add Percy or Chromatic integration
   - Configure visual diff thresholds

2. **Load Testing**
   - Implement k6 scripts
   - Define performance benchmarks

3. **Mutation Testing**
   - Add Stryker for test quality
   - Track mutation score

4. **Accessibility Testing**
   - Add axe-core integration
   - WCAG compliance checks

5. **API Monitoring**
   - Setup synthetic monitoring
   - Alert on performance degradation

## 📚 Additional Resources

- [Playwright Documentation](https://playwright.dev/)
- [Lighthouse CI](https://github.com/GoogleChrome/lighthouse-ci)
- [Schemathesis Docs](https://schemathesis.readthedocs.io/)
- [MCP Protocol](https://modelcontextprotocol.io/)
- [MCP Servers Guide](./MCP_SERVERS_GUIDE.md)

## 🤝 Contributing

When adding new features:

1. Add E2E tests in `tests/e2e/`
2. Ensure `make quality` passes
3. Run `make e2e` locally
4. Check performance with `make lighthouse`
5. Validate API contracts with `make api-contract`

## 📞 Support

For issues or questions:

- Check existing tests in `tests/e2e/`
- Review scripts in `scripts/`
- Consult MCP documentation in `docs/MCP_SERVERS_GUIDE.md`
