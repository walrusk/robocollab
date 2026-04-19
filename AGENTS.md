# Agents

This file is the entry point for agent behavior in this project. It defines how you pick a working mode, the rules that always apply, the project styleguide, and how to interact with git. Each mode has its own rule file, imported below.

## Mode selection

You are always in exactly one mode. The default is DISCUSS. You leave DISCUSS only under the conditions in the rules below.

1. You will be in DISCUSS mode unless one of the following is true:
   1. The user explicitly asks for COLLAB or DEV mode. The mode must be named exactly, and the phrasing should match or be very close to one of:
      - `"in collab mode ..."`
      - `"collab mode, ..."`
      - `"collab. ..."`
      (same shape applies to `dev`).
   2. You have just finished the initial round of changes in DEV mode — you then auto-switch into FOLLOWUP mode.
2. DISCUSS, COLLAB, and FOLLOWUP modes are continuous. Stay in them across turns until the user switches you back to DISCUSS or DEV.
3. User-provided text is input for the mode you are currently in. Do not switch modes on implicit cues — only on the conditions above.

## Available modes

- **DISCUSS** (default) — no code changes; discuss and refine prospective work. See @.claude/rules/discuss-mode.md.
- **COLLAB** — live edits on the current branch while the user also edits in parallel; user handles git. See @.claude/rules/collab-mode.md.
- **DEV** — planned change on a new branch, ending in a PR. See @.claude/rules/dev-mode.md.
- **FOLLOWUP** — additional changes on an active plan branch after the DEV PR is open. Entered automatically from DEV. See @.claude/rules/followup-mode.md.

## Important rules and reminders

### Critical rules

1. Never read, display, or reference the contents of `.env`, `.envrc`, or `.env.local`.
2. If you are not in DISCUSS mode, begin your initial response by stating which mode you are in. You are always in exactly one mode from the list above.
3. Always follow the rules of your current mode.
4. Follow the styleguide below. Also stick to existing project conventions where reasonable.

## Styleguide

1. Follow these guidelines silently. Do not mention them in plans.
2. Write code that is elegant and optimized for readability and maintainability.
3. Avoid tiny wrapping functions unless they are genuinely reusable.
4. For React components, use `type Props = {}` for props rather than giving the type a component-specific name.
5. Keep the directory structure fairly flat. Where folders are needed, make them domain-based (prefer `domain/controllers.ts` or `domain/repo.ts` over `controllers/domain-controller.ts` or `repos/domain-controller.ts`). The one exception is types: new types go in the existing contextual `types.ts` file.
6. For flex / padding / margin styling on `View` and `Text` from `@/components/ui`, follow the modifier guide at https://wix.github.io/react-native-ui-lib/docs/foundation/modifiers.

## Git

See @.claude/rules/git.md for the full rules. Summary: prefer `.ai/scripts/` wrappers (`start.sh`, `branch.sh`, `commit.sh`, `push.sh`, `pr.sh`) over raw git for any operation they cover. Read-only git is fine. Never force push, reset, rebase, amend, skip hooks, or edit git config without an explicit user request.
