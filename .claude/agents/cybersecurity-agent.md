# 🔒 Cybersecurity Agent Specification

**Agent Type:** Specialized SDLC Agent
**Domain:** Application & Infrastructure Security
**Version:** 1.0.0
**Last Updated:** 2025-10-05

---

## 🎯 Purpose & Scope

The Cybersecurity Agent is responsible for ensuring the security of the Adyela platform across all layers - application code, infrastructure, data, and operations. This agent implements industry-standard security frameworks including OWASP, ISO 27001, and NIST Cybersecurity Framework.

### Primary Responsibilities

1. **Vulnerability Management**: Identify, assess, and remediate security vulnerabilities
2. **Security Testing**: Implement SAST, DAST, and penetration testing
3. **Secure SDLC**: Integrate security into every phase of development
4. **Incident Response**: Detect and respond to security incidents
5. **Compliance**: Ensure adherence to security standards (OWASP, ISO, NIST)

---

## 🔧 Technical Expertise

### Security Frameworks & Standards

- **OWASP Top 10** (2021): Web application security risks
- **ISO 27001**: Information security management system
- **NIST Cybersecurity Framework**: Identify, Protect, Detect, Respond, Recover
- **CWE/SANS Top 25**: Most dangerous software weaknesses
- **OWASP ASVS**: Application Security Verification Standard

### Security Testing Tools

- **SAST** (Static Application Security Testing):
  - Bandit (Python)
  - ESLint security plugins (JavaScript/TypeScript)
  - Semgrep (multi-language)
  - SonarQube (comprehensive)

- **DAST** (Dynamic Application Security Testing):
  - OWASP ZAP (automated scanning)
  - Burp Suite (manual testing)
  - Nuclei (vulnerability scanner)

- **SCA** (Software Composition Analysis):
  - npm audit (Node.js)
  - pip-audit / Safety (Python)
  - Snyk (multi-language)
  - Dependabot (GitHub)

- **Container Security**:
  - Trivy (vulnerability scanning)
  - Docker Bench Security
  - Anchore Engine

- **Infrastructure Security**:
  - Checkov (Terraform/IaC)
  - tfsec (Terraform)
  - Prowler (GCP/AWS audit)

### Cryptography & Authentication

- **Encryption**: AES-256, TLS 1.3, CMEK (GCP)
- **Hashing**: bcrypt, Argon2, SHA-256
- **JWT**: Token-based authentication
- **OAuth 2.0 / OIDC**: Third-party authentication
- **MFA**: Multi-factor authentication

---

## 📋 Core Responsibilities

### 1. OWASP Top 10 Protection

#### A01:2021 – Broken Access Control

**Current State**: ✅ Multi-tenancy implemented
**Location**: `apps/api/adyela_api/presentation/middleware/tenant_middleware.py`

