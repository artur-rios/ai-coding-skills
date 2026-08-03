---
name: generate-specs-from-brainstorm
description: Use when the user has a Brainstorm.md (or similar free-form idea notes) for a software project and wants it expanded into structured project documentation and a starting backlog — an `initial/` folder (Brainstorm, Project Overview, Technology Stack, Workflow, Business Rules), a formal `requirements/` folder (Vision, System Requirements, Use Case Specification, Development Workflow, Operations & Infrastructure, Technology Stack, Testing Specification), then a root README and GitHub milestones and issues derived from the use cases. Triggers on "turn my brainstorm into docs", "generate specs from Brainstorm.md", "create the requirements documents for this project", "expand these notes into a vision and requirements doc", "break the specs into milestones and issues". Not for README/docs-site generation of an existing codebase — that is generate-nuget-lib-docs.
---

# Generate Specs from Brainstorm

## Overview

Expands a human-written `Brainstorm.md` into twelve structured documents and a
GitHub backlog, in three phases with a review gate before each hand-off.

| Phase | Produces |
|---|---|
| 1 | `initial/` — four informal documents, with `Brainstorm.md` moved in beside them |
| 2 | `requirements/` — seven formal documents |
| 3 | root `README.md`, plus GitHub milestones and one issue per unit of work |

**Core principle:** the brainstorm is the only source of truth about intent.
Where it is silent, **ask** — never invent a requirement, a version number, or a
business rule. A fabricated requirement is worse than a missing one, because it
looks authoritative and gets implemented.

Phase 2 reads the `initial/` documents **back from disk**, so the user's edits
during review are what feed the formal documents. Phase 3 derives every milestone
and issue from the `requirements/` documents, and writes nothing to GitHub before
the user approves the plan.

## When to Use

- The user points at a `Brainstorm.md` (or equivalent notes) and wants project
  documentation generated from it.
- A greenfield project needs its vision, requirements, use cases, and process
  documents written before implementation begins.
- The user asks for "the requirements docs" for a project that exists only as
  notes.
- The user wants the specifications broken into a starting backlog — milestones
  and issues — and a README that tracks them.

Skip / adapt if:
- The user wants a README or a documentation site for **existing code** — for a
  .NET/NuGet library that is `generate-nuget-lib-docs`.
- The user wants to implement something. Specs come first, but this skill stops
  at documents and the backlog; it writes no code. Implementing one of the issues
  it creates is `implement-use-case`.
- There is no brainstorm and no notes — there is nothing to expand. Ask the user
  to write the brainstorm first, or offer to interview them into one.

## Red Flags — STOP and Re-read the Procedure

- "The brainstorm doesn't say which database, I'll assume PostgreSQL" → NO. Ask.
- "I'll write `TBD` and let them fill it in" → NO. A gap is a question asked
  before writing, not a marker shipped in the output.
- "I'll generate all twelve documents now and let them review at the end" → NO.
  Phase 1 stops at four documents and waits.
- "The plan looks right, I'll just create the issues" → NO. Creating issues and
  milestones on GitHub is an outward-facing action. Present the plan, get a clear
  yes, then create.
- "The scaffold needs six setup issues to be trackable" → NO. One foundation
  issue, with the `IR-xx` requirements as its Definition of Done.
- "This use case is big, I'll split it into three issues" → NO. One use case, one
  issue, one branch, one pull request.
- "I already know what's in the initial docs, I just wrote them" → NO. Re-read
  them from disk at the start of Phase 2; the user may have edited them.
- "I'll pin the library at version 3.2.1" → NO. Never invent a version. Ask, or
  record "latest stable at implementation time".
- "The use case list is obvious, I'll skip the traceability table" → NO. An `FR`
  no use case exercises is a defect the verification pass must catch.

