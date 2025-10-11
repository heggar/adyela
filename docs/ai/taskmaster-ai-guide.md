# 🎯 Taskmaster AI Integration Guide

**Project:** Adyela Medical Appointments Platform
**MCP Server:** Taskmaster AI
**Version:** 1.0.0
**Date:** 2025-10-05

---

## 🌟 Overview

Taskmaster AI is an intelligent project and task management MCP server that helps track, organize, and manage development tasks within the Adyela project. It integrates seamlessly with Claude Code and the specialized SDLC agents.

### Key Capabilities

- ✅ **Task Creation & Management** - Create, update, and track tasks
- 📊 **Project Organization** - Organize tasks by projects, milestones, and sprints
- 🤖 **AI-Powered Insights** - Get intelligent task prioritization and suggestions
- 🔗 **Integration with Git** - Link tasks to commits, branches, and PRs
- 📈 **Progress Tracking** - Visual progress tracking and reporting
- 🎯 **Sprint Planning** - Plan and manage agile sprints

---

## 📦 Installation

### Automatic Setup (Recommended)

```bash
# Run the MCP setup script
bash scripts/setup-mcp-servers.sh

# This will:
# 1. Install Taskmaster AI MCP server
# 2. Configure Claude Desktop/Code
# 3. Create .taskmaster data directory
# 4. Set up initial configuration
```

### Manual Setup

If you prefer manual setup:

1. **Install Taskmaster AI:**

   ```bash
   npm install -g @taskmaster/mcp-server
   ```

2. **Configure Claude Desktop:**
   Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:

   ```json
   {
     "mcpServers": {
       "taskmaster": {
         "command": "npx",
         "args": ["-y", "@taskmaster/mcp-server"],
         "env": {
           "TASKMASTER_DATA_DIR": "/path/to/adyela/.taskmaster"
         }
       }
     }
   }
   ```

3. **Restart Claude Desktop/Code**

---

## 🚀 Quick Start

### Create Your First Task

```
"Create a task: Implement Terraform modules for Cloud Run"
```

Taskmaster AI will:

- Create the task with intelligent categorization
- Suggest priority based on project context
- Link to relevant documentation
- Assign to appropriate sprint/milestone

### View All Tasks

```
"Show me all tasks in the current sprint"
"List all high-priority tasks"
"What tasks are assigned to Cloud Architecture Agent?"
```

### Update Task Status

```
"Mark 'Implement Terraform modules' as in progress"
"Complete task: Add security headers"
"Block task: Deploy to staging (waiting for budget approval)"
```

---

## 📋 Task Management Workflows

### 1. Sprint Planning Workflow

#### Create Sprint

```
"Create a new sprint: Infrastructure Foundation - Week 1"
```

#### Add Tasks to Sprint

```
"Add these tasks to current sprint:
1. Create Terraform module structure
2. Implement cloud-run module
3. Implement storage module
4. Setup remote state backend
5. Configure dev, staging, production environments"
```

#### Set Sprint Goals

```
"Set sprint goal: Complete infrastructure as code foundation with 100% Terraform coverage"
```

---

### 2. Feature Development Workflow

#### Plan Feature

```
"Plan feature: Prescription Management
- Create domain entities
- Implement repository
- Add API endpoints
- Create UI components
- Write tests"
```

Taskmaster AI will:

- Break down into subtasks
- Estimate complexity
- Suggest dependencies
- Assign to agents

#### Track Progress

```
"Show progress on Prescription Management feature"
"What's blocking this feature?"
"When can we ship this?"
```

---

### 3. Bug Tracking Workflow

#### Report Bug

```
"Create bug: Login validation error on invalid email
Priority: High
Affected: Frontend authentication
Steps to reproduce: Enter invalid email format, submit form"
```

#### Link to Issue

```
"Link task 'Fix login validation' to GitHub issue #123"
```

#### Track Resolution

```
"Update bug status: Fixed in PR #125"
"Mark as ready for QA testing"
```

---

### 4. Compliance & Audit Workflow

#### Create Compliance Tasks

```
"Create compliance checklist for HIPAA Security Rule:
- Implement access controls
- Setup audit logging
- Add encryption at rest
- Configure security headers
- Test incident response"
```

