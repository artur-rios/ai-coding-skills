---
name: create-nuget-publish-workflow
description: Use when adding or generating a GitHub Actions workflow that publishes a .NET library's NuGet package(s) to nuget.org and GitHub Packages — a tag-triggered publish-package.yml. Requires a .NET repository with at least one packable project (`<PackageId>`, `<IsPackable>true</IsPackable>`, or `<GeneratePackageOnBuild>`); says so and stops if the repo ships no NuGet package. Picks the single-package (simple tag) or multi-package (PackageId@version tag + release.py) strategy based on how many packable projects the solution has.
---

# Create NuGet Publish Workflow

## Overview

Generates a `.github/workflows/publish-package.yml` that packs a .NET project and
pushes it to **nuget.org** and **GitHub Packages** on a version tag — but only a
tag that points at a commit on `main` and names the version the csproj declares.
Released code is what reaches `main` through a `release/*` pull request, so the
workflow refuses anything else.

**Core principle:** the repository decides the strategy, not you. Count the packable
projects and let the count pick:

- **Exactly one** packable project → **single-package** strategy:
  any version tag (`1.2.3` or `v1.2.3`) publishes the one package.
- **More than one** → **multi-package** strategy: tags of the
  form `<PackageId>@<version>` publish a specific package, plus a `scripts/release.py`
  helper to bump/tag/push.
- **None** → nothing to publish. Stop and say so.

## When to Use

**Precondition: the repository must ship at least one NuGet package.** Verify it
with the detection below *before* anything else.

- The user asks to "publish to NuGet", "add a release/publish workflow", or "set
  up the GitHub action to publish the package(s)", **and** the repo has a packable
  project.
- A .NET repo has one or more packable projects but no publish workflow (or an
  outdated one) in `.github/workflows/`.

**If no packable project exists, stop and say so.** A repo of applications,
services, or samples has nothing to publish; adding `<PackageId>` to a project to
make this skill applicable is a decision for the user, not for you. Ask whether
they want a project made packable, and which.

Skip / adapt if the repo publishes somewhere other than NuGet/GitHub Packages.

## What Counts as a Packable Project

*(This rule is shared verbatim with `generate-nuget-lib-docs` so the two skills
never disagree about what a repository ships. Change it in both or neither.)*

A `.csproj` ships a NuGet package when it **opts in** and is **not excluded**:

| | Signal |
|---|---|
| **Opts in** | An explicit `<PackageId>`, or `<IsPackable>true</IsPackable>`, or `<GeneratePackageOnBuild>true</GeneratePackageOnBuild>` |
| **Excluded** | `<IsPackable>false</IsPackable>`; a test project (references `Microsoft.NET.Test.Sdk`); an executable (`<OutputType>Exe</OutputType>`) that has no `<PackageId>` |

An executable *with* a `<PackageId>` is legitimate — that is how .NET tools ship —
so do not exclude it on `OutputType` alone.

Detect from the **repository root**, not just `src/` — not every repo has one:

```bash
grep -rl -e "<PackageId>" -e "<IsPackable>true</IsPackable>" \
        -e "<GeneratePackageOnBuild>true</GeneratePackageOnBuild>" \
        --include=*.csproj . | sort
```

Then read each match and drop the ones the exclusion column catches.

**The package id** is the `<PackageId>` when set; otherwise it defaults to the
assembly name, which defaults to the project file name. Read it — never infer it
from the folder name.

### This skill needs an explicit `<PackageId>`

The multi-package strategy tags releases as `<PackageId>@<version>`, so it can only
address packages whose id is written in the csproj. A project that packs under the
default id is a packable project but not an addressable one: tell the user and ask
them to set `<PackageId>` explicitly before generating a multi-package workflow.
Single-package repos are unaffected — the tag carries only a version.

