#!/bin/bash
# scripts/task-start.sh - Start a new feature from Task Master task

set -e

TASK_ID=$1

if [ -z "$TASK_ID" ]; then
  echo "Usage: ./scripts/task-start.sh <task-id>"
  echo "Example: ./scripts/task-start.sh 5"
  exit 1
fi

# Get task details from Task Master
TASK_JSON=$(npx task-master-ai show $TASK_ID --format=json)
TASK_TITLE=$(echo "$TASK_JSON" | jq -r '.title' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')

# Create more descriptive branch name with task ID as prefix for traceability
BRANCH_NAME="feature/${TASK_TITLE}"

# Create feature branch
git checkout -b "$BRANCH_NAME"

# Update task status to in-progress
npx task-master-ai set-status --id=$TASK_ID --status=in-progress

# Create feature workspace
mkdir -p ".task-context/task-${TASK_ID}"
echo "$TASK_JSON" > ".task-context/task-${TASK_ID}/details.json"

# Generate test structure based on task
cat > ".task-context/task-${TASK_ID}/checklist.md" << EOF
# Task ${TASK_ID} Checklist

## Pre-Development
- [ ] Read task details and dependencies
- [ ] Review related PRD sections
- [ ] Identify affected services (API/Web/Infra)

## Development
- [ ] Write tests first (TDD)
- [ ] Implement feature
- [ ] Run local quality checks (\`pnpm quality\`)
- [ ] Update documentation

## Pre-Commit
- [ ] All tests passing
- [ ] Code formatted (auto via pre-commit)
- [ ] No linter errors
- [ ] Security scan clean

## PR Creation
- [ ] Conventional commit messages
- [ ] PR description references task #${TASK_ID}
- [ ] All CI checks passing
- [ ] Code coverage maintained

## Post-Merge
- [ ] Update task status to 'done'
- [ ] Update dependent tasks if needed
- [ ] Verify staging deployment
EOF

echo "✓ Feature branch created: $BRANCH_NAME"
echo "✓ Task #$TASK_ID status: in-progress"
echo "✓ Task context: .task-context/task-${TASK_ID}/"
echo "✓ Checklist: .task-context/task-${TASK_ID}/checklist.md"
echo ""
echo "Next steps:"
echo "  1. Review checklist: cat .task-context/task-${TASK_ID}/checklist.md"
echo "  2. Start development"
echo "  3. Run quality checks: make quality-local"

