# Contributing

## Prerequisites

- Git
- [PowerShell 7](https://learn.microsoft.com/powershell/scripting/install/installing-powershell) (`pwsh`) to run
  `sync-skills.ps1` on Linux or macOS
- An agent that loads skills, such as [Claude Code](https://docs.claude.com/en/docs/claude-code) or
  [opencode](https://opencode.ai), to try a skill out

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

## Adding or editing a skill

A skill is a top-level directory containing a `SKILL.md` file with YAML frontmatter (`name` + `description`) and a set
of instructions, optionally alongside templates and reference files. Agents match skills by the `description` field,
and load the templates and reference files relative to `SKILL.md`.

To add one:

1. Create `<skill-name>/SKILL.md` following the [skill anatomy](#skill-anatomy) above, with any templates or reference
   files in `templates/` and `references/` next to it.
2. Write `docs/<skill-name>.md`, explaining what the skill does, when it triggers, how it works, and what files it
   contains.
3. Add the skill to the [README](./README.md): a row in the *Skills in this repository* table linking its docs page,
   and its folder in the *Repository layout* tree.
4. If it handles a case next to an existing skill's, name it in that skill's *Skip / adapt if* list, and the other
   skill in its own.

When editing a skill, keep its docs page and its README row in step with it.

## Syncing the skills to your agents

`sync-skills.ps1` copies every skill in this repository (any top-level directory containing `SKILL.md`) to the skill
folders of your agents, replacing each skill's previous copy there. Everything else in the repository is ignored.

1. Copy `.env.example` to `.env` and uncomment the pair of paths for your platform (absolute paths on Linux and
   macOS). `.env` is git-ignored; never commit it. Both pairs are commented out on purpose: an unedited copy makes the
   sync skip every target instead of writing to a bogus path.
2. Run it:

   ```bash
   ./sync-skills.ps1                         # every target in .env
   ./sync-skills.ps1 -Target CODEX_SKILLS    # only the named targets
   ./sync-skills.ps1 -WhatIf                 # show what would be copied
   ```

   On Linux and macOS, run it with PowerShell 7: `pwsh ./sync-skills.ps1`.

## Branching and pull requests

`develop` is the integration branch and the base for all new work; `main` only holds released skills.

Branch off `develop` — `feature/<name>` for new skills or behaviour, `fix/<name>` for fixes (`chore/`, `refactor/`,
`docs/`, `ci/`, `test/`, `perf/` and `build/` are accepted too) — and open a pull request back into `develop`.

Pull requests into `develop` and `main` must pass the branch policy check
([`branch-policy.yml`](.github/workflows/branch-policy.yml)); the repository has no other CI. The rulesets
"Develop: PRs only" and "Main: release PRs only" reject direct pushes, force pushes and deletion, and `main` takes
merge commits only.

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/) with a lowercase subject, e.g.
`feat: add scaffold-dotnet-web-api skill` or `fix: scope skills and align them on one pattern`. The
`commit-staged-changes` skill in this repository writes them.

Record every change a user of the skills would notice under `## [Unreleased]` in [CHANGELOG.md](./CHANGELOG.md), in the
same pull request that makes it.

## Versioning

Semantic Versioning (SemVer). The public API of this collection is what a user of the skills relies on: each skill's
name, the requests that trigger it (its `description`), the inputs it asks for, and the files it generates in their
repositories.

- **Major** — a skill is renamed or removed, stops triggering on requests it used to handle, needs an input it did not
  need before, or generates files a repository built with the previous version cannot keep using as they are.
- **Minor** — a new skill, or new behaviour in an existing one that leaves those things working: a new optional input,
  an additional generated file, a practice brought up to date.
- **Patch** — corrections to instructions, templates or documentation that do not change what a skill asks for or
  generates.

The version is not stored in any file: a release's version is its `## [<version>]` heading in
[CHANGELOG.md](./CHANGELOG.md) and its `v<version>` tag on `main`. No release has been tagged yet.

## Releasing

1. Cut `release/<version>` from `develop`, rename `## [Unreleased]` in [CHANGELOG.md](./CHANGELOG.md) to
   `## [<version>] - <yyyy-mm-dd>` above a fresh, empty `## [Unreleased]`, update the links at the bottom, and open a
   pull request into `main`. Only `release/*` branches can be merged into `main`; the branch policy check rejects a
   release branch whose CHANGELOG has no section for its version, or whose version is already tagged.
2. Once it is merged, tag the merge commit on `main`:

   ```bash
   git switch main && git pull
   git tag v<version> && git push origin v<version>
   ```

3. Open a pull request from `main` into `develop` to bring the release back into the integration branch.
4. Sync the released skills to your agents from an up-to-date `main` (see
   [Syncing the skills to your agents](#syncing-the-skills-to-your-agents)).

Only the repository owner can push tags ("Version tags" ruleset).