| Rationalization | Reality |
|---|---|
| "Asking about every gap will annoy the user" | Gaps are collected and asked in **one batch per phase**, not one at a time. Three batches total. |
| "A reasonable default is basically the same as an answer" | Only three things may be defaulted (see `references/gap-questions.md`), and each must be reported. |
| "The templates are just suggestions" | The templates are the format the user asked for. Follow the section structure; adapt content, not skeleton. |
| "Phase 2 can reuse what I generated in Phase 1 from memory" | The review gate exists so the user can correct Phase 1. Reading from memory discards their corrections. |
| "This project is simple, it doesn't need twelve documents" | The user asked for twelve. Scale each document's depth to the project; do not drop documents. |
| "One milestone per use case keeps it granular" | A milestone is a deliverable slice, not a ticket. Group logically — 3–7 milestones for a typical project. |

## Procedure

Create a todo per step.

### 1. Locate the brainstorm and plan the output

Find the brainstorm file the user means (usually `Brainstorm.md`). If several
candidates exist, ask which one. Read it in full.

The **project root** is the folder the brainstorm was found in — unless it is
already inside a folder named `initial/`, in which case the root is that folder's
parent. Everything is written relative to that root:

```
<project-root>/
├── README.md          ← Phase 3
├── initial/           ← Phase 1, and where Brainstorm.md ends up
└── requirements/      ← Phase 2
```

If either folder, or a root `README.md`, already exists with content, stop and ask
whether to overwrite, merge, or write elsewhere. Do not silently overwrite prior
work.

Read [references/doc-conventions.md](references/doc-conventions.md) now — the ID
schemes, traceability rules, and link style apply to every document that follows.

### 2. Phase 1 — inventory the gaps

Walk the **Phase 1** checklists in
[references/gap-questions.md](references/gap-questions.md) against the brainstorm.
Mark each item answered or missing. An item counts as answered only when a single
reading of the brainstorm is possible.

### 3. Phase 1 — ask everything missing, in one batch

Ask all Phase 1 gaps at once, grouped by topic. Do not write any file before the
answers are in.

If the brainstorm answers essentially nothing, say so plainly and ask whether to
proceed as a full interview rather than firing thirty questions at once.

### 4. Phase 1 — write `initial/`

Write the four documents. Three of them use the outlines below; `Workflow.md`
uses [templates/Workflow.md](templates/Workflow.md).

These documents are deliberately **informal** — readable prose and tables, no
numbered sections, no requirement IDs except `BR-xx` in Business Rules. They are
what a person reads to understand the project in ten minutes.

**`Project Overview.md`**

```
# Project Overview — <Project Name>

## What This Is          one paragraph
## The Problem           what hurts today, and for whom
## Who It's For          users, roles, calling systems
## What It Does          bulleted core capabilities
## What It Doesn't Do    explicit non-goals
## How Success Is Measured   observable outcomes
```

**`Technology Stack.md`**

```
# Technology Stack — <Project Name>

## Platform & Language       with version if decided
## Application Type          API / CLI / worker / library / desktop
## Data Storage              engine, or explicitly none
## Data Access               ORM / driver / query builder
## Authentication            mechanism, or explicitly none
## Testing                   framework and the kinds of tests intended
## External Dependencies     services the system calls
## Deployment                target, or "not decided yet"
```

Record undecided items as *undecided*, not as a guess. This document feeds the
formal Technology Stack Document, where versions get pinned.

**`Workflow.md`** — fill [templates/Workflow.md](templates/Workflow.md). This is
the agent-facing delivery flow: how one unit of work goes from backlog to a
review-ready pull request, and where the implementer must stop and ask. Keep the
pause gates unless the user explicitly said an agent may advance unattended.

**`Business Rules.md`**

```
# Business Rules — <Project Name>

## Domain Entities        what each represents
## Relationships          cardinality between entities
## Rules                  BR-01 … numbered table: rule + rationale
## Validation Constraints per field: required, unique, format, range
## Permissions            which role may do what
## Lifecycle              creation, state transitions, deletion semantics
## Prohibitions           what must never happen
```

