# generate-specs-from-brainstorm

Expands a human-written `Brainstorm.md` into **eleven structured project
documents** across two folders — an informal `initial/` set you read to understand
the project in ten minutes, and a formal `requirements/` set an implementer (human
or agent) builds from.

## What it does

- Reads your free-form brainstorm and works out what the documents need that the
  brainstorm doesn't say.
- **Asks about every gap before writing** — one batch per phase. It never invents
  a requirement, a business rule, or a library version.
- Writes `initial/` (four documents), then **stops** so you can review and edit.
- On your go-ahead, re-reads those four files **from disk** — your edits are what
  feed the formal documents — and writes `requirements/` (seven documents).
- Runs a traceability and consistency pass before reporting: every requirement is
  exercised by a use case, every cross-link resolves, no template scaffolding
  survives.

## When to use it

Ask for it with phrases like "turn my brainstorm into docs", "generate specs from
Brainstorm.md", "create the requirements documents for this project", or "expand
these notes into a vision and requirements doc".

It is **not** for documenting existing code — for a README and a docs site, use
[generate-project-docs](generate-project-docs.md). This skill writes documents
only; it writes no code.

## What you get

Both folders are created as **siblings of the brainstorm file**:

```
<brainstorm-folder>/
├── Brainstorm.md
├── initial/
│   ├── Project Overview.md
│   ├── Technology Stack.md
│   ├── Workflow.md
│   └── Business Rules.md
└── requirements/
    ├── Vision Document.md
    ├── System Requirements Document.md
    ├── Use Case Specification Document.md
    ├── Development Workflow Document.md
    ├── Operations & Infrastructure Document.md
    ├── Technology Stack Document.md
    └── Testing Specification Document.md
```

**`initial/`** is deliberately loose — prose and tables, no numbered sections. The
one exception is `Business Rules.md`, whose `BR-xx` rules are traced into the
formal requirements later.

**`requirements/`** is formal — numbered sections, identifier schemes, traceability
tables, and mermaid diagrams (context, ER, state, and flow).

## The two workflow documents

They are complementary, not duplicates:

| Document | Answers |
|---|---|
| `initial/Workflow.md` | *How do I deliver one unit of work?* — the operational, step-by-step flow an implementer follows, with the pause gates where an agent must stop and ask. |
| `requirements/Development Workflow Document.md` | *What is the process?* — the normative branch pattern, issue status lifecycle, testing gate, and Definition of Done. |

The formal document **formalizes** the approved `initial/Workflow.md`. Where the
two could disagree, the version you approved wins.

## Identifier schemes

| Identifier | Meaning | Defined in |
|---|---|---|
| `BR-xx` | Business rule | `initial/Business Rules.md` |
| `F-xx` | Feature | Vision Document |
| `FR-<AREA>-xx` | Functional requirement (area code per domain area) | System Requirements Document |
| `NFR-xx` | Non-functional requirement | System Requirements Document |
| `IR-xx` | Platform requirement | Operations & Infrastructure Document |
| `UC-xx` | Use case | Use Case Specification Document |
| `AF-xx` | Alternative flow, numbered within its use case | Use Case Specification Document |

Identifiers are never renumbered. A dropped requirement is marked withdrawn rather
than shifting everything below it.

## How it works

1. **Locate** the brainstorm; plan `initial/` and `requirements/` as its siblings.
   Stop and ask if either already has content.
2. **Inventory Phase 1 gaps** against the per-document checklists.
3. **Ask** everything missing, in one batch.
4. **Write `initial/`** — three inline outlines plus the `Workflow.md` template.
5. **Stop for review.** This gate is the point of the two-phase design: a
   misreading caught here doesn't contaminate seven formal documents.
6. **Re-read from disk** on your go-ahead.
7. **Inventory Phase 2 gaps** and ask in one batch.
8. **Write `requirements/`** in dependency order — Technology Stack first, so
   every later document links to it instead of restating versions.
9. **Verify** traceability, links, leftover scaffolding, and workflow consistency.
10. **Report** the files, any defaults applied, and any deferred decisions.

## What it refuses to guess

Only three things are defaulted without asking, and each is named in the final
report so you can correct it: the project name, the two-letter requirement area
codes, and which entities appear in a diagram.

Everything else — the database, the auth model, the deployment target, a library
version — is a question. When you don't know a version yet, it records
`latest stable at implementation time` rather than inventing a number.

## Files in this skill

| Path | Purpose |
|---|---|
| `SKILL.md` | The skill instructions and the two-phase procedure. |
| `references/doc-conventions.md` | ID schemes, traceability rules, cross-link encoding, diagram and table style. |
| `references/gap-questions.md` | Per-document checklists of required inputs, and the questions to ask when they're missing. |
| `templates/Workflow.md` | Skeleton for the agent-facing delivery workflow. |
| `templates/Vision Document.md` | Skeleton for the Vision Document. |
| `templates/System Requirements Document.md` | Skeleton for functional/non-functional requirements, data model, and traceability. |
| `templates/Use Case Specification Document.md` | Skeleton for actors, use cases, alternative flows, and state diagrams. |
| `templates/Development Workflow Document.md` | Skeleton for the normative delivery process. |
| `templates/Operations & Infrastructure Document.md` | Skeleton for platform, configuration, logging, health, and delivery. |
| `templates/Technology Stack Document.md` | Skeleton for the single-source-of-truth technology and version tables. |
| `templates/Testing Specification Document.md` | Skeleton for how tests are written, named, and run. |

## What you get back

Eleven documents, a list of the defaults applied, the decisions explicitly
deferred, and the verification results — with a review gate in the middle where
your edits actually change what gets generated next.
