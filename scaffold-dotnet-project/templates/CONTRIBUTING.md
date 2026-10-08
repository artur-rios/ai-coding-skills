<!--
GUIDANCE — delete this comment block, and every "VARIANT" block that does not
apply, in the generated file.

Two variants, picked by the project template (step 7 of SKILL.md):
  LIBRARY      the template is `classlib` — versioned in the csproj, released by
               tagging main; release branches carry the version bump and the
               CHANGELOG finalization; main is merged back into develop.
               Pairs with templates/branch-policy-library.yml.
  APPLICATION  any other template — the version is the release branch name and
               its tag; release branches are snapshots of develop and carry no
               commits. Pairs with templates/branch-policy-app.yml.

Substitutions:
  {{SDK}}        the SDK major version the projects target, e.g. 10.0
  {{Solution}}   src/<Prefix.>SolutionName.sln
  {{CSPROJ}}     the main project's csproj path (LIBRARY only)
-->
# Contributing

## Prerequisites

- [.NET SDK {{SDK}}](https://dotnet.microsoft.com/download) or later
- Git

## Build

```bash
dotnet build {{Solution}}
```

## Testing

Tests live under `tests/`, one test project per project under test, and are written with xUnit. Every test is named
with the Given / When / Then pattern (`GivenSomeCondition_WhenSomeAction_ThenSomeOutput`), and every test class carries
a `Category` trait — `[Trait("Category", "Unit")]` or `[Trait("Category", "Functional")]` — so the two kinds can be run,
and reported, separately:

```bash
dotnet test {{Solution}} --filter "Category=Unit"
dotnet test {{Solution}} --filter "Category=Functional"
```

Unit tests exercise the code in isolation against test doubles; functional tests exercise it end to end.

<!-- VARIANT: LIBRARY -->
## Branching and pull requests

`develop` is the integration branch and the base for all new work; `main` only holds released code.

Branch off `develop` — `feature/<name>` for features, `fix/<name>` for fixes (`feat/`, `bugfix/`, `chore/`,
`refactor/`, `docs/`, `ci/`, `test/`, `perf/` and `build/` are accepted too) — and open a pull request back into
`develop`. Dependabot's `dependabot/*` branches are accepted into `develop` too.

Pull requests into `develop` and `main` must pass the branch policy check
([`branch-policy.yml`](.github/workflows/branch-policy.yml)). The rulesets "Develop: PRs only" and "Main: release PRs
only" reject direct pushes, force pushes and deletion; `main` takes merge commits only.

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/) with a lowercase subject, e.g.
`feat: add order totals` or `fix: reject negative quantities`.

Record every change a package consumer would notice under `## [Unreleased]` in [CHANGELOG.md](./CHANGELOG.md), in the
same pull request that makes it.

## Versioning

Semantic Versioning (SemVer). Breaking changes to the public API or its behaviour result in a new major version. New
types, members or non-breaking behaviour changes increment the minor version; fixes or tweaks increment the patch.
While the version is below 1.0.0, SemVer allows anything to change; a breaking change then increments the minor
version.

The version is the `<Version>` in `{{CSPROJ}}`.

## Releasing

1. Cut `release/<version>` from `develop`, set `<Version>` in `{{CSPROJ}}` to that version, rename `## [Unreleased]` in
   [CHANGELOG.md](./CHANGELOG.md) to `## [<version>] - <yyyy-mm-dd>` above a fresh, empty `## [Unreleased]`, update the
   links at the bottom, and open a pull request into `main`. Only `release/*` branches can be merged into `main`, and
   the branch policy check rejects a release whose version differs from the csproj's or is already tagged.
2. Once it is merged, tag the merge commit on `main` with the version:

   ```bash
   git switch main && git pull
   git tag <version> && git push origin <version>
   ```

3. Open a pull request from `main` into `develop` to bring the release back into the integration branch.

Only the repository owner can push version tags ("Version tags" ruleset).
<!-- END VARIANT -->

<!-- VARIANT: APPLICATION -->
## Branching model

```
feature/<name> ─┐
fix/<name> ─────┴─▶ develop ──▶ release/x.y.z ──▶ main  (tag vx.y.z)
```

| Branch | Cut from | Merges into | How |
|---|---|---|---|
| `feature/<name>`, `fix/<name>` | `develop` | `develop` | Pull request, squash or merge. The branch is deleted on merge. |
| `release/x.y.z` | `develop` | `main` | Pull request, merge commit. |
| `develop`, `main` | — | — | Protected: no direct pushes, no force pushes, no deletion. |

Names are lowercase: letters, digits, `.`, `_` and `-`. A `release/` branch is a snapshot of `develop` and carries no
commits of its own: a fix for a release lands on `develop` through a `fix/` branch and a new release branch is cut.

The **Branch Policy** workflow ([`branch-policy.yml`](.github/workflows/branch-policy.yml)) checks all of this on every
pull request and is a required check on `develop` and `main` (rulesets "Develop: PRs only" and "Main: release PRs
only").

## Commits and the changelog

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/) with a lowercase subject, e.g.
`feat: add order totals` or `fix: reject negative quantities`.

Record every change a user or operator would notice under `## [Unreleased]` in [CHANGELOG.md](./CHANGELOG.md), in the
same pull request that makes it.

## Versioning

Releases are numbered `major.minor.patch` following [Semantic Versioning](https://semver.org/). A major version breaks
something a user, an operator or a client relies on — user-visible behaviour, stored data, configuration, or the
contract clients call; a minor version adds to them compatibly; a patch fixes them. While the version is below 1.0.0,
SemVer allows anything to change; a breaking change then increments the minor version.

The version is the name of the release branch (`release/1.4.0` releases `v1.4.0`); it is not stored in the source. The
Branch Policy workflow refuses a release branch whose version already has a tag.

## Releasing

1. Because a release branch carries no commits of its own, finalize the changelog on `develop` first: in a `feature/`
   or `fix/` branch, rename `## [Unreleased]` in [CHANGELOG.md](./CHANGELOG.md) to `## [x.y.z] - <yyyy-mm-dd>` above a
   fresh, empty `## [Unreleased]`, update the links at the bottom, and merge it into `develop`.
2. Cut the release from an up-to-date `develop` and open a pull request into `main`:

   ```bash
   git switch develop && git pull && git switch -c release/x.y.z && git push -u origin release/x.y.z
   ```

3. Once every check passes, merge it with a merge commit, then tag the merge commit on `main`:

   ```bash
   git switch main && git pull
   git tag vx.y.z && git push origin vx.y.z
   ```

Only the repository owner can push version tags ("Version tags" ruleset), and any workflow a tag triggers must first
verify that the tagged commit is on `main`.
<!-- END VARIANT -->