The `BR-xx` identifiers are traced into the System Requirements Document in
Phase 2, so number them carefully and do not renumber later.

### 5. Phase 1 — move the brainstorm into `initial/`

**After** the four documents are written, move the brainstorm in beside them so
the source and its expansion live together:

```bash
git mv Brainstorm.md initial/Brainstorm.md   # or plain mv if the file is untracked
```

Use `git mv` when the file is tracked — it preserves history. Skip this step
entirely if the brainstorm was already inside `initial/`. Never copy-and-delete:
one file, moved.

Then fix anything that pointed at the old location — the brainstorm's own
relative links to images or notes, and any reference in the documents you just
wrote.

### 6. Gate — stop and hand back for review

Report what was written, note that the brainstorm was moved, list any of the three
permitted defaults you applied, and stop:

> "The four `initial/` documents are written and `Brainstorm.md` now sits beside
> them in `initial/`. Review and edit them — I'll read the files back from disk
> when you're ready, so your edits carry into the formal documents. Tell me when
> to continue."

**Do not start Phase 2 without an explicit go-ahead.** This gate is the whole
reason the skill has phases.

### 7. Phase 2 — re-read the approved documents

Read all four `initial/` files **from disk**, even if you just wrote them. The
user may have rewritten entire sections. Everything downstream derives from what
is on disk now, not from what you generated.

### 8. Phase 2 — inventory gaps and ask in one batch

Walk the **Phase 2** checklists in
[references/gap-questions.md](references/gap-questions.md) against the four
approved documents. Ask everything missing at once.

Never invent a version number. When the user does not know, record
"latest stable at implementation time" — a recorded policy, not a fabrication.

### 9. Phase 2 — write `requirements/` in dependency order

Each document depends on the ones before it. Write them in this order:

| # | Document | Template | Derives from |
|---|---|---|---|
| 1 | Technology Stack Document | [templates/Technology Stack Document.md](templates/Technology%20Stack%20Document.md) | `initial/Technology Stack.md` + pinned versions |
| 2 | Vision Document | [templates/Vision Document.md](templates/Vision%20Document.md) | `initial/Project Overview.md`, `initial/Business Rules.md` |
| 3 | System Requirements Document | [templates/System Requirements Document.md](templates/System%20Requirements%20Document.md) | Vision features + `initial/Business Rules.md` |
| 4 | Use Case Specification Document | [templates/Use Case Specification Document.md](templates/Use%20Case%20Specification%20Document.md) | System Requirements §3 |
| 5 | Development Workflow Document | [templates/Development Workflow Document.md](templates/Development%20Workflow%20Document.md) | the **approved** `initial/Workflow.md` |
| 6 | Testing Specification Document | [templates/Testing Specification Document.md](templates/Testing%20Specification%20Document.md) | Technology Stack §7 + Use Case flows |
| 7 | Operations & Infrastructure Document | [templates/Operations & Infrastructure Document.md](templates/Operations%20%26%20Infrastructure%20Document.md) | `initial/Technology Stack.md` + operations answers |

Writing the Technology Stack Document first is what lets every later document
link to it instead of restating versions.

The Development Workflow Document is the **formalization** of the approved
`initial/Workflow.md`, not a re-derivation. Where the two could differ, the
approved `Workflow.md` wins.

Delete every `<!-- GUIDANCE -->` block and replace every `{{token}}` as you fill
each template. A template comment surviving into the output is a defect.

### 10. Phase 2 — verify the documents

Check, and fix what fails:

- [ ] Every `FR-<AREA>-xx` cited by a use case exists in System Requirements §3.
- [ ] Every `FR-<AREA>-xx` in §3 is exercised by at least one use case.
- [ ] Every `F-xx` from the Vision Document appears in the traceability table.
- [ ] Every `BR-xx` from Business Rules is realized by at least one requirement.
- [ ] No `TBD`, `TODO`, `{{token}}`, or `<!-- GUIDANCE -->` survives in any file.
- [ ] Every cross-document link resolves — file names match exactly, spaces are
      `%20`, `&` is `%26`.
