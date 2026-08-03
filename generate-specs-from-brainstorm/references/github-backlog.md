# GitHub Backlog — Milestones and Issues

How the approved `requirements/` documents become a GitHub backlog: milestones
that group work logically, one issue per unit of work, and a README that tracks
both.

**Nothing in this file is written to GitHub before the user approves the plan.**
Creating issues and milestones is an outward-facing, hard-to-undo action — the
plan is presented first, in the README, and only then created.

---

## 1. What becomes an issue

The backlog is **one issue per use case, plus exactly one foundation issue**:

```
issue count = number of UC-xx use cases + 1
```

| # | Issue | Title | Comes from |
| --- | --- | --- | --- |
| 1 | Foundation — created first | `Project scaffold and initial infrastructure` | Operations & Infrastructure + Technology Stack Documents |
| 2 … n | One per use case | `UC-03 — Create order` | Use Case Specification §2 |

No other issues. If you find yourself proposing a third kind, you are inventing
work — the documents already say everything the backlog needs to say.

### The foundation issue

Exactly one, always first, so every use-case issue has a codebase to land in. It
covers the project scaffold and the initial infrastructure the rest of the work
builds on: repository and solution layout, the runtime and dependencies from the
Technology Stack Document, configuration, persistence bootstrap, the test project,
and CI — whichever of those the Operations & Infrastructure Document specifies.

It is **one issue, not a checklist split into many**. The individual `IR-xx`
platform requirements are listed inside its body as its Definition of Done, not
promoted into issues of their own.

```markdown
Set up the project scaffold and the initial infrastructure every use case builds
on. This is the first unit of work; no use-case issue starts before it closes.

**Specifications:** [Operations & Infrastructure Document](requirements/Operations%20%26%20Infrastructure%20Document.md),
[Technology Stack Document](requirements/Technology%20Stack%20Document.md)
**Platform requirements:** IR-01, IR-02, IR-03, IR-04

## Scope
| Requirement | What it means here |
|---|---|
| IR-01 | <the repository / solution layout the document specifies> |
| IR-02 | <configuration mechanism> |

## Definition of Done
- [ ] <one checkbox per IR-xx above>
- [ ] The test project runs and the empty suite passes with `<test command>`.
- [ ] `README.md` installation and testing steps work on a clean clone.
```

Everything in its scope comes from a document. If the Operations & Infrastructure
Document says nothing about CI, the foundation issue says nothing about CI — ask
instead of filling the gap.

### Use case issues

One `UC-xx` = one issue = one branch = one pull request, matching the approved
`initial/Workflow.md`. Do **not** split a use case into several issues, and do not
merge two use cases into one issue — that breaks the workflow's core invariant.

```markdown
<one-sentence summary from the use case's Description>

**Specification:** [Use Case Specification Document](requirements/Use%20Case%20Specification%20Document.md) §UC-03
**Requirements:** FR-OR-01, FR-OR-02
**Business rules:** BR-04

## Main flow
<the numbered main flow, copied from the specification>

## Alternative flows
| ID | Flow |
|---|---|
| AF-01 | ... |

## Definition of Done
<the Definition of Done checklist from the Development Workflow Document>
```

Copy the flows from the specification; do not paraphrase them into something the
implementer then has to reconcile with the document.

Write each body to a file and pass `--body-file` — issue bodies are multi-line and
shell quoting will mangle them.

---

## 2. What becomes a milestone

A milestone is a **deliverable slice**, not a sprint and not a category. The test:
when this milestone closes, what can the project do that it could not do before?

Derive milestones in this order:

1. **`M-01 — Foundation`** — holds the single foundation issue and nothing else.
   It is always the first milestone, and every other milestone depends on it.
2. **One milestone per domain area** — group the use cases of each
   `FR-<AREA>` area, ordered so no milestone depends on a later one. An entity
   that others reference is delivered before the ones that reference it.
3. **Cross-cutting capabilities** — authentication, authorization, auditing:
   a milestone of their own only when they span several areas *and* the documents
   specify them. Otherwise they belong to the area that owns them.
4. **Hardening / release** — the use cases that deliver the `NFR-xx` and
   deployment work, when the documents define such use cases. Omit the milestone
   entirely if they do not — a milestone with no issues is noise.

### Rules

