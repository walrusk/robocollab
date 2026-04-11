#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_BRANCH_FILE="$SCRIPT_DIR/.base-branch"

if [[ ! -f "$BASE_BRANCH_FILE" ]]; then
  echo "Error: $BASE_BRANCH_FILE not found. Run scripts/start.sh first."
  exit 1
fi

if [[ $# -eq 0 ]]; then
  echo "Usage: pr.sh <gh pr create args>"
  exit 1
fi

base_branch="$(cat "$BASE_BRANCH_FILE")"
branch="$(git rev-parse --abbrev-ref HEAD)"

if [[ "$branch" == "HEAD" ]]; then
  echo "Error: not on a branch."
  exit 1
fi

if [[ "$branch" == "develop" ]]; then
  echo "Error: refusing to open a PR from develop."
  exit 1
fi

if [[ "$branch" == "main" ]]; then
  echo "Error: refusing to open a PR from main."
  exit 1
fi

git push --set-upstream origin "$branch"
gh pr create --head "$branch" --base "$base_branch" "$@"
