# Git

Two layered rules apply to every git-related action:

1. **Prefix raw shell commands with `rtk`.** `rtk` is a token-optimized CLI proxy. Use it for every raw command you run, including `git`, `gh`, and any other tool (e.g. `npm`, `pytest`). Do **not** add `rtk` in front of `.ai/scripts/git.sh` or the legacy compatibility shims — they already call `rtk git` / `rtk gh` internally.
2. **Prefer the single `.ai/scripts/git.sh` wrapper over raw git.** It centralizes the repo guardrails (e.g. refusing to commit or push on `main`/`develop`) and keeps workflow state consistent. The legacy per-action scripts remain only as compatibility shims. Raw git is acceptable only for read-only inspection.

## Script mapping

Before running any git command, check whether `.ai/scripts/git.sh` covers your intent. If it does, use that script as-is (no `rtk` prefix).

| Intent | Use | Instead of |
| --- | --- | --- |
| Check readiness for a new plan / record base branch | `.ai/scripts/git.sh start` | `rtk git status` + `rtk git rev-parse --abbrev-ref HEAD` |
| Create and switch to a new branch | `.ai/scripts/git.sh branch <branch-name>` | `rtk git checkout -b <branch-name>` |
| Stage everything and commit | `.ai/scripts/git.sh commit "message"` | `rtk git add ...` + `rtk git commit -m "..."` |
| Push the current branch to origin | `.ai/scripts/git.sh push` | `rtk git push` / `rtk git push --set-upstream origin <branch>` |
| Push and open a PR | `.ai/scripts/git.sh pr <gh pr create args>` | `rtk git push ...` + `rtk gh pr create ...` |

## Rules

1. Prefix raw shell commands with `rtk` (git, gh, other tools). Do not prefix `.ai/scripts/git.sh` or the legacy compatibility shims — they call `rtk` internally.
2. Never run `git add`, `git commit`, `git push`, `git checkout -b`, or `gh pr create` directly when `.ai/scripts/git.sh` covers the intent. Always use that script.
3. If a `.ai/scripts/git.sh` invocation needs to run outside the sandbox, request approval with the exact `.ai/scripts/git.sh` prefix rule. In tool terms, prefer `prefix_rule=[".ai/scripts/git.sh"]` so one approval covers all supported subcommands.
4. Read-only git commands (e.g. `git status`, `git diff`, `git log`, `git rev-parse`, `git branch`) are fine to run directly — still via `rtk`, e.g. `rtk git status`.
5. Never force push, reset, rebase, or amend unless the user explicitly asks for it.
6. Never run `git commit --no-verify` or otherwise skip hooks.
7. Never modify git config.
8. If you need a git operation not covered by a script and not listed as always-safe above, stop and ask the user before running it.

## rtk meta commands

`rtk` also exposes its own commands for analytics and escape hatches:

```bash
rtk gain            # Token savings analytics
rtk gain --history  # Recent command savings history
rtk proxy <cmd>     # Run raw command without filtering
```

Use `rtk proxy <cmd>` only when you specifically need the unfiltered output of a command — otherwise always use the plain `rtk <cmd>` form.

## Verification

To confirm `rtk` is installed and available:

```bash
rtk --version
rtk gain
which rtk
```

## Notes

- `.ai/scripts/git.sh commit`, `push`, and `pr` refuse to run on `main` or `develop`. If one of them fails for that reason, do not work around it with a raw git command — surface the error to the user.
- The legacy `start.sh`, `branch.sh`, `commit.sh`, `push.sh`, and `pr.sh` scripts now forward to `.ai/scripts/git.sh`. Keep them only for backwards compatibility; new instructions should use the single entrypoint.
- `.ai/scripts/git.sh pr` relies on the base branch recorded by `.ai/scripts/git.sh start` (which is itself wrapped by `rtk git`). If `pr` reports a missing base-branch file, run `start` first (typically this means you skipped the DEV-mode planning flow).
