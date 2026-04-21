# Git

Two layered rules apply to every git-related action:

1. **Prefix raw shell commands with `rtk`.** `rtk` is a token-optimized CLI proxy. Use it for every raw command you run, including `git`, `gh`, and any other tool (e.g. `npm`, `pytest`). Do **not** add `rtk` in front of `.ai/scripts/...` invocations — those scripts already call `rtk git` / `rtk gh` internally.
2. **Prefer the `.ai/scripts/` wrappers over raw git.** The scripts enforce guardrails (e.g. refusing to commit or push on `main`/`develop`) and keep workflow state consistent. Raw git is only acceptable for read-only inspection.

## Script mapping

Before running any git command, check whether one of the wrappers covers your intent. If it does, use the script as-is (no `rtk` prefix).

| Intent | Use | Instead of |
| --- | --- | --- |
| Check readiness for a new plan / record base branch | `.ai/scripts/start.sh` | `rtk git status` + `rtk git rev-parse --abbrev-ref HEAD` |
| Create and switch to a new branch | `.ai/scripts/branch.sh <branch-name>` | `rtk git checkout -b <branch-name>` |
| Stage everything and commit | `.ai/scripts/commit.sh "message"` | `rtk git add ...` + `rtk git commit -m "..."` |
| Push the current branch to origin | `.ai/scripts/push.sh` | `rtk git push` / `rtk git push --set-upstream origin <branch>` |
| Push and open a PR | `.ai/scripts/pr.sh <gh pr create args>` | `rtk git push ...` + `rtk gh pr create ...` |

## Rules

1. Prefix raw shell commands with `rtk` (git, gh, other tools). Do not prefix `.ai/scripts/...` invocations — they call `rtk` internally.
2. Never run `git add`, `git commit`, `git push`, `git checkout -b`, or `gh pr create` directly when a wrapper script covers the intent. Always use the script.
3. If a `.ai/scripts/...` invocation needs to run outside the sandbox, request approval with the shared `.ai/scripts` prefix rule rather than a script-specific path such as `.ai/scripts/start.sh`. In tool terms, prefer `prefix_rule=[".ai/scripts"]` so the user can whitelist the whole wrapper directory in one go.
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

- `commit.sh`, `push.sh`, and `pr.sh` refuse to run on `main` or `develop`. If one of them fails for that reason, do not work around it with a raw git command — surface the error to the user.
- `pr.sh` relies on the base branch recorded by `start.sh` (which is itself wrapped by `rtk git`). If `pr.sh` reports a missing base-branch file, run `start.sh` first (typically this means you skipped the DEV-mode planning flow).
