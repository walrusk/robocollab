#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_BRANCH_FILE="$SCRIPT_DIR/.base-branch"
CANONICAL_ENTRYPOINT=".ai/scripts/git.sh"

usage() {
  cat >&2 <<'EOF'
Usage:
  .ai/scripts/git.sh start
  .ai/scripts/git.sh branch <branch-name>
  .ai/scripts/git.sh commit "commit message"
  .ai/scripts/git.sh push
  .ai/scripts/git.sh pr <gh pr create args>
EOF
  exit 1
}

current_branch() {
  rtk git rev-parse --abbrev-ref HEAD
}

is_linked_worktree() {
  local git_dir
  git_dir="$(rtk git rev-parse --git-dir)"

  local common_dir
  common_dir="$(rtk git rev-parse --git-common-dir)"

  [[ "$git_dir" != "$common_dir" ]]
}

ref_exists() {
  local ref="$1"
  rtk git rev-parse --verify --quiet "$ref^{commit}" >/dev/null
}

detached_head_base_branch() {
  local head_commit
  head_commit="$(rtk git rev-parse HEAD)"

  local candidate ref
  for candidate in main develop; do
    for ref in "$candidate" "origin/$candidate"; do
      if ref_exists "$ref" && [[ "$(rtk git rev-parse "$ref^{commit}")" == "$head_commit" ]]; then
        echo "$candidate"
        return 0
      fi
    done
  done

  for candidate in main develop; do
    for ref in "$candidate" "origin/$candidate"; do
      if ref_exists "$ref" && rtk git merge-base --is-ancestor HEAD "$ref"; then
        echo "$candidate"
        return 0
      fi
    done
  done

  return 1
}

refuse_if_protected_branch() {
  local branch="$1"
  local action="$2"

  if [[ "$branch" == "develop" || "$branch" == "main" ]]; then
    echo "Error: refusing to $action $branch."
    exit 1
  fi
}

cmd_start() {
  if [[ $# -ne 0 ]]; then
    usage
  fi

  local branch
  branch="$(current_branch)"
  local is_clean=true

  if [[ -n "$(git status --porcelain)" ]]; then
    is_clean=false
  fi

  if [[ "$branch" == "develop" && "$is_clean" == true ]]; then
    echo "$branch" > "$BASE_BRANCH_FILE"
    echo "on develop. ready for new plan."
    return 0
  fi

  if [[ "$branch" == "main" && "$is_clean" == true ]]; then
    echo "$branch" > "$BASE_BRANCH_FILE"
    echo "on main. ready for new plan."
    return 0
  fi

  if [[ "$branch" == "HEAD" && "$is_clean" == true ]] && is_linked_worktree; then
    local base_branch
    if ! base_branch="$(detached_head_base_branch)"; then
      echo "in worktree on HEAD. not ready for new plan; could not infer base branch."
      exit 1
    fi

    echo "$base_branch" > "$BASE_BRANCH_FILE"
    echo "in worktree on HEAD from $base_branch. ready to continue."
    return 0
  fi

  echo "on $branch. not ready for new plan."
  exit 1
}

cmd_branch() {
  if [[ $# -ne 1 ]]; then
    echo "Usage: $CANONICAL_ENTRYPOINT branch <branch-name>"
    exit 1
  fi

  local branch_name="$1"
  rtk git checkout -b "$branch_name"
}

cmd_commit() {
  if [[ $# -ne 1 ]]; then
    echo "Usage: $CANONICAL_ENTRYPOINT commit \"commit message\""
    exit 1
  fi

  local branch
  branch="$(current_branch)"
  refuse_if_protected_branch "$branch" "commit on"

  local message="$1"

  # Stage tracked and untracked changes, including dotfiles and deletions.
  rtk git add --all
  rtk git commit -m "$message"
}

cmd_push() {
  if [[ $# -ne 0 ]]; then
    echo "Usage: $CANONICAL_ENTRYPOINT push"
    exit 1
  fi

  local branch
  branch="$(current_branch)"

  if [[ "$branch" == "HEAD" ]]; then
    echo "Error: not on a branch."
    exit 1
  fi

  refuse_if_protected_branch "$branch" "push from"
  rtk git push --set-upstream origin "$branch"
}

cmd_pr() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: $CANONICAL_ENTRYPOINT pr <gh pr create args>"
    exit 1
  fi

  if [[ ! -f "$BASE_BRANCH_FILE" ]]; then
    echo "Error: $BASE_BRANCH_FILE not found. Run .ai/scripts/git.sh start first."
    exit 1
  fi

  local base_branch
  base_branch="$(cat "$BASE_BRANCH_FILE")"
  local branch
  branch="$(current_branch)"

  if [[ "$branch" == "HEAD" ]]; then
    echo "Error: not on a branch."
    exit 1
  fi

  refuse_if_protected_branch "$branch" "open a PR from"
  rtk git push --set-upstream origin "$branch"
  rtk gh pr create --head "$branch" --base "$base_branch" "$@"
}

if [[ $# -eq 0 ]]; then
  usage
fi

command="$1"
shift

case "$command" in
  start)
    cmd_start "$@"
    ;;
  branch)
    cmd_branch "$@"
    ;;
  commit)
    cmd_commit "$@"
    ;;
  push)
    cmd_push "$@"
    ;;
  pr)
    cmd_pr "$@"
    ;;
  *)
    usage
    ;;
esac