- [ ] No version number appears outside the Technology Stack Document.
- [ ] `Development Workflow Document.md` and `initial/Workflow.md` agree on
      stages, branch pattern, gates, and Definition of Done.
- [ ] Every mermaid block parses — balanced fences, valid diagram type, no empty
      diagram.

Grep is enough for most of these:

```bash
grep -rn "TBD\|TODO\|{{\|GUIDANCE" initial requirements
```

### 11. Phase 3 — derive the milestones and issues

Read [references/github-backlog.md](references/github-backlog.md) now, then walk
the **Phase 3** checklist in
[references/gap-questions.md](references/gap-questions.md) and ask anything still
open in one batch.

Derive, in this order:

1. **Issues** — exactly **one per `UC-xx`** from the Use Case Specification, plus
   **exactly one foundation issue** for the project scaffold and initial
   infrastructure that everything else is built on. That is the whole backlog:

   ```
   issue count = number of use cases + 1
   ```

   The foundation issue comes first and covers repository layout, dependencies,
   configuration, persistence bootstrap, the test project, and CI — whichever of
   those the Operations & Infrastructure and Technology Stack documents specify.
   Its `IR-xx` requirements become its Definition of Done, **not** issues of their
   own. Everything in its scope must come from a document; ask rather than fill a
   gap.

2. **Milestones** — `M-01 — Foundation` holds the foundation issue alone; every
   other milestone depends on it. Group the use-case issues into the remaining
   milestones (3–7 in total) in dependency order: one per domain area, then
   cross-cutting and hardening where the documents define them. Each milestone
   answers "what can the project do now that it could not before?"

Nothing is created on GitHub in this step.

### 12. Phase 3 — write the README

Fill [templates/README.md](templates/README.md) at the project root: overview and
non-goals from `initial/Project Overview.md`, the specification index, installation
and testing from the Technology Stack and Testing Specification documents, and the
roadmap and backlog tables from step 11.

The project has no code yet, so the installation and test commands are the
**intended** ones the stack determines. Take them from the documents; ask when the
documents do not determine them. Never write a command you cannot justify.

Write the roadmap and backlog tables in their planned form — `—` in the **Issue**
column, `planned` as the status. They become the plan the user reviews next.

### 13. Gate — approve the backlog before creating anything

Show the milestone grouping and the issue list, and ask for a clear yes before
touching GitHub:

> "Here are N milestones covering M issues, and the README that tracks them.
> Create them on GitHub, or leave the README roadmap as a plan you'll create
> yourself?"

**Creating issues and milestones is outward-facing and awkward to undo. Never
create them on an assumed yes.** If the user declines, Phase 3 ends here — the
README roadmap is the deliverable.

### 14. Phase 3 — create the milestones and issues

Only after approval, and following
[references/github-backlog.md](references/github-backlog.md) §3:

1. Preflight `gh auth status` and `gh repo view`. If `gh` is missing, not
   authenticated, or there is no GitHub remote, **stop and report it** — the
   README roadmap stands as the plan. Do not improvise another tracker.
2. List existing milestones and issues. Anything whose title already exists is
   **skipped, not recreated** — re-running must not duplicate.
3. Create the milestones in `M-xx` order, then the foundation issue, then the use
   case issues in `UC-xx` order — each assigned to its milestone, each body passed
   with `--body-file`.
4. Update the README roadmap and backlog tables with the real issue numbers,
   milestone URLs, and `0 / N closed` counts.

### 15. Verify and report

Check the Phase 3 output too:

