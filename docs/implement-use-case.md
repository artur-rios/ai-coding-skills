# implement-use-case

Drives a **single use case** from backlog to a review-ready pull request — loading
the specs, refining a design and plan, branching, implementing every flow, testing
until green, recording the change in the README backlog and the CHANGELOG, and
preparing the PR into your integration branch — stopping for your approval at every
stage boundary.

It is a production line, not a code generator: it follows **your project's own
workflow documents** rather than a process baked into the skill.

## What it does

- Reads the project's `Development Workflow Document` and `Workflow.md` at
  invocation time and extracts the real parameters: branch pattern, base branch,
  status lifecycle, issue tracker, test commands, Definition of Done.
- Checks whether the repository **enforces** a branching model — a branching
  section in `CONTRIBUTING.md`, a Branch Policy workflow, a `develop` branch,
  rulesets. Where it does, that model sets the base branch: work is cut from
  `develop` as `feature/` (or `fix/`) and the pull request targets `develop`, never
  `main`, which only takes release pull requests. A workflow document that still
  says `main` is reported as stale at Gate 1, not followed and not silently fixed.
- Loads the specifications for the named use case — actors, main flow, every
  `AF-xx` alternative flow, the `FR-xx` requirements it cites, the data model, the
  authorization rules, the testing standard, the technology stack.
- Refines a repository-specific design and a test-first plan, then **stops for
  approval before any code is written**.
- Branches, implements the main flow and every alternative flow, tests until the
  suite is actually green, and prepares the pull request — pausing at each
  boundary.
- Marks the use case done in the README backlog, when the project keeps one, and
  adds its entry under `## [Unreleased]` in `CHANGELOG.md`, when the project keeps
  one, so both merge with the implementation.
- Verifies the Definition of Done from the project's document, not a remembered
  version of it.

## When to use it

It triggers whenever a message names a use case in an implementation context —
"implement UC-03", "start UC-11", "let's do use case 7", "begin the create scope
use case" — even if you never say the word "skill".

Skip it for a quick edit, a bugfix, or an experiment; the full production line is
heavy for anything that isn't a specified unit of work.

## The core principle

> The documents own the steps. The skill owns the gates.

The skill deliberately does **not** restate your workflow's steps. If it did, you'd
have two sources of truth that drift, and no way to tell which one the agent
actually followed. What it adds is the three things a document in a folder cannot
do on its own:

1. **Trigger** — a spec file is inert; nothing loads it when you say "implement
   UC-03". The skill's description is what makes that happen.
2. **Bind** — red-flag and rationalization tables that stop an agent talking
   itself past a review boundary.
3. **Enforce spec-loading** — read the five documents for *this* use case, every
   time, instead of working from memory of the last one.

## The gates

| Gate | When | Blocks |
|---|---|---|
| 1 | Design and plan written | Any code being written |
| 2 | Implementation complete | Moving to the testing stage |
| 3 | Full suite green | The README tracking update, the CHANGELOG entry, and the pull request |
| 4 | You merged and deleted the branch | Closing the issue |

**Exactly one transition is unattended:** marking the work started, right after the
branch is created.

**Approval is per gate.** A yes at the design gate authorizes implementation, not
the pull request. Approvals are never banked, and gates are never batched into one
message.

**Always yours:** approving the pull request, merging it, deleting the branch, and
releasing — cutting `release/*`, the pull request into `main`, the tag.
The skill may prepare and push the branch and open the PR once Gate 3 clears —
that's the boundary. A blanket "just do the whole thing" skips gates, not those.

## README backlog tracking

If your `README.md` mirrors the backlog — the roadmap and backlog tables
[generate-specs-from-brainstorm](generate-specs-from-brainstorm.md) writes, or any
equivalent — the skill marks the use case's row done as part of finishing it.

| Behavior | Rule |
|---|---|
| Detection | A `Roadmap`/`Backlog` section, a table with issue numbers or `UC-xx` identifiers, a milestone closed-count, or a use case checklist. A feature list or a link to the issues page is not tracking. |
| Scope of the edit | This use case's row, the milestone's closed count if there is one, and the milestone's status only when this was its last open item. Nothing else. |
| Done marker | Copied from the file's own convention. If nothing is complete yet, it picks the obvious form for the column and tells you at Gate 3 so you can correct it. |
| No tracking present | Skipped silently. It will not add a backlog to a README that doesn't have one. |
| Row missing | Reported, not invented — a use case absent from the backlog means the README is stale or the use case was never planned, and that's yours to decide. |

