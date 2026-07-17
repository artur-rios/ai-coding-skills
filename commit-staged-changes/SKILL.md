---
name: commit-staged-changes
description: Use when the user wants to commit the already-staged files in a repository with a well-formed message — a lowercase Conventional Commits subject (chore/feat/build/fix/docs) that follows the 50/72 rule (≤50-char subject, blank line, body wrapped at 72, imperative mood). Triggers on "commit the staged changes", "commit staged files", "make a commit", "commit this with a good message".
---

# Commit Staged Changes

## Overview

Commits the **already-staged** changes in a target repository with a message that
follows two hard conventions:

1. **Conventional Commits, all lower case** — a `type: description` subject where
   `type` is chosen from the change (`chore`, `feat`, `build`, `fix`, `docs`, and
   the other standard types below).
2. **The 50/72 rule** — subject ≤ 50 characters, no trailing period, imperative
   mood; a blank second line; body (when present) wrapped at 72 characters.

**Core principle:** commit only what is already staged, and derive the message
from the actual staged diff — never invent a type or scope you did not verify by
reading the changes.

## When to Use

- The user asks to "commit the staged changes / staged files", "make a commit",
  or "commit this with a proper message".
- Files are already staged (`git add` done) and the user wants them committed.

Skip / adapt if:
- **Nothing is staged** — report it and stop; do NOT `git add` on the user's
  behalf unless they explicitly ask you to stage files too.
- The user wants you to stage, amend, push, or open a PR — those are separate
  actions; only do what was asked.

## Do Not Stage — Commit Only What Is Staged

Use `git commit` **without** `-a` and without any `git add`. The whole point is to
capture the user's staged selection exactly. Unstaged and untracked files stay out
of the commit.

## Procedure

Create a todo per step.

### 1. Identify the target repository

Default to the current working directory. If the user names another repo, run the
git commands against it (`git -C <path> …`). Confirm it is a git repo.

### 2. Inspect the staged changes — do not guess

```bash
git -C <repo> diff --cached --stat   # which files, how much changed
git -C <repo> diff --cached          # the actual staged diff
```

If `--stat` is empty, **nothing is staged** — tell the user and stop.

Read the diff enough to answer: what changed, and why does it exist? The message
must describe the staged changes, not assumptions about them.

### 3. Choose the Conventional Commit type

Pick the single best-fitting type from the staged diff (all lower case):

| Type | Use when the staged change… |
|---|---|
| `feat` | adds a new user-facing feature or capability |
| `fix` | fixes a bug or incorrect behavior |
| `docs` | changes only documentation (README, docs/, comments) |
| `build` | changes build system, packaging, or dependencies (csproj, package.json, lockfiles, Dockerfile) |
| `chore` | maintenance that fits nothing above (configs, tooling, housekeeping) |
| `test` | adds or changes tests only |
| `refactor` | restructures code without changing behavior |
| `ci` | changes CI/CD config (`.github/workflows`, pipelines) |
| `perf` | improves performance |
| `style` | formatting/whitespace only, no logic change |

Prefer the four the user emphasized (`chore`, `feat`, `build`, `fix`, `docs`) when
they fit; reach for the others only when clearly more accurate. If the diff spans
several types, pick the type of the **primary** change and describe the rest in the
body. An optional scope is allowed: `type(scope): description`.

### 4. Write the subject line (the 50/72 rule, part 1)

- Format: `type: short summary` (or `type(scope): short summary`).
- **≤ 50 characters total**, including the `type:` prefix.
- **All lower case.** No trailing period.
- **Imperative mood** — "add", "fix", "update", not "added"/"fixes"/"updating".

Examples: `feat: add commit-staged-changes skill` ·
`fix: handle empty staged diff` · `docs: clarify install steps`.

### 5. Write the body only if it adds value (the 50/72 rule, part 2)

- Simple, self-explanatory changes: **omit the body** — subject only.
- Otherwise: blank line after the subject, then body **wrapped at 72 characters**
  per line, imperative mood. Explain *what* and *why*, not a file-by-file replay of
  the diff. Bullet lines (`- …`) are fine; wrap them at 72 too.

### 6. Commit

Write the message to a temp file and commit with `-F` — this avoids shell quoting
and newline problems (especially on Windows/PowerShell) and preserves the exact
line wrapping:

```bash
# message written to a scratch file, e.g. $TMP/commitmsg.txt
git -C <repo> commit -F "$TMP/commitmsg.txt"
```

Do not append tool/co-author trailers unless the user asks for them.

### 7. Report to the user

Show the final message and `git -C <repo> log -1 --stat` (or the commit hash and
subject) so the user can confirm what landed.

## Message Template

```
type: concise lower-case summary under 50 chars

Optional body explaining what changed and why, in the imperative
mood, hard-wrapped at 72 characters per line. Leave it out entirely
when the subject already says everything.
```

## Common Mistakes

- **Staging files that weren't staged.** Never `git add` or use `git commit -a`
  unless explicitly asked — commit the user's staged selection only.
- **Committing when nothing is staged.** Check `git diff --cached --stat` first;
  stop and report if it's empty.
- **Breaking the case/format rules.** Capitalized subject, a `type` like `Feat`,
  or a trailing period all violate the convention — keep it all lower case.
- **Subject over 50 chars.** The limit includes the `type:` prefix; tighten the
  summary or move detail into the body.
- **Past-tense subjects.** Use imperative mood ("fix bug", not "fixed bug").
- **Guessing the type.** Read the staged diff and pick the type it actually is;
  don't default to `chore` for everything.
- **A body that restates the diff.** Explain the reasoning; skip the body entirely
  for trivial changes.
- **Wrong repo.** When a target repo is given, pass `-C <path>` to every git
  command so you don't commit in the wrong place.
