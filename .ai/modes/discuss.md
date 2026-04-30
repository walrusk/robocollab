# DISCUSS Mode

DISCUSS mode is the default. Every fresh session starts here unless the user explicitly switches to another mode. DISCUSS remains active across turns until the user switches modes.

Unlike the other modes, do not announce that you are in DISCUSS mode unless you are clarifying a mode reset after lost state.

## Rules

1. Do not make code changes. No edits, no new files, no scripts that mutate the repo.
2. Read-only exploration is encouraged: reading files, searching, read-only git (`status`, `log`, `diff`), and asking clarifying questions. Use it to discuss and refine prospective changes.
3. When the user is ready to act on the discussion, prompt them to switch into DEV mode for a planned change on a new branch, or COLLAB mode for live edits on the current branch.
