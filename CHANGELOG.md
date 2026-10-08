# Changelog

All notable changes to this skill collection are recorded in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

No release has been tagged yet. So far the repository holds:

### Added

- Skills for .NET work: `create-unit-tests`, `create-nuget-publish-workflow`, `generate-nuget-lib-docs` (README plus a
  Hugo docs site on the Docsy theme), `scaffold-dotnet-project` and `scaffold-dotnet-web-api`.
- `commit-staged-changes`, which commits the staged files with a lowercase Conventional Commits message.
- A specs-to-delivery chain: `generate-specs-from-brainstorm` (project documents, README backlog, GitHub milestones and
  issues), `implement-use-case` (one use case to a review-ready pull request, with approval gates) and
  `implement-use-cases-batch` (a range of use cases, unattended).
- A documentation page per skill in `docs/`, and `sync-skills.ps1` to copy every skill to the agents' skill folders
  configured in `.env`.
- The `develop` / `release/<version>` / `main` branching model for this repository, enforced by the Branch Policy
  workflow, with the versioning and release process described in CONTRIBUTING.md.

### Changed

The skills now generate and follow the practices the author's repositories use: a README for consumers and operators
only, a Keep a Changelog `CHANGELOG.md` and a `CONTRIBUTING.md` beside it, docs sites that render those two files
instead of copying them, and the `develop` / `release/<version>` / `main` branching model.

- `generate-nuget-lib-docs` writes `CHANGELOG.md` (SemVer, `## [Unreleased]`, compare links from the real tags,
  upgrade guides under `### Upgrading from <X>.x to <Y>.0`) and `CONTRIBUTING.md` (build, `Category` Unit / Functional
  tests, branching, versioning, releasing), and moves contributor material out of the README. The README's fixed
  sections are now Upgrading (when there is a guide), Changelog, Contributing and Legal Details, linking the files by
  absolute GitHub URL because the README is packed into the package; the Versioning and Build-test-publish sections
  are gone, and SemVer is no longer asked about.
- `generate-nuget-lib-docs` builds the Hugo site on the `@docsy/theme` npm package instead of a git submodule, adds
  Changelog and Contributing pages that render the root files through a `repo-file` shortcode, removes contributor and
  release pages from existing sites, and deploys through the GitHub Pages actions, rebuilding when `CHANGELOG.md` or
  `CONTRIBUTING.md` change.
- `create-nuget-publish-workflow`'s workflows refuse to publish a tag whose commit is not on `main`. The multi-package
  `release.py` bumps versions on the release branch, never on `main`, and tags and pushes only commits on
  `origin/main`; its one-step `release` command is gone. The skill aligns the repository's CONTRIBUTING Releasing
  section with it.
- `scaffold-dotnet-project` writes `CHANGELOG.md`, `CONTRIBUTING.md` and `.github/workflows/branch-policy.yml` — a
  library variant for `classlib` and an application variant otherwise — keeps build and test instructions out of the
  README, asks for the GitHub repository when there is no remote, and lists the remote branch and ruleset setup in its
  report.
- `scaffold-dotnet-web-api` writes a consumer- and operator-only README ending in Changelog and Contributing sections,
  plus `CHANGELOG.md` and a `CONTRIBUTING.md` holding the build, test, migration, branching, versioning and release
  instructions. It adds `branch-policy.yml`, runs CI on pull requests into and pushes to `develop` and `main`, lists the
  remote branch and ruleset setup in its report, and its docs site renders `CHANGELOG.md` and `CONTRIBUTING.md` instead
  of a Testing page.
- `generate-specs-from-brainstorm` also writes `CHANGELOG.md` and `CONTRIBUTING.md`; its README keeps only consumer
  and operator content plus the roadmap and backlog, and ends with short Changelog and Contributing sections. Its
  Development Workflow Document and `Workflow.md` branch from and merge into `develop`, record each change under
  `## [Unreleased]` in the same pull request, and point at CONTRIBUTING.md for releases.
- `implement-use-case` and `implement-use-cases-batch` follow the branching model a repository enforces
  (CONTRIBUTING.md, the Branch Policy workflow, a `develop` branch, rulesets): use-case work is cut from `develop` as
  `feature/` or `fix/` and its pull request targets `develop`, never `main`; a workflow document that still says `main`
  is reported. Both add the use case's entry under `## [Unreleased]` in CHANGELOG.md next to the README backlog
  update, and never create a CHANGELOG or touch released sections.
- `implement-use-cases-batch` checks rulesets as well as branch protection for a required review and the allowed merge
  methods, waits for the Branch Policy check, merges only into the integration branch and leaves releases to the owner.
- `create-unit-tests` marks new test classes with the project's category (`[Trait("Category", "Unit")]` or its own
  marker) when CI runs unit and functional tests as separate filtered jobs.

### Fixed

- `scaffold-dotnet-project`'s `SKILL.md` frontmatter is valid YAML again (a `: ` in the description broke strict
  parsers), and its template table lists only templates the .NET 10 SDK ships — `blazorserver`, `blazorserver-empty`,
  `blazorwasm-empty`, `angular` and `react` are gone, so `dotnet new` no longer fails on them.
- `scaffold-dotnet-project`'s library variant adds a `<Version>` to the csproj (`dotnet new classlib` writes none), and
  its branch policy reports a missing `<Version>` with an error instead of failing silently.
- `scaffold-dotnet-web-api` follows `ArturRios.Util.WebApi` 5.x: controllers return `result.ToActionResult(…)`,
  the actor plumbing reads the caller with the non-generic `GetUser()` (the generic form returned `null` with the
  default mapper), `Program` / `Startup` use the 5.x `WebApiStartup`, repositories and fakes take the key type
  (`IAsyncRepository<T, long>`, `Entity<long>`), and a command with no payload returns `DataOutput` with an empty
  command output. Step 2b reads the resolved package version instead of every cached one.
- `scaffold-dotnet-web-api` also: pins every `docs/openapi/*.json` to LF instead of heimdall's file name, applies
  `tests/default.runsettings` through `tests/Directory.Build.props` so the `.trx` files CI uploads exist, sets
  `<NAME>_DATA_DATABASETYPE` in the container smoke test, and no longer lists an identity mapper and token issuer it
  does not write.
- `implement-use-cases-batch` no longer stops on a Definition of Done item that asks for a human review: the batch
  authorization stands in for it, and the report says so.
- `create-nuget-publish-workflow`'s single-package workflow asks only for `contents: read` and says to run a manual
  publish from the tag instead of failing the version check on a branch name.
- `create-unit-tests`' examples compile: the quick example passes the payment gateway the worked example's
  `CartService` requires, and the worked example defines `IPaymentGateway`, `Receipt` and `PaymentDeclinedException`.
- `generate-nuget-lib-docs` no longer refers to a Technology Stack Document a library repository does not have, its
  README skeleton renders (nested fences, a real HTML comment), the no-coverage Pages workflow points its own path
  filter at the renamed file, CONTRIBUTING's tag command follows the existing tag prefix, and the Hugo notes no longer
  claim a missing mount source fails the build.
- `generate-specs-from-brainstorm`'s README template changes into the repository directory, not the project name.
- `implement-use-case` and `implement-use-cases-batch` find the workflow documents with a `find` that really skips
  `node_modules` and `.git`.

[Unreleased]: https://github.com/artur-rios/ai-coding-skills/commits/develop
