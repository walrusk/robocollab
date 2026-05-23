# RoboCollab

A structured workflow for collaborating with AI coding agents. It defines a small sticky mode router, inline default collaboration rules, lazy-loaded planning mode instructions, lazy-loaded workflow policies, and wrapper scripts for the parts of git that have footguns — so you get a repeatable, predictable process for planning, executing, and reviewing changes with an agent without loading every workflow into context up front.

RoboCollab is runtime-agnostic: it ships a universal `AGENTS.md` with the mode router and styleguide that any agent that respects those conventions can read, plus thin runtime adapters for Claude Code, Cursor, and Codex.

## Install

Download `install.sh` into the root of your repo and run it:

```bash
curl -fsSL https://raw.githubusercontent.com/walrusk/robocollab/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

The script announces exactly what it will do and prompts before making changes. It:

- copies `.ai/scripts/`, `.ai/modes/`, `.ai/workflows/`, `.ai/plans/`, `.cursor/rules/`, and `.codex/` into your repo (overwriting matching files);
- removes legacy `.ai/modes/discuss.md` and `.ai/modes/collab.md` files from older installs;
- installs the latest Bash version of `robotnik` from [`walrusk/robotnik`](https://github.com/walrusk/robotnik) via `bash/install.sh`;
- asks whether to install or update a `robocollab` command in a writable directory on your `PATH`;
- asks whether to install React Native skills (`react-native` and `react-native-ui-lib`); if you decline, asks whether to install the React skill;
- line-merges `.gitignore` and `.cursorignore` (skipping duplicates);
- prompts before overwriting an existing `AGENTS.md`, `CLAUDE.md`, or `.claude/settings.json`;
- asks whether to stage the installed RoboCollab repo files for commit.

After it finishes you can delete `install.sh`.

If installed, `robocollab` can be run from any project directory. It prompts before downloading the latest RoboCollab `install.sh` and running it in the current directory, and it can also fetch and run Sonic against the current project. You can also run `robocollab sonic` or `robocollab view` directly.

## How it works

Agents operate in one of three sticky modes. **COLLAB** is the default; DEV is triggered by a short phrase at the start of your instruction, and FOLLOWUP is entered automatically after a DEV PR opens. Once a mode is active, it remains active as conversation state until you switch modes again.

### COLLAB — default pair-programming on the current branch

Trigger explicitly with `"in collab mode, ..."` or `"collab. ..."` when returning from another mode.

The agent edits the current branch directly and does not touch git — you handle branches, commits, and pushes. If it notices a problem with something you wrote, it points it out rather than silently changing it. Because COLLAB is the assumed default, the agent does not announce that it is in this mode.

### DEV — planned change on a new branch

Trigger with something like `"in dev mode, ..."` or `"dev. ..."`.

The agent will:

1. Run `.ai/scripts/git.sh start` to confirm you're on `main`/`develop` and clean.
2. Draft a plan and present it for review. Iterate until you approve.
3. When you say "proceed", write the plan to `.ai/plans/NNN_description.md`, create a branch via `.ai/scripts/git.sh branch`, implement the change, commit, and open a PR.

After the PR is opened, the agent auto-switches to FOLLOWUP.

### FOLLOWUP — iterate on an open PR

Entered automatically at the end of DEV. The agent makes follow-up edits on the same branch, keeps the plan file in `.ai/plans/` in sync, and commits/pushes via the scripts. Refuses to run on `main`/`develop`.

## Project layout

```
.ai/
├── modes/                 Lazy-loaded DEV and FOLLOWUP mode instructions
├── plans/                 Plan files written during DEV mode
├── scripts/               Workflow scripts
└── workflows/             Lazy-loaded workflow policies
.agents/
└── skills/                Optional repo-scoped Codex framework skills
.claude/
└── settings.json          Claude Code permissions (denies reads of .env*)
.cursor/
├── rules/                 Thin Cursor sticky mode router
└── skills/                Optional framework-specific Cursor skills
.codex/
├── config.toml            Codex filesystem permissions (denies reads of .env*)
└── rules/                 Codex exec-policy rules
bin/
└── robocollab             Optional PATH command for installer updates and Sonic
sonic/
├── prompts/               Sonic agent instructions
├── viewer/                React/Node project map viewer
└── sonic.sh               Sonic runner for project graph generation and viewing
AGENTS.md                  Always-loaded mode router, inline styleguide, git summary
CLAUDE.md                  Imports AGENTS.md for Claude Code
.cursorignore              Blocks Cursor from reading .env* files
.gitignore                 Base ignores for RoboCollab's own artifacts
```

## Rules

Each runtime picks up the same sticky router, inline COLLAB rules, and lazy DEV/FOLLOWUP mode files:

- **Claude Code** reads `CLAUDE.md`, which imports `AGENTS.md`. Agents read a file from `.ai/modes/` only after the router selects DEV or FOLLOWUP.
- **Cursor** reads `AGENTS.md` plus a thin `alwaysApply: true` router under `.cursor/rules/`. DEV and FOLLOWUP still live in `.ai/modes/` and are read only when active. When installed, Cursor skills under `.cursor/skills/` hold framework-specific conventions such as React props typing.
- **Codex** reads `AGENTS.md`, including its inline styleguide. Codex discovers installed repo-scoped skills from `.agents/skills/`, applies `.codex/config.toml` for project-scoped filesystem permissions, and enforces `.codex/rules/git.rules` for command-level approval decisions outside the sandbox (allowing `.ai/scripts/git.sh` and read-only `rtk git`, blocking raw or `rtk`-wrapped mutating git/PR commands covered by the wrapper, and prompting for everything else).
- **Any other agent** that reads `AGENTS.md` gets the mode router, COLLAB rules, styleguide, and git summary. For DEV or FOLLOWUP detail, it should read the active file in `.ai/modes/` when the router selects one of those modes.

`AGENTS.md` is the source of truth for COLLAB behavior.
The `.ai/modes/` files are the source of truth for DEV and FOLLOWUP behavior.
The `.ai/workflows/` files are the source of truth for reusable workflow policies like git.

## Scripts

All scripts live in `.ai/scripts/`. `.ai/scripts/git.sh` is the canonical entrypoint and wraps the git operations that have guardrails worth enforcing (no commits on `main`/`develop`, recorded base branch for PRs, etc.).

| Script | Purpose |
|---|---|
| `git.sh start` | Check readiness for a new plan and record the base branch |
| `git.sh branch <name>` | Create and switch to a feature branch |
| `git.sh commit "message"` | Stage all changes and commit |
| `git.sh push` | Push the current branch to `origin` |
| `git.sh pr <gh pr create args>` | Push and open a PR against the recorded base branch |

Read-only git (`status`, `diff`, `log`, `rev-parse`, etc.) is still fine where the active mode permits git; run raw shell commands through `rtk`.

`robotnik <request>` is installed as an external tool by `install.sh` from [`walrusk/robotnik`](https://github.com/walrusk/robotnik)'s `bash/install.sh`, rather than vendored in `.ai/scripts/`.

## Sonic

Sonic is an early RoboCollab tool for generating and viewing a project overview graph. Run `robocollab` from a project directory and choose the Sonic option, or run `robocollab sonic` directly. The command downloads the latest Sonic bundle, then uses the user's existing Claude Code or Codex CLI subscription to inspect the project in read-only mode.

Sonic runs the selected agent CLI with its highest available effort setting by default: Codex uses `model_reasoning_effort="xhigh"` and Claude Code uses `--effort max`.

Sonic writes `.sonic/project-map.json` by default. The JSON stays close to the agent's canonical graph output: `nodes` describe major purpose-level modules with representative files, inputs, outputs, and technologies; `edges` describe the most important runtime, user-flow, data-flow, deployment, or ownership relationships between them. The viewer may add a `view.positions` object to the same file so `@xyflow/react` can persist manually adjusted node positions without mixing renderer-specific fields into the module records.

Run `robocollab view` or `./sonic/sonic.sh view` to start the prototype browser viewer. It runs the contained React/Node project in `sonic/viewer/`, serves the JSON store through a small Express API, and opens the local viewer URL. Useful options:

```bash
robocollab view --data .sonic/project-map.json --port 5177
./sonic/sonic.sh view --no-open
```

## Sensitive files

RoboCollab uses defense-in-depth for `.env`, `.env.*`, and `.envrc`:

- `.cursorignore` hard-blocks Cursor;
- `.claude/settings.json` adds matching `permissions.deny` entries for Claude Code.
- `.codex/config.toml` sets project-scoped Codex filesystem permissions that deny reads for matching files once the project `.codex/` layer is trusted.

If you use other agent runtimes (Gemini Code Assist, JetBrains AI, Codeium, Continue, etc.), add their equivalent ignore file with the same patterns.
