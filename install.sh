#!/usr/bin/env bash
# Install the issue-doc-sync Claude Code skill.
#
# Usage:
#   ./install.sh                 Install globally to ~/.claude/skills/issue-doc-sync
#   ./install.sh /path/to/repo   Install into a specific project's .claude/skills/issue-doc-sync
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/SKILL.md"

if [ ! -f "$SRC" ]; then
  echo "error: $SRC not found (run this script from inside ai-issue-doc-sync)" >&2
  exit 1
fi

if [ "$#" -ge 1 ]; then
  TARGET_ROOT="$1"
  if [ ! -d "$TARGET_ROOT" ]; then
    echo "error: target directory '$TARGET_ROOT' does not exist" >&2
    exit 1
  fi
  DEST="$TARGET_ROOT/.claude/skills/issue-doc-sync"
else
  DEST="$HOME/.claude/skills/issue-doc-sync"
fi

mkdir -p "$DEST"
cp "$SRC" "$DEST/SKILL.md"

echo "Installed issue-doc-sync skill to: $DEST"
