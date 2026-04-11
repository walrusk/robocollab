# RoboCollab

A structured workflow for collaborating with AI coding agents in Cursor. It provides a set of commands, rules, and scripts that give you a repeatable process for planning, executing, and reviewing code changes with an agent.

## How It Works

By default the agent will only discuss — it won't make code changes until you invoke a command. There are three workflows:

### `/dev` — Plan and execute a change

Use this when starting new work. The agent will:

1. Check that you're on `main` or `develop` and ready for a new branch.
2. Create a plan and present it for your review.
3. Wait for you to say **"proceed"** before writing any code.
4. Create a plan file in `.ai/plans/`, branch off, implement the change, and open a PR.

### `/followup` — Iterate on an open PR

Use this when you want to make additional changes to an in-progress feature branch. The agent will make the changes, keep the plan file in sync, commit, and push.

### `/collab` — Pair-program

Use this when you want to work on the same branch together. The agent makes code changes directly and you handle git. If the agent notices a problem with something you wrote, it will mention it rather than silently changing it.

## Project Structure

```
.ai/
├── plans/              # Plan files created during /dev workflows
└── scripts/            # Git operation scripts (branch, commit, push, pr)
.cursor/
├── commands/           # Cursor slash commands (/dev, /followup, /collab)
└── rules/              # Always-on rules (git policy, styleguide, project conventions)
```

## Rules

Rules in `.cursor/rules/` are automatically applied to every agent conversation:

- **git** — All git operations must go through `.ai/scripts/`. No raw git commands.
- **styleguide** — Coding conventions (component props, directory structure, UI patterns).
- **project** — General project context (repo structure, skill usage).

## Scripts

The scripts in `.ai/scripts/` manage the git lifecycle. They include safety checks (e.g. refusing to commit on `main` or `develop`).

| Script | Purpose |
|---|---|
| `start.sh` | Check readiness for a new plan |
| `branch.sh {name}` | Create a feature branch |
| `commit.sh "message"` | Stage all changes and commit |
| `push.sh` | Push the current branch |
| `pr.sh <args>` | Push and open a PR (wraps `gh pr create`) |
