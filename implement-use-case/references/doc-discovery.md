# Document Discovery

How to find the project's workflow documents, decide which is authoritative, and
extract the concrete parameters this project runs on.

Do this **before** touching the use case. Everything the skill does afterwards is
governed by what these documents say.

## 1. Locate the documents

Search the repository for the two workflow documents and the four specification
documents. The canonical layout produced by `generate-specs-from-brainstorm` is:

```
<docs-root>/
├── initial/
│   └── Workflow.md                              ← operational step-by-step
└── requirements/
    ├── Development Workflow Document.md         ← normative process
    ├── Use Case Specification Document.md
    ├── System Requirements Document.md
    ├── Testing Specification Document.md
    └── Technology Stack Document.md
```

`<docs-root>` is commonly `docs/`, but not always. Search by file name rather than
assuming a path:

```bash
find . -name "Development Workflow Document.md" -o -name "Workflow.md" \
       -o -name "Use Case Specification Document.md" -not -path "*/node_modules/*"
```

If the repository uses different file names for the same documents, match on
content: a normative process document defines a status lifecycle and a Definition
of Done; a use case specification defines actors and numbered use cases.

## 2. Handle a missing set

**If no workflow document exists, stop.** Do not infer a process from git history,
branch names, or an existing pull request. Tell the user what is missing and offer
the two ways forward:

> "I can't find a workflow document in this repository, so I don't know this
> project's branch pattern, status lifecycle, or review gates. Two options: run
> `generate-specs-from-brainstorm` to produce the requirements set, or tell me the
> process and I'll follow it for this use case."

The same applies when the **use case specification** is missing — there is no
use case to implement, only a name.

If the workflow documents exist but the use case specification does not, say so
specifically; the user may have the specification somewhere else.

## 3. Decide which document wins

The two workflow documents have different jobs:

| Document | Job |
| --- | --- |
| `requirements/Development Workflow Document.md` | **Normative.** The process: branch pattern, status lifecycle, testing gate, Definition of Done. |
| `initial/Workflow.md` | **Operational.** The step-by-step an implementer follows, including where to pause. |

They are written to agree. When only one exists, follow it.

**When both exist and they disagree** — different branch pattern, different
stages, a gate present in one and absent in the other — **do not pick one
silently.** That contradiction is a defect in the project's documentation and the
user needs to know:

> "`Development Workflow Document.md` says branches are `feature/uc-##-name`, but
> `Workflow.md` says `uc/##-name`. Which is right? I'll follow your answer and you
> may want to fix the other document."

## 4. Extract the project's parameters

Pull these from the documents rather than assuming them. Record what you found and
where, so the user can correct a misreading before any work starts.

| Parameter | Read from |
| --- | --- |
| Unit-of-work name and ID prefix (`UC`, ticket, story) | Development Workflow §Purpose, Use Case Specification |
| Branch naming pattern | Development Workflow §Step 1 |
| Base branch | Development Workflow §Step 1 |
| Status lifecycle and its column names | Development Workflow §Issue status lifecycle |
| Which transition may be made unattended | `Workflow.md` §The golden rule |
| Issue tracker and how issues are located | Development Workflow, `Workflow.md` |
| Test command(s) and how suites are separated | Testing Specification §Running the suites |
| Definition of Done checklist | Development Workflow §Definition of Done |
| Pull request target and description convention | Development Workflow §Step 6 |
| Whether the backlog is mirrored in the root `README.md`, and how it marks done | The repository's `README.md` — see [readme-tracking.md](readme-tracking.md) §1 |

**If a parameter is undefined in the documents, ask.** A branch pattern nobody
wrote down is not a branch pattern you get to choose.

The README check is the one exception to "read it from the documents": the README
is not a workflow document, and its absence of tracking is an answer, not a gap to
ask about.

## 5. Load the use case specifications

With the process understood, read the specifics for **this** use case. Pull them
fresh; do not work from memory of an earlier use case in the same session.

| Document | What to pull |
| --- | --- |
| Use Case Specification | The target use case: actors, pre/postconditions, the numbered main flow, and **every** `AF-xx` alternative flow. |
| System Requirements | The `FR-<AREA>-xx` requirements the use case cites, plus the data model for the entities it touches, the interface surface, and the authorization matrix rows that apply. |
| Testing Specification | How the tests for this use case must be written, named, and structured. |
| Technology Stack | The libraries, versions, and patterns to build with. |
| Operations & Infrastructure | Only when the use case touches configuration, health, or platform concerns. |

Cross-check as you read: if the use case cites an `FR` that the System
Requirements Document does not define, stop and raise it. Implementing against a
dangling reference means guessing at a requirement.

## 6. Ground in the repository's existing patterns

The specification says *what*. Before designing the *how*, read how the repository
already does this kind of work — the most recently implemented use case is usually
the best reference. Match its layering, naming, error handling, and registration
patterns rather than introducing a new shape.

If the repository has no prior implementation to copy, say so at the first gate.
The user should know the design is establishing a pattern rather than following
one.
