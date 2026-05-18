#!/usr/bin/env bash

set -euo pipefail

REPO_URL="${ROBOCOLLAB_REPO_URL:-https://github.com/walrusk/robocollab.git}"
ROBOCOLLAB_COMMAND_NAME="robocollab"
ROBOCOLLAB_COMMAND_DEST_DIR="${ROBOCOLLAB_BIN_DIR:-}"
ROBOTNIK_INSTALL_URL="${ROBOTNIK_INSTALL_URL:-https://raw.githubusercontent.com/walrusk/robotnik/main/bash/install.sh}"
TMP_DIR=".robocollab-install"
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$INSTALL_DIR/$(basename "${BASH_SOURCE[0]}")"
SRC="$INSTALL_DIR/$TMP_DIR"

# --- Helpers ---

info()  { printf "\n\033[1;34m%s\033[0m\n" "$1"; }
item()  { printf "  \033[0;36m•\033[0m %s\n" "$1"; }
warn()  { printf "  \033[0;33m⚠\033[0m %s\n" "$1"; }
ok()    { printf "\033[1;32m%s\033[0m\n" "$1"; }

INSTALL_REACT_NATIVE_SKILLS=false
INSTALL_REACT_SKILLS=false
INSTALL_ROBOCOLLAB_COMMAND=false

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

path_contains_dir() {
  local target="$1"
  local dir
  local path_dirs=()

  IFS=':' read -r -a path_dirs <<< "${PATH:-}"
  for dir in "${path_dirs[@]}"; do
    if [[ "$dir" == "$target" ]]; then
      return 0
    fi
  done

  return 1
}