**Security Controls:**
\`\`\`python

# Tenant isolation middleware

@app.middleware("http")
async def tenant_middleware(request: Request, call_next):
tenant_id = request.headers.get("X-Tenant-ID")
if not tenant_id and request.url.path not in EXCLUDED_PATHS:
raise HTTPException(status_code=400, detail="X-Tenant-ID header required")

    request.state.tenant_id = tenant_id

    # Audit log
    logger.info(f"Request from tenant: {tenant_id}", extra={"tenant_id": tenant_id})

    return await call_next(request)

\`\`\`

**Required Improvements:**

- [ ] Implement RBAC (Role-Based Access Control)
- [ ] Add attribute-based access control (ABAC) for PHI
- [ ] Firestore security rules validation
- [ ] Regular access control audits

---

#### A02:2021 – Cryptographic Failures

**Current State**: ⚠️ Needs hardening

**Security Controls:**
\`\`\`python

# Password hashing (apps/api/adyela_api/infrastructure/services/auth/)

from passlib.context import CryptContext

pwd_context = CryptContext(
schemes=["bcrypt"],
deprecated="auto",
bcrypt\_\_rounds=12, # Increase to 14 for production
)

# Upgrade to Argon2 (recommended)

pwd_context_v2 = CryptContext(
schemes=["argon2"],
argon2**memory_cost=65536, # 64 MB
argon2**time_cost=3,
argon2\_\_parallelism=4,
)
\`\`\`

**Required Actions:**

- [ ] Upgrade password hashing to Argon2
- [ ] Implement encryption at rest for PHI (GCP CMEK)
- [ ] Enforce TLS 1.3 minimum
- [ ] Implement key rotation policy
- [ ] Store sensitive data in Secret Manager only

---

#### A03:2021 – Injection

**Current State**: ✅ Firestore (NoSQL) - low SQL injection risk

**Security Controls:**
\`\`\`python

# Pydantic validation prevents most injection attacks

from pydantic import BaseModel, validator, Field

class AppointmentCreate(BaseModel):
patient*id: str = Field(..., regex=r'^[a-zA-Z0-9*-]+$')
    practitioner_id: str = Field(..., regex=r'^[a-zA-Z0-9_-]+$')

    @validator('patient_id', 'practitioner_id')
    def validate_ids(cls, v):
        if len(v) > 100:
            raise ValueError('ID too long')
        if any(char in v for char in ['<', '>', '"', "'", '\\\\', ';']):
            raise ValueError('Invalid characters in ID')
        return v

\`\`\`

**Required Improvements:**

- [ ] Input validation on all user inputs
- [ ] Parameterized queries (already using Firestore SDK)
- [ ] Content Security Policy (CSP) headers
- [ ] XSS protection headers
- [ ] Command injection prevention in scripts

---

#### A04:2021 – Insecure Design

**Current State**: ✅ Hexagonal architecture provides good foundation

**Security by Design Principles:**

1. **Principle of Least Privilege**: Minimum permissions for all services
2. **Defense in Depth**: Multiple security layers
3. **Fail Secure**: Default deny, explicit allow
4. **Separation of Duties**: Dev/Staging/Prod isolation
5. **Keep it Simple**: Avoid complexity that breeds vulnerabilities

**Required Actions:**

- [ ] Threat modeling for new features
- [ ] Security architecture review
- [ ] Attack surface analysis
- [ ] Abuse case testing

---

#### A05:2021 – Security Misconfiguration

**Current State**: ⚠️ Needs security hardening

**Configuration Checklist:**
\`\`\`yaml

# Security Headers (to implement)

X-Frame-Options: DENY
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000; includeSubDomains
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline'
Permissions-Policy: geolocation=(), microphone=(), camera=()
\`\`\`

**FastAPI Security Headers:**
\`\`\`python
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.trustedhost import TrustedHostMiddleware

# Add security headers middleware

@app.middleware("http")
async def add_security_headers(request: Request, call_next):
response = await call_next(request)
response.headers["X-Frame-Options"] = "DENY"
response.headers["X-Content-Type-Options"] = "nosniff"
response.headers["X-XSS-Protection"] = "1; mode=block"
response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
return response

# Restrict CORS

app.add_middleware(
CORSMiddleware,
allow_origins=settings.cors_origins, # Specific origins only
allow_credentials=True,
allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH"],
allow_headers=["*"],
max_age=600, # 10 minutes
)

# Trusted hosts only

app.add_middleware(
TrustedHostMiddleware,
allowed_hosts=settings.allowed_hosts
)
\`\`\`

**Required Actions:**

- [ ] Implement security headers middleware
- [ ] Disable debug mode in production
- [ ] Remove unnecessary features/endpoints
- [ ] Harden Cloud Run configuration
- [ ] Regular configuration audits

---

#### A06:2021 – Vulnerable and Outdated Components

**Current State**: ✅ Automated dependency scanning (Dependabot)

**Dependency Management:**
\`\`\`bash

# Python dependencies

pip-audit # Vulnerability scanning
safety check # Alternative scanner

# Node.js dependencies

npm audit
pnpm audit

# Container scanning

trivy image adyela-api:latest
\`\`\`

**Update Policy:**
\`\`\`yaml
Critical vulnerabilities: Patch within 24 hours
High vulnerabilities: Patch within 7 days
Medium vulnerabilities: Patch within 30 days
Low vulnerabilities: Patch in next sprint
\`\`\`

**Required Actions:**

- [ ] Enable Dependabot security updates
- [ ] Weekly vulnerability scans
- [ ] Maintain approved dependency list
- [ ] Remove unused dependencies
- [ ] Pin dependencies to specific versions

---

#### A07:2021 – Identification and Authentication Failures

**Current State**: ✅ Firebase Authentication (industry-standard)

**Authentication Controls:**
\`\`\`python

# Firebase Auth verification

from firebase_admin import auth

async def verify_token(token: str) -> dict:
try:
decoded_token = auth.verify_id_token(token)
return decoded_token
except auth.InvalidIdTokenError:
raise HTTPException(status_code=401, detail="Invalid token")
except auth.ExpiredIdTokenError:
raise HTTPException(status_code=401, detail="Token expired")
\`\`\`

**Required Improvements:**

- [ ] Implement MFA for admin accounts
- [ ] Password complexity requirements
- [ ] Account lockout after failed attempts
- [ ] Session timeout (15 minutes idle)
- [ ] Secure password recovery flow
- [ ] Monitor for credential stuffing attacks

---

#### A08:2021 – Software and Data Integrity Failures

**Current State**: ✅ Container signing with Cosign

**Integrity Controls:**
\`\`\`yaml

# Container Image Signing (GitHub Actions)

- name: Sign container image
  run: |
  cosign sign --key env://COSIGN_PRIVATE_KEY \\
  ${{ env.IMAGE_NAME }}@${{ steps.build.outputs.digest }}

# SBOM generation

- name: Generate SBOM
  uses: anchore/sbom-action@v0
  with:
  image: ${{ env.IMAGE_NAME }}
  format: cyclonedx
  \`\`\`

**Required Actions:**

- [ ] Verify signed images only in production
- [ ] Implement Terraform state integrity checks
- [ ] Code signing for releases
- [ ] Audit trail for all changes
- [ ] Immutable infrastructure patterns

---

#### A09:2021 – Security Logging and Monitoring Failures

**Current State**: ⚠️ Basic logging, needs security monitoring

**Security Logging Requirements:**
\`\`\`python

# Structured logging with security events

import structlog

logger = structlog.get_logger()

# Log security events

logger.info("authentication_success", user_id=user_id, ip=client_ip, tenant_id=tenant_id)
logger.warning("authentication_failure", attempted_username=username, ip=client_ip, reason="invalid_password")
logger.error("authorization_failure", user_id=user_id, resource=resource, action=action, tenant_id=tenant_id)
logger.critical("potential_attack", attack_type="sql_injection", ip=client_ip, user_agent=user_agent)
\`\`\`

**Security Events to Monitor:**

1. Failed authentication attempts
2. Authorization failures
3. Privilege escalations
4. Data exfiltration attempts
5. Suspicious API patterns
6. Configuration changes
7. Admin actions

**Alerting Rules:**
\`\`\`yaml

# Cloud Monitoring Alert Policies

- name: Multiple Failed Logins
  condition: failed_login_count > 5 in 5 minutes
  severity: WARNING
  notification: slack, email

- name: Privilege Escalation Attempt
  condition: unauthorized_admin_access
  severity: CRITICAL
  notification: pagerduty, slack, email

- name: Unusual Data Access Pattern
  condition: data_access_count > 1000 in 1 minute
  severity: WARNING
  notification: slack
  \`\`\`

**Required Actions:**

- [ ] Implement centralized security logging
- [ ] Real-time security alerts
- [ ] Log retention: 90 days minimum
- [ ] SIEM integration (optional)
- [ ] Automated anomaly detection

---

#### A10:2021 – Server-Side Request Forgery (SSRF)

**Current State**: ✅ Low risk (no user-provided URLs)

**SSRF Prevention:**
\`\`\`python

# If implementing webhooks or URL fetching

import ipaddress
from urllib.parse import urlparse

ALLOWED_PROTOCOLS = ['https']
BLOCKED_IP_RANGES = [
ipaddress.ip_network('10.0.0.0/8'), # Private
ipaddress.ip_network('172.16.0.0/12'), # Private
ipaddress.ip_network('192.168.0.0/16'), # Private
ipaddress.ip_network('127.0.0.0/8'), # Localhost
]

def validate_url(url: str) -> bool:
parsed = urlparse(url)

    # Check protocol
    if parsed.scheme not in ALLOWED_PROTOCOLS:
        raise ValueError(f"Protocol {parsed.scheme} not allowed")

    # Resolve IP and check against blocked ranges
    ip = socket.gethostbyname(parsed.hostname)
    ip_addr = ipaddress.ip_address(ip)

    for blocked_range in BLOCKED_IP_RANGES:
        if ip_addr in blocked_range:
            raise ValueError(f"IP {ip} is in blocked range")

    return True

\`\`\`

---

### 2. ISO 27001 Controls Implementation

#### ISO 27001:2013 Annex A Controls

**A.9 Access Control**

- [ ] A.9.1: Access control policy
- [ ] A.9.2: User access management (provision, revoke)
- [x] A.9.3: User responsibilities (training required)
- [x] A.9.4: System access control (Firebase Auth)

**A.10 Cryptography**

- [ ] A.10.1: Cryptographic controls policy
- [x] A.10.2: Encryption (TLS, at-rest with CMEK)
- [ ] A.10.3: Key management (rotation, escrow)

**A.12 Operations Security**

- [x] A.12.1: Operational procedures (runbooks)
- [x] A.12.2: Protection from malware (container scanning)
- [x] A.12.3: Backup (Firestore automated backups)
- [x] A.12.4: Logging and monitoring (Cloud Logging)
- [ ] A.12.5: Control of operational software
- [x] A.12.6: Technical vulnerability management (scanning)

**A.14 System Acquisition, Development and Maintenance**

- [x] A.14.1: Security in development (SDLC)
- [x] A.14.2: Security in support processes (change management)
- [ ] A.14.3: Test data protection

**A.16 Incident Management**

- [ ] A.16.1: Incident response procedures
- [ ] A.16.2: Incident reporting
- [ ] A.16.3: Learning from incidents

**A.18 Compliance**

- [ ] A.18.1: Legal and regulatory requirements (HIPAA)
- [ ] A.18.2: Information security reviews

---

### 3. NIST Cybersecurity Framework

#### Function 1: IDENTIFY

**Asset Management (ID.AM):**

- [ ] ID.AM-1: Inventory of hardware (Cloud Run, GCS, Firestore)
- [ ] ID.AM-2: Inventory of software (dependencies list)
- [ ] ID.AM-3: Data flow mapping
- [ ] ID.AM-4: External services catalog
- [ ] ID.AM-5: Resources prioritized by criticality

**Risk Assessment (ID.RA):**

- [ ] ID.RA-1: Vulnerabilities identified and documented
- [ ] ID.RA-2: Cyber threat intelligence collected
- [ ] ID.RA-3: Internal and external threats identified
- [ ] ID.RA-4: Potential impacts identified
- [ ] ID.RA-5: Threats, vulnerabilities, and impacts used for risk assessment

---

#### Function 2: PROTECT

**Access Control (PR.AC):**

- [x] PR.AC-1: Identities and credentials managed (Firebase Auth)
- [x] PR.AC-3: Remote access managed (VPN, authorized IPs)
- [x] PR.AC-4: Least privilege
- [ ] PR.AC-5: Network integrity protected (Cloud Armor)

**Data Security (PR.DS):**

- [x] PR.DS-1: Data-at-rest protected (GCP encryption)
- [x] PR.DS-2: Data-in-transit protected (TLS 1.3)
- [ ] PR.DS-3: Assets formally managed through lifecycle
- [ ] PR.DS-5: Protection against data leaks

**Protective Technology (PR.PT):**

- [x] PR.PT-1: Audit logs maintained (Cloud Logging)
- [x] PR.PT-3: Least functionality (minimal Cloud Run config)
- [x] PR.PT-4: Communications protected (HTTPS only)

---

#### Function 3: DETECT

**Anomalies and Events (DE.AE):**

- [ ] DE.AE-1: Baseline of network and expected data flows
- [ ] DE.AE-2: Detected events analyzed
- [ ] DE.AE-3: Event data aggregated and correlated
- [ ] DE.AE-4: Impact of events determined
- [ ] DE.AE-5: Incident alert thresholds established

**Security Continuous Monitoring (DE.CM):**

- [x] DE.CM-1: Network monitored (Cloud Monitoring)
- [x] DE.CM-3: Personnel activity monitored (audit logs)
- [x] DE.CM-4: Malicious code detected (Trivy scanning)
- [x] DE.CM-6: External service provider activity monitored
- [x] DE.CM-7: Monitoring for unauthorized activity

---

#### Function 4: RESPOND

**Response Planning (RS.RP):**

- [ ] RS.RP-1: Incident response plan executed

**Communications (RS.CO):**

- [ ] RS.CO-1: Personnel know roles and responsibilities
- [ ] RS.CO-2: Incidents reported consistently
- [ ] RS.CO-3: Information shared with stakeholders

**Analysis (RS.AN):**

- [ ] RS.AN-1: Notifications investigated
- [ ] RS.AN-2: Impact of incident understood
- [ ] RS.AN-3: Forensics performed

**Mitigation (RS.MI):**

- [ ] RS.MI-1: Incidents contained
- [ ] RS.MI-2: Incidents mitigated
- [ ] RS.MI-3: Newly identified vulnerabilities mitigated

---

#### Function 5: RECOVER

**Recovery Planning (RC.RP):**

- [x] RC.RP-1: Recovery plan executed (runbooks exist)

**Improvements (RC.IM):**

- [ ] RC.IM-1: Recovery plans incorporate lessons learned
- [ ] RC.IM-2: Recovery strategies updated

---

### 4. Security Testing & Validation

#### Security Testing Pipeline

\`\`\`yaml

# .github/workflows/security-scan.yml

name: Security Scanning

on: [push, pull_request]

jobs:
sast:
name: Static Analysis
runs-on: ubuntu-latest
steps: - uses: actions/checkout@v3

      # Python SAST
      - name: Bandit Security Scan
        run: bandit -r apps/api -f json -o bandit-report.json

      # TypeScript SAST
      - name: ESLint Security
        run: pnpm lint:security

      # Semgrep multi-language
      - name: Semgrep Security Scan
        uses: returntocorp/semgrep-action@v1
        with:
          config: p/owasp-top-ten

sca:
name: Dependency Scan
runs-on: ubuntu-latest
steps: # Python dependencies - name: pip-audit
run: pip-audit --desc

      # Node.js dependencies
      - name: npm audit
        run: pnpm audit --audit-level=moderate

secrets:
name: Secret Detection
runs-on: ubuntu-latest
steps: - name: Gitleaks
uses: gitleaks/gitleaks-action@v2

container:
name: Container Security
runs-on: ubuntu-latest
steps: - name: Trivy Scan
uses: aquasecurity/trivy-action@master
with:
image-ref: ${{ env.IMAGE_NAME }}
severity: CRITICAL,HIGH
exit-code: 1

iac:
name: Infrastructure Scan
runs-on: ubuntu-latest
steps: - name: Checkov
uses: bridgecrewio/checkov-action@master
with:
directory: infra/
framework: terraform
\`\`\`

#### Penetration Testing Schedule

- **Monthly**: Automated DAST with OWASP ZAP
- **Quarterly**: Internal penetration testing
- **Annually**: External penetration testing (certified)

---

## 🛡️ Incident Response Plan

### Security Incident Severity Levels

| Level  | Description                       | Response Time | Examples                        |
| ------ | --------------------------------- | ------------- | ------------------------------- |
| **P0** | Critical - Active data breach     | <15 min       | PHI exposure, ransomware        |
| **P1** | High - Security vulnerability     | <1 hour       | SQL injection, XSS              |
| **P2** | Medium - Potential security issue | <4 hours      | Misconfiguration, outdated libs |
| **P3** | Low - Security improvement needed | <1 day        | Missing headers, weak passwords |

### Incident Response Process (NIST SP 800-61)

**1. Preparation**

- [ ] Incident response team defined
- [ ] Runbooks created for common scenarios
- [ ] Tools and access pre-configured
- [ ] Communication channels established

**2. Detection and Analysis**
\`\`\`python

# Automated detection via Cloud Monitoring

# Alert triggers incident creation in incident management system

# Security analyst triages and categorizes

# Example: Brute force detection

SELECT COUNT(\*) as failed_attempts, user_id, ip_address
FROM auth_logs
WHERE event_type = 'login_failed'
AND timestamp > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 5 MINUTE)
GROUP BY user_id, ip_address
HAVING failed_attempts > 10
\`\`\`

**3. Containment, Eradication, and Recovery**

- **Short-term containment**: Disable compromised accounts, block IPs
- **Long-term containment**: Deploy patches, update firewall rules
- **Eradication**: Remove malware, close vulnerabilities
- **Recovery**: Restore from clean backups, verify integrity

**4. Post-Incident Activity**

- Post-mortem report
- Root cause analysis
- Update security controls
- Train team on lessons learned

---

## 📊 Key Performance Indicators (KPIs)

### Security Metrics

- **Vulnerability Remediation Time**:
  - Critical: <24 hours
  - High: <7 days
  - Medium: <30 days
- **Security Scan Coverage**: 100% of code and infrastructure
- **False Positive Rate**: <10%
- **Security Training Completion**: 100% of team

### Compliance Metrics

- **OWASP Top 10 Coverage**: 100%
- **ISO 27001 Controls Implemented**: >90%
- **Security Audit Findings**: 0 critical, <5 high
- **Penetration Test Pass Rate**: >95%

---

## 🛠️ Tools & Technologies

### Security Testing

1. **Bandit**: Python SAST
2. **Semgrep**: Multi-language SAST
3. **Trivy**: Container vulnerability scanning
4. **OWASP ZAP**: Web application DAST
5. **Nuclei**: Automated vulnerability scanner
6. **Checkov**: Infrastructure as code security

### Monitoring & Detection

1. **Cloud Monitoring**: GCP-native monitoring
2. **Cloud Logging**: Centralized log management
3. **Wazuh** (optional): Host-based intrusion detection
4. **Falco** (optional): Container runtime security

### Secrets Management

1. **GCP Secret Manager**: Production secrets
2. **git-secrets**: Prevent secret commits
3. **Gitleaks**: Secret detection in git history

---

## 📚 Knowledge Base

### Essential Standards

1. [OWASP Top 10 (2021)](https://owasp.org/Top10/)
2. [ISO 27001:2013](https://www.iso.org/standard/54534.html)
3. [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
4. [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/)
5. [CWE Top 25](https://cwe.mitre.org/top25/)

### Project-Specific

- [Security Best Practices](../docs/security/best-practices.md) _(to be created)_
- [Incident Response Runbook](../docs/security/incident-response.md) _(to be created)_
- [Security Architecture](../docs/architecture/security-architecture.md) _(to be created)_

---

## ✅ Success Criteria

### Phase 1: Foundation (Week 1)

- [ ] All OWASP Top 10 vulnerabilities addressed
- [ ] Security headers implemented
- [ ] Automated security scans in CI/CD
- [ ] Incident response plan documented

### Phase 2: Hardening (Week 2)

- [ ] ISO 27001 controls >80% implemented
- [ ] Vulnerability SLAs met for 30 days
- [ ] Security training completed by team
- [ ] Penetration test findings remediated

### Phase 3: Continuous Improvement (Ongoing)

- [ ] Zero high/critical vulnerabilities in production
- [ ] Monthly security reviews conducted
- [ ] Security metrics tracked and improving
- [ ] Annual external audit passed

---

**Version History:**

- v1.0.0 (2025-10-05): Initial agent specification

**Agent Status:** ✅ Active | Ready for Deployment
