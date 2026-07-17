# commit-staged-changes

Commits the **already-staged** files in a repository with a clean, conventional
message — a lowercase Conventional Commits subject that follows the **50/72 rule**.

## What it does

- Commits only what is staged (`git commit`, never `git add` or `-a`), so the
  user's staged selection is captured exactly.
- Reads the staged diff and picks the best Conventional Commit type
  (`chore`, `feat`, `build`, `fix`, `docs`, and the other standard types).
- Writes an all-lowercase subject ≤ 50 characters, imperative mood, no trailing
  period; adds a body wrapped at 72 characters only when it earns its place.
- Reports the final message and the resulting commit so you can confirm.

## When to use it

Ask for it with phrases like "commit the staged changes", "commit staged files",
"make a commit", or "commit this with a good message". Files should already be
staged; if nothing is staged, the skill stops and tells you instead of staging on
your behalf.

## The rules it enforces

**Conventional Commits, lower case** — `type: description`, where `type` is
derived from the actual staged diff:

| Type | For staged changes that… |
|---|---|
| `feat` | add a feature | 
| `fix` | fix a bug |
| `docs` | change documentation only |
| `build` | change build/packaging/dependencies |
| `chore` | maintenance with no better fit |
| `test` / `refactor` / `ci` / `perf` / `style` | the standard remaining types |

**The 50/72 rule:**

```
type: concise lower-case summary under 50 chars

Optional body explaining what and why, imperative mood, wrapped at
72 characters per line. Omitted entirely for simple changes.
```

- Subject ≤ 50 chars (including the `type:` prefix), lower case, no period,
  imperative mood ("fix bug", not "fixed bug").
- Blank second line.
- Body wrapped at 72 chars, and only present when it adds real context.

## How it works

1. **Identify** the target repo (current directory by default, `-C <path>` for a
   named one).
2. **Inspect** the staged changes with `git diff --cached --stat` and
   `git diff --cached`; stop if nothing is staged.
3. **Choose the type** that matches the primary staged change.
4. **Write the subject** under the 50-char, lowercase, imperative rules.
5. **Write a body** only when the change isn't self-explanatory, wrapped at 72.
6. **Commit** via a temp message file and `git commit -F` (reliable on Windows).
7. **Report** the final message and the new commit.

## Files in this skill

| Path | Purpose |
|---|---|
| `SKILL.md` | The skill instructions. |

## What you get back

The composed commit message and confirmation of the commit (hash, subject, and
changed files) — with the staged selection committed exactly as it was, and
nothing extra staged on your behalf.
