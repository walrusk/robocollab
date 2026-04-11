#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 \"commit message\""
  exit 1
fi

branch="$(git rev-parse --abbrev-ref HEAD)"

if [[ "$branch" == "develop" ]]; then
  echo "Error: refusing to commit on develop."
  exit 1
fi

if [[ "$branch" == "main" ]]; then
  echo "Error: refusing to commit on main."
  exit 1
fi


message="$1"

# Stages all tracked/untracked changes, including dotfiles and deletions.
git add --all
git commit -m "$message"
