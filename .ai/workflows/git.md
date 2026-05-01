# Git Workflow

These rules apply only when the active mode asks you to run git. This is a workflow policy, not a mode.

## Contract

1. Use `.ai/scripts/git.sh` directly for covered workflow actions: `start`, `branch`, `commit`, `push`, and `pr`.
2. Do not run the raw commands that wrapper replaces: `git add`, `git commit`, `git push`, `git checkout -b`, or `gh pr create`.
3. Raw read-only inspection is fine, e.g. `git status`, `git diff`, `git log`, `git rev-parse`, `git show`, `git branch --show-current`, and `git branch --list`.
4. Prefix raw shell commands with `rtk`, including raw read-only git and `gh` commands. Do not prefix `.ai/scripts/git.sh`; it already uses `rtk` internally.
5. Never force push, reset, rebase, amend, skip hooks, or edit git config unless the user explicitly asks.
6. If a needed git operation is not covered by the wrapper and is not read-only, ask the user before running it.

## Wrapper

```bash
.ai/scripts/git.sh start
.ai/scripts/git.sh branch <branch-name>
.ai/scripts/git.sh commit "commit message"
.ai/scripts/git.sh push
.ai/scripts/git.sh pr <gh pr create args>
```

Use the canonical `.ai/scripts/git.sh` entrypoint for covered workflow actions.

If the wrapper refuses to commit, push, or open a PR on `main`/`develop`, do not work around it with raw git. If `pr` reports a missing base-branch file, run `start` first.

When outside-sandbox approval is needed, request the `.ai/scripts/git.sh` prefix rule so one approval covers the wrapper workflow.
