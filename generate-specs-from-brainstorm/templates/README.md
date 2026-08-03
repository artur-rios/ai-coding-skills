<!--
GUIDANCE — delete this comment block in the generated file.

The project README, written at the repository root. It is the entry point: what
the project is, where its specifications live, how to install and test it, and
what the planned work is.

The project has no code yet. Installation and testing commands are therefore the
**intended** commands implied by the approved Technology Stack Document and
Testing Specification Document (`dotnet restore`, `npm install`, `pytest`, …).
Take them from those documents. If the stack does not determine a command, ask —
never invent one, and never write a command you could not justify from a document.

Substitutions:
  {{Project Name}}        e.g. Acme Ordering API
  {{one-paragraph description}}   from initial/Project Overview.md §What This Is
  {{capability}}          core capabilities, from §What It Does
  {{non-goal}}            from §What It Doesn't Do
  {{prerequisite}}        runtime/SDK and version, from the Technology Stack Document
  {{install command}}     from the Technology Stack Document
  {{run command}}         how the application is started, if the documents define it
  {{test command}}        from the Testing Specification Document
  {{test category}}       unit / integration / functional, per the Testing Specification

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
cd {{Project Name}}
{{install command}}
```

{{run command block — include only if the documents define how the application is started}}

## Testing

{{test command}} runs the suite described in the
[Testing Specification Document](requirements/Testing%20Specification%20Document.md):

```bash
{{test command}}
```

The suite covers {{test category}} tests. Every unit of work is expected to ship
with tests before its pull request is opened.

## Roadmap

<!-- Milestones, in dependency order. See references/github-backlog.md §4. -->

| Milestone | Delivers | Depends on | Issues | Status |
|---|---|---|---|---|

## Backlog

<!-- One H3 per milestone, in the same order as the Roadmap table. -->

## Contributing

One unit of work = one branch = one issue = one pull request. The full process —
branch naming, issue status lifecycle, the testing gate, and the Definition of
Done — is in the
[Development Workflow Document](requirements/Development%20Workflow%20Document.md).