#### Track Compliance Progress

```
"Show HIPAA compliance status"
"What compliance tasks are overdue?"
"Generate compliance report for audit"
```

---

## 🤖 Integration with SDLC Agents

### Cloud Architecture Agent + Taskmaster

```
# Create infrastructure tasks
"Cloud Architecture Agent: Create tasks for Terraform implementation"

Taskmaster AI creates:
- [ ] Design Terraform module structure
- [ ] Implement cloud-run module
- [ ] Implement storage module
- [ ] Implement networking module
- [ ] Setup state backend
- [ ] Configure environments
- [ ] Document Terraform usage
```

### Cybersecurity Agent + Taskmaster

```
# Security audit tasks
"Cybersecurity Agent: Generate security audit tasks"

Taskmaster AI creates:
- [ ] Run SAST scans (Semgrep, Bandit)
- [ ] Run DAST scans (OWASP ZAP)
- [ ] Update dependencies
- [ ] Fix critical vulnerabilities
- [ ] Review OWASP Top 10 compliance
- [ ] Generate security report
```

### QA Automation Agent + Taskmaster

```
# Testing tasks
"QA Agent: Create test expansion tasks"

Taskmaster AI creates:
- [ ] Write unit tests (target: 80% coverage)
- [ ] Create E2E tests for appointments
- [ ] Setup visual regression testing
- [ ] Configure performance budgets
- [ ] Add accessibility tests
- [ ] Document test strategy
```

### Healthcare Compliance Agent + Taskmaster

```
# Compliance tasks
"Compliance Agent: Create HIPAA implementation tasks"

Taskmaster AI creates:
- [ ] Implement PHI access logging
- [ ] Add patient rights endpoints
- [ ] Create audit trail system
- [ ] Setup breach notification
- [ ] Document compliance procedures
- [ ] Prepare for external audit
```

---

## 📊 Project Organization

### Project Hierarchy

```
Adyela Project
├── Infrastructure (Cloud Architecture)
│   ├── Terraform Modules
│   ├── GCP Resources
│   └── Monitoring & Alerts
├── Security (Cybersecurity)
│   ├── OWASP Compliance
│   ├── Vulnerability Management
│   └── Incident Response
├── Quality (QA Automation)
│   ├── Test Coverage
│   ├── E2E Testing
│   └── Performance Testing
├── Compliance (Healthcare)
│   ├── HIPAA Implementation
│   ├── GDPR Compliance
│   └── Audit Preparation
└── Features
    ├── Appointments
    ├── Prescriptions
    └── Video Consultations
```

### Labels & Tags

Taskmaster AI automatically applies intelligent labels:

- **Priority**: `P0-Critical`, `P1-High`, `P2-Medium`, `P3-Low`
- **Type**: `feature`, `bug`, `security`, `compliance`, `infrastructure`
- **Status**: `todo`, `in-progress`, `blocked`, `review`, `done`
- **Agent**: `cloud`, `security`, `qa`, `compliance`
- **Complexity**: `XS`, `S`, `M`, `L`, `XL`

---

## 🎯 Smart Task Features

### AI-Powered Prioritization

```
"Prioritize my tasks based on:
- Production blockers
- Security vulnerabilities
- HIPAA compliance requirements
- Team dependencies"
```

Taskmaster AI analyzes:

- Business impact
- Technical dependencies
- Risk assessment
- Resource availability

### Intelligent Suggestions

```
"What should I work on next?"
```

Taskmaster AI suggests based on:

- Current sprint goals
- Your expertise (agent role)
- Blocking dependencies
- Critical path analysis

### Dependency Management

```
"Show dependencies for 'Deploy to staging' task"
```

Taskmaster AI maps:

- Technical dependencies (Terraform before deploy)
- Resource dependencies (needs approval)
- Team dependencies (waiting for review)

---

## 📈 Reporting & Analytics

### Sprint Reports

```
"Generate sprint report"
```

Includes:

- ✅ Completed: 12/15 tasks (80%)
- 🚧 In Progress: 2 tasks
- ⏸️ Blocked: 1 task
- 📊 Velocity: 45 story points
- 🎯 Sprint goal: 90% complete

