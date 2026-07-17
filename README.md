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

## Skills in this repository

| Skill | What it does | Docs |
|---|---|---|
| **create-nuget-publish-workflow** | Generates a tag-triggered GitHub Actions workflow that publishes a .NET project's NuGet package(s) to nuget.org and GitHub Packages. | [docs/create-nuget-publish-workflow.md](docs/create-nuget-publish-workflow.md) |
| **generate-project-docs** | Generates a README plus a Hugo docs site (deployed to GitHub Pages via CI) for the current project. | [docs/generate-project-docs.md](docs/generate-project-docs.md) |

Each linked page explains what the skill does, when it triggers, how it works,
and what files it contains.

## Repository layout

```
.
├── README.md
├── docs/                              # Per-skill documentation (linked above)
│   ├── create-nuget-publish-workflow.md
│   └── generate-project-docs.md
├── create-nuget-publish-workflow/
│   ├── SKILL.md
│   └── templates/
└── generate-project-docs/
    ├── SKILL.md
    └── references/
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

For example, to install `generate-project-docs` personally:

```bash
mkdir -p ~/.claude/skills
cp -r generate-project-docs ~/.claude/skills/
```

Then in any Claude Code session, ask something like *"generate docs for this
project"* and the skill is invoked automatically. You can also confirm it loaded
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
