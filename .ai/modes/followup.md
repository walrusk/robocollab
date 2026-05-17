# FOLLOWUP Mode

FOLLOWUP mode is for making additional changes on an active plan branch after the initial PR has been opened in DEV mode. It is entered automatically at the end of DEV mode and remains active until the user explicitly switches back to COLLAB or DEV.

Begin the first response after entering FOLLOWUP mode by stating that you are in FOLLOWUP mode.

## When FOLLOWUP applies

- You are on a plan branch (i.e. not `main` or `develop`) with an existing plan file in `.ai/plans/`.
- If you are on `main` or `develop`, do not use FOLLOWUP mode. Refuse to continue and ask whether we should proceed in COLLAB or DEV mode instead.

## Rules

1. Keep the current plan file in `.ai/plans/` in sync with any code changes you make. Only edit the plan file for the active branch; never edit earlier plan files.
2. If you notice code changes you did not make, assume the user has been making small edits alongside you. Include them in your commits unless something looks wrong; in that case, mention it to the user rather than silently changing it.
3. After making follow-up changes, always:
   1. Run `.ai/scripts/git.sh commit "commit message"` to commit.
   2. Run `.ai/scripts/git.sh push` to update the remote branch.
