#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 branch-name"
  exit 1
fi

branch_name="$1"
git checkout -b "$branch_name"
