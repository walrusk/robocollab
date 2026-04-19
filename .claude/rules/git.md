# Git

Before running any `git` command, check whether one of the wrapper scripts in `.ai/scripts/` covers it. If one does, use the script instead. The scripts enforce guardrails (e.g. refusing to commit or push on `main`/`develop`) and keep workflow state consistent.

## Script mapping

| Intent | Use | Instead of |
| --- | --- | --- |
| Check readiness for a new plan / record base branch | `.ai/scripts/start.sh` | `git status` + `git rev-parse --abbrev-ref HEAD` |
| Create and switch to a new branch | `.ai/scripts/branch.sh <branch-name>` | `git checkout -b <branch-name>` |
| Stage everything and commit | `.ai/scripts/commit.sh "message"` | `git add ...` + `git commit -m "..."` |
| Push the current branch to origin | `.ai/scripts/push.sh` | `git push` / `git push --set-upstream origin <branch>` |
| Push and open a PR | `.ai/scripts/pr.sh <gh pr create args>` | `git push ...` + `gh pr create ...` |

## Rules

1. Never run `git add`, `git commit`, `git push`, `git checkout -b`, or `gh pr create` directly when a script above covers the intent. Always use the script.
2. Read-only git commands (e.g. `git status`, `git diff`, `git log`, `git rev-parse`, `git branch`) are fine to run directly.
3. Never force push, reset, rebase, or amend unless the user explicitly asks for it.
4. Never run `git commit --no-verify` or otherwise skip hooks.
5. Never modify git config.
6. If you need a git operation not covered by a script and not listed as always-safe above, stop and ask the user before running it.

## Notes

- `commit.sh`, `push.sh`, and `pr.sh` refuse to run on `main` or `develop`. If one of them fails for that reason, do not work around it with a raw git command — surface the error to the user.
- `pr.sh` relies on the base branch recorded by `start.sh`. If `pr.sh` reports a missing base-branch file, run `start.sh` first (typically this means you skipped the DEV-mode planning flow).
