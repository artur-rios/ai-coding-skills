<!--
GUIDANCE — delete this comment block in the generated file.

The project README, written at the repository root. It is the entry point for
someone who will use or operate the project: what it is, where its
specifications live, how to install and run it, and what the planned work is.

The README holds consumer and operator content only. Building from source,
running the tests, the branching model and the release process belong in
CONTRIBUTING.md (templates/CONTRIBUTING.md), and the release history in
CHANGELOG.md (templates/CHANGELOG.md) — the README ends with two short sections
pointing at them. The Roadmap and Backlog tables stay here.

The project has no code yet. Installation commands are therefore the
**intended** commands implied by the approved Technology Stack Document and
Operations & Infrastructure Document (`dotnet restore`, `npm install`, a
`docker compose` invocation, …). Take them from those documents. If the stack
does not determine a command, ask — never invent one, and never write a command
you could not justify from a document.

Substitutions:
  {{Project Name}}        e.g. Acme Ordering API
  {{one-paragraph description}}   from initial/Project Overview.md §What This Is
  {{capability}}          core capabilities, from §What It Does
  {{non-goal}}            from §What It Doesn't Do
  {{prerequisite}}        what an operator needs installed to run it, from the
                          Technology Stack Document
  {{repo}}                the repository's directory name — the last segment of
                          its URL, not the project name, which may contain spaces
  {{install command}}     from the Technology Stack Document
  {{configure step}}      how configuration is supplied, from the Operations &
                          Infrastructure Document — omit if it defines none
  {{run command}}         how the application is started, if the documents define it

Omit the Roadmap and Backlog rows' links until the issues exist; see
references/github-backlog.md §4.
-->

# {{Project Name}}

{{one-paragraph description}}

> **Status:** specification complete, implementation not started.

## What it does

- {{capability}}
- {{capability}}

## What it doesn't do

- {{non-goal}}

## Specifications

The project is specified before it is built. Start with the `initial/` documents
for context, then the `requirements/` documents for the normative detail.

| Document | What's in it |
|---|---|
| [Brainstorm](initial/Brainstorm.md) | The original free-form notes this project grew from. |
| [Project Overview](initial/Project%20Overview.md) | What the project is, who it's for, and how success is measured. |
| [Technology Stack](initial/Technology%20Stack.md) | The informal stack decisions. |
| [Workflow](initial/Workflow.md) | How one unit of work is delivered, step by step. |
| [Business Rules](initial/Business%20Rules.md) | Domain entities, relationships, and the `BR-xx` rules. |
| [Vision Document](requirements/Vision%20Document.md) | Stakeholders, positioning, and the `F-xx` features. |
| [System Requirements Document](requirements/System%20Requirements%20Document.md) | The `FR-<AREA>-xx` and `NFR-xx` requirements, data model, and traceability. |
| [Use Case Specification Document](requirements/Use%20Case%20Specification%20Document.md) | The `UC-xx` use cases, their flows, and their `AF-xx` alternatives. |
| [Development Workflow Document](requirements/Development%20Workflow%20Document.md) | The normative branch pattern, issue lifecycle, and Definition of Done. |
| [Testing Specification Document](requirements/Testing%20Specification%20Document.md) | How tests are written, named, and run. |
| [Technology Stack Document](requirements/Technology%20Stack%20Document.md) | The single source of truth for every technology and version. |
| [Operations & Infrastructure Document](requirements/Operations%20%26%20Infrastructure%20Document.md) | Layout, configuration, logging, health, and the `IR-xx` platform requirements. |

## Installation

Prerequisites: {{prerequisite}}

```bash
git clone <repository-url>
cd {{repo}}
{{install command}}
```

{{configure step — include only if the documents define how configuration is supplied}}

{{run command block — include only if the documents define how the application is started}}

## Roadmap

<!-- Milestones, in dependency order. See references/github-backlog.md §4. -->

| Milestone | Delivers | Depends on | Issues | Status |
|---|---|---|---|---|

## Backlog

<!-- One H3 per milestone, in the same order as the Roadmap table. -->

## Changelog

Notable changes in each release are recorded in [CHANGELOG.md](./CHANGELOG.md).

## Contributing

Building from source, running the tests, the delivery workflow, the branching model and the release
process are described in [CONTRIBUTING.md](./CONTRIBUTING.md).
