---
name: create-nuget-publish-workflow
description: Use when adding or generating a GitHub Actions workflow that publishes a .NET project's NuGet package(s) to nuget.org and GitHub Packages — a tag-triggered publish-package.yml. Picks the single-package (simple tag) or multi-package (PackageId@version tag + release.py) strategy based on how many packable projects the solution has.
---

# Create NuGet Publish Workflow

## Overview

Generates a `.github/workflows/publish-package.yml` that packs a .NET project and
pushes it to **nuget.org** and **GitHub Packages** on a version tag.

**Core decision:** the number of publishable projects picks the strategy.

- **Exactly one** publishable project → **single-package** strategy:
  any version tag (`1.2.3` or `v1.2.3`) publishes the one package.
- **More than one** → **multi-package** strategy: tags of the
  form `<PackageId>@<version>` publish a specific package, plus a `scripts/release.py`
  helper to bump/tag/push.

## When to Use

- The user asks to "publish to NuGet", "add a release/publish workflow", "set up
  the GitHub action to publish the package(s)", or points at these reference repos.
- A .NET repo has one or more packable projects but no publish workflow (or an
  outdated one) in `.github/workflows/`.

Skip / adapt if the repo is not .NET, does not use the `src/<Project>/…csproj`
layout, or publishes somewhere other than NuGet/GitHub Packages.

## What Counts as a Publishable Project

A `.csproj` is publishable to NuGet when it has a **`<PackageId>`** element (these
repos also carry `<Version>`, `<PackageLicenseExpression>`, etc.). Test/sample
projects and internal libraries omit `<PackageId>` and are excluded.

Detect them (run from the repo root):

```bash
# Packable projects = csproj files containing <PackageId>
grep -rl "<PackageId>" --include=*.csproj src | sort
```

Both layouts are valid:
- Single: project may sit directly in `src/` (e.g. `src/MyLib.csproj`).
- Multi: each project in its own folder `src/<PackageId>/<PackageId>.csproj`
  (the multi-package workflow's "Locate project" step assumes this layout).

## Procedure

1. **Analyze the target repo.** Confirm it is a .NET solution and find publishable
   projects with the grep above. Read each matched csproj to capture its
   `<PackageId>`, `<Version>`, `<RepositoryUrl>`, and the `<TargetFramework>`
   (to choose the SDK version, e.g. `net10.0` → `10.0.x`).
2. **Count publishable projects.**
   - **1 project → single-package.** Copy `templates/single-package.yml` and fill
     placeholders (see below).
   - **>1 projects → multi-package.** Copy `templates/multi-package.yml`, then copy
     `templates/release.py` to `scripts/release.py` in the repo. Confirm every
     package uses the `src/<PackageId>/<PackageId>.csproj` layout; if any project
     sits elsewhere, adjust the "Locate project" step accordingly.
3. **Write the workflow** to `.github/workflows/publish-package.yml` in the target
   repo (create `.github/workflows/` if missing).
4. **Handle non-publishable-but-present packages** (rare): if a project has a
   `<PackageId>` but must NOT be published (e.g. a dependency is unavailable), add
   its id to the `DEFERRED` set in `scripts/release.py` and add a matching guard in
   the workflow's "Locate project" step, so the script refuses to tag/push it and the
   workflow won't publish it.
5. **Tell the user the follow-ups** (these are their responsibility, not yours):
   - Add the `NUGET_API_KEY` secret in the repo settings (`GITHUB_TOKEN` is
     automatic). The workflow needs `packages: write` permission (already set).
   - How to release: single-package → `git tag 1.2.3 && git push origin 1.2.3`
     (tag must equal the csproj `<Version>`); multi-package → run
     `python scripts/release.py` (interactive) or
     `python scripts/release.py release <project> patch`.

## Placeholders to Fill

Both templates use `__UPPER_CASE__` placeholders — replace every occurrence:

| Placeholder | Value | Source |
|---|---|---|
| `__DOTNET_VERSION__` | SDK version glob, e.g. `10.0.x` | from `<TargetFramework>` (net10.0 → 10.0.x) |
| `__CSPROJ_PATH__` | repo-relative path, e.g. `src/MyLib.csproj` | single-package only |
| `__REPOSITORY_URL__` | e.g. `https://github.com/owner/repo` | single-package only; from `<RepositoryUrl>` or `git remote` |

The multi-package template resolves the project path and version at runtime from
the tag, so it has no per-project placeholders beyond `__DOTNET_VERSION__`.

## How the Two Workflows Differ

| | Single-package | Multi-package |
|---|---|---|
| Tag trigger | `'*'` (any tag; `v` prefix stripped) | `'*@*'` (`<PackageId>@<version>`) |
| Version check | tag vs the one csproj `<Version>` | resolves package from tag, checks its `<Version>` |
| `workflow_dispatch` | reason only | package id + version inputs |
| Release helper | none (plain `git tag`) | `scripts/release.py` (bump/tag/push, per-package) |
| Layout assumed | any csproj path | `src/<PackageId>/<PackageId>.csproj` |

Both jobs are otherwise identical: checkout tag → setup .NET → validate version →
restore → pack (Release) → `dotnet nuget push` to nuget.org then GitHub Packages,
both with `--skip-duplicate`.

## Common Mistakes

- **Counting non-packable projects.** Only `<PackageId>`-bearing csproj files count.
  A repo with one library + several test projects is *single-package*.
- **Picking multi-package for one project.** Don't add `release.py` / `@`-tags when
  a single package would use the simpler tag flow.
- **Wrong SDK version.** Derive `__DOTNET_VERSION__` from `<TargetFramework>`; don't
  hardcode `10.0.x` if the project targets something else.
- **Forgetting the release ergonomics for multi-package.** The `release.py` script
  is what makes per-package `@`-tags usable — copy it, don't skip it.
- **Batch-pushing >3 tags at once.** GitHub drops the push event past three tags in
  one push, so nothing publishes. `release.py` already pushes tags one at a time;
  preserve that if you edit it.