### Burndown Charts

```
"Show burndown chart for current sprint"
```

Visualizes:

- Remaining work over time
- Projected completion date
- Velocity trends

### Agent Performance

```
"Show task completion by agent"
```

Breakdown:

- Cloud Architecture Agent: 8 tasks (95% on time)
- Cybersecurity Agent: 6 tasks (100% on time)
- QA Automation Agent: 10 tasks (90% on time)
- Healthcare Compliance Agent: 5 tasks (80% on time)

---

## 🔗 Git Integration

### Link Tasks to Commits

```
# In commit message
git commit -m "feat: implement Terraform modules

Taskmaster: #TASK-123"
```

Taskmaster AI automatically:

- Updates task status
- Links commit to task
- Tracks code changes

### Link Tasks to PRs

```
# In PR description
Implements Taskmaster tasks: #TASK-123, #TASK-124
```

Benefits:

- Automatic task updates on PR merge
- Traceability from requirement to code
- Audit trail for compliance

### Branch Management

```
"Create branch for task: Implement PHI logging"
```

Taskmaster AI suggests:

- Branch name: `feature/phi-logging-TASK-125`
- Base branch: `main`
- Related tasks to include

---

## 💡 Best Practices

### 1. Task Granularity

**Good:**

```
- [ ] Implement Cloud Run Terraform module (4h)
  - [ ] Define variables
  - [ ] Create main.tf
  - [ ] Add outputs
  - [ ] Write documentation
```

**Too Large:**

```
- [ ] Implement entire infrastructure (3 weeks)
```

**Too Small:**

```
- [ ] Add one line to main.tf (5min)
```

### 2. Clear Acceptance Criteria

```
Task: Implement HIPAA audit logging

Acceptance Criteria:
- [x] Log all PHI access events
- [x] Include user, timestamp, action, resource
- [x] Store in immutable audit log
- [x] Implement 90-day retention
- [x] Create audit query API
- [x] Test with 1000+ events
```

### 3. Link to Documentation

```
Task: Configure Cloud Armor WAF

References:
- Cloud Architecture Agent: .claude/agents/cloud-architect-agent.md
- GCP Setup Guide: docs/deployment/gcp-setup.md
- Security Policy: docs/security/waf-rules.md
```

### 4. Regular Updates

```
# Daily standup
"Update tasks: What did I complete yesterday?"
"What am I working on today?"
"Any blockers?"
```

---

## 🎨 Example Workflows

### Example 1: Weekly Planning

```
# Monday morning
"What are this week's priorities?"

Taskmaster AI responds:
Priority 1 (P0 - Critical):
- [ ] Implement Terraform state backend
- [ ] Fix critical security vulnerability CVE-2024-1234

Priority 2 (P1 - High):
- [ ] Complete HIPAA audit logging
- [ ] Add E2E tests for appointments
- [ ] Deploy to staging environment

Priority 3 (P2 - Medium):
- [ ] Create shared types package
- [ ] Update API documentation
```

### Example 2: Feature Implementation

```
# Start feature
"Create feature: Patient Prescription Management"

Taskmaster AI breaks down:
1. [ ] Design prescription domain model (Cloud Architect)
2. [ ] Implement prescription entity (Backend)
3. [ ] Add prescription repository (Backend)
4. [ ] Create prescription API endpoints (Backend)
5. [ ] Add security validation (Cybersecurity)
6. [ ] Implement prescription UI (Frontend)
7. [ ] Add E2E tests (QA Automation)
8. [ ] Verify HIPAA compliance (Compliance)
9. [ ] Document feature (All)

# Track progress
"Show prescription feature progress"
✅ Completed: 3/9 (33%)
🚧 In Progress: 2
📋 Todo: 4
```

### Example 3: Bug Triage

```
# New bug reported
"Create bug from GitHub issue #456:
Video call disconnecting randomly"

Taskmaster AI:
- Analyzes error logs
- Identifies potential cause: WebRTC timeout
- Assigns to: Video feature team
- Priority: P1 (affects patient care)
- Links to: Video call service code
- Suggests: Check network stability, review timeout configs

# Add to current sprint
"Add to current sprint with priority bump"
```

