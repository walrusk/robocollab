# DEV Mode

DEV mode is for making planned changes on a new branch, ending in a PR. DEV starts with a planning session and remains active until the initial changes have been committed and the PR has been opened. After that, automatically switch to FOLLOWUP.

Begin the first response after entering DEV mode by stating that you are in DEV mode.

## Flow

1. Before planning, run the checks in **Before planning**.
2. Produce a plan based on the user's instructions. Ask any questions needed to make it coherent.
3. Output the plan for review. Revise it based on feedback until it is finalized.
4. When the user asks you to proceed, follow **Before executing the plan**, then execute.
5. After executing, follow **After executing the plan**.

## Before planning

1. Run `.ai/scripts/git.sh start`. It reports whether we are on `main`/`develop` with a clean working tree and ready for a new plan.
2. If you are on `main` or `develop`, treat that as the normal state for starting a new planned change. Do not treat that branch state itself as a blocker.
3. If we are not ready for a new plan, refuse to continue and explain why.
4. Do not include `.ai/scripts/git.sh` invocations as plan steps. You may still run that script yourself to manage the workflow.

## Before executing the plan

1. Create a new file in `.ai/plans` containing the finalized plan. Do not review existing plan files for style; just write a new one. Name it with a 3-digit incrementing count plus a one or two word description, e.g. `001_add_tailwind.md`, `002_metadata_request.md`. Check `.ai/plans/` to determine the next sequential number.
2. For new planned changes, never edit prior plan files in `.ai/plans` (e.g. earlier `00x_*.md` files). Only the newly created plan file for this change may be edited.
3. Run `.ai/scripts/git.sh branch <name>` to create a new branch. Use the plan filename with dashes instead of underscores, e.g. `.ai/scripts/git.sh branch 001-add-tailwind`.

## After executing the plan

1. Run `.ai/scripts/git.sh commit "commit message"` to add and commit all changes on your branch.
2. Run `.ai/scripts/git.sh pr <gh pr create args>` to push the branch and open a PR. It takes the same args as `gh pr create`. Include a short PR description with bullet points if applicable.
3. Do not ask the user whether you should create the PR. Opening the PR is part of the standard DEV mode flow, so do it automatically unless the user explicitly tells you not to open one.
4. After the PR opens successfully, set the conversation mode to FOLLOWUP and follow the FOLLOWUP mode rules from here on.
