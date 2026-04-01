#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_BRANCH_FILE="$SCRIPT_DIR/.base-branch"

branch="$(git rev-parse --abbrev-ref HEAD)"
is_clean=true

if [[ -n "$(git status --porcelain)" ]]; then
  is_clean=false
fi

if [[ "$branch" == "develop" && "$is_clean" == true ]]; then
  echo "$branch" > "$BASE_BRANCH_FILE"
  echo "on develop. ready for new plan."
  exit 0
fi

if [[ "$branch" == "main" && "$is_clean" == true ]]; then
  echo "$branch" > "$BASE_BRANCH_FILE"
  echo "on main. ready for new plan."
  exit 0
fi

echo "on $branch. not ready for new plan."
exit 1
