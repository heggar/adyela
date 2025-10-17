# 🎯 Token Optimization Strategy for Claude Code

**Project:** Adyela Medical Appointments Platform **Date:** October 5, 2025
**Version:** 1.0.0

---

## 🎯 Purpose

Optimize the use of Claude's context window (200K tokens) to maximize
productivity, reduce costs, and enable more comprehensive code analysis and
generation for the Adyela project.

**Context Window:** 200,000 tokens (~150,000 words or ~600 pages)

---

## 📊 Current Token Usage Analysis

### Typical Session Breakdown

\`\`\` Component | Tokens | Percentage
-----------------------------|-----------|------------ System Prompt | ~3,000 |
1.5% Conversation History | ~40,000 | 20% File Reads (Code) | ~50,000 | 25%
Agent Responses | ~20,000 | 10% Documentation/Reports | ~30,000 | 15% Available
Buffer | ~57,000 | 28.5% -----------------------------|-----------|------------
Total | 200,000 | 100% \`\`\`

### Token Costs per File Type (Approximate)

\`\`\` File Type | Avg Size | Tokens/File | Files in Project
------------------|----------|-------------|------------------ Python (.py) |
200 LOC | ~800 | ~50 TypeScript (.ts) | 150 LOC | ~600 | ~80 Config (.json) | 50
lines | ~250 | ~20 Markdown (.md) | 100 lines| ~400 | ~30 \`\`\`

---

## 🎯 Optimization Strategies

### Strategy 1: Selective File Reading

#### Use Glob/Grep Before Read

**Before:** \`\`\` Read entire file → Extract relevant section Cost: 800 tokens
(full file) \`\`\`

**After:** \`\`\` Grep for specific function → Read with offset/limit Cost: 200
tokens (relevant section only) Savings: 75% \`\`\`

**Implementation:** \`\`\`bash

# Instead of reading entire file

Read("/path/to/large/file.py")

# Use targeted search

Grep("def create_appointment", path="apps/api/adyela_api/") → Get exact location
→ Read(file_path, offset=line_number, limit=50) \`\`\`

---

### Strategy 2: Context-Aware File Reading

#### Read Only What's Needed

**Principle:** Don't read files you won't modify or reference

**Decision Matrix:** \`\`\` Task Type | Files to Read | Skip
--------------------|--------------------------------|------------------ Bug Fix
| Affected file + tests | Unrelated modules New Feature | Related components
only | Framework code Refactoring | Target files + dependents | Independent code
Documentation | Docs folder only | Source code Architecture Review | Config
files, main entry points| Implementation details \`\`\`

**Example:** \`\`\` Task: "Fix login validation bug"

Read (required): ✅ apps/web/src/features/auth/components/LoginPage.tsx ✅
apps/web/src/features/auth/hooks/useAuth.ts ✅ tests/e2e/auth.spec.ts

Skip (unnecessary): ❌ apps/api/ (backend not involved) ❌
apps/web/src/features/appointments/ (different feature) ❌ docs/ (not
code-related) \`\`\`

---

### Strategy 3: Incremental Context Building

#### Progressive Disclosure Pattern

**Start Small → Expand as Needed**

\`\`\`mermaid graph TD A[Task Request] --> B[Read Config/Overview] B --> C{Need
More Context?} C -->|Yes| D[Read Specific Files] C -->|No| E[Proceed with Task]
D --> F{Still Need More?} F -->|Yes| G[Read Related Files] F -->|No| E G --> E
\`\`\`

**Example:** \`\`\` User: "Add email validation to appointment form"

Step 1 (High-level context):

- Read: apps/web/src/features/appointments/components/AppointmentForm.tsx

Step 2 (If needed - validation logic):

- Read: packages/validation/src/schemas/appointment.ts

Step 3 (If needed - similar patterns):

- Read: apps/web/src/features/auth/components/LoginPage.tsx

Stop when you have enough context to complete the task. \`\`\`

---

### Strategy 4: Use MCP Servers for Heavy Lifting

#### Delegate to Specialized Agents

**Instead of:** \`\`\` Reading 50 files to find all occurrences of
"createAppointment" Cost: 40,000 tokens \`\`\`

**Use MCP:** \`\`\` Task Agent: "Search for all occurrences of
createAppointment" Agent reads files internally, returns summary Cost: 500
tokens (result only) Savings: 98.75% \`\`\`

**When to Use Agents:**

- Searching across many files
- Complex analysis (security, performance)
- Repetitive operations
- Background tasks

---

### Strategy 5: Structured Information Extraction

#### Extract Before Processing

**Technique:** Read file → Extract key info → Discard rest

\`\`\`python

# Instead of keeping full file in context

Read("apps/api/adyela_api/domain/entities/appointment.py") # 800 tokens

# Extract only signatures and types

class Appointment: - id: str - tenant_id: TenantId - patient_id: str - Methods:
confirm(), cancel(), complete()

# Now only 100 tokens in context

# Read full implementation only when needed

\`\`\`

**Application:**

- API endpoints → Extract routes and schemas
- Classes → Extract method signatures
- Config files → Extract relevant sections

---

### Strategy 6: Caching & Reuse

#### Leverage Claude's Context Caching

**How it works:** Claude caches repeated content within a conversation

**Best Practices:** \`\`\`

1. Read foundational files early in conversation
   - package.json, tsconfig.json, pyproject.toml
   - These are unlikely to change

2. Reference by name instead of re-reading "According to package.json we read
   earlier..." Instead of: Read("package.json") again

3. Keep stable context at beginning of conversation
   - Project structure overview
   - Architecture documentation \`\`\`

---

### Strategy 7: Smart Summarization

#### Progressive Summarization Pattern

**Long conversation → Summarize → Continue**

\`\`\` Tokens Used: 150,000 / 200,000 (75%)

Action: Request conversation summary "Summarize the key decisions and changes we
made"

Claude provides 2,000 token summary

Reset with summary as context Tokens Used: 2,000 / 200,000 (1%) Continue working
with 198,000 tokens available \`\`\`

**When to Summarize:**

- At 70% token usage
- Before switching major tasks
- End of work session (save state)

---

### Strategy 8: Documentation-Driven Development

#### Use Docs Instead of Code Exploration

**Scenario:** Understanding authentication flow

**Inefficient:** \`\`\` Read:
apps/api/adyela_api/infrastructure/services/auth/firebase_auth.py Read:
apps/web/src/features/auth/hooks/useAuth.ts Read:
apps/web/src/features/auth/services/authService.ts Read:
apps/api/adyela_api/presentation/middleware/auth_middleware.py

Total: ~3,000 tokens \`\`\`

**Efficient:** \`\`\` Read: docs/architecture/authentication-flow.md (if exists)
Or Request: "Explain authentication flow" (use existing knowledge)

Total: ~500 tokens Savings: 83% \`\`\`

**Recommendation:** Create architecture docs for complex flows

---

### Strategy 9: Diff-Based Editing

#### Show Changes, Not Entire Files

**Inefficient:** \`\`\` Read: file.py (800 tokens) Modify: 5 lines Write:
file.py (800 tokens)

Total: 1,600 tokens \`\`\`

**Efficient:** \`\`\` Read: file.py:45-60 (120 tokens) Edit: Use Edit tool with
old_string/new_string Write: Only changed lines

Total: 250 tokens Savings: 84% \`\`\`

**Implementation:** Use Grep to find exact location, then Read with offset/limit

---

### Strategy 10: Batch Operations

#### Group Similar Tasks

**Inefficient:** \`\`\` Task 1: Add data-testid to Button component Task 2: Add
data-testid to Input component Task 3: Add data-testid to Card component

Each requires reading component file separately Total: 3 × 600 = 1,800 tokens
\`\`\`

**Efficient:** \`\`\` Single Task: Add data-testid to all UI components Read all
components together or use Glob pattern Process in single pass

Total: ~1,000 tokens Savings: 44% \`\`\`

---

## 🛠️ Implementation Patterns

### Pattern 1: Task Agent for Large-Scale Analysis

\`\`\` User Request: "Analyze security vulnerabilities across the codebase"

Inefficient Approach:

- Read all files one by one
- Analyze each file
- Synthesize findings Token Cost: 80,000+

Efficient Approach:

- Launch SecurityAgent with task
- Agent reads files internally
- Returns consolidated report Token Cost: 2,000 \`\`\`

### Pattern 2: Progressive File Discovery

\`\`\`python

# Start with structure

Bash("tree -L 2 apps/api") # 200 tokens

# Find relevant files

Glob("\*_/appointment_.py") # 50 tokens

# Read specific file

Read("apps/api/.../firestore_appointment_repository.py") # 800 tokens

# Total: 1,050 tokens

# vs Reading everything: 10,000+ tokens

\`\`\`

### Pattern 3: Context Window Monitoring

\`\`\`

# Monitor token usage

if (tokens_used > 140,000): # 70% threshold request_summary() save_progress()
start_new_session() \`\`\`

---

## 📏 Token Budgets by Task Type

### Quick Fix (< 5,000 tokens)

\`\`\`

- Read: 1-2 files (max 2,000 tokens)
- Edit: Targeted changes
- Verify: Quick test \`\`\`

### Feature Addition (10,000-20,000 tokens)

\`\`\`

- Read: 5-10 related files
- Create: New components
- Tests: Read test files
- Documentation: Update docs \`\`\`

### Refactoring (20,000-40,000 tokens)

\`\`\`

- Read: Multiple related files
- Analyze: Dependencies
- Modify: Several files
- Tests: Update test suite \`\`\`

### Architecture Review (40,000-80,000 tokens)

\`\`\`

- Read: Config files, main entry points
- Use: Task agents for detailed analysis
- Generate: Comprehensive reports
- Document: Create diagrams and ADRs \`\`\`

---

## 🎯 Best Practices Summary

### DO ✅

1. **Use Grep/Glob before Read** - Find exact location first
2. **Read with offset/limit** - Only read relevant sections
3. **Leverage Task Agents** - For large-scale analysis
4. **Cache frequently accessed info** - Reference without re-reading
5. **Summarize long conversations** - Reset context when needed
6. **Batch similar operations** - Reduce redundant reads
7. **Use documentation** - When available, prefer docs over code exploration
8. **Monitor token usage** - Request summary at 70% capacity

### DON'T ❌

1. **Don't read entire files** - When you only need a section
2. **Don't re-read unchanged files** - Reference previously read content
3. **Don't explore blindly** - Use targeted search first
4. **Don't keep unused context** - Summarize and discard
5. **Don't read generated files** - node_modules, build artifacts
6. **Don't analyze without purpose** - Read only what's needed for the task

---

## 📊 Example Token Savings

### Scenario: Add Validation to Form

**Inefficient Approach:** \`\`\`

1. Read entire form component (800)
2. Read form library docs (1,500)
3. Read validation library docs (1,200)
4. Read similar components for reference (2,400)
5. Implement changes
6. Read test file (600)

Total: 6,500 tokens \`\`\`

**Optimized Approach:** \`\`\`

1. Grep for validation patterns (50)
2. Read form component (validation section only) (200)
3. Check existing validation in codebase (100)
4. Implement changes using known patterns
5. Read relevant test section (150)

Total: 500 tokens Savings: 92% \`\`\`

---

## 🔧 Tools for Token Optimization

### Built-in Tools

1. **Grep**: Find before reading (saves 80-90%)
2. **Glob**: Pattern matching (saves 70-80%)
3. **Read with offset/limit**: Targeted reading (saves 60-80%)
4. **Task Agent**: Delegate heavy tasks (saves 90-95%)
5. **Edit**: Precise modifications (saves 80%)

### MCP Servers

1. **Filesystem MCP**: Advanced file operations
2. **Sequential Thinking MCP**: Break down complex problems
3. **GitHub MCP**: Repository-level operations

---

## 📋 Token Optimization Checklist

### Before Starting Task

- [ ] Understand exact scope
- [ ] Identify minimum files needed
- [ ] Check if similar task was done recently
- [ ] Plan file reading order (foundational → specific)

### During Task

- [ ] Use Grep/Glob before Read
- [ ] Read with offset/limit when possible
- [ ] Keep running mental token budget
- [ ] Summarize at 70% usage

### After Task

- [ ] Review what was read vs. what was needed
- [ ] Identify unnecessary reads
- [ ] Document patterns for future reference

---

## 🎓 Advanced Techniques

### Technique 1: Lazy Loading Pattern

\`\`\`

# Read interface/type definitions first

# Only read implementations when needed

\`\`\`

### Technique 2: Reference Architecture

\`\`\`

# Maintain architecture doc with file purposes

# Reduces need to read files to understand structure

\`\`\`

### Technique 3: Smart Defaults

\`\`\`

# For common patterns, use knowledge from training

# Only verify with code when dealing with custom logic

\`\`\`

---

## 📈 Expected Outcomes

### Token Efficiency Gains

- **Individual Tasks**: 60-90% reduction in tokens per task
- **Complex Projects**: 40-70% reduction in total session tokens
- **Analysis Tasks**: 80-95% reduction using Task Agents

### Productivity Improvements

- **More tasks per session**: 3-5x increase
- **Faster context switches**: Less re-reading
- **Better long-term context**: Effective summarization

---

## 🔗 Related Documents

- [Project Structure Analysis](./PROJECT_STRUCTURE_ANALYSIS.md)
- [MCP Integration Matrix](./MCP_INTEGRATION_MATRIX.md)
- [Cloud Architecture Agent](./.claude/agents/cloud-architect-agent.md)
- [QA Automation Agent](./.claude/agents/qa-automation-agent.md)

---

**Version History:**

- v1.0.0 (2025-10-05): Initial token optimization strategy

**Status:** ✅ Ready for Implementation
