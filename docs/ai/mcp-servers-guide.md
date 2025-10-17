# MCP Servers Integration Guide

## Overview

This guide provides recommendations and configuration for Model Context Protocol
(MCP) servers to enhance development quality, testing, and verification.

## Currently Available

- ✅ **Playwright** - Browser automation and E2E testing

## Recommended MCP Servers

### 1. Testing & Quality Assurance

#### Playwright (Already Configured)

**Purpose**: End-to-end testing, browser automation **Use cases**:

- Test user flows (login, appointments, video calls)
- Visual regression testing
- Automated screenshot capture
- Form validation testing

**Key features available**:

- `browser_navigate` - Navigate to URLs
- `browser_snapshot` - Capture accessibility tree
- `browser_click` - Interact with elements
- `browser_type` - Fill forms
- `browser_take_screenshot` - Visual testing

#### Context7

**Purpose**: Advanced code analysis and semantic search **Installation**:

```bash
npm install -g @context7/mcp-server
```

**Use cases**:

- Deep code analysis across the monorepo
- Find similar patterns
- Detect code smells
- Track architectural decisions

### 2. Code Quality & Linting

#### ESLint MCP

**Purpose**: Real-time linting and code quality checks **Use cases**:

- Automated linting on file changes
- Custom rule enforcement
- Fix suggestions

#### Prettier MCP

**Purpose**: Code formatting **Use cases**:

- Consistent code style
- Auto-formatting on save

### 3. Testing & Coverage

#### Jest/Vitest MCP

**Purpose**: Unit and integration testing **Use cases**:

- Run tests on demand
- Coverage reports
- Test generation

#### Schemathesis MCP

**Purpose**: API contract testing **Use cases**:

- OpenAPI spec validation
- API fuzzing
- Contract testing

### 4. Database & Data

#### PostgreSQL MCP (Future)

**Purpose**: Database operations and schema management **Use cases**:

- Query execution
- Schema migrations
- Data seeding

#### Firebase Admin MCP

**Purpose**: Firebase operations **Use cases**:

- Firestore queries
- Auth management
- Storage operations

### 5. DevOps & Deployment

#### Docker MCP

**Purpose**: Container management **Use cases**:

- Build and tag images
- Container inspection
- Log streaming

#### Kubernetes MCP (Future)

**Purpose**: Kubernetes cluster management **Use cases**:

- Deployment status
- Pod logs
- Resource scaling

#### Google Cloud MCP

**Purpose**: GCP operations **Installation**:

```bash
npm install -g @google-cloud/mcp-server
```

**Use cases**:

- Cloud Run deployments
- Secret Manager access
- GCS operations
- Cloud Build triggers

### 6. Monitoring & Observability

#### Sentry MCP

**Purpose**: Error tracking and monitoring **Use cases**:

- Error investigation
- Performance monitoring
- Release tracking

#### Lighthouse MCP

**Purpose**: Performance and accessibility audits **Use cases**:

- Performance scores
- Accessibility checks
- SEO audits
- Best practices validation

### 7. Development Tools

#### GitHub MCP (Partially Available via gh CLI)

**Purpose**: GitHub operations **Use cases**:

- PR management
- Issue tracking
- Code reviews
- Actions workflows

#### Sequential Thinking MCP

**Purpose**: Complex problem solving **Use cases**:

- Debugging complex issues
- Architecture decisions
- Refactoring planning

## Configuration

### Global MCP Configuration

Create or update
`~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp"]
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@context7/mcp-server"]
    },
    "docker": {
      "command": "npx",
      "args": ["-y", "@docker/mcp-server"]
    },
    "gcloud": {
      "command": "npx",
      "args": ["-y", "@google-cloud/mcp-server"],
      "env": {
        "GOOGLE_CLOUD_PROJECT": "adyela-dev"
      }
    },
    "lighthouse": {
      "command": "npx",
      "args": ["-y", "@lighthouse/mcp-server"]
    },
    "sentry": {
      "command": "npx",
      "args": ["-y", "@sentry/mcp-server"],
      "env": {
        "SENTRY_DSN": "${SENTRY_DSN}"
      }
    },
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/Users/hevergonzalezgarcia/TFM Agentes IA/CLAUDE/adyela"
      ]
    }
  }
}
```

### Project-Specific MCP Scripts

Create `.claude/mcp-config.json` in the project:

```json
{
  "testing": {
    "playwright": {
      "enabled": true,
      "config": "./playwright.config.ts"
    },
    "vitest": {
      "enabled": true,
      "config": "./vitest.config.ts"
    }
  },
  "quality": {
    "eslint": true,
    "prettier": true,
    "lighthouse": {
      "url": "http://localhost:3000",
      "categories": ["performance", "accessibility", "best-practices", "seo"]
    }
  },
  "deployment": {
    "docker": {
      "registry": "gcr.io/adyela-dev"
    },
    "gcloud": {
      "project": "adyela-dev",
      "region": "us-central1"
    }
  }
}
```

## Usage Examples

### 1. E2E Testing with Playwright

```typescript
// Test login flow
await browser_navigate({ url: 'http://localhost:3000' });
const snapshot = await browser_snapshot();
await browser_type({
  element: 'email input',
  ref: 'email-field',
  text: 'test@example.com',
});
await browser_type({
  element: 'password input',
  ref: 'password-field',
  text: 'password123',
});
await browser_click({
  element: 'login button',
  ref: 'login-btn',
});
```

### 2. Performance Audit with Lighthouse

```bash
# Run Lighthouse audit
lighthouse http://localhost:3000 --output=json
```

### 3. API Testing with Schemathesis

```bash
# Test API against OpenAPI spec
schemathesis run http://localhost:8000/openapi.json \
  --base-url http://localhost:8000 \
  --checks all
```

### 4. Docker Operations

```bash
# Build and test images
docker build -t adyela-api:test ./apps/api
docker build -t adyela-web:test ./apps/web
```

## Verification Workflows

### Pre-Commit Checks

1. ESLint + Prettier formatting
2. Type checking (TypeScript + Python)
3. Unit tests
4. API contract validation

### Pre-Push Checks

1. Integration tests
2. E2E critical paths
3. Lighthouse performance audit
4. Security scanning

### Pre-Release Checks

1. Full E2E test suite
2. Performance benchmarks
3. Accessibility audit
4. API load testing
5. Docker image security scan

## Priority Implementation

### Phase 1 (Immediate)

- [x] Playwright - Already configured
- [ ] Lighthouse - Performance monitoring
- [ ] Docker MCP - Container operations

### Phase 2 (Short-term)

- [ ] Context7 - Code analysis
- [ ] Schemathesis - API testing
- [ ] GitHub MCP - Enhanced PR workflow

### Phase 3 (Medium-term)

- [ ] Google Cloud MCP - GCP operations
- [ ] Sentry MCP - Error monitoring
- [ ] Firebase Admin MCP - Data operations

## Next Steps

1. Install recommended MCP servers
2. Configure Playwright test suite
3. Set up Lighthouse CI
4. Create automated quality gates
5. Document testing procedures

## Resources

- [MCP Documentation](https://modelcontextprotocol.io/)
- [Playwright MCP](https://github.com/microsoft/playwright-mcp)
- [Available MCP Servers](https://github.com/modelcontextprotocol/servers)
