#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC2016
CODEX_SONIC_AI_CMD='out=$(mktemp); log=$(mktemp); if codex exec --skip-git-repo-check --ephemeral --sandbox read-only --color never -c approval_policy=\"never\" -c model_reasoning_effort=\"xhigh\" --output-last-message "$out" - >"$log" 2>&1; then cat "$out"; rc=0; else rc=$?; cat "$log" >&2; fi; rm -f "$out" "$log"; exit $rc'
CLAUDE_SONIC_AI_CMD='claude -p --no-session-persistence --permission-mode dontAsk --effort max --output-format text'
DEFAULT_SONIC_AI_CMD="$CODEX_SONIC_AI_CMD"
DEFAULT_PROMPT_URL="${SONIC_PROMPT_URL:-https://raw.githubusercontent.com/walrusk/robocollab/main/sonic/prompts/project-overview.md}"
DEFAULT_VIEWER_ARCHIVE_URL="${SONIC_VIEWER_ARCHIVE_URL:-https://github.com/walrusk/robocollab/archive/refs/heads/main.tar.gz}"
DEFAULT_OUTPUT=".sonic/project-map.json"

usage() {
  cat >&2 <<'EOF'
Usage:
  sonic [--output <path>] [--host <host>] [--port <port>] [--no-open] [optional focus text]

Examples:
  sonic
  sonic --output .sonic/project-map.json focus on the API and database layers
  sonic --port 5177 --no-open

Configuration:
  SONIC_AI_CMD       Optional custom agent command. If unset, Sonic asks you to
                     choose Claude Code or Codex on first run and saves the
                     default to ${XDG_CONFIG_HOME:-$HOME/.config}/sonic/config.

                     The command receives Sonic's full prompt on stdin and must
                     print JSON matching sonic/prompts/project-overview.md.

  SONIC_OUTPUT       Default output path when --output is not provided.
  SONIC_PROMPT_PATH  Optional path to the project overview prompt.
  SONIC_VIEWER_DIR   Optional path to the Sonic React viewer project.

Safety:
  Sonic asks the selected agent CLI to inspect the project in read-only mode and
  writes only the validated JSON graph file itself.
EOF
}

die() {
  echo "sonic: $*" >&2
  exit 1
}

have() {
  command -v "$1" >/dev/null 2>&1
}

sonic_config_path() {
  if [[ -n "${SONIC_CONFIG:-}" ]]; then
    printf '%s\n' "$SONIC_CONFIG"
    return
  fi

  if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
    printf '%s\n' "$XDG_CONFIG_HOME/sonic/config"
    return
  fi

  if [[ -n "${HOME:-}" ]]; then
    printf '%s\n' "$HOME/.config/sonic/config"
    return
  fi

  return 1
}

