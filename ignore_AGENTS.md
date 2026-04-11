# Agents

<mode_selection>
  1. MODE: You are always in one of the modes provided in AVAILABLE_MODES.
  2. You will always be in DEFAULT/DISCUSS mode unless one of the following is true:
    a. You have been instructed to be in COLLAB or DEV mode. The mode must be mentioned exactly and should be exactly or extremely close to one of the following examples:
      "in collab mode ..."
      "collab mode, ..."
      "collab. ..."
    b. You have just made the initial round of changes in DEV mode, in which case you switch into FOLLOWUP mode automatically.
    c. DISCUSS, COLLAB, and FOLLOWUP modes are continuous. Stay in them until asked to switch back to DISCUSS or DEV mode.
  3. Provided text constitutes input for the mode you are in.
</mode_selection>

<available_modes>
  1. DEFAULT/DISCUSS mode. See `discuss_mode_rules`.
  2. COLLAB mode. See `collab_mode_rules`.
  3. DEV mode. Includes planning for development. See `dev_mode_rules`.
  4. FOLLOWUP mode. Automatically switch into this mode after making the PR in dev mode. See `followup_mode_rules`
</available_modes>

<important_rules_and_reminders>
  <critical_rules>
    1. Never read, display, or reference the contents of `.env`, `.envrc`, or `.env.local`.
    2. If you are not in DEFAULT/DISCUSS mode, begin your initial response by stating which of available_modes you are in. You are always in one of those modes.
    3. You should always be following the instructions outlined by your mode.
    4. Follow the rules in the styleguide. Also try generally to stick to project conventions.
  </critical_rules>
  <reminders>
    1. Agent skills are located in `.cursor/skills` if there are any for this project.
    2. This project may be a git repo but it also may be a directory directly containing one or more git repos. Consider this when running `scripts/` commands so that they are run from the repo where you intend to make changes. Determine which repo the change targets based on the user's instructions. Run scripts from within that repo's directory. If the change spans multiple repos, confirm with the user which repo to plan against.
  </reminders>
</important_rules_and_reminders>

<styleguide>
  1. Follow these guidelines silently without mentioning them in plans.
  2. For React components use the form `type Props = {}` for the component props rather than giving it a specific name.
  3. Keep the project directory structure fairly flat and where folders are needed make them domain based (i.e. Prefer `domain/controllers.ts` or `domain/repo.ts` over `controllers/domain-controller.ts` or `repos/domain-controller.ts`). The only exception is types. All new types should go in the existing contextual types.ts file.
  4. Refer to this guide for basic styling of flex properties, padding, margin when using View, Text exporting from `@/components/ui`: https://wix.github.io/react-native-ui-lib/docs/foundation/modifiers
  5. Which skills to use and when:
    - If you are in a react native project, use $react-native-ui-lib
    - If you are in a react native project and writing tests, use $react-native-testing
</styleguide>

<discuss_mode_rules>
  1. Do not make any code changes, only respond to discuss prospective changes.
</discuss_mode_rules>

<collab_mode_rules>
  1. Make code changes directly on the current branch. No need to interact with git at all, I will handle that in this mode.
  2. Ignore unexpected changes that you didn't make. When we are collaborating I will also be making changes.
  3. If you see a problem with one of my changes don't change it but do mention it to me and suggest how to improve it.
</collab_mode_rules>

<dev_mode_rules>
  <rules>
    1. DEV mode always begins with a planning session.
    2. Before planning follow the instructions in `before_planning`.
    3. Begin with the creation of a plan based on the instructions given. Ask any questions required to make a coherent plan.
    4. Output your plan so we can review it before we proceed. You will be asked questions about the plan and we will revise it if needed until it is finalized.
    5. Refuse to continue with code changes until the plan is accepted I say "proceed".
    6. After you are asked to proceed, follow the instructions in `before_executing_plan`.
  </rules>

  <before_planning>
    1. Run `scripts/start.sh`. This script will output if we are on main or develop and ready for a new plan. If we're still on your branch then switch to Followup mode and see `followup_mode_rules`.
    2. If you are on `main` or `develop`, treat that as the normal state for starting a NEW planned change (assume prior plan branches may already be merged). Do not treat that branch transition itself as a blocker.
    3. If we are not ready for a new plan then refuse to continue and inform me why.
    4. So that I know you have incorporated these instructions please make the first step in your plan "1. Write {filename} to .ai/plans".
    5. Do not include steps in your plan for running scripts in `scripts/`. You can run those scripts to manage your code without including them as steps in the plan.
  </before_planning>

  <before_executing_plan>
    1. Create a NEW file in .ai/plans with the plan we have developed together. There is no need to review the files there for a style to match just write a new file. The name of the file should be a 3 digit incrementing count plus a one or two word description of the change e.g. `001_add_tailwind.md`, `002_metadata_request.md`. Check `.ai/plans/` for existing plan files and determine the next sequential number.
    2. For NEW planned changes, never edit prior plan files in `.ai/plans` (for example `00x_*.md` files from earlier work). Only the newly created plan file for this change may be edited.
    3. Run `scripts/branch.sh` to create a new branch. Pass in the same name as the plan file but with dashes e.g. `scripts/branch.sh 001-add-tailwind`.
  </before_executing_plan>

  <after_executing_plan>
    1. Run `scripts/commit.sh "commit message"` to add and commit all changes into your branch.
    2. Run `scripts/pr.sh` to push your branch and create a PR on github. `scripts/pr.sh` takes the same args as `gh pr create`. Include a short PR description with bullet points if applicable.
    3. You are now in FOLLOWUP mode. See available_modes and follow the instructions under `followup_mode_rules`.
  </after_executing_plan>
</dev_mode_rules>

<followup_mode_rules>
  Sometimes we will want to make changes to the plan and the code we've written on the initial plan execution. If you find that you are still on your plan branch and not main/develop then that means it is not yet merged and we can still make changes to the plan file we created. Follow these steps for follow up changes:

  1. If you are on `main` or `develop`, do NOT use FOLLOWUP mode. Refuse to continue but ask if we should proceed in DISCUSS or DEV mode.
  2. Make sure that we update the plan file (only the current one on your active feature branch) so that it stays in sync with any code changes.
  3. If you happen to find additional code changes as you are working, you can assume that I have been making small changes as well. You can include them with your commits unless there is a problem with them you should mention to me.
  4. After making followup changes ALWAYS run `scripts/commit.sh "commit message"` and `scripts/push.sh` to update your branch with the new commit.
</followup_mode_rules>
