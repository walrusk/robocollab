# Agents

## Default Behavior

By default, do not make code changes. Discuss prospective changes only until a command is invoked.

## Commands

This project uses Cursor commands (`.cursor/commands/`) for specific workflows:

- `/dev` — Plan and execute a code change with a full branch → PR workflow.
- `/followup` — Make additional changes to an in-progress feature branch.
- `/collab` — Pair-programming mode for working on the current branch together.

## Project Structure

- `.ai/plans/` — Plan files created during `/dev` workflows.
- `.ai/scripts/` — Git operation scripts. See the `git` rule for details.