The change is committed **on the use case's branch**, so it merges with the
implementation rather than as a direct commit to your base branch. Marking it done
before the merge isn't premature: the edit is invisible on the base branch until
the pull request merges, which is the same moment the issue closes. If the pull
request is abandoned, the README change goes with it.

## CHANGELOG entry

Projects that keep a `CHANGELOG.md` record every change under `## [Unreleased]` in
the same pull request that makes it, and a use case is no exception.

| Behavior | Rule |
|---|---|
| Detection | `CHANGELOG.md` at the root with a `## [Unreleased]` section. `CONTRIBUTING.md` usually says who it is written for. |
| Subsection | `### Added` for a new capability (the usual case), `### Fixed` for a fix, `### Changed` / `### Removed` / `### Security` when they fit — reused if already present. |
| Wording | Written for the changelog's reader — API client, operator, or user — in the file's own phrasing. Not a list of handlers and tests. |
| Scope of the edit | One entry under `## [Unreleased]`. Released sections and the compare links are left alone; the owner finalizes them at release time. |
| No `CHANGELOG.md` | None is created; Gate 3 says so. |

The exact entry is shown at Gate 3 and committed on the use case's branch with the
README update.

## Requirements

The project needs workflow documents. The canonical layout is the one
[generate-specs-from-brainstorm](generate-specs-from-brainstorm.md) produces:

```
<docs-root>/
├── initial/Workflow.md                              ← operational step-by-step
└── requirements/
    ├── Development Workflow Document.md             ← normative process
    ├── Use Case Specification Document.md
    ├── System Requirements Document.md
    ├── Testing Specification Document.md
    └── Technology Stack Document.md
```

`<docs-root>` is the project root in that layout; other projects nest the same pair
under `docs/`. Documents are found **by name and content**, not by a hardcoded
path, so either is fine.

**If no workflow document exists, the skill stops** and offers two ways forward:
generate the requirements set, or state the process yourself. It will not infer a
workflow from git history or existing branch names — an inferred process is a
guessed process.

If both workflow documents exist and contradict each other — different branch
patterns, a gate present in one and absent in the other — it surfaces the conflict
and asks, rather than silently picking one.

The one thing a document cannot override is a branching model the repository
**enforces**: a pull request the Branch Policy check rejects cannot merge, so the
enforced base branch and prefixes win, and the disagreeing document is reported.

## How it works

1. **Identify** the use case; one invocation handles exactly one.
2. **Locate and validate** the workflow documents; stop if they're missing.
3. **Extract** the project's parameters — including the enforced branching model
   and whether a README backlog and a `CHANGELOG.md` exist — and report them, so a
   misread is cheap to fix.
4. **Load** the specifications for this use case and find its tracking issue.
5. **Design and plan**, grounded in the repository's existing patterns → **Gate 1**,
   which also names the branch, its base, and any stale workflow document.
6. **Branch** from the base (`develop` on the `develop` flow) and mark the work
   started — the one unattended transition.
7. **Implement** the main flow and every alternative flow.
8. **Gate 2** → move to the testing status.
9. **Test until green**, reporting real command output.
10. **Gate 3**.
11. **Record the use case** — its README backlog row, if the README tracks issues,
    and its `## [Unreleased]` CHANGELOG entry, if the project keeps a changelog.
12. **Push and open the pull request** into the base branch, then hand off.
13. **Gate 4** → close out after you merge.
14. **Verify** the Definition of Done from the project's document.

## Files in this skill

| Path | Purpose |
|---|---|
| `SKILL.md` | The procedure, the red flags, and the gate structure. |
| `references/doc-discovery.md` | Finding the workflow documents, resolving conflicts between them, the enforced branching model, and the parameter-extraction table. |
| `references/gate-protocol.md` | What a pause looks like, what never counts as approval, and which actions stay human. |
| `references/readme-tracking.md` | Detecting a README backlog, which rows to change, and matching the file's own done marker. |
| `references/changelog-entry.md` | Detecting a changelog, choosing the `## [Unreleased]` subsection, and writing the entry for its reader. |

## What you get back

A use case implemented on its own branch with every flow covered, a green suite
whose real output you've seen, its backlog row and changelog entry in place, and a
pull request into your integration branch ready for your review — with four
points along the way where the work stopped and asked.
