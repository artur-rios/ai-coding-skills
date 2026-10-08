# CHANGELOG.md and CONTRIBUTING.md

A NuGet library keeps three documents at the repository root, each with one audience:

| File | For | Holds |
|---|---|---|
| `README.md` | Consumers of the package | What it is, install, usage, upgrading pointers, links to the other two |
| `CHANGELOG.md` | Consumers deciding whether and how to upgrade | Every release's notable changes, upgrade guides |
| `CONTRIBUTING.md` | Whoever builds, tests or releases the library | Prerequisites, build, tests, branching, commits, versioning, releasing |

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

All notable changes to `<PrimaryPackageId>` are recorded in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [<version>] - <yyyy-mm-dd>

### Added

- <what a consumer can now do, naming the public type or member>

### Changed

- <behaviour that differs, and how>

### Upgrading from <X>.x to <Y>.0

<the upgrade guide, only in the entry of the major version that needs one>

[Unreleased]: https://github.com/<owner>/<repo>/compare/<tag>...HEAD
[<version>]: https://github.com/<owner>/<repo>/compare/<previous-tag>...<tag>
[<first-version>]: https://github.com/<owner>/<repo>/releases/tag/<first-tag>
```

- Subsections, in this order and only when non-empty: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`,
  `Security`. Each bullet is one change a package consumer would notice, written for them: the public type or member,
  and what is different. Internal refactors and CI changes are not listed.
- **Upgrade guides** live in the entry of the version that needs them, under a subsection titled exactly
  `### Upgrading from <X>.x to <Y>.0` (GitHub anchor `#upgrading-from-<x>x-to-<y>0`). The README's `## Upgrading`
  section links each one (`references/fixed-sections.md`). Keep that entry's other lists concise; the guide carries the
  detail.
- **Compare links use the tags exactly as they exist** (`git tag --list`), `v`-prefixed or not. Never assume a prefix.
- **Building it for a library that has already shipped:** derive the released versions from the tags (or nuget.org's
  version list when tags are missing), and each entry's changes from `git log <previous-tag>..<tag>` and the merged pull
  requests. Date an entry with its tag's commit date. When no release has been tagged, write only `## [Unreleased]`,
  saying so, and link it to `https://github.com/<owner>/<repo>/commits/develop` (or the default branch if there is no
  `develop`).
- **Multi-package repositories** version each package independently: headings are `## [<PackageId> <version>] -
  <yyyy-mm-dd>`, and compare links use the `<PackageId>@<version>` tags.

## CONTRIBUTING.md

Sections in this order. Fill every command from the repository — the real solution path, the real test filters, the
real csproj path — never from habit.

````markdown
# Contributing

## Prerequisites

