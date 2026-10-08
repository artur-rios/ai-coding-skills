# README, CHANGELOG, CONTRIBUTING

Three root files, each with one audience. Keeping them apart is the point:

| File | Reader | Holds |
| --- | --- | --- |
| `README.md` | Whoever calls or operates the API | What it is, where the docs are, how to configure, run and deploy it |
| `CHANGELOG.md` | The same reader, over time | What changed in each release, in Keep a Changelog form |
| `CONTRIBUTING.md` | Whoever changes the code | Prerequisites, structure, build, tests, migrations, OpenAPI, docs site, conventions, branching, commits, versioning, releasing |

**Nothing contributor-facing goes in the README** — no test commands, no branching rules, no project
tree, no docs-site preview steps. The README ends with two short sections that point at the other two
files. The docs site renders `CHANGELOG.md` and `CONTRIBUTING.md` (see `tooling.md`), so it does not
repeat them either.

Substitute `<Prefix>.<Name>`, `<NAME>`, `<name>`, `<owner>`/`<repo>` and the description throughout.

## README.md

Sections, in order:

1. Title, a docs-site badge and a license badge.
2. A link to the documentation site.
3. One paragraph: what the API is, built with ASP.NET Core (.NET 10).
4. **Overview** — bullets for the architecture and the cross-cutting features.
5. **Documentation** — the site, and a table of its pages (Overview, Getting started, Architecture,
   API explorer, Operations, Changelog, Contributing) with one line each.
6. **Configure** — copying `Environments/.env.example` to `.env.local`, and a table of the required
   variables: `<NAME>_DATA_CONNECTIONSTRING`, `<NAME>_AUTH_TOKEN_SECRET`, the three master-user
   variables. State plainly that the project ships with **no domain entities** — the only migration
   is the one creating the Data Protection key ring, applied with `python scripts/migrations.py` —
   and that the first feature adds both an entity and its migration. A reader who does not know that
   will assume the scaffold is broken.
7. **Run** — `dotnet run --project src/Presentation/<Prefix>.<Name>.WebApi`, the Swagger UI URL, and
   a pointer to `api-client/`.
8. **Deploy with Docker** — the env-file templates under `docker/` and the three
   `docker compose --env-file …` commands.
9. **Changelog** and **Contributing** — verbatim below.
10. **License** (or **Legal**) — the chosen license.

If the project later tracks its use cases, milestones or backlog in the README, those tables belong
in the README, between *Documentation* and *Configure*: they describe the product's state, not how to
work on it.

```markdown
## Changelog

Notable changes in each release are recorded in [CHANGELOG.md](./CHANGELOG.md). Releases follow
[Semantic Versioning](https://semver.org/).

## Contributing

Building from source, running the tests, authoring migrations, regenerating the OpenAPI document,
the branching model and the release process are described in [CONTRIBUTING.md](./CONTRIBUTING.md).
```

## CHANGELOG.md

```markdown
# Changelog

All notable changes to the <Name> API are recorded in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- The API scaffold: Domain, Command, Query, Shared, Data and WebApi projects on .NET 10, with
  PostgreSQL through EF Core, JWT role authorization, Serilog, health checks, Docker, the OpenAPI
  document, the documentation site and CI. No domain entities yet.

[Unreleased]: https://github.com/<owner>/<repo>/commits/develop
```

The `[Unreleased]` link points at `develop` until the first release is tagged; from then on it is
`https://github.com/<owner>/<repo>/compare/v<latest>...HEAD`, and each release gets its own
`[x.y.z]: …/compare/v<previous>...vx.y.z` line.

## CONTRIBUTING.md

Write it as below, then fill the bracketed parts from the scaffold you actually produced.

````markdown
# Contributing

## Prerequisites

