#!/usr/bin/env bash
# Plain-English PBIP change summary for one commit range (default HEAD~1..HEAD).
set -euo pipefail

OLD_REF="${1:-HEAD~1}"
NEW_REF="${2:-HEAD}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REVIEWER="$SCRIPT_DIR/pbip_change_reviewer.py"
[ -f "$REVIEWER" ] || { echo "error: pbip_change_reviewer.py not found next to this script." >&2; exit 1; }

OLD_SHA=$(git rev-parse "$OLD_REF")
NEW_SHA=$(git rev-parse "$NEW_REF")

TMP_PARENT=$(mktemp -d)
OLD_WT="$TMP_PARENT/old"
NEW_WT="$TMP_PARENT/new"
SUMMARY_FILE=$(mktemp)

cleanup() {
  git worktree remove --force "$OLD_WT" >/dev/null 2>&1 || true
  git worktree remove --force "$NEW_WT" >/dev/null 2>&1 || true
  rm -rf "$TMP_PARENT" "$SUMMARY_FILE"
}
trap cleanup EXIT

git worktree add --detach "$OLD_WT" "$OLD_SHA" >/dev/null
git worktree add --detach "$NEW_WT" "$NEW_SHA" >/dev/null

python3 "$REVIEWER" --old "$OLD_WT" --new "$NEW_WT" --output "$SUMMARY_FILE"
cat "$SUMMARY_FILE"