read_config_ai_cmd() {
  local config_file="$1"
  local line value first last

  [[ -f "$config_file" ]] || return 1

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" == export\ SONIC_AI_CMD=* ]] && line="${line#export }"
    [[ "$line" == SONIC_AI_CMD=* ]] || continue

    value="${line#SONIC_AI_CMD=}"
    if [[ "${#value}" -ge 2 ]]; then
      first="${value:0:1}"
      last="${value: -1}"
      if { [[ "$first" == "'" ]] && [[ "$last" == "'" ]]; } ||
         { [[ "$first" == '"' ]] && [[ "$last" == '"' ]]; }; then
        value="${value:1:${#value}-2}"
      fi
    fi

    [[ -n "$value" ]] || return 1
    value="${value//model_reasoning_effort=\\\"high\\\"/model_reasoning_effort=\\\"xhigh\\\"}"
    if [[ "$value" == claude\ * && "$value" != *"--effort "* ]]; then
      value="${value//--output-format text/--effort max --output-format text}"
    fi
    printf '%s\n' "$value"
    return 0
  done < "$config_file"

  return 1
}

write_config_ai_cmd() {
  local config_file="$1"
  local ai_cmd="$2"
  local config_dir

  config_dir="$(dirname "$config_file")"
  mkdir -p "$config_dir" || return 1
  {
    echo "# Sonic config"
    echo "# Used when SONIC_AI_CMD is not set in the environment."
    printf 'SONIC_AI_CMD=%s\n' "$ai_cmd"
  } > "$config_file" || return 1
  chmod 600 "$config_file" 2>/dev/null || true
}

resolve_ai_cmd() {
  local config_file choice ai_cmd

  if [[ -n "${SONIC_AI_CMD:-}" ]]; then
    printf '%s\n' "$SONIC_AI_CMD"
    return
  fi

  if config_file="$(sonic_config_path)" && ai_cmd="$(read_config_ai_cmd "$config_file")"; then
    printf '%s\n' "$ai_cmd"
    return
  fi

  if [[ ! -t 0 ]]; then
    printf '%s\n' "$DEFAULT_SONIC_AI_CMD"
    return
  fi

  echo "Choose your AI CLI for Sonic:" >&2
  echo "1. Claude Code" >&2
  echo "2. Codex" >&2

  while true; do
    printf 'Selection [1-2]: ' >&2
    IFS= read -r choice || die "no AI CLI selected"
    choice="${choice%.}"

    case "$choice" in
      1)
        have claude || die "claude was not found on PATH"
        ai_cmd="$CLAUDE_SONIC_AI_CMD"
        break
        ;;
      2)
        have codex || die "codex was not found on PATH"
        ai_cmd="$CODEX_SONIC_AI_CMD"
        break
        ;;
      *)
        echo "Please enter 1 or 2." >&2
        ;;
    esac
  done

  if [[ -n "${config_file:-}" ]]; then
    write_config_ai_cmd "$config_file" "$ai_cmd" || die "could not write sonic config: $config_file"
    echo "Saved default AI command to $config_file" >&2
    echo >&2
  fi

  printf '%s\n' "$ai_cmd"
}

download() {
  local url="$1"
  local output="$2"

  if have curl; then
    curl -fsSL "$url" -o "$output"
    return
  fi

  if have wget; then
    wget -qO "$output" "$url"
    return
  fi

  die "curl or wget is required to download Sonic's prompt"
}

prompt_path_for_script() {
  local script_dir prompt_path tmp_prompt

  if [[ -n "${SONIC_PROMPT_PATH:-}" ]]; then
    [[ -f "$SONIC_PROMPT_PATH" ]] || die "SONIC_PROMPT_PATH does not exist: $SONIC_PROMPT_PATH"
    printf '%s\n' "$SONIC_PROMPT_PATH"
    return
  fi

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  prompt_path="$script_dir/prompts/project-overview.md"
  if [[ -f "$prompt_path" ]]; then
    printf '%s\n' "$prompt_path"
    return
  fi

  tmp_prompt="$tmp_dir/project-overview.md"
  download "$DEFAULT_PROMPT_URL" "$tmp_prompt"
  printf '%s\n' "$tmp_prompt"
}

viewer_dir_for_script() {
  local script_dir viewer_dir archive found_package

  if [[ -n "${SONIC_VIEWER_DIR:-}" ]]; then
    [[ -f "$SONIC_VIEWER_DIR/package.json" ]] || die "SONIC_VIEWER_DIR does not contain package.json: $SONIC_VIEWER_DIR"
    printf '%s\n' "$SONIC_VIEWER_DIR"
    return
  fi

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  viewer_dir="$script_dir/viewer"
  if [[ -f "$viewer_dir/package.json" ]]; then
    printf '%s\n' "$viewer_dir"
    return
  fi

  archive="$tmp_dir/robocollab.tar.gz"
  download "$DEFAULT_VIEWER_ARCHIVE_URL" "$archive"
  tar -xzf "$archive" -C "$tmp_dir"

  found_package="$(find "$tmp_dir" -path '*/sonic/viewer/package.json' -print -quit)"
  [[ -n "$found_package" ]] || die "could not find Sonic viewer in downloaded RoboCollab archive"
  printf '%s\n' "$(dirname "$found_package")"
}

