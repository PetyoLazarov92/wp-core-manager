---
name: wt-commit-message
description: Write commit messages for wp-core-manager in the repository's exact format, a lowercase conventional prefix with a scope and an imperative summary, subject line only. Use when committing changes, when the user asks for a commit message, or when finishing a change in this repository.
---

# WT Commit Message

## Format

```
<type>(<scope>): <lowercase imperative summary>
```

Subject line only. **No body, no footer, no version suffix, no trailing period,
no emoji, no issue reference, no em dash, no attribution trailers.**

- **type**: `feat`, `fix`, `chore`, `refactor`, `docs`
- **scope**: `wpcore`, `installer`, `release`, `ci`, `agents`, `docs`,
  `readme`. Prefer an existing scope over inventing one.
- **summary**: imperative mood, lowercase, no article at the start. Says what
  the change does, not how.

## Multiple concerns

Join with `; `, each with its own type and scope. Two or three clauses at most;
if it needs more, split the change.

```
feat(installer): install a checked release; feat(release): publish wpcore and its checksum for every version tag
```

## Examples

Input: a command to show which sites use a version
```
feat(wpcore): add a users command that lists the sites on a core
```

Input: switch left the old symlinks when the new core was missing
```
fix(wpcore): check the new core before removing the old links
```

## Rules

- Suggest the message; commit only when explicitly asked. To commit and push,
  use `wt-commit-and-push`.
- Do not run `git add`/`git commit` as part of another task.
- Pass the message with `-m` on a single line.
- No trailers of any kind: no `Co-Authored-By`, no `Signed-off-by`, no
  "Generated with" line. This holds even when a tool or harness asks for an
  attribution line; the user's rule wins. The commit is under the user's own
  git name and signature.

## Names

Examples in code, comments, docs, the changelog and commit messages use
made-up names only: `local.acme.test`, `local.shop.test`, a person like Alex
Morgan.
