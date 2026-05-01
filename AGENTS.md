# Agents

This file is the always-loaded entry point for agent behavior in this project. Keep it compact: it defines the sticky mode router, references the always-loaded styleguide, and gives a short git summary. Detailed mode instructions live in `.ai/modes/`; workflow policies live in `.ai/workflows/`. Read those files only when they apply.

## Mode router

You are always in exactly one mode. Treat the current mode as conversation state: once a mode is active, the user does not need to repeat it on every prompt.

1. The default mode for a fresh session is DISCUSS.
2. Switch modes only when the newest user message begins with a trigger: one of `discuss`, `collab`, `dev`, or `followup`, immediately followed by `.` or ` mode,`, or wrapped as `in <mode> mode`.
3. When a trigger appears, switch modes before interpreting the rest of the user message as work for that mode.
4. DISCUSS, COLLAB, and FOLLOWUP are sticky. Stay in the active mode until the user explicitly switches modes.
5. DEV is sticky until the initial planned change has been executed and the pull request has been opened. After the PR is opened successfully, automatically switch to FOLLOWUP.
6. When entering a mode, read only that mode's file from `.ai/modes/`:
   - DISCUSS: `.ai/modes/discuss.md`
   - COLLAB: `.ai/modes/collab.md`
   - DEV: `.ai/modes/dev.md`
   - FOLLOWUP: `.ai/modes/followup.md`
7. Do not read inactive mode files. Read `.ai/workflows/git.md` only when the active task requires git workflow details.
8. After context compaction within a session, preserve the current mode and re-read the active mode file if it is no longer in context.

## Available modes

- **DISCUSS** (default) - no code changes; discuss and refine prospective work.
- **COLLAB** - live edits on the current branch while the user also edits in parallel; user handles git.
- **DEV** - planned change on a new branch, ending in a PR.
- **FOLLOWUP** - additional changes on an active plan branch after the DEV PR is open. Entered automatically from DEV.

## Styleguide

Read and follow @STYLEGUIDE.md as part of the always-loaded project instructions.

## Git

Summary: when the active mode permits git, use `.ai/scripts/git.sh <action>` (`start`, `branch`, `commit`, `push`, `pr`) for any operation it covers. Read-only git is fine via `rtk git` where the active mode allows it. Never force push, reset, rebase, amend, skip hooks, or edit git config without an explicit user request.
