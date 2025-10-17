# Branch Naming Guide

## Overview

Adyela uses descriptive, human-readable branch names derived from Task Master
task titles. This approach makes Git history more meaningful and easier to
understand.

## Branch Naming Convention

### Format

```
feature/<descriptive-name>
```

### How It Works

When you run `make task-start ID=5`, the script:

1. Fetches the task title from Task Master
2. Converts it to lowercase
3. Replaces spaces and special characters with hyphens
4. Creates a clean, URL-safe branch name

### Examples

| Task ID | Task Title                    | Branch Name                             |
| ------- | ----------------------------- | --------------------------------------- |
| 5       | Implement User Authentication | `feature/implement-user-authentication` |
| 12      | Add Email Notification System | `feature/add-email-notification-system` |
| 23      | Fix Memory Leak in API        | `feature/fix-memory-leak-in-api`        |
| 47      | Optimize Database Queries     | `feature/optimize-database-queries`     |
| 88      | Configure CI/CD Pipeline      | `feature/configure-ci-cd-pipeline`      |

## Benefits

### ✅ Readability

```bash
# ❌ Old approach - cryptic
feature/task-5-impl-user-auth

# ✅ New approach - clear
feature/implement-user-authentication
```

### ✅ Meaningful Git History

```bash
git log --oneline --graph
* 8a3f2d1 Merge 'feature/implement-user-authentication' into staging
* 6b2c9e4 Merge 'feature/add-email-notification-system' into staging
* 4d1a7f8 Merge 'feature/optimize-database-queries' into staging
```

### ✅ Better Pull Requests

GitHub PR titles automatically use the branch name, making them instantly
understandable.

### ✅ Task Traceability

Despite using descriptive names, full traceability is maintained:

- Task context stored in `.task-context/task-<id>/`
- Task ID automatically appended to commits via hook
- PR template requires Task #X reference

## Task ID Linking

### How Commits Get Task References

The `commit-msg` hook automatically links commits to tasks:

```bash
# You commit:
git commit -m "feat(api): add JWT token validation"

# Hook automatically adds:
feat(api): add JWT token validation

Task #5
```

### How It Works

1. **Primary Method**: Checks `.task-context/` directory for active task
2. **Fallback**: Extracts from branch name if it contains `task-<number>`

## Workflow Example

### Starting a Feature

```bash
# 1. Start task
make task-start ID=5
# ✓ Feature branch created: feature/implement-user-authentication
# ✓ Task #5 status: in-progress
# ✓ Task context: .task-context/task-5/

# 2. Verify branch
git branch
# * feature/implement-user-authentication
#   main
```

### During Development

```bash
# Commit as usual
git add src/auth/jwt.ts
git commit -m "feat(auth): implement JWT token generation"

# Hook automatically appends "Task #5"
# View the commit:
git log -1
# feat(auth): implement JWT token generation
#
# Task #5
```

### Completing Feature

```bash
# Push with descriptive name
git push origin feature/implement-user-authentication

# Create PR - title auto-fills from branch:
# "Implement user authentication"
```

## Comparison: Before vs After

### Before (Task Number Prefix)

```bash
feature/task-5-user-auth
feature/task-12-email-notif
feature/task-23-fix-leak
feature/task-47-opt-queries
```

**Problems**:

- Not immediately clear what each feature does
- Requires looking up task numbers
- Git history less readable

### After (Descriptive Names)

```bash
feature/implement-user-authentication
feature/add-email-notification-system
feature/fix-memory-leak-in-api
feature/optimize-database-queries
```

**Benefits**:

- Instantly understand purpose
- Self-documenting Git history
- Better team communication

## Special Cases

### Very Long Task Titles

If a task title is extremely long, the script handles it gracefully:

**Original**: "Implement comprehensive user authentication system with OAuth2,
JWT, and multi-factor authentication support"

**Branch**:
`feature/implement-comprehensive-user-authentication-system-with-oauth2-jwt-and-multi-factor-authentication-support`

**Note**: While this is valid, consider editing task titles to be more concise
(20-40 characters ideal).

### Task Titles with Special Characters

The script automatically sanitizes:

- Removes or converts special characters
- Collapses multiple hyphens
- Trims leading/trailing hyphens

**Examples**:

- "Fix bug: API timeout (critical)" → `feature/fix-bug-api-timeout-critical`
- "Add feature - Email & SMS" → `feature/add-feature-email-sms`
- "Update docs (version 2.0)" → `feature/update-docs-version-2-0`

## Task Context Directory

While branches use descriptive names, task metadata is preserved:

```
.task-context/
└── task-5/
    ├── details.json      # Full task details from Task Master
    └── checklist.md      # Development checklist
```

This directory:

- ✅ Is Git-ignored (in `.gitignore`)
- ✅ Links commits to tasks via hook
- ✅ Preserves all task metadata locally
- ✅ Can store implementation notes

## Migration from Old Style

If you have existing branches with old naming:

```bash
# Old branch
git checkout feature/task-5-user-auth

# Rename to new style
git branch -m feature/implement-user-authentication

# Update remote
git push origin :feature/task-5-user-auth
git push origin feature/implement-user-authentication
```

The commit hook will still find Task #5 from the `.task-context/` directory.

## Best Practices

### DO ✅

- Use descriptive task titles in Task Master
- Keep titles concise (20-40 characters)
- Use action verbs (implement, add, fix, optimize)
- Trust the automatic branch naming

### DON'T ❌

- Manually create branches (use `make task-start`)
- Edit branch names after creation
- Remove `.task-context/` directory while working
- Use abbreviations in task titles

## Troubleshooting

### Issue: Branch name too generic

**Problem**: Task title "Update API" creates `feature/update-api`

**Solution**: Edit task title in Task Master before starting:

```bash
# Instead of "Update API"
# Use "Update API endpoint rate limiting"
npx task-master-ai update-task --id=5 --prompt="Change title to 'Update API endpoint rate limiting'"
```

### Issue: Multiple tasks with similar names

**Problem**: "Add user settings" and "Add user preferences" create similar
branches

**Solution**: Add context to task titles:

- "Add user settings page"
- "Add user preferences API"

### Issue: Can't find task ID in commits

**Problem**: Commits missing Task #X reference

**Solution**: Verify `.task-context/` directory exists:

```bash
ls -la .task-context/
# Should show task-<id>/ directory

# If missing, the hook can't link tasks
# Ensure you started the task via `make task-start`
```

## Summary

**Key Points**:

- ✅ Descriptive branch names from task titles
- ✅ Task IDs tracked via `.task-context/` directory
- ✅ Automatic commit linking via hook
- ✅ Better Git history and PR titles
- ✅ Full traceability maintained

**Remember**: Use `make task-start ID=<id>` to let the system handle everything
automatically!
