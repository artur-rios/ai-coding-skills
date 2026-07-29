---
name: generate-specs-from-brainstorm
description: Use when the user has a Brainstorm.md (or similar free-form idea notes) for a software project and wants it expanded into structured project documentation — first an `initial/` folder (Project Overview, Technology Stack, Workflow, Business Rules), then a formal `requirements/` folder (Vision, System Requirements, Use Case Specification, Development Workflow, Operations & Infrastructure, Technology Stack, Testing Specification). Triggers on "turn my brainstorm into docs", "generate specs from Brainstorm.md", "create the requirements documents for this project", "expand these notes into a vision and requirements doc". Not for README/docs-site generation of an existing codebase — that is generate-project-docs.
---

# Generate Specs from Brainstorm

## Overview

Expands a human-written `Brainstorm.md` into eleven structured documents across
two folders, in two phases with a review gate between them.

**Core principle:** the brainstorm is the only source of truth about intent.
Where it is silent, **ask** — never invent a requirement, a version number, or a
business rule. A fabricated requirement is worse than a missing one, because it
looks authoritative and gets implemented.

Phase 2 reads the `initial/` documents **back from disk**, so the user's edits
during review are what feed the formal documents.

## When to Use

- The user points at a `Brainstorm.md` (or equivalent notes) and wants project
  documentation generated from it.
- A greenfield project needs its vision, requirements, use cases, and process
  documents written before implementation begins.
- The user asks for "the requirements docs" for a project that exists only as
  notes.

Skip / adapt if:
- The user wants a README or a documentation site for **existing code** — that is
  `generate-project-docs`.
- The user wants to implement something. Specs come first, but this skill stops
  at documents; it writes no code.
- There is no brainstorm and no notes — there is nothing to expand. Ask the user
  to write the brainstorm first, or offer to interview them into one.

## Red Flags — STOP and Re-read the Procedure

- "The brainstorm doesn't say which database, I'll assume PostgreSQL" → NO. Ask.
- "I'll write `TBD` and let them fill it in" → NO. A gap is a question asked
  before writing, not a marker shipped in the output.
- "I'll generate all eleven documents now and let them review at the end" → NO.
  Phase 1 stops at four documents and waits.
- "I already know what's in the initial docs, I just wrote them" → NO. Re-read
  them from disk at the start of Phase 2; the user may have edited them.
- "I'll pin the library at version 3.2.1" → NO. Never invent a version. Ask, or
  record "latest stable at implementation time".
- "The use case list is obvious, I'll skip the traceability table" → NO. An `FR`
  no use case exercises is a defect the verification pass must catch.

| Rationalization | Reality |
|---|---|
| "Asking about every gap will annoy the user" | Gaps are collected and asked in **one batch per phase**, not one at a time. Two batches total. |
| "A reasonable default is basically the same as an answer" | Only three things may be defaulted (see `references/gap-questions.md`), and each must be reported. |
| "The templates are just suggestions" | The templates are the format the user asked for. Follow the section structure; adapt content, not skeleton. |
| "Phase 2 can reuse what I generated in Phase 1 from memory" | The review gate exists so the user can correct Phase 1. Reading from memory discards their corrections. |
| "This project is simple, it doesn't need eleven documents" | The user asked for eleven. Scale each document's depth to the project; do not drop documents. |

## Procedure

Create a todo per step.

### 1. Locate the brainstorm and plan the output

Find the brainstorm file the user means (usually `Brainstorm.md`). If several
candidates exist, ask which one. Read it in full.

Both output folders are **siblings of the brainstorm file**:

```
<brainstorm-folder>/
├── Brainstorm.md
├── initial/
└── requirements/
```

If either folder already exists and contains documents, stop and ask whether to
overwrite, merge, or write elsewhere. Do not silently overwrite prior work.

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

### 5. Gate — stop and hand back for review

Report what was written, list any of the three permitted defaults you applied,
and stop:

> "The four `initial/` documents are written. Review and edit them — I'll read
> the files back from disk when you're ready, so your edits carry into the formal
> documents. Tell me when to continue."

**Do not start Phase 2 without an explicit go-ahead.** This gate is the whole
reason the skill has two phases.

### 6. Phase 2 — re-read the approved documents

Read all four `initial/` files **from disk**, even if you just wrote them. The
user may have rewritten entire sections. Everything downstream derives from what
is on disk now, not from what you generated.

### 7. Phase 2 — inventory gaps and ask in one batch

Walk the **Phase 2** checklists in
[references/gap-questions.md](references/gap-questions.md) against the four
approved documents. Ask everything missing at once.

Never invent a version number. When the user does not know, record
"latest stable at implementation time" — a recorded policy, not a fabrication.

### 8. Phase 2 — write `requirements/` in dependency order

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

### 9. Verify before reporting

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

### 10. Report

Tell the user:
- The eleven files written and where.
- Which defaults you applied without asking (project name, area codes, diagram
  composition) so they can correct them.
- Anything recorded as an explicit deferred decision (unpinned versions,
  undecided deployment target).
- The verification results.

## Quick Reference

| Phase | Output | Gate |
|---|---|---|
| 1 | `initial/` — Project Overview, Technology Stack, Workflow, Business Rules | Stop for human review |
| 2 | `requirements/` — Technology Stack, Vision, System Requirements, Use Case Specification, Development Workflow, Testing Specification, Operations & Infrastructure | Verify, then report |

| Identifier | Meaning | Defined in |
|---|---|---|
| `BR-xx` | Business rule | `initial/Business Rules.md` |
| `F-xx` | Feature | Vision Document |
| `FR-<AREA>-xx` | Functional requirement | System Requirements Document |
| `NFR-xx` | Non-functional requirement | System Requirements Document |
| `IR-xx` | Platform requirement | Operations & Infrastructure Document |
| `UC-xx` | Use case | Use Case Specification Document |
| `AF-xx` | Alternative flow (per use case) | Use Case Specification Document |

## Common Mistakes

- **Inventing an answer the brainstorm didn't give.** The single most damaging
  failure. Ask instead.
- **Shipping `TBD` markers.** Gaps are questions asked before writing.
- **Skipping the Phase 1 gate.** Generating all eleven documents in one pass
  propagates every early misreading into seven formal documents.
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
- **Nesting the folders.** `initial/` and `requirements/` are siblings of the
  brainstorm file, not nested inside each other.
- **Dropping documents because the project seems small.** Scale depth, not count.
