# CHANGELOG.md and CONTRIBUTING.md

Every project keeps three documents at the repository root, each with one audience:

| File | For | Holds |
|---|---|---|
| `README.md` | Users — a library's consumers, an application's callers and operators | What it is, install and usage (library) or configure, run, deploy (application), upgrading pointers, links to the other two |
| `CHANGELOG.md` | Users deciding whether and how to upgrade | Every release's notable changes, upgrade guides |
| `CONTRIBUTING.md` | Whoever builds, tests or releases the project | Prerequisites, build, tests, branching, commits, versioning, releasing |

Nothing is written twice. The docs site renders `CHANGELOG.md` and `CONTRIBUTING.md` instead of copying them
(`references/hugo-setup.md` step 5).

**If either file already exists, extend it — never replace it.** Move contributor material you find in the README
(Testing, Build/test/publish, Branching, Versioning, Releasing sections) into `CONTRIBUTING.md`, and upgrade or
migration guides (README "Upgrading to N.0" sections, docs-site migration pages) into `CHANGELOG.md`, verbatim. Say in
the report what moved where.

## CHANGELOG.md

[Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) format. Newest release first, an `## [Unreleased]`
section always on top, compare links at the bottom.

```markdown
# Changelog

All notable changes to `<PrimaryPackageId>` (a library) / <Project Title> (an application) are recorded in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [<version>] - <yyyy-mm-dd>

### Added

- <what a user can now do — a library: naming the public type or member; an application: the endpoint, screen,
  command or setting>

### Changed

- <behaviour that differs, and how>

### Upgrading from <X>.x to <Y>.0

<the upgrade guide, only in the entry of the major version that needs one>

[Unreleased]: https://github.com/<owner>/<repo>/compare/<tag>...HEAD
[<version>]: https://github.com/<owner>/<repo>/compare/<previous-tag>...<tag>
[<first-version>]: https://github.com/<owner>/<repo>/releases/tag/<first-tag>
```

- Subsections, in this order and only when non-empty: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`,
  `Security`. Each bullet is one change a user would notice, written for them: for a library the public type or
  member, for an application the endpoint, screen, command, configuration variable or migration — and what is
  different. Internal refactors and CI changes are not listed.
- **Upgrade guides** live in the entry of the version that needs them, under a subsection titled exactly
  `### Upgrading from <X>.x to <Y>.0` (GitHub anchor `#upgrading-from-<x>x-to-<y>0`). The README's `## Upgrading`
  section links each one (`references/fixed-sections.md`). Keep that entry's other lists concise; the guide carries the
  detail.
- **Compare links use the tags exactly as they exist** (`git tag --list`), `v`-prefixed or not. Never assume a prefix.
- **Building it for a project that has already shipped:** derive the released versions from the tags (or the
  registry's version list when tags are missing), and each entry's changes from `git log <previous-tag>..<tag>` and the merged pull
  requests. Date an entry with its tag's commit date. When no release has been tagged, write only `## [Unreleased]`,
  saying so, and link it to `https://github.com/<owner>/<repo>/commits/develop` (or the default branch if there is no
  `develop`).
- **Multi-package repositories** version each package independently: headings are `## [<PackageId> <version>] -
  <yyyy-mm-dd>`, and compare links use the `<PackageId>@<version>` tags.

## CONTRIBUTING.md

Sections in this order. Fill every command from the repository — the real solution, project or package path, the
real scripts and test filters, the real version file — using `references/stacks.md` for the stack's defaults, never
from habit. A repository with several components gives each its own Build and Testing subsection.

````markdown
# Contributing

## Prerequisites

- <the stack's toolchain and version, with its link (references/stacks.md)>
- <anything else the build or tests need: Docker for Testcontainers, a database, Hugo + Node.js for the docs site>
- Git

<.NET only, optional: "Use the official [.NET CLI](https://learn.microsoft.com/en-us/dotnet/core/tools/) to build,
test and publish the project. If you want, optional helper toolsets I built to facilitate these tasks are
available:" followed by the two links in references/identity.md.>

## Build

```bash
<the build command(s)>
```

## Testing

<the test framework, where the tests live, and the naming pattern they follow (Given / When / Then where the project
uses it). When the tests are split into kinds — a .NET `Category` trait, pytest markers, JUnit tags, separate
folders — say how, and give one command per kind:>

```bash
<the test command(s)>
```

<one sentence each: what the unit and the functional tests exercise in this project. Which CI jobs run them, and
any check CI adds — a format check, a guard against uncategorized tests — with the command to run it locally.>

## Branching and pull requests

`develop` is the integration branch and the base for all new work; `main` only holds released code.

Branch off `develop` — `feature/<name>` for features, `fix/<name>` for fixes (`feat/`, `bugfix/`, `chore/`,
`refactor/`, `docs/`, `ci/`, `test/`, `perf/` and `build/` are accepted too) — and open a pull request back into
`develop`.

Dependabot's `dependabot/*` dependency-update branches are accepted into `develop` too.

Pull requests into `develop` and `main` must pass the tests and the branch policy check.

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/) with a lowercase subject, e.g.
`feat: <example from this project>` or `fix: <example from this project>`.

