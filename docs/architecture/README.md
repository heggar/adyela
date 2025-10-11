# Adyela Architecture Documentation

## Overview

This directory contains comprehensive architecture documentation for the Adyela health system, including GCP infrastructure diagrams, deployment guides, and technical specifications.

## Files

### 📊 Diagrams

#### `adyela-gcp-architecture.drawio`

**Complete GCP Architecture Diagram with Official Icons**

Visual representation of the entire Google Cloud Platform infrastructure for both staging and production environments using **official GCP icons** (`mxgraph.gcp2` library).

⚠️ **IMPORTANTE**: Este archivo **debe abrirse en Draw.io** para visualizarse correctamente.

**Visualización Rápida (5 segundos)**:

1. Visita [app.diagrams.net](https://app.diagrams.net/)
2. Arrastra el archivo `.drawio` o usa File → Open
3. ¡Listo! Verás el diagrama completo en HD

**📖 Guías de Ayuda**:

- **[Instrucciones de Visualización](./VIEWING_INSTRUCTIONS.md)** - ⭐ **LÉEME PRIMERO** si no puedes ver el diagrama
- **[Guía de Edición del Diagrama](./DIAGRAM_GUIDE.md)** - Para editar y exportar
- **[Guía Técnica Completa](./GCP_ARCHITECTURE_GUIDE.md)** - 50+ páginas de documentación

**What's Included:**

- User access layers (Patients, Doctors, Admins, Ops, Developers)
- DNS & CDN configuration
- **Staging Environment** (yellow):
  - Security & Edge (Cloud Armor, API Gateway, Load Balancer, Identity Platform)
  - Compute (Cloud Run API & Web, Cloud Functions, Cloud Scheduler)
  - Data & Storage (Firestore, Cloud Storage, Secret Manager)
  - Async Processing (Pub/Sub, Cloud Tasks)
  - Observability (Logging, Monitoring, Trace, Error Reporting)
- **Production Environment** (green):
  - Enhanced security (VPC-SC, CMEK encryption)
  - High availability configuration
  - Advanced monitoring & alerting
- **Shared Services**:
  - CI/CD Pipeline (Cloud Build, GitHub Actions)
  - Infrastructure as Code (Terraform)
  - Governance & Cost Management
  - Security Center

**Color Coding:**

- 🟨 **Yellow boxes** = Staging environment components
- 🟩 **Green boxes** = Production environment components
- ⬜ **Gray boxes** = Shared services (both environments)
- 🟥 **Red boxes** = Security components
- 🟦 **Blue boxes** = Compute services
- 🟪 **Purple boxes** = Identity/Auth services

---

### 📖 Guides

#### `GCP_ARCHITECTURE_GUIDE.md`

**Comprehensive Architecture Guide**

50+ page detailed document explaining every component of the GCP architecture.

**Sections:**

1. **Overview** - High-level architecture summary
2. **Architecture Layers** - Detailed layer-by-layer explanation
3. **Staging Environment** - Complete staging setup
4. **Production Environment** - Production configuration with HIPAA compliance
5. **Shared Services** - CI/CD, IaC, Governance
6. **Data Flow Examples** - Sequence diagrams for common operations
7. **Network Architecture** - VPC configuration and networking
8. **Security Controls** - Comprehensive security measures
9. **HIPAA Compliance** - Compliance checklist and controls
10. **Cost Estimates** - Detailed cost breakdown
11. **Deployment Process** - Step-by-step deployment guide
12. **Disaster Recovery** - RTO/RPO and recovery procedures
13. **Monitoring & Alerting** - Metrics, alerts, and SLOs
14. **Future Enhancements** - Roadmap for architecture evolution

**Best For:**

- New team members onboarding
- Architecture reviews
- Compliance audits
- Capacity planning
- Cost optimization
- Security assessments

---

## Quick Start

### For Developers

1. **View the Architecture**:

   ```bash
   # Open diagram in draw.io
   open https://app.diagrams.net/
   # Then: File → Open → adyela-gcp-architecture.drawio
   ```

2. **Read the Guide**:

   ```bash
   # Read the complete guide
   cat docs/architecture/GCP_ARCHITECTURE_GUIDE.md

   # Or open in your editor
   code docs/architecture/GCP_ARCHITECTURE_GUIDE.md
   ```

3. **Understand Data Flow**:
   - See "Data Flow Examples" section in the guide
   - Review sequence diagrams for:
     - Patient books appointment
     - Document upload
     - Scheduled backups

### For DevOps/SRE

1. **Infrastructure Setup**:

   ```bash
   # Navigate to infrastructure directory
   cd infra/

   # Review Terraform modules (per Epic)
   ls modules/
   ```

2. **Deployment**:

   ```bash
   # Staging deployment
   # See: GCP_ARCHITECTURE_GUIDE.md → "Deployment Process"

   # Production deployment (manual)
   # Requires 2 approvals + manual dispatch
   ```

3. **Monitoring**:
   ```bash
   # Access Cloud Console
   # See: GCP_ARCHITECTURE_GUIDE.md → "Monitoring & Alerting"
   ```

### For Security/Compliance

1. **HIPAA Compliance**:
   - Review "HIPAA Compliance Checklist" in guide
   - Verify all controls are implemented
   - Check audit log retention (7 years)

2. **Security Controls**:
   - Review "Security Controls Summary" section
   - Verify VPC-SC is enabled (production)
   - Check CMEK encryption (production)

3. **Audit Logs**:
   ```bash
   # Access audit logs
   gcloud logging read "logName:cloudaudit.googleapis.com" \
     --project=adyela-production \
     --format=json
   ```

---

## Architecture Highlights

### Key Features

#### Multi-Environment Strategy

- **Staging**: Cost-optimized ($5-10/month)
  - Scale to zero (min-instances: 0)
  - Minimal resources
  - Perfect for testing
- **Production**: High-availability ($200-500/month)
  - Always-on (min-instances: 1-2)
  - Auto-scaling (max-instances: 10)
  - HIPAA compliant

#### Security Layers

1. **Edge Security**
   - Cloud Armor (WAF)
   - DDoS protection
   - TLS 1.3 everywhere

2. **Application Security**
   - JWT authentication
   - MFA (required in production)
   - Rate limiting per endpoint

3. **Data Security**
   - Encryption at rest (CMEK in production)
   - Encryption in transit (TLS 1.3)
   - VPC Service Controls (production)
   - 7-year audit logs (HIPAA)

4. **Network Security**
   - Private VPC
   - No public IPs
   - Private Google Access
   - Serverless VPC Access

#### High Availability

- **Multi-Region Load Balancing**: Global HTTPS LB
- **Auto-Scaling**: Cloud Run automatic scaling
- **Database**: Firestore (multi-region replication)
- **Backups**: Daily automated backups (35-day retention)
- **RTO**: < 4 hours
- **RPO**: < 1 hour

#### Cost Optimization

- **Staging**: Scale to zero when not used
- **Production**: Committed use discounts
- **Storage**: Lifecycle policies
- **Networking**: Cloud CDN for static assets
- **Monitoring**: Smart retention policies

---

## Component Overview

### Compute Services

| Service             | Purpose                | Staging       | Production          |
| ------------------- | ---------------------- | ------------- | ------------------- |
| **Cloud Run API**   | FastAPI backend        | 0-1 instances | 1-10 instances      |
| **Cloud Run Web**   | React PWA frontend     | 0-2 instances | 2-10 instances      |
| **Cloud Functions** | Event-driven functions | Gen2          | Gen2                |
| **Cloud Scheduler** | Cron jobs              | Basic         | + Backup automation |

### Data Services

| Service            | Purpose             | Staging     | Production      |
| ------------------ | ------------------- | ----------- | --------------- |
| **Firestore**      | Primary database    | Native mode | Native + CMEK   |
| **Cloud Storage**  | Documents & backups | Standard    | Standard + CMEK |
| **Secret Manager** | Credentials & keys  | Standard    | + Key rotation  |

### Security Services

| Service               | Purpose         | Staging     | Production       |
| --------------------- | --------------- | ----------- | ---------------- |
| **Cloud Armor**       | WAF             | OWASP rules | + Advanced rules |
| **Identity Platform** | Auth + JWT      | Basic       | + MFA required   |
| **VPC-SC**            | Data perimeter  | No          | Yes              |
| **CMEK**              | Encryption keys | No          | Yes              |

### Observability Services

| Service              | Purpose              | Staging          | Production       |
| -------------------- | -------------------- | ---------------- | ---------------- |
| **Cloud Logging**    | Log management       | 30-day retention | 7-year retention |
| **Cloud Monitoring** | Metrics & dashboards | Basic            | + SLO/SLI        |
| **Cloud Trace**      | Distributed tracing  | Enabled          | Enabled          |
| **Error Reporting**  | Error aggregation    | Email alerts     | PagerDuty        |

---

## Integration with Other Docs

### Related Documentation

- **[PRD](../.taskmaster/docs/health-system-prd.txt)** - Product requirements
- **[GitHub Audit Report](../GITHUB_AUDIT_REPORT.md)** - CI/CD audit
- **[Workflow Guide](../guides/feature-workflow.md)** - Development workflow
- **[Deployment Guide](../../DEPLOYMENT_SUCCESS.md)** - Deployment procedures
- **[Security Policy](../../SECURITY.md)** - Security practices

### Epic-Based Infrastructure

Architecture aligns with PRD Epics:

- **EP-NET**: Network & VPC configuration
- **EP-IDP**: Identity Platform setup
- **EP-API**: API Gateway configuration
- **EP-DATA**: Firestore & Storage
- **EP-SEC**: Security controls
- **EP-RUN**: Cloud Run services
- **EP-ASYNC**: Pub/Sub & Cloud Tasks
- **EP-OBS**: Monitoring & logging
- **EP-IAC**: Terraform modules
- **EP-COST**: Cost management

---

## Maintenance

### Updating the Diagram

1. Open `adyela-gcp-architecture.drawio` in draw.io
2. Make changes to reflect infrastructure updates
3. Save the file
4. Update `GCP_ARCHITECTURE_GUIDE.md` if needed
5. Update version number in both files

### Document Review Schedule

- **Monthly**: Cost estimates review
- **Quarterly**: Architecture review
- **Semi-Annually**: Security audit
- **Annually**: HIPAA compliance review

### Change Process

1. Propose architecture changes via ADR (Architecture Decision Record)
2. Review with team
3. Update diagrams and documentation
4. Implement in staging first
5. Test thoroughly
6. Deploy to production
7. Update documentation

---

## Support

### Questions?

- **Architecture Questions**: Review this guide first
- **Infrastructure Issues**: Check Cloud Console logs
- **Security Concerns**: Contact security team
- **Cost Questions**: Review cost dashboard

### Contributing

To improve this documentation:

1. Create feature branch
2. Update diagrams/guides
3. Test changes
4. Submit PR with description
5. Request review from DevOps team

---

## Version History

| Version | Date       | Changes                            | Author      |
| ------- | ---------- | ---------------------------------- | ----------- |
| 1.0.0   | 2025-10-11 | Initial architecture documentation | DevOps Team |

---

**Last Updated**: October 11, 2025  
**Next Review**: January 11, 2026  
**Maintained By**: Adyela DevOps Team
