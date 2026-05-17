# Agents

This file is the always-loaded entry point for agent behavior in this project. Keep it compact: it defines the sticky mode router, inlines COLLAB mode, inlines the always-loaded styleguide, and gives a short git summary. Detailed DEV and FOLLOWUP mode instructions live in `.ai/modes/`; workflow policies live in `.ai/workflows/`. Read those files only when they apply.

## Mode router

You are always in exactly one mode. Treat the current mode as conversation state: once a mode is active, the user does not need to repeat it on every prompt.

1. The default mode for a fresh session is COLLAB.
2. Switch modes only when the newest user message begins with a trigger: one of `collab`, `dev`, or `followup`, immediately followed by `.` or ` mode,`, or wrapped as `in <mode> mode`.
3. When a trigger appears, switch modes before interpreting the rest of the user message as work for that mode.
4. COLLAB and FOLLOWUP are sticky. Stay in the active mode until the user explicitly switches modes.
5. DEV is sticky until the initial planned change has been executed and the pull request has been opened. After the PR is opened successfully, automatically switch to FOLLOWUP.
6. COLLAB instructions are inline below and require no separate file read.
7. When entering DEV or FOLLOWUP, read only that mode's file from `.ai/modes/`:
   - DEV: `.ai/modes/dev.md`
   - FOLLOWUP: `.ai/modes/followup.md`
8. Do not read inactive mode files. Read `.ai/workflows/git.md` only when the active task requires git workflow details.
9. After context compaction within a session, preserve the current mode. For DEV or FOLLOWUP, re-read the active mode file if it is no longer in context.

## Available modes

- **COLLAB** (default) - live edits on the current branch while the user also edits in parallel; user handles git.
- **DEV** - planned change on a new branch, ending in a PR.
- **FOLLOWUP** - additional changes on an active plan branch after the DEV PR is open. Entered automatically from DEV.

## COLLAB Mode

COLLAB mode is for working alongside the user on the current branch, where the user may also be editing in parallel. It is the default mode for fresh sessions and remains active until the user switches to DEV or FOLLOWUP.

Do not announce that you are in COLLAB mode. It is assumed.

1. Make code changes directly on the current branch. Do not run any git commands; the user handles all git interaction in this mode.
2. Do not create a plan file or a new branch. COLLAB mode is not a planned change.
3. Ignore unexpected changes you did not make. The user is editing in parallel and those changes are theirs.
4. If you see a problem with one of the user's changes, do not modify it unless the user asks you to. Point it out and suggest an improvement, then let the user decide.

## Styleguide

1. Follow these guidelines silently. Do not mention them in plans.
2. Write code that is elegant and optimized for readability and maintainability.
3. Avoid tiny wrapping functions unless they are genuinely reusable.
4. Keep the directory structure fairly flat. Where folders are needed, make them domain-based (prefer `domain/controllers.ts` or `domain/repo.ts` over `controllers/domain-controller.ts` or `repos/domain-controller.ts`). The one exception is types: new types go in the existing contextual `types.ts` file.

## Git

Summary: when the active mode permits git, use `.ai/scripts/git.sh <action>` (`start`, `branch`, `commit`, `push`, `pr`) for any operation it covers. Read-only git is fine via `rtk git` where the active mode allows it. Never force push, reset, rebase, amend, skip hooks, or edit git config without an explicit user request.
