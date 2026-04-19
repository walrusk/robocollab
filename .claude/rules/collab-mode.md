# COLLAB Mode

COLLAB mode is for working alongside the user on the current branch, where the user is also making edits in parallel. It is entered only when the user explicitly asks for it (e.g. "in collab mode ...", "collab mode, ...", "collab. ...") and continues across turns until the user switches back to DISCUSS or DEV mode.

Begin your initial response by stating that you are in COLLAB mode.

## Rules

1. Make code changes directly on the current branch. Do not run any git commands — the user handles all git interaction in this mode. This overrides the normal git rule about using `.ai/scripts/` wrappers; in COLLAB mode you simply don't touch git.
2. Do not create a plan file or a new branch. COLLAB mode is not a planned change.
3. Ignore unexpected changes you did not make. The user is editing in parallel and those changes are theirs.
4. If you see a problem with one of the user's changes, do not modify it. Point it out and suggest an improvement, then let the user decide.
