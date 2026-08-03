# generate-specs-from-brainstorm

Expands a human-written `Brainstorm.md` into **twelve structured project
documents** and a **starting GitHub backlog** — an informal `initial/` set you read
to understand the project in ten minutes, a formal `requirements/` set an
implementer (human or agent) builds from, and a root README that tracks the
milestones and issues derived from the use cases.

## What it does

- Reads your free-form brainstorm and works out what the documents need that the
  brainstorm doesn't say.
- **Asks about every gap before writing** — one batch per phase. It never invents
  a requirement, a business rule, or a library version.
- Writes `initial/` (four documents), moves `Brainstorm.md` in beside them, then
  **stops** so you can review and edit.
- On your go-ahead, re-reads those four files **from disk** — your edits are what
  feed the formal documents — and writes `requirements/` (seven documents).
- Derives a backlog from the use cases: one issue per `UC-xx`, plus one foundation
  issue for the project scaffold and initial infrastructure, grouped into logical
  milestones, plus a README that tracks them.
- **Stops again** before creating anything on GitHub, then creates the milestones,
  the foundation issue, and the use-case issues, and fills the README with their
  real numbers.
- Runs a traceability and consistency pass before reporting: every requirement is
  exercised by a use case, every use case has exactly one issue, every cross-link
  resolves, no template scaffolding survives.

## When to use it

Ask for it with phrases like "turn my brainstorm into docs", "generate specs from
Brainstorm.md", "create the requirements documents for this project", "expand
these notes into a vision and requirements doc", or "break the specs into
milestones and issues".

It is **not** for documenting existing code — for a README and a docs site for a
.NET/NuGet library, use
[generate-nuget-lib-docs](generate-nuget-lib-docs.md). This skill writes documents
and a backlog only; it writes no code. To implement one of the issues it creates,
use [implement-use-case](implement-use-case.md).

## What you get

`initial/` and `requirements/` are siblings at the project root, and the brainstorm
ends up inside `initial/` beside the documents it produced:

```
<project-root>/
├── README.md
├── initial/
│   ├── Brainstorm.md
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

The project root is the folder the brainstorm was found in — unless it was already
inside a folder named `initial/`, in which case the root is that folder's parent.

**`initial/`** is deliberately loose — prose and tables, no numbered sections. The
one exception is `Business Rules.md`, whose `BR-xx` rules are traced into the
formal requirements later.

**`requirements/`** is formal — numbered sections, identifier schemes, traceability
tables, and mermaid diagrams (context, ER, state, and flow).

**`README.md`** is the entry point: overview, an index of every specification
document, installation and test instructions, and the roadmap and backlog tables.

## The backlog

| Concept | Rule |
|---|---|
| Issue | Exactly one per `UC-xx`, plus exactly one foundation issue — `issue count = use cases + 1`. Nothing else; a third kind of issue is invented work. |
| Foundation issue | Created first, so every use-case issue has a codebase to land in. Covers the project scaffold and initial infrastructure — repository layout, dependencies, configuration, persistence bootstrap, test project, CI — as far as the Operations & Infrastructure and Technology Stack documents specify them. The `IR-xx` requirements become its Definition of Done, not issues of their own. |
| Milestone | A deliverable slice, not a sprint or a category. 3–7 for a typical project, dependency-ordered: `M-01 — Foundation` holds the foundation issue alone, then one milestone per domain area, then cross-cutting and hardening where the documents define them. |
| Due dates | Never invented. Omitted unless you give real ones. |
| Re-runs | Milestones and issues whose titles already exist are skipped, not recreated. |

Creating them on GitHub happens only after you approve the plan. If you decline —
or if `gh` isn't available, isn't authenticated, or the repo has no GitHub remote —
the README roadmap stands as the plan and the skill says so.

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
| `M-xx` | Milestone | GitHub milestone titles and the README roadmap |

Identifiers are never renumbered. A dropped requirement is marked withdrawn rather
than shifting everything below it.

## How it works

1. **Locate** the brainstorm and derive the project root. Stop and ask if
   `initial/`, `requirements/`, or a root README already has content.
2. **Inventory Phase 1 gaps** against the per-document checklists.
3. **Ask** everything missing, in one batch.
4. **Write `initial/`** — three inline outlines plus the `Workflow.md` template.
5. **Move `Brainstorm.md`** into `initial/` (with `git mv` when it's tracked).
6. **Stop for review.** This gate is the point of the phased design: a misreading
   caught here doesn't contaminate seven formal documents.
7. **Re-read from disk** on your go-ahead.
8. **Inventory Phase 2 gaps** and ask in one batch.
9. **Write `requirements/`** in dependency order — Technology Stack first, so
   every later document links to it instead of restating versions.
10. **Verify** traceability, links, leftover scaffolding, and workflow consistency.
11. **Derive** the issues — one per use case plus the foundation issue — and group
    them into milestones.
12. **Write the README**, with the roadmap and backlog as a plan.
13. **Stop for approval** before anything is created on GitHub.
14. **Create** the milestones and issues, then fill the README with real numbers.
15. **Verify and report** the files, the backlog, any defaults applied, and any
    deferred decisions.

## What it refuses to guess

Only three things are defaulted without asking, and each is named in the final
report so you can correct it: the project name, the two-letter requirement area
codes, and which entities appear in a diagram.

Everything else — the database, the auth model, the deployment target, a library
version, the install and test commands in the README — is a question. When you
don't know a version yet, it records `latest stable at implementation time` rather
than inventing a number.

## Files in this skill

| Path | Purpose |
|---|---|
| `SKILL.md` | The skill instructions and the three-phase procedure. |
| `references/doc-conventions.md` | ID schemes, traceability rules, cross-link encoding, diagram and table style. |
| `references/gap-questions.md` | Per-document checklists of required inputs, and the questions to ask when they're missing. |
| `references/github-backlog.md` | How use cases become issues, how issues group into milestones, the `gh` commands, and the README tracking format. |
| `templates/README.md` | Skeleton for the project README, roadmap, and backlog. |
| `templates/Workflow.md` | Skeleton for the agent-facing delivery workflow. |
| `templates/Vision Document.md` | Skeleton for the Vision Document. |
| `templates/System Requirements Document.md` | Skeleton for functional/non-functional requirements, data model, and traceability. |
| `templates/Use Case Specification Document.md` | Skeleton for actors, use cases, alternative flows, and state diagrams. |
| `templates/Development Workflow Document.md` | Skeleton for the normative delivery process. |
| `templates/Operations & Infrastructure Document.md` | Skeleton for platform, configuration, logging, health, and delivery. |
| `templates/Technology Stack Document.md` | Skeleton for the single-source-of-truth technology and version tables. |
| `templates/Testing Specification Document.md` | Skeleton for how tests are written, named, and run. |

## What you get back

Twelve documents, a GitHub backlog of milestones and issues, a list of the defaults
applied, the decisions explicitly deferred, and the verification results — with
review gates where your edits actually change what gets generated next, and before
anything is created outside your working tree.