Record every change a user would notice under `## [Unreleased]` in [CHANGELOG.md](./CHANGELOG.md), in the same pull
request that makes it.

## Versioning

Semantic Versioning (SemVer). <Library: "Breaking changes to the public API or its behaviour result in a new major
version. New types, members or non-breaking behaviour changes increment the minor version; fixes or tweaks increment
the patch." Application: "A major version breaks something a user, an operator or a client relies on — user-visible
behaviour, stored data, configuration, or the contract clients call; a minor version adds to them compatibly; a patch
fixes them.">

<where the version lives — the release model below decides it.>

## Releasing

<the steps of the release model the repository uses — below.>
````

### The two release models

The author's repositories use one of two models, both on `develop` → `release/<version>` → `main`. Write the one the
repository's branch policy and workflows implement (a `branch-policy.yml` that checks a version file → library
model; one that requires release branches to be snapshots of `develop` → application model):

**Library model** — the version lives in a file (`<Version>` in the csproj, `version` in `package.json` /
`pyproject.toml` / `Cargo.toml` / `pubspec.yaml`, `version` in the Gradle build), tags are the bare version:

1. Cut `release/<version>` from `develop`, set the version in `<version file>` to that version, rename
   `## [Unreleased]` in [CHANGELOG.md](./CHANGELOG.md) to `## [<version>] - <yyyy-mm-dd>` above a fresh, empty
   `## [Unreleased]`, update the compare links at the bottom, and open a pull request into `main`. Only `release/*`
   branches can be merged into `main`.
2. Once it is merged, tag the merge commit on `main` with the version. <When a publish workflow exists: "Pushing the
   tag publishes the package to <registry>:">

   ```bash
   git switch main && git pull
   git tag <version> && git push origin <version>
   ```

3. Open a pull request from `main` into `develop` to bring the release back into the integration branch.

Only the repository owner can push version tags, and the publish workflow rejects tags that do not point at a commit
on `main` or whose version differs from the one in the source. <Drop this sentence when no publish workflow exists.>

**Application model** — the version is the release branch name and its `v` tag, not stored in the source:

1. Because a release branch carries no commits of its own, finalize the changelog on `develop` first: in a `feature/`
   or `fix/` branch, rename `## [Unreleased]` to `## [x.y.z] - <yyyy-mm-dd>` above a fresh, empty `## [Unreleased]`,
   update the links at the bottom, and merge it into `develop`.
2. Cut the release from an up-to-date `develop` and open a pull request into `main`:

   ```bash
   git switch develop && git pull && git switch -c release/x.y.z && git push -u origin release/x.y.z
   ```

3. Once every check passes, merge it with a merge commit, then tag the merge commit on `main`:

   ```bash
   git switch main && git pull
   git tag vx.y.z && git push origin vx.y.z
   ```

### Describe the repository as it is

The sections above describe the model the author's projects run on: tests split into unit and functional kinds run
as separate CI jobs (for .NET, a `Category` trait per test class, a guard that fails on an uncategorized test, and a
`dotnet format --verify-no-changes` check), `develop` as the integration branch enforced by a `branch-policy.yml`
required check and the rulesets "Develop: PRs only", "Main: release PRs only" and "Version tags", and — for a
library — a tag-triggered publish workflow that verifies the tag is on `main` and matches the version in the source.

Check each piece before writing its sentence — `git branch -r`, `.github/workflows/`, how the tests are split, the
publish workflow — and write what the repository actually does:

| If the repository | Then |
|---|---|
| Has neither a `branch-policy.yml` nor a `develop` branch | Describe its real flow, and recommend the develop/release model in the report — do not document a model that is not enforced. A fresh repository with the policy but no remote branches yet (one from **scaffold-project**) does enforce it: document it. |
| Does not split its tests into kinds, or has one CI test job | Show the plain test command and say what the suite covers. |
| Is a library with no publish workflow | Say how the package is actually published; for a .NET library point at `create-nuget-publish-workflow` in the report. |
| Is a multi-package .NET library (`release.py`) | Step 1 bumps each changed package with `python scripts/release.py bump <project> {patch\|minor\|major}` and moves its entries into `## [<PackageId> <version>]`; step 2 tags with `python scripts/release.py tag <project>` and `push <project>` on `main`, dependencies first. |
| Is an application with migrations, a container image or a deploy workflow | Add how a release is deployed — the image tag, the workflow, who runs the migrations — to Releasing. |

Take the commit-message examples from the repository's own `git log`, not invented ones. The author's libraries tag
releases with the bare version (`git tag <version>`, e.g. `1.3.0`; multi-package: `<PackageId>@<version>`): every
release since August 2026 uses that form, and older `v`-prefixed tags (`v1.1.0`) are kept as history. Write the bare
form in CONTRIBUTING, say in one sentence that older tags carry a `v`, and never rewrite compare links to a form the
tags do not have. Applications tag `v<version>`. For a repository outside that family, use the form its newest tag
uses (`git tag --sort=-creatordate`).