find_writable_path_dir() {
  local dir
  local path_dirs=()

  IFS=':' read -r -a path_dirs <<< "${PATH:-}"

  if [[ -n "${HOME:-}" ]]; then
    for dir in "$HOME/.local/bin" "$HOME/bin"; do
      if path_contains_dir "$dir"; then
        printf "%s\n" "$dir"
        return 0
      fi
    done

    for dir in "${path_dirs[@]}"; do
      if [[ -n "$dir" && "$dir" == "$HOME"/* && -d "$dir" && -w "$dir" ]]; then
        printf "%s\n" "$dir"
        return 0
      fi
    done
  fi

  for dir in /usr/local/bin /opt/homebrew/bin; do
    if path_contains_dir "$dir" && [[ -d "$dir" && -w "$dir" ]]; then
      printf "%s\n" "$dir"
      return 0
    fi
  done

  for dir in "${path_dirs[@]}"; do
    if [[ -n "$dir" && -d "$dir" && -w "$dir" ]]; then
      printf "%s\n" "$dir"
      return 0
    fi
  done

  return 1
}

select_robocollab_command_install() {
  info "Optional command install"

  if command -v "$ROBOCOLLAB_COMMAND_NAME" >/dev/null 2>&1; then
    item "$ROBOCOLLAB_COMMAND_NAME is already installed at $(command -v "$ROBOCOLLAB_COMMAND_NAME")"
    return
  fi

  if [[ -z "$ROBOCOLLAB_COMMAND_DEST_DIR" ]]; then
    ROBOCOLLAB_COMMAND_DEST_DIR="$(find_writable_path_dir || true)"
  fi

  if [[ -z "$ROBOCOLLAB_COMMAND_DEST_DIR" ]]; then
    warn "No writable directory was found in PATH."
    warn "Set ROBOCOLLAB_BIN_DIR to a writable PATH directory and rerun this installer to install the robocollab command."
    return
  fi

  if prompt_yes_no "Install $ROBOCOLLAB_COMMAND_NAME command to $ROBOCOLLAB_COMMAND_DEST_DIR?" "y/N"; then
    INSTALL_ROBOCOLLAB_COMMAND=true
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

select_framework_skills() {
  info "Optional framework skills"

  if prompt_yes_no "Install React Native skills? (react-native and react-native-ui-lib)" "y/N"; then
    INSTALL_REACT_NATIVE_SKILLS=true
    return
  fi

  if prompt_yes_no "Install React skills? (react)" "y/N"; then
    INSTALL_REACT_SKILLS=true
  fi
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

remove_obsolete_managed_file() {
  local path="$1"
  local label="$2"

  if [[ -e "$path" ]]; then
    rm -f "$path"
    item "$label (removed obsolete file)"
  fi
}

copy_skill() {
  local skill="$1"

  copy_tree "$SRC/.agents/skills/$skill" "$INSTALL_DIR/.agents/skills/$skill" ".agents/skills/$skill/"
  copy_tree "$SRC/.cursor/skills/$skill" "$INSTALL_DIR/.cursor/skills/$skill" ".cursor/skills/$skill/"
}

install_framework_skills() {
  info "Installing optional framework skills..."

  if [[ "$INSTALL_REACT_NATIVE_SKILLS" == true ]]; then
    copy_skill "react-native"
    copy_skill "react-native-ui-lib"
    ok "Done."
    return
  fi

  if [[ "$INSTALL_REACT_SKILLS" == true ]]; then
    copy_skill "react"
    ok "Done."
    return
  fi

  item "No framework skills selected"
  ok "Done."
}

sync_scripts() {
  local src_dir="$1"
  local dest_dir="$2"

  if [[ ! -d "$src_dir" ]]; then
    warn "Source missing: $src_dir (skipping .ai/scripts/)"
    return
  fi

  mkdir -p "$dest_dir"

  local src_script
  local copied=0
  for src_script in "$src_dir"/*; do
    [[ -f "$src_script" ]] || continue

    local script_name
    local dest_script
    script_name="$(basename "$src_script")"
    dest_script="$dest_dir/$script_name"

    cp "$src_script" "$dest_script"
    if [[ -x "$src_script" ]]; then
      chmod +x "$dest_script"
    fi

    item ".ai/scripts/$script_name"
    copied=$((copied + 1))
  done

  if [[ $copied -eq 0 ]]; then
    warn "No scripts found in $src_dir"
  fi
}

install_robotnik() {
  info "Installing Robotnik..."

  if ! command -v curl >/dev/null 2>&1; then
    warn "curl is required to install Robotnik from $ROBOTNIK_INSTALL_URL."
    return 1
  fi

  local robotnik_installer="$SRC/robotnik-install.sh"
  curl -fsSL "$ROBOTNIK_INSTALL_URL" -o "$robotnik_installer"
  bash "$robotnik_installer"
  ok "Robotnik installed."
}

install_robocollab_command() {
  if [[ "$INSTALL_ROBOCOLLAB_COMMAND" != true ]]; then
    return
  fi

  info "Installing $ROBOCOLLAB_COMMAND_NAME command..."

  local src="$SRC/bin/$ROBOCOLLAB_COMMAND_NAME"
  if [[ ! -f "$src" ]]; then
    warn "Source missing: $src (skipping $ROBOCOLLAB_COMMAND_NAME command)"
    return
  fi

  mkdir -p "$ROBOCOLLAB_COMMAND_DEST_DIR"
  if [[ ! -d "$ROBOCOLLAB_COMMAND_DEST_DIR" || ! -w "$ROBOCOLLAB_COMMAND_DEST_DIR" ]]; then
    warn "$ROBOCOLLAB_COMMAND_DEST_DIR is not writable, so $ROBOCOLLAB_COMMAND_NAME cannot be installed there."
    return
  fi

  local dest="$ROBOCOLLAB_COMMAND_DEST_DIR/$ROBOCOLLAB_COMMAND_NAME"
  cp "$src" "$dest"
  chmod +x "$dest"
  item "$dest"

  if ! path_contains_dir "$ROBOCOLLAB_COMMAND_DEST_DIR"; then
    warn "$ROBOCOLLAB_COMMAND_DEST_DIR is not currently in PATH."
  fi

  ok "Done."
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

stage_untrack_ignored_agent_files() {
  local ignore_src="$1"

  if ! prompt_yes_no "Untrack RoboCollab files now covered by .gitignore? This stages their removal from git while keeping them on disk." "y/N"; then
    item "Tracked RoboCollab files left unchanged"
    return
  fi

  if ! command -v git >/dev/null 2>&1; then
    warn "git is not available, so tracked RoboCollab files cannot be untracked automatically."
    return
  fi

  if ! git -C "$INSTALL_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    warn "$INSTALL_DIR is not inside a git work tree, so tracked RoboCollab files cannot be untracked automatically."
    return
  fi

  if [[ ! -f "$ignore_src" ]]; then
    warn "Source missing: $ignore_src (skipping git untrack cleanup)"
    return
  fi

  if [[ -f "$INSTALL_DIR/.gitignore" ]]; then
    if git -C "$INSTALL_DIR" add -- .gitignore; then
      item ".gitignore (staged)"
    else
      warn "Could not stage .gitignore."
    fi
  fi

  local tracked=()
  local tracked_file
  while IFS= read -r -d '' tracked_file; do
    tracked+=("$tracked_file")
  done < <(git -C "$INSTALL_DIR" ls-files -z -c -i --exclude-from="$ignore_src")

  if [[ ${#tracked[@]} -eq 0 ]]; then
    item "No tracked RoboCollab files matched the installed .gitignore entries"
    return
  fi

  if git -C "$INSTALL_DIR" rm --cached -q -- "${tracked[@]}"; then
    item "${#tracked[@]} tracked RoboCollab file(s) staged for removal from git"
    item "Files remain on disk"
  else
    warn "Could not untrack every matching RoboCollab file automatically."
    warn "No files were deleted; review git status and untrack them manually if needed."
  fi
}

# Copy src to dest. If dest exists with different content, prompt the user to
# overwrite or skip — do not attempt to merge structured content.
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
    if cmp -s "$src" "$dest"; then
      item "$label (already up to date)"
      return
    fi

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
item ".ai/scripts/      — RoboCollab scripts"
item ".ai/modes/          — Lazy-loaded DEV and FOLLOWUP mode instructions"
item ".ai/workflows/      — Lazy-loaded workflow policies"
item ".ai/plans/          — Plan file directory"
item ".cursor/rules/      — Cursor sticky mode router"
item ".codex/             — Codex config and exec-policy rules"
item ".ai/modes/discuss.md and .ai/modes/collab.md are removed if left over from an older install"
echo ""
info "Install latest external tools:"
item "Robotnik from $ROBOTNIK_INSTALL_URL"
echo ""
info "Prompt for optional installs:"
item "robocollab command into a writable PATH directory"
item "React Native installs react-native and react-native-ui-lib skills"
item "React installs the react skill"
echo ""
info "Merge into existing files line-by-line (or create if missing):"
item ".gitignore (from .gitignore.installed; excludes .ai/plans/)"
item ".cursorignore"
item "Offer to untrack RoboCollab files covered by .gitignore and stage the git index removals"
echo ""
info "Copy these files (prompt to overwrite if they already exist):"
item "AGENTS.md"
item "CLAUDE.md"
item ".claude/settings.json"
echo ""
info "Clean up:"
item "Remove the temporary directory"

confirm
select_robocollab_command_install
select_framework_skills

# --- Clone ---

info "Cloning RoboCollab..."

if [[ -d "$SRC" ]]; then
  rm -rf "$SRC"
fi

git clone --quiet --depth 1 "$REPO_URL" "$SRC"
ok "Done."

# --- Copy directories ---

info "Copying directories..."

sync_scripts "$SRC/.ai/scripts" "$INSTALL_DIR/.ai/scripts"
copy_tree "$SRC/.ai/modes"     "$INSTALL_DIR/.ai/modes"     ".ai/modes/"
remove_obsolete_managed_file "$INSTALL_DIR/.ai/modes/discuss.md" ".ai/modes/discuss.md"
remove_obsolete_managed_file "$INSTALL_DIR/.ai/modes/collab.md" ".ai/modes/collab.md"
copy_tree "$SRC/.ai/workflows" "$INSTALL_DIR/.ai/workflows" ".ai/workflows/"
copy_tree "$SRC/.ai/plans"     "$INSTALL_DIR/.ai/plans"     ".ai/plans/"
copy_tree "$SRC/.cursor/rules" "$INSTALL_DIR/.cursor/rules" ".cursor/rules/"
copy_tree "$SRC/.codex"        "$INSTALL_DIR/.codex"        ".codex/"

ok "Done."

# --- External tools ---

install_robotnik
install_robocollab_command

# --- Optional framework skills ---

install_framework_skills

# --- Integrate line-based files ---

info "Merging ignore files..."

integrate_lines "$SRC/.gitignore.installed" "$INSTALL_DIR/.gitignore"
integrate_lines "$SRC/.cursorignore"        "$INSTALL_DIR/.cursorignore"
stage_untrack_ignored_agent_files "$SRC/.gitignore.installed"

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
if [[ "$INSTALL_ROBOCOLLAB_COMMAND" == true ]]; then
  item "Run 'robocollab' from any project directory to fetch and run the latest installer."
fi
item "Open this project in your agent of choice and try DEV mode."
echo ""

if [[ "${ROBOCOLLAB_INSTALLER_TEMP:-}" == "1" ]]; then
  :
elif prompt_yes_no "Delete this installer script ($SCRIPT_PATH)?" "y/N"; then
  if rm -- "$SCRIPT_PATH"; then
    ok "Installer script deleted."
  else
    warn "Could not delete $SCRIPT_PATH."
  fi
fi