---

## 📊 Dashboard & Visualizations

### Project Dashboard

```
"Show project dashboard"
```

Displays:

```
📊 Adyela Project Dashboard

Sprint: Infrastructure Foundation (Week 1)
Progress: ████████░░ 80% (12/15 tasks)
Velocity: 45 story points
Burndown: On track ✅

By Priority:
🔴 P0: 1 task (critical - infrastructure)
🟠 P1: 3 tasks (high - security, compliance)
🟡 P2: 5 tasks (medium - features)
🟢 P3: 3 tasks (low - documentation)

By Agent:
☁️  Cloud Architecture: 4 tasks (3 done, 1 in progress)
🔒 Cybersecurity: 3 tasks (2 done, 1 todo)
🧪 QA Automation: 5 tasks (4 done, 1 in progress)
🏥 Compliance: 3 tasks (3 done)

Blockers: 1
- Terraform state backend (waiting for GCP permissions)

Next Up:
1. Complete cloud-run module
2. Fix security headers
3. Add E2E tests for prescriptions
```

---

## 🔍 Advanced Features

### 1. Smart Dependencies

Taskmaster AI automatically detects dependencies:

```
Task: Deploy to production
Dependencies detected:
- [ ] All E2E tests passing
- [ ] Security scan clean
- [ ] HIPAA compliance verified
- [ ] Terraform modules complete
- [ ] Budget alerts configured
```

### 2. Time Tracking

```
"Start timer for task: Implement Terraform modules"
# Work on task...
"Stop timer"

Logged: 3h 45min
Estimate: 4h (on track ✅)
```

### 3. Recurring Tasks

```
"Create recurring task:
Weekly security scan
Every Monday at 9 AM
Assigned to: Cybersecurity Agent"
```

### 4. Task Templates

```
"Create template: New Feature Implementation"

Template includes:
1. Domain model design
2. Repository implementation
3. API endpoints
4. Security review
5. UI components
6. E2E tests
7. HIPAA compliance check
8. Documentation
```

---

## 🚨 Alerts & Notifications

### Configure Alerts

```
"Alert me when:
- Critical (P0) task created
- Task overdue by 24 hours
- Sprint progress < 50% at midpoint
- Blocker identified
- Security vulnerability detected"
```

### Integration with Slack/Email

```
"Send daily task summary to Slack #dev-team"
"Email weekly progress report to stakeholders"
```

---

## 📚 Task Query Language

Taskmaster AI supports powerful queries:

```
# By status
"Show all in-progress tasks"
"List completed tasks this week"

# By priority
"Show all P0 and P1 tasks"
"What are the critical blockers?"

# By agent
"Tasks assigned to Cloud Architecture Agent"
"QA Automation Agent tasks due this week"

# By label/tag
"All security-related tasks"
"HIPAA compliance tasks"

# Complex queries
"Show high-priority infrastructure tasks
 that are blocked or overdue"

"List all tasks completed by Cybersecurity Agent
 in the last sprint"
```

---

## 🎓 Tips & Tricks

### 1. Use Natural Language

```
# Instead of:
"CREATE TASK title='Fix bug' priority=P1 assignee=QA"

# Just say:
"There's a high priority bug in the login form
 that the QA team should fix"
```

### 2. Batch Operations

```
"Mark all security scan tasks as complete"
"Move all P2 tasks to next sprint"
"Assign all infrastructure tasks to Cloud Architecture Agent"
```

### 3. Quick Add

```
"Quick add: Review PR #123"
# Automatically creates task with smart defaults
```

### 4. Task Relationships

```
"Make 'Deploy to staging' dependent on 'E2E tests passing'"
"Link 'Security audit' to 'HIPAA compliance report'"
```

---

## 🔗 Integration with Other Tools

### GitHub Issues

```
"Import GitHub issues from adyela/adyela repository"
"Sync task status with GitHub issue #456"
```

### Jira (if used)

```
"Export tasks to Jira"
"Import Jira tickets with label 'infrastructure'"
```

### Calendar

