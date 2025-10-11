#!/bin/bash
# scripts/task-complete.sh - Complete a task and update Task Master

set -e

TASK_ID=$1

if [ -z "$TASK_ID" ]; then
  # Try to extract from branch name
  BRANCH_NAME=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")
  if [[ $BRANCH_NAME =~ feature/task-([0-9]+) ]]; then
    TASK_ID="${BASH_REMATCH[1]}"
  else
    echo "Usage: ./scripts/task-complete.sh <task-id>"
    exit 1
  fi
fi

echo "🎯 Completing Task #$TASK_ID..."

# Run final quality checks
echo "Running final quality validation..."
./scripts/testing/quality-checks.sh || {
  echo "❌ Quality checks failed. Fix issues before marking complete."
  exit 1
}

# Update task status
npx task-master-ai set-status --id=$TASK_ID --status=done

# Update task with completion notes
BRANCH_NAME=$(git symbolic-ref --short HEAD)
COMMIT_COUNT=$(git rev-list --count origin/staging..$BRANCH_NAME)
LAST_COMMIT=$(git log -1 --pretty=format:"%h - %s")

npx task-master-ai update-task \
  --id=$TASK_ID \
  --append \
  --prompt="Task completed successfully.
  
Branch: $BRANCH_NAME
Commits: $COMMIT_COUNT
Latest: $LAST_COMMIT
Quality: All checks passed
Status: Ready for PR"

echo "✓ Task #$TASK_ID marked as done"
echo "✓ Completion notes added"
echo ""

# Push changes to remote
echo "📤 Pushing changes to remote..."
git push origin $BRANCH_NAME || git push -u origin $BRANCH_NAME

echo ""
echo "✅ Task #$TASK_ID completed successfully!"
echo ""
echo "📋 Next steps:"
echo "  1. Create PR: gh pr create --base staging --title 'Task #$TASK_ID' --fill"
echo "  2. Or create PR manually on GitHub"
echo "  3. Request 2 reviews"
echo ""
echo "💡 Tip: Run 'gh pr create --fill' to auto-create PR with task details"

