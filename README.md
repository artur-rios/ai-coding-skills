# ai-coding-skills

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)

A collection of reusable **agent skills** for AI coding assistants such as
[Claude Code](https://docs.claude.com/en/docs/claude-code) and
[opencode](https://opencode.ai). Each skill packages a focused, repeatable
workflow — instructions, templates, and reference material — that the agent loads
on demand when your request matches the skill's purpose.

## What's a skill?

A skill is a directory containing a `SKILL.md` file with YAML frontmatter
(`name` + `description`) and a set of instructions, optionally alongside
templates and reference files. The agent reads the descriptions of the skills
available to it and invokes the matching one automatically — you don't call it by
hand, you just describe what you want.

## Skill anatomy

Every skill in this repository follows the same shape, so one is readable once you
have read another:

| Section | Contains |
|---|---|
| `# Title` + `## Overview` | What the skill produces, and a **Core principle:** — the one rule that resolves the ambiguous cases. |
| `## When to Use` | Trigger phrases, the **precondition** that scopes the skill to the situations it's for, and a *Skip / adapt if* list naming the skill that handles the neighbouring case. |
| *(domain sections)* | Optional. Anything the reader needs before the red flags make sense — a detection rule, a naming convention, a hard constraint. |
| `## Red Flags — STOP and Re-read the Procedure` | The rationalizations that precede the skill's real failure modes, each with the correction; then a Rationalization / Reality table. |
| `## Procedure` | "Create a todo per step.", then `### N.` steps in execution order. |
| `## Quick Reference` | The decisions and their rules, condensed to tables. |
| `## Common Mistakes` | What goes wrong in practice, phrased as **bold lede** + why it matters. |

Two conventions carry across skills:

- **Preconditions are checked, not assumed.** A skill scoped to a situation says so
  in its `description` and verifies it in step 1, then stops rather than
  improvising. `generate-nuget-lib-docs` and `create-nuget-publish-workflow` share
  their packable-project rule **verbatim** so they can never disagree about what a
  repository ships.
- **Skills defer to the project.** Where a repository documents its own convention —
  a testing standard, a workflow, a branch pattern — the document wins and the
  skill says which it followed.

## Skills in this repository

| Skill | What it does | Docs |
|---|---|---|
| **create-unit-tests** | Generates a thorough unit-test suite for a target project, using Given-When-Then test names and covering happy paths plus edge cases. | [docs/create-unit-tests.md](docs/create-unit-tests.md) |
| **create-nuget-publish-workflow** | Generates a tag-triggered GitHub Actions workflow that publishes a .NET library's NuGet package(s) to nuget.org and GitHub Packages. Requires a repo that actually ships a package. | [docs/create-nuget-publish-workflow.md](docs/create-nuget-publish-workflow.md) |
| **generate-nuget-lib-docs** | Generates a README (package table, NuGet badges, install commands) plus a Hugo docs site (Docsy theme) deployed to GitHub Pages via CI, for a .NET library published as NuGet packages. | [docs/generate-nuget-lib-docs.md](docs/generate-nuget-lib-docs.md) |
| **scaffold-dotnet-project** | Bootstraps a new .NET solution from scratch — `dotnet new` template, DDD or basic layout, config files, README and LICENSE, verified with a build. | [docs/scaffold-dotnet-project.md](docs/scaffold-dotnet-project.md) |
| **scaffold-dotnet-web-api** | Bootstraps a whole .NET 10 web API repository in the layered DDD + CQRS style — six source projects, six test projects, Docker, CI, OpenAPI, docs site — with every cross-cutting concern wired and no domain in it. | [docs/scaffold-dotnet-web-api.md](docs/scaffold-dotnet-web-api.md) |
| **commit-staged-changes** | Commits the already-staged files with a lowercase Conventional Commits message that follows the 50/72 rule. | [docs/commit-staged-changes.md](docs/commit-staged-changes.md) |
| **generate-specs-from-brainstorm** | Expands a `Brainstorm.md` into twelve project documents — an informal `initial/` set, a formal `requirements/` set, and a README — then derives GitHub milestones and issues from the use cases, pausing for review at each hand-off. | [docs/generate-specs-from-brainstorm.md](docs/generate-specs-from-brainstorm.md) |
| **implement-use-case** | Drives one use case from backlog to a review-ready pull request, following the project's own workflow documents, marking it done in the README backlog, and pausing for approval at every stage boundary. | [docs/implement-use-case.md](docs/implement-use-case.md) |
| **implement-use-cases-batch** | Runs that same workflow across a range of use cases unattended — the four approval gates become automated verifications, and it merges its own pull requests. Authorized once up front; stops the batch on any failed check. | [docs/implement-use-cases-batch.md](docs/implement-use-cases-batch.md) |

Each linked page explains what the skill does, when it triggers, how it works,
and what files it contains.

## Repository layout

```
.
├── README.md
├── docs/                              # Per-skill documentation (linked above)
│   ├── create-unit-tests.md
│   ├── create-nuget-publish-workflow.md
│   ├── generate-nuget-lib-docs.md
│   ├── generate-specs-from-brainstorm.md
│   ├── implement-use-case.md
│   ├── implement-use-cases-batch.md
│   ├── scaffold-dotnet-project.md
│   ├── scaffold-dotnet-web-api.md
│   └── commit-staged-changes.md
├── create-unit-tests/
│   ├── SKILL.md
│   └── references/
├── create-nuget-publish-workflow/
│   ├── SKILL.md
│   └── templates/
├── generate-nuget-lib-docs/
│   ├── SKILL.md
│   └── references/
├── generate-specs-from-brainstorm/
│   ├── SKILL.md
│   ├── references/
│   └── templates/
├── implement-use-case/
│   ├── SKILL.md
│   └── references/
├── implement-use-cases-batch/
│   ├── SKILL.md
│   └── references/
├── scaffold-dotnet-project/
│   ├── SKILL.md
│   └── references/
├── scaffold-dotnet-web-api/
│   ├── SKILL.md
│   └── references/
└── commit-staged-changes/
    └── SKILL.md
```

## Using these skills

Skills are discovered by scanning known **skill directories**. To install one,
copy its folder (the directory containing `SKILL.md`) into the appropriate
location for your agent, then start a session and describe your task — the agent
picks the matching skill from its `description`.

### Claude Code

Claude Code loads skills from `.claude/skills/`. Use the project location to
share a skill with a repo, or the personal location to make it available
everywhere.

- **Project (shared via the repo):** `.claude/skills/<skill-name>/SKILL.md`
- **Personal (all your projects):** `~/.claude/skills/<skill-name>/SKILL.md`
  (on Windows: `%USERPROFILE%\.claude\skills\<skill-name>\SKILL.md`)

For example, to install `generate-nuget-lib-docs` personally:

```bash
mkdir -p ~/.claude/skills
cp -r generate-nuget-lib-docs ~/.claude/skills/
```

Then in any Claude Code session, ask something like *"generate docs for this
project"* from a NuGet library repo and the skill is invoked automatically. You can also confirm it loaded
with `/skills`.

### opencode

opencode is compatible with the same `SKILL.md` format and discovers skills from
its own skill directories:

- **Project (shared via the repo):** `.opencode/skill/<skill-name>/SKILL.md`
- **Global (all your projects):** `~/.config/opencode/skill/<skill-name>/SKILL.md`

For example, to install `create-nuget-publish-workflow` globally:

```bash
mkdir -p ~/.config/opencode/skill
cp -r create-nuget-publish-workflow ~/.config/opencode/skill/
```

Then start opencode and describe the task (e.g. *"add a workflow to publish this
package to NuGet"*); opencode loads the matching skill from its description.

> **Note:** both agents match skills by the `description` field in each
> `SKILL.md`, so keep the folder's contents intact when copying — the templates
> and reference files are loaded relative to `SKILL.md`.

## Author

Artur Rios · arturdev@duck.com

## Legal

This project is licensed under the terms of the [MIT License](./LICENSE).
