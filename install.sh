#!/usr/bin/env bash

set -euo pipefail

REPO_URL="${ROBOCOLLAB_REPO_URL:-https://github.com/walrusk/robocollab.git}"
TMP_DIR=".robocollab-install"
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$INSTALL_DIR/$(basename "${BASH_SOURCE[0]}")"
SRC="$INSTALL_DIR/$TMP_DIR"

# --- Helpers ---

info()  { printf "\n\033[1;34m%s\033[0m\n" "$1"; }
item()  { printf "  \033[0;36m•\033[0m %s\n" "$1"; }
warn()  { printf "  \033[0;33m⚠\033[0m %s\n" "$1"; }
ok()    { printf "\033[1;32m%s\033[0m\n" "$1"; }

prompt_yes_no() {
  local prompt="$1"
  local default="${2:-N}"
  local answer

  printf "\n\033[1;33m%s [%s]\033[0m " "$prompt" "$default"
  read -r answer

  case "$answer" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

confirm() {
  if ! prompt_yes_no "Proceed?" "y/N"; then
    echo "Aborted."
    exit 1
  fi
}

ensure_rtk() {
  if command -v rtk >/dev/null 2>&1; then
    item "rtk is already installed"
    return
  fi

  warn "rtk is not installed."

  if ! prompt_yes_no "Install rtk with Homebrew?" "y/N"; then
    warn "Continuing without rtk."
    return
  fi

  if ! command -v brew >/dev/null 2>&1; then
    warn "Homebrew is not installed, so rtk cannot be installed automatically."
    warn "Install Homebrew first, then run: brew install rtk"
    return
  fi

  info "Installing rtk..."
  brew install rtk
  ok "rtk installed."

  info "Initializing rtk..."
  rtk init -g
  ok "rtk initialized."
}

# Copy a source directory's contents into a destination directory, creating the
# destination if needed. Existing files in the destination are overwritten.
copy_tree() {
  local src="$1"
  local dest="$2"
  local label="$3"

  if [[ ! -d "$src" ]]; then
    warn "Source missing: $src (skipping $label)"
    return
  fi

  mkdir -p "$dest"
  # Copy contents (including dotfiles) without nesting src inside dest.
  cp -R "$src/." "$dest/"
  item "$label"
}

sync_git_wrapper() {
  local src_dir="$1"
  local dest_dir="$2"
  local src_git="$src_dir/git.sh"
  local dest_git="$dest_dir/git.sh"
  local legacy_script
  local removed_any=false

  if [[ ! -f "$src_git" ]]; then
    warn "Source missing: $src_git (skipping .ai/scripts/git.sh)"
    return
  fi

  mkdir -p "$dest_dir"
  cp "$src_git" "$dest_git"
  chmod +x "$dest_git"
  item ".ai/scripts/git.sh"

  for legacy_script in start.sh branch.sh commit.sh push.sh pr.sh; do
    if [[ -e "$dest_dir/$legacy_script" ]]; then
      rm -f "$dest_dir/$legacy_script"
      removed_any=true
    fi
  done

  if [[ "$removed_any" == true ]]; then
    item ".ai/scripts/ legacy shims removed"
  fi
}

# Append lines from src into dest, skipping duplicates. Creates dest from src if
# it doesn't exist. Intended for simple line-oriented files like .gitignore.
integrate_lines() {
  local src="$1"
  local dest="$2"
  local label
  label="$(basename "$dest")"

  if [[ ! -f "$src" ]]; then
    warn "Source missing: $src (skipping $label)"
    return
  fi

  if [[ ! -f "$dest" ]]; then
    cp "$src" "$dest"
    item "$label (created)"
    return
  fi

  local added=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    if ! grep -qFx "$line" "$dest"; then
      echo "$line" >> "$dest"
      added=$((added + 1))
    fi
  done < "$src"

  if [[ $added -gt 0 ]]; then
    item "$label (added $added new line(s))"
  else
    item "$label (already up to date)"
  fi
}

# Copy src to dest. If dest exists, prompt the user to overwrite or skip — do
# not attempt to merge structured content.
# $3 is a short label for output (defaults to basename of dest).
# $4 is the relative path inside the source repo used in the skip message.
copy_or_prompt() {
  local src="$1"
  local dest="$2"
  local label="${3:-$(basename "$dest")}"
  local rel="${4:-$label}"

  if [[ ! -f "$src" ]]; then
    warn "Source missing: $src (skipping $label)"
    return
  fi

  if [[ -e "$dest" ]]; then
    local answer=""
    printf "  \033[0;33m?\033[0m %s already exists. Overwrite? [y/N] " "$label"
    read -r answer
    case "$answer" in
      [yY]|[yY][eE][sS])
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        item "$label (overwritten)"
        ;;
      *)
        warn "$label left unchanged. Compare against $rel in $REPO_URL and merge manually if needed."
        ;;
    esac
    return
  fi

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  item "$label (created)"
}

