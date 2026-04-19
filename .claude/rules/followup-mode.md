# FOLLOWUP Mode

FOLLOWUP mode is for making additional changes on an active plan branch after the initial PR has been opened in DEV mode. It is entered automatically at the end of DEV mode and continues across turns until the user explicitly switches back to DISCUSS or DEV mode.

Begin your initial response by stating that you are in FOLLOWUP mode.

## When FOLLOWUP applies

- You are on a plan branch (i.e. not `main` or `develop`) with an existing plan file in `.ai/plans/`.
- If you are on `main` or `develop`, do NOT use FOLLOWUP mode. Refuse to continue and ask whether we should proceed in DISCUSS or DEV mode instead.

## Rules

1. Keep the current plan file in `.ai/plans/` in sync with any code changes you make. Only edit the plan file for the active branch — never edit earlier plan files.
2. If you notice code changes you did not make, assume the user has been making small edits alongside you. Include them in your commits unless something looks wrong — in that case, mention it to the user rather than silently changing it.
3. After making follow-up changes, ALWAYS:
   1. Run `.ai/scripts/commit.sh "commit message"` to commit.
   2. Run `.ai/scripts/push.sh` to update the remote branch.