Both layouts are valid:
- Single: project may sit directly in `src/` (e.g. `src/MyLib.csproj`).
- Multi: each project in its own folder `src/<PackageId>/<PackageId>.csproj`
  (the multi-package workflow's "Locate project" step assumes this layout).

## Red Flags — STOP and Re-read the Procedure

- "No project has a `<PackageId>`, I'll add one so the workflow makes sense" → NO.
  Making a project packable is a release decision. Ask.
- "There's a library and three test projects, so it's multi-package" → NO. Test
  projects are not packable. That repo is *single-package*.
- "One package, but multi-package is more flexible" → NO. It forces `@`-tags and a
  release script on a repo that needs neither.
- "The folder is `src/MyLib`, so the package id is `MyLib`" → Usually, but read
  `<PackageId>`. A guessed id produces tags nothing responds to.
- "The latest SDK is 10.0.x, I'll use that" → NO. Derive it from
  `<TargetFramework>`; a wrong SDK fails at tag time.
- "`release.py` is just ergonomics, the `@`-tags work without it" → NO. It is what
  makes per-package tagging usable, and it pushes tags one at a time on purpose.
- "The tag-on-main step is redundant, only the owner pushes tags" → NO. It is what
  stops a tag on a release or feature branch from publishing code that never
  reached `main`. Keep it, and keep it before the build.

| Rationalization | Reality |
|---|---|
| "A workflow that publishes nothing is harmless" | It is a broken CI file the user debugs months later, at the worst moment. Stop and ask. |
| "The version check is fussy, packing is enough" | The tag and the csproj `<Version>` disagreeing is exactly the mistake the check exists to catch. |
| "`--skip-duplicate` hides problems" | Re-running a publish after one feed succeeded and the other failed must not fail on the one that already has the package. The version check is what catches a wrong version. |
| "They can add `NUGET_API_KEY` whenever" | Without it every publish fails. It is the one follow-up they cannot skip — say it. |
| "I'll push all the version tags at once" | GitHub drops the push event past three tags in one push, so nothing publishes at all. |

## Procedure

Create a todo per step.

### 1. Analyze the target repo

Confirm it is a .NET solution and find packable projects with the detection above.
**If there are none, stop and report it** — do not generate a workflow for a
repository that publishes nothing.

Read each matched csproj to capture its `<PackageId>`, `<Version>`,
`<RepositoryUrl>`, and the `<TargetFramework>` (which picks the SDK version, e.g.
`net10.0` → `10.0.x`).

### 2. Count the packable projects and pick the strategy

- **1 project → single-package.** Copy `templates/single-package.yml` and fill the
  placeholders in step 3.
- **>1 projects → multi-package.** Copy `templates/multi-package.yml`, then copy
  `templates/release.py` to `scripts/release.py` in the repo. Confirm every package
  uses the `src/<PackageId>/<PackageId>.csproj` layout; if any project sits
  elsewhere, adjust the "Locate project" step accordingly. Confirm too that every
  package has an explicit `<PackageId>` — the `@`-tags cannot address a default id.

### 3. Write the workflow and fill the placeholders

Write it to `.github/workflows/publish-package.yml` in the target repo (create
`.github/workflows/` if missing). Both templates use `__UPPER_CASE__` placeholders —
replace **every** occurrence:

| Placeholder | Value | Source |
|---|---|---|
| `__DOTNET_VERSION__` | SDK version glob, e.g. `10.0.x` | from `<TargetFramework>` (net10.0 → 10.0.x) |
| `__CSPROJ_PATH__` | repo-relative path, e.g. `src/MyLib.csproj` | single-package only |
| `__REPOSITORY_URL__` | e.g. `https://github.com/owner/repo` | single-package only; from `<RepositoryUrl>` or `git remote` |

The multi-package template resolves the project path and version at runtime from
the tag, so it has no per-project placeholders beyond `__DOTNET_VERSION__`.

### 4. Handle packable-but-must-not-publish projects (rare)

If a project has a `<PackageId>` but must NOT be published (e.g. a dependency is
unavailable), add its id to the `DEFERRED` set in `scripts/release.py` and add a
matching guard in the workflow's "Locate project" step, so the script refuses to
tag/push it and the workflow won't publish it.

### 5. Align CONTRIBUTING.md, if the repository has one

The release steps the workflow enforces belong in the repository's
`CONTRIBUTING.md` `## Releasing` section. If the file exists, make that section say
what the workflow now requires; if it does not, leave it and mention it in the report
(`generate-nuget-lib-docs` writes one).

- **Single-package:** cut `release/<version>` from `develop`, set `<Version>`,
  finalize `CHANGELOG.md` (`## [Unreleased]` → `## [<version>] - <yyyy-mm-dd>`),
  open the pull request into `main`; once merged, tag the merge commit on `main`
  (`git switch main && git pull && git tag <version> && git push origin <version>`);
  then a pull request from `main` back into `develop`.
- **Multi-package:** the same, except the version bumps are made on the release
  branch with `python scripts/release.py bump <project> {patch|minor|major}`, the
  CHANGELOG headings are `## [<PackageId> <version>]`, and the tags are created and
  pushed on `main` with `python scripts/release.py tag <project>` /
  `push <project>` (or the interactive menu), dependencies first.
- Close with: only the repository owner can push version tags, and the publish
  workflow rejects tags that do not point at a commit on `main` or whose version
  differs from the one in the csproj.

Tag with the bare version (`1.2.3`) — the form the author's libraries use for
every release since August 2026; older `v1.2.3` tags stay as history, and the
workflow accepts both. In a repository outside that family, use the form its
newest tag uses (`git tag --sort=-creatordate`).

### 6. Report the follow-ups

These are the user's responsibility, not yours — but they must be told:

- Add the `NUGET_API_KEY` secret in the repo settings (`GITHUB_TOKEN` is
  automatic). The workflow needs `packages: write` permission (already set).
- How to release: tags are created on `main`, after the `release/*` pull request
  is merged. Single-package → `git tag 1.2.3 && git push origin 1.2.3` on the merge
  commit (tag must equal the csproj `<Version>`); multi-package → bump on the release
  branch with `python scripts/release.py bump <project> patch`, then on `main` run
  `python scripts/release.py` (interactive) or `tag <project>` and `push <project>`.
  `release.py` refuses to bump on `main` and to tag anything that is not on
  `origin/main`.
- Protect the tags: the author's libraries carry a "Version tags" tag ruleset
  (creation, update and deletion restricted to the repository admin), so only the
  owner can trigger a publish.

## Quick Reference

| Decision | Rule |
|---|---|
| Is the repo in scope? | At least one packable project. None → stop. |
| Which strategy? | 1 packable project → single-package; more than 1 → multi-package. |
| Which SDK version? | From `<TargetFramework>`, never hardcoded. |
| Which package id? | `<PackageId>` as written; never the folder name. |
| Who adds `NUGET_API_KEY`? | The user. Always say so. |
| Which commits can publish? | Only commits on `main`. The workflow verifies it before building. |
| Where are tags created? | On `main`, on the merge commit of the `release/*` pull request. |

### How the two workflows differ

| | Single-package | Multi-package |
|---|---|---|
| Tag trigger | `'*'` (any tag; `v` prefix stripped) | `'*@*'` (`<PackageId>@<version>`) |
| Version check | tag vs the one csproj `<Version>` | resolves package from tag, checks its `<Version>` |
| `workflow_dispatch` | reason only; run it from the tag ("Use workflow from") | package id + version inputs |
| Release helper | none (plain `git tag`) | `scripts/release.py` (bump on the release branch, tag/push on `main`, per-package) |
| Layout assumed | any csproj path | `src/<PackageId>/<PackageId>.csproj` |
| Explicit `<PackageId>` | not required | required — the tag addresses it |

Both jobs are otherwise identical: checkout tag → verify the tagged commit is on
`main` → setup .NET → validate version → restore → pack (Release) →
`dotnet nuget push` to nuget.org then GitHub Packages, both with `--skip-duplicate`.

## Common Mistakes

- **Generating a workflow for a repo with no package.** Check first; a repo of
  apps and samples has nothing to publish, and adding `<PackageId>` to make the
  skill applicable is the user's call.
- **Counting non-packable projects.** Test projects, samples, and executables
  without a `<PackageId>` are excluded. A repo with one library + several test
  projects is *single-package*.
- **Searching only `src/`.** Not every repository has one. Detect from the root.
- **Assuming the package id equals the folder or project name.** It does by
  default, but read `<PackageId>` — an overridden id that you guessed wrong
  produces tags nothing responds to.
- **Picking multi-package for one project.** Don't add `release.py` / `@`-tags when
  a single package would use the simpler tag flow.
- **Wrong SDK version.** Derive `__DOTNET_VERSION__` from `<TargetFramework>`; don't
  hardcode `10.0.x` if the project targets something else.
- **Forgetting the release ergonomics for multi-package.** The `release.py` script
  is what makes per-package `@`-tags usable — copy it, don't skip it.
- **Dropping the "Verify tagged commit is on main" step**, or moving it after the
  pack. A tag pushed from a release or feature branch would publish unreleased code.
- **Telling the user to tag the release branch.** Tags go on the merge commit on
  `main`, after the release pull request merges — the workflow rejects a tag whose
  commit is not on `main`.
- **Batch-pushing >3 tags at once.** GitHub drops the push event past three tags in
  one push, so nothing publishes. `release.py` already pushes tags one at a time;
  preserve that if you edit it.
