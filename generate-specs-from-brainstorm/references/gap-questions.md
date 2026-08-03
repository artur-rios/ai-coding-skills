# Gap Questions

Each document needs specific inputs. Before writing a phase, walk its checklist
against the source material and collect every unanswered item. Ask them **in one
batch** per phase — never write a document and then discover you needed an
answer, and never invent one.

## How to use this file

1. Read the source material for the phase (Phase 1: `Brainstorm.md`; Phase 2:
   the four approved `initial/` documents; Phase 3: the `requirements/` set).
2. For each checklist item below, mark it **answered** (the source states it,
   explicitly or by unambiguous implication) or **missing**.
3. Ask every missing item in a single batch, grouped by topic.
4. Only then write the documents.

An item is answered by *implication* only when a single reading is possible.
"A REST API for managing orders" implies the system exposes HTTP endpoints; it
does **not** imply the authentication model, the database, or who the actors are.

## Reasonable-default exceptions

Three narrow cases may be defaulted instead of asked, and each must be stated
plainly in the completion report so the user can correct it:

- **Document metadata** — project name taken from the brainstorm's title or the
  containing folder name.
- **Identifier area codes** — derived from the domain areas the brainstorm
  already names (see `doc-conventions.md` §3).
- **Diagram composition** — which entities appear in a diagram, when the entities
  themselves are all stated.

Everything else on the checklists is a question.

---

## Phase 1 — `initial/` documents

### Project Overview

- [ ] Project name.
- [ ] One-sentence description of what the system is.
- [ ] The problem it solves, and for whom.
- [ ] Primary users / consumers (human roles, calling systems, or both).
- [ ] Core capabilities — the handful of things the system must do.
- [ ] Explicit non-goals: what is deliberately out of scope.
- [ ] Success criteria — how you would know it works.

### Technology Stack (informal)

- [ ] Runtime platform and language, with version if the user has a preference.
- [ ] Application type (HTTP API, CLI, worker/daemon, desktop, library, …).
- [ ] Persistence: database engine, or explicitly none.
- [ ] Data access approach (ORM, query builder, raw driver).
- [ ] Authentication / authorization mechanism, or explicitly none.
- [ ] Test framework and the kinds of tests intended.
- [ ] Any first-party or mandated libraries that must be used.
- [ ] External services the system depends on (email, payments, identity
      providers, message brokers, object storage).
- [ ] Hosting / deployment target, if decided.

### Workflow

- [ ] Version control host and repository (GitHub, GitLab, …).
- [ ] Issue / work tracking (project board, issue tracker, none).
- [ ] Branch naming convention, if the user has one.
- [ ] Whether pull requests and human review are required before merge.
- [ ] Which stage transitions an agent may perform unattended, and which need
      explicit approval.
- [ ] Whether the unit of work is a use case, a ticket, or something else.

If the brainstorm is silent on all of these, ask once whether to adopt the
template's default flow (one unit of work = one branch = one issue = one pull
request, human review required, agent pauses at every stage boundary) rather than
asking six separate questions.

### Business Rules

- [ ] The domain entities and what each represents.
- [ ] Relationships and cardinality between entities.
- [ ] Invariants — what must always be true.
- [ ] Validation constraints on key fields (uniqueness, format, required).
- [ ] Permission rules: which role may do what.
- [ ] Lifecycle rules: creation, state transitions, deletion semantics
      (soft delete, hard delete, or both).
- [ ] Anything explicitly forbidden.

---

## Phase 2 — `requirements/` documents

Most Phase 2 input comes from the approved `initial/` documents. These checklists
cover what those four do **not** already answer.

### Vision Document

- [ ] Stakeholders beyond the end users, and each one's primary concern.
- [ ] What the product is positioned *against* — the status quo it replaces.
- [ ] Hard constraints: mandated platform, compliance, budget, deadline.

### System Requirements Document

- [ ] For each entity: its fields, types, and which are required.
- [ ] Identifier strategy — how entities are addressed internally versus
      externally (single ID, or internal key plus public identifier).
- [ ] The endpoint or command surface, if the brainstorm did not enumerate it.
- [ ] Non-functional targets: response time, throughput, availability, retention,
      audit, or explicitly "none defined yet".
- [ ] The authorization matrix — role × operation.

### Use Case Specification Document

- [ ] Confirmation of the actor list, including external systems.
- [ ] Whether any capability in the overview should be split into, or merged
      from, multiple use cases.
- [ ] Failure behavior worth specifying as alternative flows beyond the obvious
      not-found / unauthorized / invalid-input trio.

### Development Workflow Document

- [ ] Nothing new — this document is the formalization of the approved
      `initial/Workflow.md`. Ask only if that document left a stage undefined.

### Operations & Infrastructure Document

- [ ] Solution / repository layout, if a structure is intended.
- [ ] Configuration mechanism (environment variables, config files, secret store).
- [ ] Logging and monitoring expectations.
- [ ] Health check requirements.
- [ ] Environments (local, staging, production) and how they differ.
- [ ] Build and deployment pipeline, if decided.

### Technology Stack Document

- [ ] Exact versions for anything the informal Technology Stack left unpinned.
- [ ] Whether unpinned items should be recorded as "latest stable at
      implementation time" rather than being guessed at a number.

Never invent a version number. If the user does not know, record the policy, not
a fabricated version.

### Testing Specification Document

- [ ] Which test categories apply (unit, integration, functional/end-to-end,
      contract, performance).
- [ ] Test naming convention, if the user has one.
- [ ] How external dependencies are handled in tests (fakes, mocks, containers,
      live sandbox).
- [ ] Coverage expectations per unit of work.
- [ ] How the suites are executed and separated (filters, tags, projects).

---

## Phase 3 — README and GitHub backlog

Phase 3 derives almost everything from the approved documents. These are the only
questions it can need — ask whatever is still open in one batch, before writing
the README and before touching GitHub.

### README

- [ ] The install command, when the Technology Stack Document does not determine
      it (`dotnet restore`, `npm install`, `uv sync`, …).
- [ ] The command that starts the application, if the documents never state one
      and the project is not a library.
- [ ] The test command, when the Testing Specification Document does not state it.

Never write a command you cannot point to a document for. A README command that
does not work is the first thing a reader tries and the first thing that breaks
their trust in the rest of the file.

### Milestones and issues

- [ ] Confirmation of the milestone grouping — always presented for approval, never
      assumed (see `github-backlog.md` §2).
- [ ] Whether to create the milestones and issues on GitHub now, or leave the
      README roadmap as a plan the user creates later.
- [ ] The target repository, if the working directory has no GitHub remote.
- [ ] Which existing labels to apply, if the user wants labels at all. Do not
      invent a label taxonomy.
- [ ] Real due dates, only if the user volunteers them. Never derive a date from
      an estimate.