# --- Announce ---

info "RoboCollab Installer"
ensure_rtk
echo ""
echo "This script will install the RoboCollab workflow into:"
echo "  $INSTALL_DIR"
echo ""
echo "It will:"
item "Clone $REPO_URL into a temporary directory"
echo ""
info "Copy these directories (overwriting matching files):"
item ".ai/scripts/git.sh  — Canonical git workflow wrapper"
item ".ai/plans/          — Plan file directory"
item ".claude/rules/      — Claude Code rule files"
item ".cursor/rules/      — Cursor rule files"
item ".cursor/skills/     — Cursor skill files"
item ".codex/rules/       — Codex rule files"
echo ""
info "Merge into existing files line-by-line (or create if missing):"
item ".gitignore"
item ".cursorignore"
echo ""
info "Copy these files (prompt to overwrite if they already exist):"
item "AGENTS.md"
item "CLAUDE.md"
item ".claude/settings.json"
echo ""
info "Clean up:"
item "Remove the temporary directory"

confirm

# --- Clone ---

info "Cloning RoboCollab..."

if [[ -d "$SRC" ]]; then
  rm -rf "$SRC"
fi

git clone --quiet --depth 1 "$REPO_URL" "$SRC"
ok "Done."

# --- Copy directories ---

info "Copying directories..."

sync_git_wrapper "$SRC/.ai/scripts" "$INSTALL_DIR/.ai/scripts"
copy_tree "$SRC/.ai/plans"     "$INSTALL_DIR/.ai/plans"     ".ai/plans/"
copy_tree "$SRC/.claude/rules" "$INSTALL_DIR/.claude/rules" ".claude/rules/"
copy_tree "$SRC/.cursor/rules" "$INSTALL_DIR/.cursor/rules" ".cursor/rules/"
copy_tree "$SRC/.cursor/skills" "$INSTALL_DIR/.cursor/skills" ".cursor/skills/"
copy_tree "$SRC/.codex/rules"  "$INSTALL_DIR/.codex/rules"  ".codex/rules/"

ok "Done."

# --- Integrate line-based files ---

info "Merging ignore files..."

integrate_lines "$SRC/.gitignore"    "$INSTALL_DIR/.gitignore"
integrate_lines "$SRC/.cursorignore" "$INSTALL_DIR/.cursorignore"

ok "Done."

# --- Copy-if-missing files ---

info "Installing top-level files..."

copy_or_prompt "$SRC/AGENTS.md"              "$INSTALL_DIR/AGENTS.md"              "AGENTS.md"              "AGENTS.md"
copy_or_prompt "$SRC/CLAUDE.md"              "$INSTALL_DIR/CLAUDE.md"              "CLAUDE.md"              "CLAUDE.md"
copy_or_prompt "$SRC/.claude/settings.json"  "$INSTALL_DIR/.claude/settings.json"  ".claude/settings.json"  ".claude/settings.json"

ok "Done."

# --- Clean up ---

info "Cleaning up..."
rm -rf "$SRC"
ok "Done."

# --- Finish ---

info "RoboCollab installed successfully!"
echo ""
echo "Next steps:"
item "Review any files reported as 'left unchanged' and merge manually if needed."
item "Open this project in your agent of choice and try DEV mode."
echo ""

if prompt_yes_no "Delete this installer script ($SCRIPT_PATH)?" "y/N"; then
  if rm -- "$SCRIPT_PATH"; then
    ok "Installer script deleted."
  else
    warn "Could not delete $SCRIPT_PATH."
  fi
fi
