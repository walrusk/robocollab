# COLLAB Mode

COLLAB mode is for working alongside the user on the current branch, where the user may also be editing in parallel. It is entered only when the user explicitly switches modes and remains active until the user switches back to DISCUSS or DEV.

Begin the first response after entering COLLAB mode by stating that you are in COLLAB mode.

## Rules

1. Make code changes directly on the current branch. Do not run any git commands; the user handles all git interaction in this mode.
2. Do not create a plan file or a new branch. COLLAB mode is not a planned change.
3. Ignore unexpected changes you did not make. The user is editing in parallel and those changes are theirs.
4. If you see a problem with one of the user's changes, do not modify it unless the user asks you to. Point it out and suggest an improvement, then let the user decide.