- **.NET 10 SDK**
- **PostgreSQL** (the API's database; the functional tests start their own via Testcontainers)
- **Docker** (the functional tests start their PostgreSQL container through it)
- **Python 3** (the migration menu, the OpenAPI generator and the other helpers under `scripts/`)
- The pinned EF Core CLI tool — restore it once after cloning:

  ```bash
  dotnet tool restore
  ```

To run the API locally, configure it first as described under [Configure](./README.md#configure) in
the README.

## Project structure

```
<the annotated tree from references/layout.md, trimmed to one line per folder>
```

## Build

```bash
dotnet build src/<Prefix>.<Name>.sln
```

## Test

The suite is xUnit, and every test is named with the Given / When / Then pattern
(`GivenX_WhenY_ThenZ`). Every test carries a `Category` trait — `[UnitFact]` / `[UnitTheory]` or
`[FunctionalFact]` from `ArturRios.Util.Test` — so the two kinds can be run separately:

```bash
dotnet test src/<Prefix>.<Name>.sln --filter "Category=Unit"
```

```bash
dotnet test src/<Prefix>.<Name>.sln --filter "Category=Functional"
```

Unit tests run in isolation against fakes. Functional tests call the API end to end against a real
PostgreSQL started by Testcontainers, so they need Docker. CI runs both, and the coverage floor in
`scripts/coverage.py`:

```bash
python scripts/coverage.py
```

## Migrations

The schema is managed with **EF Core migrations, applied explicitly** — the API never migrates on
startup. Use the interactive menu to add, remove, list or apply migrations, or to generate an
idempotent SQL script:

```bash
python scripts/migrations.py
```

It asks which environment file to load for the connection string, then offers the actions.

## OpenAPI document

`docs/openapi/<name>.json` is generated and committed. Regenerate it after changing anything it
describes:

```bash
python scripts/openapi.py
```

`check-openapi.yml` fails the build when it is out of date.

## Documentation site

The site is built with [Hugo](https://gohugo.io/) and the [Docsy](https://www.docsy.dev/) theme from
`docs/`. Its Changelog and Contributing pages render this file and `CHANGELOG.md` directly, so they
are never copied into the site. To preview it locally — Hugo Extended and Node.js required:

```bash
git submodule update --init --recursive
```

```bash
npm install --prefix docs/themes/docsy
```

```bash
hugo -s docs server
```

## Conventions

Read [docs/conventions.md](docs/conventions.md) before adding a feature: what a feature is made of,
in what order, and the rules that are not negotiable — errors are values on an output envelope, and
nothing in the request path catches.

## Branching model

```
feature/<name> ─┐
fix/<name> ─────┴─▶ develop ──▶ release/x.y.z ──▶ main  (tag vx.y.z)
```

| Branch | Cut from | Merges into | How |
|---|---|---|---|
| `feature/<name>`, `fix/<name>` | `develop` | `develop` | Pull request, squash or merge. The branch is deleted on merge. |
| `release/x.y.z` | `develop` | `main` | Pull request, merge commit only. |
| `develop`, `main` | — | — | Protected: no direct pushes, no force pushes, no deletion. |

Names are lowercase: letters, digits, `.`, `_` and `-`. A `release/` branch is a snapshot of
`develop` and carries no commits of its own: a fix for a release lands on `develop` through a
`fix/` branch and a new release branch is cut.

The **Branch Policy** workflow checks all of this on every pull request and is a required check on
`develop` and `main`, alongside the tests. The repository's rulesets — *Develop: PRs only*,
*Main: release PRs only* and *Version tags* — enforce the rest: pull requests only, no force pushes or
deletion, and only the repository owner creates, moves or deletes `v*` tags.

## Commits and the changelog

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/) with a lowercase
subject, e.g. `feat: add the create order endpoint` or `fix: return 404 for an unknown order`.

Record every change an API client or operator would notice under `## [Unreleased]` in
[CHANGELOG.md](./CHANGELOG.md), in the same pull request that makes it.

## Versioning

Releases are numbered `major.minor.patch` following [Semantic Versioning](https://semver.org/). For
this API:

- **major** — a breaking change to the HTTP contract (a removed or renamed endpoint, field or
  status code), to the configuration (a renamed or newly required variable), or to the data (a
  migration that cannot be applied in place);
- **minor** — a backwards-compatible addition: a new endpoint, an optional field or variable;
- **patch** — a fix that changes no contract.

The version is the name of the release branch (`release/1.4.0` releases `v1.4.0`); it is not stored in
the source. The Branch Policy workflow refuses a release branch whose version already has a tag.

## Releasing

1. Because a release branch carries no commits of its own, finalize the changelog on `develop` first:
   in a `feature/` or `fix/` branch, rename `## [Unreleased]` in [CHANGELOG.md](./CHANGELOG.md) to
   `## [x.y.z] - <yyyy-mm-dd>` above a fresh, empty `## [Unreleased]`, update the compare links at
   the bottom, and merge it into `develop`.
2. Cut the release branch from `develop` and push it:

   ```bash
   git switch develop && git pull && git switch -c release/x.y.z && git push -u origin release/x.y.z
   ```

3. Open a pull request `release/x.y.z → main` and, once every check passes, merge it with a merge
   commit.
4. Tag the merge commit on `main`:

   ```bash
   git switch main && git pull
   git tag vx.y.z && git push origin vx.y.z
   ```
````
