#!/usr/bin/env bash

set -euo pipefail

REPO_URL="https://github.com/walrusk/robocollab.git"
TMP_DIR=".robocollab-install"
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Helpers ---

info()  { printf "\n\033[1;34m%s\033[0m\n" "$1"; }
item()  { printf "  \033[0;36m•\033[0m %s\n" "$1"; }
warn()  { printf "  \033[0;33m⚠\033[0m %s\n" "$1"; }
ok()    { printf "\033[1;32m%s\033[0m\n" "$1"; }

confirm() {
  printf "\n\033[1;33mProceed? [y/N]\033[0m "
  read -r answer
  case "$answer" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) echo "Aborted."; exit 1 ;;
  esac
}

# Append lines from a source file into a target file, skipping duplicates.
# Creates the target file if it doesn't exist.
integrate_file() {
  local src="$1"
  local dest="$2"

  if [[ ! -f "$dest" ]]; then
    cp "$src" "$dest"
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
    item "Added $added new line(s) to $(basename "$dest")"
  else
    item "$(basename "$dest") already up to date"
  fi
}

# Append content from a source file into a target file, separated by a blank
# line. If the target doesn't exist, copies the source as-is. If the target
# already contains a marker line from the source, skips the integration.
integrate_block() {
  local src="$1"
  local dest="$2"
  local marker="$3"

  if [[ ! -f "$dest" ]]; then
    cp "$src" "$dest"
    return
  fi

  if grep -qF "$marker" "$dest"; then
    item "$(basename "$dest") already contains RoboCollab content"
    return
  fi

  printf "\n" >> "$dest"
  cat "$src" >> "$dest"
  item "Appended RoboCollab content to $(basename "$dest")"
}

# --- Announce ---

info "RoboCollab Installer"
echo ""
echo "This script will install the RoboCollab workflow into:"
echo "  $INSTALL_DIR"
echo ""
echo "It will:"
item "Clone $REPO_URL into a temporary directory"
echo ""
info "Copy these directories (creating them if needed):"
item ".ai/plans/          — Plan file directory (empty)"
item ".ai/scripts/        — Git operation scripts"
item ".cursor/commands/   — Cursor slash commands (/dev, /followup, /collab)"
item ".cursor/rules/      — Always-on agent rules"
echo ""
info "Integrate into existing files (or create if missing):"
item ".gitignore          — Add entries line-by-line, skipping duplicates"
item ".cursorignore       — Add entries line-by-line, skipping duplicates"
item "AGENTS.md           — Append RoboCollab agent instructions"
echo ""
info "Clean up:"
item "Remove the temporary directory"

confirm

# --- Clone ---

info "Cloning RoboCollab..."

if [[ -d "$INSTALL_DIR/$TMP_DIR" ]]; then
  rm -rf "$INSTALL_DIR/$TMP_DIR"
fi

git clone --quiet --depth 1 "$REPO_URL" "$INSTALL_DIR/$TMP_DIR"
ok "Done."

# --- Copy directories ---

info "Copying files..."

mkdir -p "$INSTALL_DIR/.ai/plans"
mkdir -p "$INSTALL_DIR/.ai/scripts"
mkdir -p "$INSTALL_DIR/.cursor/commands"
mkdir -p "$INSTALL_DIR/.cursor/rules"

for f in "$INSTALL_DIR/$TMP_DIR/.ai/scripts/"*.sh; do
  cp "$f" "$INSTALL_DIR/.ai/scripts/"
  item "$(basename "$f")"
done

for f in "$INSTALL_DIR/$TMP_DIR/.cursor/commands/"*.md; do
  cp "$f" "$INSTALL_DIR/.cursor/commands/"
  item "$(basename "$f")"
done

for f in "$INSTALL_DIR/$TMP_DIR/.cursor/rules/"*.mdc; do
  cp "$f" "$INSTALL_DIR/.cursor/rules/"
  item "$(basename "$f")"
done

chmod +x "$INSTALL_DIR/.ai/scripts/"*.sh

ok "Done."

# --- Integrate files ---

info "Integrating config files..."

integrate_file \
  "$INSTALL_DIR/$TMP_DIR/.gitignore" \
  "$INSTALL_DIR/.gitignore"

integrate_file \
  "$INSTALL_DIR/$TMP_DIR/.cursorignore" \
  "$INSTALL_DIR/.cursorignore"

integrate_block \
  "$INSTALL_DIR/$TMP_DIR/AGENTS.md" \
  "$INSTALL_DIR/AGENTS.md" \
  "## Commands"

ok "Done."

# --- Clean up ---

info "Cleaning up..."
rm -rf "$INSTALL_DIR/$TMP_DIR"
ok "Done."

# --- Finish ---

info "RoboCollab installed successfully!"
echo ""
echo "Next steps:"
item "Open this project in Cursor"
item "Type /dev in chat to start your first planned change"
echo ""
