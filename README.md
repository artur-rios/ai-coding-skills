# ai-coding-skills

> [!NOTE]
> This is the real, open-source code of ai-coding-skills. Its home is Forgejo, at
> https://git.techcraftsmen.net/artur-rios/ai-coding-skills; the copy on GitHub is a read-only mirror, for viewing only, and
> its issues and pull requests are not followed. If you want to contribute, email me at
> arturdev@duck.com.

[![License: Attribution](https://img.shields.io/badge/License-Attribution-blue.svg)](./LICENSE)

A collection of reusable **agent skills** for AI coding assistants such as
[Claude Code](https://docs.claude.com/en/docs/claude-code),
[Codex](https://developers.openai.com/codex) and [opencode](https://opencode.ai). Each skill packages a focused, repeatable
workflow — instructions, templates, and reference material — that the agent loads
on demand when your request matches the skill's purpose.

## What's a skill?

A skill is a directory containing a `SKILL.md` file with YAML frontmatter
(`name` + `description`) and a set of instructions, optionally alongside
templates and reference files. The agent reads the descriptions of the skills
available to it and invokes the matching one automatically — you don't call it by
hand, you just describe what you want.

## Skills in this repository

| Skill | What it does | Docs |
|---|---|---|
| **create-unit-tests** | Generates a thorough unit-test suite for a target project in any stack (.NET, JS / TS, Python, JVM, Rust, Go, Dart / Flutter) and any kind of project (library, API, front end, CLI, mobile), using Given-When-Then test names spelled the language's way, the project's own framework, test location and unit marker, and covering happy paths plus edge cases. | [docs/create-unit-tests.md](docs/create-unit-tests.md) |
| **create-nuget-publish-workflow** | Generates a tag-triggered GitHub Actions workflow that publishes a .NET library's NuGet package(s) to nuget.org and GitHub Packages, only from tags on `main` that match the csproj version. Requires a repo that actually ships a package. | [docs/create-nuget-publish-workflow.md](docs/create-nuget-publish-workflow.md) |
| **generate-project-docs** | Documents an existing project in any stack — a library published as packages (NuGet, npm, PyPI, crates.io, Maven Central, pub.dev, Go) or an application (API, web app, CLI) — with a README for its users, a CHANGELOG.md and a CONTRIBUTING.md, plus a Hugo docs site (Docsy theme) that renders those two files, with an optional test coverage report, deployed to GitHub Pages via CI. | [docs/generate-project-docs.md](docs/generate-project-docs.md) |
| **scaffold-project** | Bootstraps a new repository in any stack — .NET (layered DDD + CQRS web API, minimal web API, NuGet library with its package metadata, any `dotnet new` template), Spring Boot, Python, Node.js / TypeScript, React with shadcn/ui, Angular with spartan/ui, Rust, Flutter — all on one shape: `src/`, `tests/`, `docs/`, README, CHANGELOG, CONTRIBUTING, LICENSE, `.wakatime-project` and the develop / release branch policy, verified with a build and the tests. | [docs/scaffold-project.md](docs/scaffold-project.md) |
| **commit-staged-changes** | Commits the already-staged files with a lowercase Conventional Commits message that follows the 50/72 rule. | [docs/commit-staged-changes.md](docs/commit-staged-changes.md) |
| **generate-specs-from-brainstorm** | Expands a `Brainstorm.md` into fourteen project documents — an informal `initial/` set, a formal `requirements/` set, and a README, CHANGELOG and CONTRIBUTING — then derives GitHub milestones and issues from the use cases, pausing for review at each hand-off. | [docs/generate-specs-from-brainstorm.md](docs/generate-specs-from-brainstorm.md) |
| **implement-use-case** | Drives one use case from backlog to a review-ready pull request into the integration branch (`develop` where the repository enforces that model), following the project's own workflow documents, marking it done in the README backlog, adding its Unreleased CHANGELOG entry, and pausing for approval at every stage boundary. | [docs/implement-use-case.md](docs/implement-use-case.md) |
| **implement-use-cases-batch** | Runs that same workflow across a range of use cases unattended — the four approval gates become automated verifications, and it merges its own pull requests into the integration branch, never `main`. Authorized once up front; stops the batch on any failed check. | [docs/implement-use-cases-batch.md](docs/implement-use-cases-batch.md) |

Each linked page explains what the skill does, when it triggers, how it works,
and what files it contains.

## Repository layout

```
.
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── .github/workflows/branch-policy.yml
├── docs/                              # Per-skill documentation (linked above)
│   ├── create-unit-tests.md
│   ├── create-nuget-publish-workflow.md
│   ├── generate-project-docs.md
│   ├── generate-specs-from-brainstorm.md
│   ├── implement-use-case.md
│   ├── implement-use-cases-batch.md
│   ├── scaffold-project.md
│   └── commit-staged-changes.md
├── create-unit-tests/
│   ├── SKILL.md
│   └── references/
├── create-nuget-publish-workflow/
│   ├── SKILL.md
│   └── templates/
├── generate-project-docs/
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
├── scaffold-project/
│   ├── SKILL.md
│   ├── references/
│   └── templates/
└── commit-staged-changes/
    └── SKILL.md
```

## Using these skills

Skills are discovered by scanning known **skill directories**. Each agent has its own, and each
skill is its whole folder — the directory containing `SKILL.md` — because the templates and reference
files are loaded relative to it. Once a skill is in place, start a session and describe your task; the
agent picks the matching skill from its `description`.

| Agent | Personal folder (all your projects) | Project folder (shared via a repo) |
|---|---|---|
| [Claude Code](https://docs.claude.com/en/docs/claude-code) | `~/.claude/skills/` | `.claude/skills/` |
| [Codex](https://developers.openai.com/codex) | `~/.agents/skills/` (older releases: `~/.codex/skills/`) | `.agents/skills/` |
| [opencode](https://opencode.ai) | `~/.config/opencode/skills/` | `.opencode/skills/` |

On Windows, `~` is `%USERPROFILE%`. opencode also reads the Claude Code and `.agents` folders, so a
skill installed for Claude Code or Codex is already visible to it.

### Install every skill with `sync-skills.ps1`

The repository mirrors itself into those folders:

1. Copy `.env.example` to `.env` and uncomment the paths of the agents you use.
2. Run `./sync-skills.ps1` (on Linux and macOS: `pwsh ./sync-skills.ps1`).

Each run copies every skill, replacing the previous copy, and **removes the skills this repository no
longer ships** — renamed or merged ones — so they stop competing for the same requests. It only ever
removes skills this repository installed; anything else in those folders is left alone.
`-WhatIf` shows what would change; `-Target CLAUDE_SKILLS` limits the run to one agent. Details are
in [CONTRIBUTING.md](./CONTRIBUTING.md#syncing-the-skills-to-your-agents).

### Install one skill by hand

Copy its folder into the agent's skill folder, for example:

```bash
mkdir -p ~/.claude/skills && cp -r generate-project-docs ~/.claude/skills/
mkdir -p ~/.agents/skills && cp -r generate-project-docs ~/.agents/skills/
mkdir -p ~/.config/opencode/skills && cp -r generate-project-docs ~/.config/opencode/skills/
```

Then ask something like *"generate docs for this project"* from a repository and the skill is invoked
automatically. In Claude Code, `/skills` confirms it loaded.

## Changelog

Notable changes are recorded in [CHANGELOG.md](./CHANGELOG.md). Releases follow
[Semantic Versioning](https://semver.org/).

## Contributing

The shape every skill follows, how to add or edit a skill, how to sync the skills to your agents' skill folders, the
branching model and the release process are described in [CONTRIBUTING.md](./CONTRIBUTING.md).

## Author

Artur Rios · arturdev@duck.com

## Legal

This project is licensed under the [Artur Rios Attribution License](./LICENSE). It is free and open source: you may view, use, fork, modify, and extend it, provided you credit the author, Artur Rios, with a link to [artur-rios.tech](https://artur-rios.tech) or [github.com/artur-rios](https://github.com/artur-rios).