```
"Add task deadlines to Google Calendar"
"Schedule sprint planning meeting"
```

---

## 📖 Command Reference

### Task Management

- `create task <description>` - Create new task
- `update task <id> <changes>` - Update existing task
- `complete task <id>` - Mark task as complete
- `delete task <id>` - Delete task
- `show task <id>` - Show task details

### Sprint Management

- `create sprint <name>` - Create new sprint
- `add to sprint <task_id>` - Add task to sprint
- `show sprint` - Show current sprint
- `close sprint` - Close and archive sprint

### Reporting

- `show dashboard` - Project dashboard
- `sprint report` - Current sprint report
- `burndown chart` - Sprint burndown
- `velocity report` - Team velocity

### Queries

- `search tasks <query>` - Search tasks
- `filter tasks <criteria>` - Filter tasks
- `group tasks by <field>` - Group tasks

---

## 🆘 Troubleshooting

### Taskmaster AI not responding

```bash
# Check MCP server status
npx @taskmaster/mcp-server --version

# Restart Claude Desktop
# Verify configuration in:
cat ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

### Data not persisting

```bash
# Check data directory
ls -la .taskmaster/

# Verify permissions
chmod -R 755 .taskmaster/
```

### Sync issues

```bash
# Force sync
"Sync all tasks with latest data"

# Reset and reimport
"Reset Taskmaster data and reimport from GitHub"
```

---

## 🔐 Security & Privacy

### Data Storage

- All task data stored locally in `.taskmaster/`
- No cloud sync (unless explicitly configured)
- Encrypted at rest (macOS keychain)

### PHI Considerations

- ⚠️ **Do NOT** include PHI in task descriptions
- ✅ Use patient IDs, not names
- ✅ Generic descriptions: "Fix appointment booking bug"
- ❌ Avoid: "Fix John Doe's appointment issue"

### Access Control

- Task data tied to project directory
- No external sharing without explicit export
- Audit log of all task operations

---

## 📈 Metrics & KPIs

Taskmaster AI tracks:

- **Velocity**: Story points per sprint
- **Cycle Time**: Time from start to completion
- **Lead Time**: Time from creation to completion
- **Throughput**: Tasks completed per week
- **WIP Limit**: Tasks in progress simultaneously
- **Blocked Time**: Time tasks spend blocked
- **Agent Utilization**: Task distribution across agents

---

## 🎯 Success Metrics

### Short-term (1 Month)

- [ ] 100% of development tasks tracked
- [ ] Daily task updates by all agents
- [ ] Sprint completion rate >80%
- [ ] Average task cycle time <3 days

### Long-term (3 Months)

- [ ] Predictable velocity (±10%)
- [ ] Zero lost tasks
- [ ] Complete audit trail
- [ ] Integrated with all workflows

---

## 🔗 Related Documentation

- [MCP Integration Matrix](./MCP_INTEGRATION_MATRIX.md)
- [Project Commands Reference](./PROJECT_COMMANDS_REFERENCE.md)
- [Comprehensive Optimization Plan](./COMPREHENSIVE_OPTIMIZATION_PLAN.md)
- [Cloud Architecture Agent](../.claude/agents/cloud-architect-agent.md)
- [Cybersecurity Agent](../.claude/agents/cybersecurity-agent.md)
- [QA Automation Agent](../.claude/agents/qa-automation-agent.md)
- [Healthcare Compliance Agent](../.claude/agents/healthcare-compliance-agent.md)

---

## 🆕 Getting Started Checklist

- [ ] Run `bash scripts/setup-mcp-servers.sh`
- [ ] Restart Claude Desktop/Code
- [ ] Create first task: "Setup Taskmaster AI"
- [ ] Create current sprint
- [ ] Import existing tasks from GitHub issues
- [ ] Configure alerts and notifications
- [ ] Set up sprint planning template
- [ ] Train team on Taskmaster usage

---

**Version History:**

- v1.0.0 (2025-10-05): Initial Taskmaster AI integration guide

**Status:** ✅ Ready to Use

**Support:** For issues with Taskmaster AI, consult the [official documentation](https://taskmaster.ai/docs) or create a GitHub issue.