- [ ] Every `UC-xx` in the Use Case Specification has exactly one issue.
- [ ] There is exactly one foundation issue, and it is the first one created.
- [ ] The issue count equals the number of use cases plus one.
- [ ] Every issue belongs to exactly one milestone.
- [ ] No milestone depends on a later one, and every milestone after `M-01`
      depends on it.
- [ ] Every README link resolves, including into `initial/` and `requirements/`.
- [ ] The README carries no `{{token}}` and no guidance comment.
- [ ] The README's issue numbers match what GitHub actually returned.

Then tell the user:
- The twelve files written and where, and that `Brainstorm.md` moved into
  `initial/`.
- The milestones and issues created — or why they were not.
- Which defaults you applied without asking (project name, area codes, diagram
  composition) so they can correct them.
- Anything recorded as an explicit deferred decision (unpinned versions,
  undecided deployment target).
- The verification results.

## Quick Reference

| Phase | Output | Gate |
|---|---|---|
| 1 | `initial/` — Project Overview, Technology Stack, Workflow, Business Rules, and `Brainstorm.md` moved in | Stop for human review |
| 2 | `requirements/` — Technology Stack, Vision, System Requirements, Use Case Specification, Development Workflow, Testing Specification, Operations & Infrastructure | Verify the traceability |
| 3 | Root `README.md`, GitHub milestones, one issue per `UC-xx` plus one foundation issue | Approve the plan before anything is created on GitHub |

| Identifier | Meaning | Defined in |
|---|---|---|
| `BR-xx` | Business rule | `initial/Business Rules.md` |
| `F-xx` | Feature | Vision Document |
| `FR-<AREA>-xx` | Functional requirement | System Requirements Document |
| `NFR-xx` | Non-functional requirement | System Requirements Document |
| `IR-xx` | Platform requirement | Operations & Infrastructure Document |
| `UC-xx` | Use case | Use Case Specification Document |
| `AF-xx` | Alternative flow (per use case) | Use Case Specification Document |
| `M-xx` | Milestone | GitHub milestone titles and the README roadmap |

## Common Mistakes

- **Inventing an answer the brainstorm didn't give.** The single most damaging
  failure. Ask instead.
- **Shipping `TBD` markers.** Gaps are questions asked before writing.
- **Skipping the Phase 1 gate.** Generating all twelve documents in one pass
  propagates every early misreading into seven formal documents.
- **Creating GitHub issues before the plan is approved.** The backlog is
  presented in the README first; creation needs an explicit yes.
- **Exploding the scaffold into many setup issues.** One foundation issue, first,
  with the `IR-xx` requirements as its Definition of Done. Its whole job is to
  give the use-case issues somewhere to land.
- **Copying `Brainstorm.md` into `initial/` instead of moving it.** Two copies
  drift apart. Move it — with `git mv` when it is tracked.
- **Writing a README install or test command from habit.** `npm install` in a
  .NET project is the kind of error a reader hits in the first minute. Take the
  command from the Technology Stack and Testing Specification documents.
- **Milestones that are categories, not slices.** "Backend", "Frontend" and
  "Testing" are not deliverables; "Order management" is.
- **Reading Phase 1 output from memory instead of disk.** Discards the user's
  review edits.
- **Leaving template scaffolding in the output.** Delete guidance comments and
  replace every `{{token}}`.
- **Restating versions outside the Technology Stack Document.** It is the single
  source of truth; everything else links to it.
- **Writing requirements no use case exercises**, or use cases citing
  requirements that don't exist. Both are caught by the verification pass — run it.
- **Renumbering identifiers.** Once written, `BR-03` stays `BR-03`. Withdraw, do
  not shift.
- **Re-deriving the Development Workflow Document.** It formalizes the approved
  `initial/Workflow.md`; it does not reinvent it.
- **Nesting the folders.** `initial/` and `requirements/` are siblings at the
  project root, not nested inside each other.
- **Dropping documents because the project seems small.** Scale depth, not count.