project_name() {
  local base
  base="$(basename "$PWD")"
  printf '%s\n' "$base"
}

request_prompt() {
  local focus="$1"

  cat <<EOF
Project root:
$PWD

Project name:
$(project_name)

Optional focus:
$focus
EOF
}

run_viewer() {
  local data_path="$1"
  local host="$2"
  local port="$3"
  local viewer_dir

  have node || die "node is required to run the Sonic viewer"
  have npm || die "npm is required to run the Sonic viewer"

  viewer_dir="$(viewer_dir_for_script)"

  if [[ ! -d "$viewer_dir/node_modules" ]]; then
    echo "Installing Sonic viewer dependencies..." >&2
    npm --prefix "$viewer_dir" install
  fi

  echo "Starting Sonic viewer..." >&2
  SONIC_PROJECT_ROOT="$PWD" \
    SONIC_DATA_PATH="$data_path" \
    SONIC_HOST="$host" \
    SONIC_PORT="$port" \
    npm --prefix "$viewer_dir" run dev
}

generate_with_ai_command() {
  local prompt_file="$1"
  local focus="$2"
  local ai_cmd="$3"
  local generator_prompt

  generator_prompt="$(printf '%s\n\n%s\n' "$(cat "$prompt_file")" "$(request_prompt "$focus")")"
  printf '%s' "$generator_prompt" | bash -lc "$ai_cmd"
}

