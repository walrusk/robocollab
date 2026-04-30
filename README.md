# RoboCollab

A structured workflow for collaborating with AI coding agents. It defines a small sticky mode router, lazy-loaded mode instructions, lazy-loaded workflow policies, and wrapper scripts for the parts of git that have footguns — so you get a repeatable, predictable process for planning, executing, and reviewing changes with an agent without loading every workflow into context up front.

RoboCollab is runtime-agnostic: it ships a universal `AGENTS.md` and top-level `STYLEGUIDE.md` that any agent that respects those conventions can read, plus thin runtime adapters for Claude Code, Cursor, and Codex.

## Install

Download `install.sh` into the root of your repo and run it:

```bash
curl -fsSL https://raw.githubusercontent.com/walrusk/robocollab/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

The script announces exactly what it will do and prompts before making changes. It:

- copies `.ai/scripts/`, `.ai/modes/`, `.ai/workflows/`, `.ai/plans/`, `.cursor/rules/`, `.cursor/skills/`, and `.codex/` into your repo (overwriting matching files);
- line-merges `.gitignore` and `.cursorignore` (skipping duplicates);
- prompts before overwriting an existing `AGENTS.md`, `STYLEGUIDE.md`, `CLAUDE.md`, or `.claude/settings.json`.

After it finishes you can delete `install.sh`.

## How it works

Agents operate in one of four sticky modes. **DISCUSS** is the default; the others are triggered by a short phrase at the start of your instruction (or entered automatically). Once a mode is active, it remains active as conversation state until you switch modes again.

### DISCUSS — default

Read-only. The agent discusses prospective changes but does not edit code or run mutating commands. Switches to DEV or COLLAB only when you explicitly ask.

### DEV — planned change on a new branch

Trigger with something like `"in dev mode, ..."` or `"dev. ..."`.

The agent will:

1. Run `.ai/scripts/git.sh start` to confirm you're on `main`/`develop` and clean.
2. Draft a plan and present it for review. Iterate until you approve.
3. When you say "proceed", write the plan to `.ai/plans/NNN_description.md`, create a branch via `.ai/scripts/git.sh branch`, implement the change, commit, and open a PR.

After the PR is opened, the agent auto-switches to FOLLOWUP.

### FOLLOWUP — iterate on an open PR

Entered automatically at the end of DEV. The agent makes follow-up edits on the same branch, keeps the plan file in `.ai/plans/` in sync, and commits/pushes via the scripts. Refuses to run on `main`/`develop`.

### COLLAB — pair-program on the current branch

Trigger with `"in collab mode, ..."` or `"collab. ..."`.

The agent edits the current branch directly and does not touch git — you handle branches, commits, and pushes. If it notices a problem with something you wrote, it points it out rather than silently changing it.

## Project layout

```
.ai/
├── modes/                 Lazy-loaded mode instructions
├── plans/                 Plan files written during DEV mode
├── scripts/               Canonical git workflow wrapper plus compatibility shims
└── workflows/             Lazy-loaded workflow policies
.claude/
└── settings.json          Claude Code permissions (denies reads of .env*)
.cursor/
├── rules/                 Thin Cursor sticky mode router
└── skills/                Framework-specific Cursor skills
.codex/
├── config.toml            Codex filesystem permissions (denies reads of .env*)
└── rules/                 Codex exec-policy rules
AGENTS.md                  Always-loaded mode router, styleguide reference, git summary
STYLEGUIDE.md              Always-loaded project-neutral code style rules
CLAUDE.md                  Imports AGENTS.md for Claude Code
.cursorignore              Blocks Cursor from reading .env* files
.gitignore                 Base ignores for RoboCollab's own artifacts
```

## Rules

Each runtime picks up the same sticky router and lazy mode files:

- **Claude Code** reads `CLAUDE.md`, which imports `AGENTS.md`. `AGENTS.md` references `STYLEGUIDE.md`; agents read the active mode file from `.ai/modes/` only after the router selects that mode.
- **Cursor** reads `AGENTS.md` plus a thin `alwaysApply: true` router under `.cursor/rules/`. The detailed mode bodies still live in `.ai/modes/` and are read only when active. Cursor skills under `.cursor/skills/` hold framework-specific conventions such as React props typing.
- **Codex** reads `AGENTS.md` and `STYLEGUIDE.md` for prose rules, applies `.codex/config.toml` for project-scoped filesystem permissions, and enforces `.codex/rules/git.rules` for command-level approval decisions outside the sandbox (allowing `.ai/scripts/git.sh` and read-only git, blocking legacy shim escalation plus raw `git add`/`commit`/`push`/`checkout -b` and `gh pr create`, and prompting for everything else).
- **Any other agent** that reads `AGENTS.md` gets the mode router, styleguide reference, and git summary. For full detail it should read `STYLEGUIDE.md` and the active file in `.ai/modes/` when the router selects a mode.

The `.ai/modes/` files are the source of truth for detailed mode behavior.
The `.ai/workflows/` files are the source of truth for reusable workflow policies like git.

## Scripts

All scripts live in `.ai/scripts/`. `.ai/scripts/git.sh` is the canonical entrypoint and wraps the git operations that have guardrails worth enforcing (no commits on `main`/`develop`, recorded base branch for PRs, etc.). The older per-action scripts remain as compatibility shims that forward to `git.sh`.

| Script | Purpose |
|---|---|
| `git.sh start` | Check readiness for a new plan and record the base branch |
| `git.sh branch <name>` | Create and switch to a feature branch |
| `git.sh commit "message"` | Stage all changes and commit |
| `git.sh push` | Push the current branch to `origin` |
| `git.sh pr <gh pr create args>` | Push and open a PR against the recorded base branch |

Read-only git (`status`, `diff`, `log`, `rev-parse`, etc.) is still fine to use directly.

## Sensitive files

RoboCollab uses defense-in-depth for `.env`, `.env.*`, and `.envrc`:

- `.cursorignore` hard-blocks Cursor;
- `.claude/settings.json` adds matching `permissions.deny` entries for Claude Code.
- `.codex/config.toml` sets project-scoped Codex filesystem permissions that deny reads for matching files once the project `.codex/` layer is trusted.

If you use other agent runtimes (Gemini Code Assist, JetBrains AI, Codeium, Continue, etc.), add their equivalent ignore file with the same patterns.
