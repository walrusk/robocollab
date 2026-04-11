# Dev Mode

You are now in dev mode. This is a structured workflow for planning and executing a code change. Follow the phases below in order.

## Phase 1: Pre-Planning

1. Run `.ai/scripts/start.sh` to check readiness.
   - If the output says "ready for new plan", continue to Phase 2.
   - If the script fails (we are on a feature branch), stop and tell me. Ask if I want to use `/followup` instead.
2. This project may contain multiple git repos. Determine which repo the change targets based on my instructions. Run scripts from within that repo's directory. If the change spans multiple repos, ask me which one to plan against.

## Phase 2: Planning

1. Based on my instructions, create a plan. Ask any clarifying questions needed to make a coherent plan.
2. The first step of the plan must be: "Write {filename} to `.ai/plans`".
3. Do not include steps for running any `.ai/scripts/` commands. You will run those behind the scenes as needed.
4. Present the plan for my review. I may ask questions or request revisions.
5. Do NOT proceed with any code changes until I say "proceed".

## Phase 3: Execution Setup

Once I say "proceed":

1. Check `.ai/plans/` for existing plan files. Create a NEW plan file with the next sequential 3-digit number and a one-or-two word description, e.g. `001_add_tailwind.md`, `002_metadata_request.md`.
2. Never edit prior plan files in `.ai/plans/`. Only the newly created plan file for this change may be edited.
3. Run `.ai/scripts/branch.sh {name}` to create a new branch. Use the same name as the plan file but with dashes, e.g. `.ai/scripts/branch.sh 001-add-tailwind`.

## Phase 4: Execute the Plan

Implement the plan step by step.

## Phase 5: Finalize

After completing all implementation:

1. Run `.ai/scripts/commit.sh "commit message"` to stage and commit all changes.
2. Run `.ai/scripts/pr.sh` to push the branch and create a PR on GitHub. `.ai/scripts/pr.sh` accepts the same arguments as `gh pr create`. Include a short PR description with bullet points if applicable.
3. After the PR is created, tell me. From here, any further changes to this branch should use `/followup`.
