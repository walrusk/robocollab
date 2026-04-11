# Followup Mode

You are now in followup mode. We are making additional changes to an in-progress feature branch that already has a PR open.

## Pre-Check

1. Determine the current branch. If we are on `main` or `develop`, stop — the prior work has already been merged. Tell me and ask if I want to use `/dev` for a new change instead.

## Rules

1. Make the requested code changes on the current branch.
2. Update the current plan file in `.ai/plans/` so it stays in sync with any code changes. Only edit the plan file that belongs to this branch — never edit prior plan files.
3. If you find additional code changes you didn't make, assume I made them. Include them in your commit unless you see a problem, in which case mention it to me and suggest how to improve it.

## After Changes

After making changes, always:

1. Run `.ai/scripts/commit.sh "commit message"` to stage and commit.
2. Run `.ai/scripts/push.sh` to push the updated branch.
