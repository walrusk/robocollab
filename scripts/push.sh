#!/usr/bin/env bash

set -euo pipefail

branch="$(git rev-parse --abbrev-ref HEAD)"

if [[ "$branch" == "HEAD" ]]; then
  echo "Error: not on a branch."
  exit 1
fi

if [[ "$branch" == "develop" ]]; then
  echo "Error: refusing to push from develop."
  exit 1
fi

if [[ "$branch" == "main" ]]; then
  echo "Error: refusing to push from main."
  exit 1
fi

git push --set-upstream origin "$branch"
