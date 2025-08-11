#!/bin/bash
set -e

# Clean up merged branch: kill tmux session + remove worktree
# Usage: ./cleanup-merged-branch.sh <branch-name>

BRANCH_NAME="$1"

if [ -z "$BRANCH_NAME" ]; then
    echo "Usage: $0 <branch-name>"
    exit 1
fi

# Kill tmux session
tmux kill-session -t "$BRANCH_NAME"

# Remove worktree
git worktree remove "$BRANCH_NAME"

echo "Cleaned up $BRANCH_NAME"