normalize_graph() {
  local raw_file="$1"
  local normalized_file="$2"
  local project_root="$3"
  local fallback_name="$4"

  jq --arg root "$project_root" --arg fallbackName "$fallback_name" '
    def clean:
      if . == null then ""
      else tostring | gsub("[\r\n\t]+"; " ") | gsub("  +"; " ")
      end;

    def safe_id:
      clean
      | ascii_downcase
      | gsub("[^a-z0-9_.:-]+"; "-")
      | gsub("^-+"; "")
      | gsub("-+$"; "");

    def array_or_empty:
      if type == "array" then . else [] end;

    def io_item($nameKey):
      if type == "object" then
        {
          name: ((.name // .title // .label // "") | clean),
          kind: ((.kind // .type // "") | clean),
          ($nameKey): ((.source // .destination // .from // .to // "") | clean)
        }
      else
        {
          name: (. | clean),
          kind: "",
          ($nameKey): ""
        }
      end;

    (.nodes // .modules // []) as $rawNodes
    | (.edges // .relationships // []) as $rawEdges
    | {
        schemaVersion: (.schemaVersion // 1),
        project: {
          name: ((.project.name // .projectName // .name // $fallbackName) | clean),
          root: ((.project.root // $root) | clean),
          summary: ((.project.summary // .summary // "") | clean)
        },
        nodes: [
          ($rawNodes | array_or_empty | to_entries[]? | .key as $index | .value as $node
          | {
              id: (($node.id // $node.name // $node.label // ("node-" + (($index + 1) | tostring))) | safe_id),
              type: (($node.type // "module") | clean),
              label: (($node.label // $node.name // $node.id // ("Node " + (($index + 1) | tostring))) | clean),
              kind: (($node.kind // "module") | clean),
              summary: (($node.summary // $node.description // "") | clean),
              representativeFile: (($node.representativeFile // $node.file // $node.path // "") | clean),
              entrypoints: (($node.entrypoints // []) | array_or_empty | map(clean)),
              technologies: (($node.technologies // $node.tech // []) | array_or_empty | map(clean)),
              inputs: (($node.inputs // []) | array_or_empty | map(io_item("source"))),
              outputs: (($node.outputs // []) | array_or_empty | map(io_item("destination")))
            }
          | select(.id != ""))
        ],
        edges: [
          ($rawEdges | array_or_empty | to_entries[]? | .key as $index | .value as $edge
          | ($edge.source // $edge.from // "") as $source
          | ($edge.target // $edge.to // "") as $target
          | ($edge.relationship // $edge.type // $edge.label // ("edge-" + (($index + 1) | tostring))) as $relationship
          | {
              id: (($edge.id // (($source | clean) + "-" + ($target | clean) + "-" + ($relationship | clean))) | safe_id),
              source: ($source | safe_id),
              target: ($target | safe_id),
              label: (($edge.label // $relationship // "") | clean),
              relationship: (($edge.relationship // $edge.type // "depends-on") | clean)
            }
          | select(.source != "" and .target != ""))
        ],
        notes: ((.notes // []) | array_or_empty | map(clean))
      }
    | .nodes |= unique_by(.id)
    | (.nodes | map(.id)) as $nodeIds
    | .edges |= map(select((.source as $source | $nodeIds | index($source)) and (.target as $target | $nodeIds | index($target))))
    | .edges |= unique_by(.id)
  ' "$raw_file" > "$normalized_file"

  jq -e '
    .schemaVersion
    and (.project | type == "object")
    and (.nodes | type == "array" and length > 0)
    and (.edges | type == "array")
    and (.notes | type == "array")
  ' "$normalized_file" >/dev/null
}

output_path="${SONIC_OUTPUT:-$DEFAULT_OUTPUT}"
view_mode=false
view_data_path="${SONIC_DATA_PATH:-}"
view_data_path_set=false
if [[ -n "$view_data_path" ]]; then
  view_data_path_set=true
fi
view_host="${SONIC_HOST:-127.0.0.1}"
view_port="${SONIC_PORT:-5177}"
print_output=false
focus_parts=()

if [[ "${1:-}" == "view" ]]; then
  view_mode=true
  shift
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      [[ $# -ge 2 ]] || die "--output requires a path"
      output_path="$2"
      shift 2
      ;;
    --data)
      [[ $# -ge 2 ]] || die "--data requires a path"
      view_data_path="$2"
      view_data_path_set=true
      shift 2
      ;;
    --host)
      [[ $# -ge 2 ]] || die "--host requires a host"
      view_host="$2"
      shift 2
      ;;
    --port)
      [[ $# -ge 2 ]] || die "--port requires a port"
      view_port="$2"
      shift 2
      ;;
    --no-open)
      export SONIC_NO_OPEN=1
      shift
      ;;
    --print)
      print_output=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do
        focus_parts+=("$1")
        shift
      done
      ;;
    -*)
      die "unknown option: $1"
      ;;
    *)
      focus_parts+=("$1")
      shift
      ;;
  esac
done

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/sonic.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

if [[ "$view_mode" == true ]]; then
  if [[ "$view_data_path_set" != true ]]; then
    view_data_path="$output_path"
  fi
  run_viewer "$view_data_path" "$view_host" "$view_port"
  exit 0
fi

have jq || die "jq is required to validate Sonic's JSON output"

if [[ -z "${SONIC_AI_CMD:-}" && ! -f "$(sonic_config_path 2>/dev/null || printf /dev/null)" ]]; then
  if ! have codex && ! have claude; then
    die "neither codex nor claude was found on PATH; install one or set SONIC_AI_CMD"
  fi
fi

focus="${focus_parts[*]}"
prompt_file="$(prompt_path_for_script)"
raw_file="$tmp_dir/raw.json"
normalized_file="$tmp_dir/project-map.json"
sonic_ai_cmd="$(resolve_ai_cmd)"
export SONIC_AI_CMD="$sonic_ai_cmd"

echo "Sonic is mapping $PWD..." >&2
generate_with_ai_command "$prompt_file" "$focus" "$sonic_ai_cmd" > "$raw_file"

normalize_graph "$raw_file" "$normalized_file" "$PWD" "$(project_name)" ||
  die "AI backend did not return a valid Sonic project graph"

mkdir -p "$(dirname "$output_path")"
cp "$normalized_file" "$output_path"

if [[ "$print_output" == true ]]; then
  cat "$output_path"
else
  echo "Wrote $output_path" >&2
  if [[ "$view_data_path_set" != true ]]; then
    view_data_path="$output_path"
  fi
  run_viewer "$view_data_path" "$view_host" "$view_port"
fi