- [.NET SDK <major>.0](https://dotnet.microsoft.com/download) or later
- Git

Use the official [.NET CLI](https://learn.microsoft.com/en-us/dotnet/core/tools/) to build, test and publish the project.
If you want, optional helper toolsets I built to facilitate these tasks are available:

- [Dotnet Tools](https://github.com/artur-rios/dotnet-tools)
- [Python Dotnet Tools](https://github.com/artur-rios/python-dotnet-tools)

## Build

```bash
dotnet build src/<Solution>.sln
```

## Testing

The test suite is xUnit, and every test is named with the Given / When / Then pattern. Every test class
carries a `Category` trait, so the two kinds can be run — and reported — separately:

```bash
dotnet test src/<Solution>.sln --filter "Category=Unit"
dotnet test src/<Solution>.sln --filter "Category=Functional"
```

<one sentence each: what the unit and the functional tests exercise in this library.>
CI runs the two as separate jobs, and both must pass before a pull request can be merged.

The unit job also fails when a test has no `Category` trait, since no job would run it, and when
`dotnet format --verify-no-changes` finds a file to reformat; run `dotnet format src/<Solution>.sln` before pushing.

## Branching and pull requests

`develop` is the integration branch and the base for all new work; `main` only holds released code.

Branch off `develop` — `feature/<name>` for features, `fix/<name>` for fixes (`feat/`, `bugfix/`, `chore/`,
`refactor/`, `docs/`, `ci/`, `test/`, `perf/` and `build/` are accepted too) — and open a pull request back into
`develop`.

Dependabot's `dependabot/*` dependency-update branches are accepted into `develop` too.

Pull requests into `develop` and `main` must pass the tests and the branch policy check.

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/) with a lowercase subject, e.g.
`feat: <example from this library>` or `fix: <example from this library>`.

Record every change a package consumer would notice under `## [Unreleased]` in [CHANGELOG.md](./CHANGELOG.md), in the
same pull request that makes it.

## Versioning

Semantic Versioning (SemVer). Breaking changes result in a new major version. New methods or non-breaking behavior
changes increment the minor version; fixes or tweaks increment the patch.

<where the version lives, e.g. "The version is the `<Version>` in `src/<Project>.csproj`." For a multi-package
repository: "Each package is versioned independently, through the `<Version>` in its own csproj, and released with a
`<PackageId>@<version>` tag.">

## Releasing

1. Cut `release/<version>` from `develop`, set `<Version>` in `src/<Project>.csproj` to that version, rename
   `## [Unreleased]` in [CHANGELOG.md](./CHANGELOG.md) to `## [<version>] - <yyyy-mm-dd>` above a fresh, empty
   `## [Unreleased]`, update the compare links at the bottom, and open a pull request into `main`. Only `release/*`
   branches can be merged into `main`.
2. Once it is merged, tag the merge commit on `main` with the version. Pushing the tag publishes the package to
   nuget.org and GitHub Packages:

   ```bash
   git switch main && git pull
   git tag <version> && git push origin <version>
   ```

3. Open a pull request from `main` into `develop` to bring the release back into the integration branch.

Only the repository owner can push version tags, and the publish workflow rejects tags that do not point at a commit on
`main` or whose version differs from the one in the csproj.
````

### Describe the repository as it is

The Testing, Branching and Releasing sections above describe the model the author's libraries run on: a `Category`
trait per test class with Unit and Functional run as separate CI jobs (plus a guard that fails on an uncategorized
test and a `dotnet format --verify-no-changes` check), `develop` as the integration branch enforced by
a `branch-policy.yml` required check and the rulesets "Develop: PRs only", "Main: release PRs only" and "Version tags",
and a tag-triggered `publish-package.yml` that verifies the tag is on `main` and matches the csproj `<Version>`.

Check each piece before writing its sentence — `git branch -r`, `.github/workflows/`, the test classes' traits, the
publish workflow — and write what the repository actually does:

| If the repository | Then |
|---|---|
| Has no `develop` branch or `branch-policy.yml` | Describe its real flow, and recommend the develop/release model in the report — do not document a model that is not enforced. |
| Has no `Category` traits, or one CI test job | Show the plain `dotnet test` command and say what the suite covers. |
| Has no `publish-package.yml` | Say how the package is actually published, and point at `create-nuget-publish-workflow` in the report. |
| Is multi-package (`release.py`) | Step 1 bumps each changed package with `python scripts/release.py bump <project> {patch\|minor\|major}` and moves its entries into `## [<PackageId> <version>]`; step 2 tags with `python scripts/release.py tag <project>` and `push <project>` on `main`, dependencies first. |

Take the commit-message examples from the repository's own `git log`, not invented ones. The author's libraries tag
releases with the bare version (`git tag <version>`, e.g. `1.3.0`; multi-package: `<PackageId>@<version>`): every
release since August 2026 uses that form, and older `v`-prefixed tags (`v1.1.0`) are kept as history. Write the bare
form in CONTRIBUTING, say in one sentence that older tags carry a `v`, and never rewrite compare links to a form the
tags do not have. For a repository outside that family, use the form its newest tag uses (`git tag --sort=-creatordate`);
the publish workflow accepts both.
