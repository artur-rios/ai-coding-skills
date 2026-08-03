# README Issue Tracking

Some projects track their backlog in the repository `README.md` as well as in the
issue tracker — a roadmap of milestones and a per-milestone table of issues. The
layout `generate-specs-from-brainstorm` produces is the common case, but any
equivalent structure counts.

When such tracking exists, finishing a use case means marking its row done there
too. When it does not, this file does not apply — **skip it silently**.

## 1. Does this README track issues?

Read the repository's root `README.md` and look for any of these:

- A `## Roadmap` or `## Backlog` section.
- A table whose rows carry issue references (`#12`, `[#12](…/issues/12)`) or unit
  of work identifiers (`UC-03 — Create order`).
- A milestone table with a status or closed-count column (`2 / 6 closed`).
- A checklist of use cases (`- [ ] UC-03 — Create order`).

**One of these present → the README tracks issues.** None present → it does not.

Do not treat a feature list, a "coming soon" paragraph, or a link to the GitHub
issues page as tracking. Those are prose about the project, not a record of work
items, and editing them is not what you were asked to do.

If the README is ambiguous — something that could be a backlog but has no clear
done marker — **ask** rather than inventing one.

## 2. What to change

Only the rows this use case actually affects:

| Change | When |
| --- | --- |
| The use case's own row → done | Always, when its row exists |
| The milestone's closed count | When the README shows one (`2 / 6` → `3 / 6`) |
| The milestone's status | Only when this use case was the last open one in it |

Nothing else. Do not restructure the tables, do not add columns, do not reorder
rows, do not fix unrelated stale counts. The pull request is about one use case.

## 3. Match the file's own convention

Use the marker the README already uses for completed work. Read a completed row
before writing one — the file will show you the convention:

| If the README uses | Mark done as |
| --- | --- |
| A `Status` column with words | The word the file already uses for done (`done`, `shipped`, `complete`) |
| A `Status` column with emoji | The emoji the file already uses (`✅`) |
| Checkboxes | `- [x]` |
| Strikethrough on closed rows | `~~…~~` |

**If no row is complete yet, there is no convention to copy.** Pick the most
obvious form for the column that exists — a checked box for checkboxes, `✅` for an
emoji status column — state which you chose at Gate 3, and let the user correct it.
Never introduce a second convention into a file that already has one.

## 4. When the row is missing

The README tracks issues but has no row for this use case. That is a real
mismatch, not something to paper over:

- Say so, and show what the README does contain for that milestone.
- Ask whether to add the row or leave the README alone.

Do not silently add the row — a use case missing from the backlog usually means
the README is stale or the use case was never planned, and the user should decide
which.

## 5. Why this happens before the pull request

The README change is committed **on the use case's branch**, so it merges with the
implementation.

Marking the row done pre-merge is not premature: the change is invisible on the
base branch until the pull request merges, and that merge is the moment the issue
closes. Doing it afterwards instead would mean committing straight to the base
branch — outside the one-use-case-one-branch-one-pull-request rule the project's
workflow document defines.

If the pull request is rejected or abandoned, the README change goes with it. That
is the correct outcome.