- Aim for **3–7 milestones**. One milestone per use case is not a grouping; a
  single milestone holding everything is not one either. `M-01` is the deliberate
  exception: one issue, because the scaffold is one unit of work.
- Every `UC-xx` belongs to **exactly one** milestone. The verification pass checks
  for use cases that landed in none.
- Milestones are **dependency-ordered**: `M-02` may depend on `M-01`, never the
  reverse. State each milestone's dependency explicitly.
- **Never invent due dates.** Omit them unless the user gave real dates.
- Identifier `M-xx`, zero-padded, sequential, never renumbered.

### Milestone title and description

| Field | Value |
| --- | --- |
| Title | `M-01 — Foundation` |
| Description | What the project can do when it closes, the identifiers it covers, and its dependency. One or two sentences. |

Example descriptions:

> **M-01 — Foundation.** Repository, configuration, and persistence in place, with
> CI running the test suite. Covers IR-01 through IR-04. No dependencies.

> **M-02 — Order management.** Orders can be created, read, updated and cancelled.
> Covers UC-01 through UC-06. Depends on M-01.

---

## 3. Creating them on GitHub

### Preflight

```bash
gh auth status
gh repo view --json nameWithOwner,url
```

If `gh` is missing, unauthenticated, or the repository has no GitHub remote:
**stop creating and say so.** The README roadmap is still written — it becomes
the plan the user creates by hand later. This is a reported outcome, not a
failure to work around.

The same applies when Phase 1 recorded a **non-GitHub host** — GitLab, Azure
DevOps, Jira. The milestone grouping and the README roadmap are host-agnostic and
still apply; only this section's `gh` commands do not. Say which tracker the
documents named and leave the creation to the user rather than improvising an API
you have not been asked to use.

### Check what already exists — always, before creating anything

```bash
gh api "repos/<owner>/<repo>/milestones?state=all" --jq '.[] | "\(.number) \(.title)"'
gh issue list --state all --limit 200 --json number,title,milestone
```

Match by title. A milestone or issue whose title already exists is **skipped, not
recreated** — report it as existing. Re-running this phase must never produce
duplicates.

### Create milestones first

`gh` has no `milestone` command; use the API:

```bash
gh api "repos/<owner>/<repo>/milestones" \
  -f title="M-01 — Foundation" \
  -f description="<description>"
```

### Then create issues — the foundation issue first

```bash
gh issue create \
  --title "Project scaffold and initial infrastructure" \
  --body-file "<path to the body file>" \
  --milestone "M-01 — Foundation"

gh issue create \
  --title "UC-03 — Create order" \
  --body-file "<path to the body file>" \
  --milestone "M-02 — Order management"
```

Create the foundation issue first, then the use cases in `UC-xx` order, so issue
numbers follow the order the work is meant to happen in.

**Labels:** use only labels that already exist in the repository. Do not invent a
label taxonomy; if the user wants labels, ask which.

Capture each created issue's number and URL — the README roadmap needs them.

---

## 4. Tracking them in the README

The README carries the plan before creation and the live state after it. Two
sections:

```markdown
## Roadmap

| Milestone | Delivers | Depends on | Issues | Status |
|---|---|---|---|---|
| [M-01 — Foundation](<milestone-url>) | The project scaffold and initial infrastructure | — | 1 | 0 / 1 closed |
| [M-02 — Order management](<milestone-url>) | Create, read, update, cancel orders | M-01 | 6 | 0 / 6 closed |

## Backlog

### M-01 — Foundation

| Issue | Work | Spec |
|---|---|---|
| [#1](<issue-url>) | Project scaffold and initial infrastructure | [Operations & Infrastructure](requirements/Operations%20%26%20Infrastructure%20Document.md) |

### M-02 — Order management

| Issue | Work | Spec |
|---|---|---|
| [#2](<issue-url>) | UC-01 — Place order | [Use Case Specification](requirements/Use%20Case%20Specification%20Document.md) |
| [#4](<issue-url>) | UC-03 — Create order | [Use Case Specification](requirements/Use%20Case%20Specification%20Document.md) |
```

Before the issues exist, the same tables are written with `—` in the **Issue**
column and `planned` as the status. After creation, fill in the real numbers,
links, and counts.

**Do not hand-maintain closed counts.** Write them as of creation time
(`0 / N closed`) and note that GitHub's milestone page is the live view — a stale
count in a README is worse than no count.
