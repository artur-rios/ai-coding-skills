# scaffold-dotnet-web-api

Creates a **complete, buildable, runnable .NET 10 web API repository** with a
layered DDD + CQRS structure — the one `heimdall-api` is built on — and no domain
in it. Every layer, every cross-cutting concern, every piece of tooling is wired
up; the entities, commands, and endpoints are yours to add.

## What it does

- Scaffolds six source projects across four layers, six test projects, an
  OpenAPI generator tool, and the solution that ties them together.
- Wires the whole stack: PostgreSQL through EF Core, mediator-dispatched
  command/query handlers, FluentValidation, JWT authentication with role
  attributes, Serilog, rate limiting, CORS, Data Protection, Swagger.
- Adds the repository furniture: Dockerfile with a migrations bundle,
  `docker-compose.yml`, env templates, four GitHub Actions workflows (tests,
  OpenAPI check, docs site, branch policy), a Hugo/Docsy documentation site,
  `.http` and Bruno API-client collections, and the Python scripts for
  migrations, coverage, OpenAPI, and vulnerability scanning.
- Writes the three root documents, each for one reader: a `README.md` with
  consumer and operator content only (what the API is, the docs, configure, run,
  deploy) ending in short *Changelog* and *Contributing* sections; a
  `CHANGELOG.md` in Keep a Changelog 1.1.0 form with a Semantic Versioning
  statement and an `## [Unreleased]` entry for the scaffold; and a
  `CONTRIBUTING.md` with prerequisites, project structure, build, the
  `Category`-split test suites, migrations, the OpenAPI document, the docs site,
  conventions, the branching model, commits and the changelog, versioning and
  releasing.
- Sets up the `develop` → `release/x.y.z` → `main` branching model: CI runs on
  pull requests into, and pushes to, both branches, and `branch-policy.yml`
  rejects any pull request that breaks the model.
- Resolves every package version from nuget.org **at scaffold time** and writes
  them into `Directory.Packages.props`.
- Writes `docs/conventions.md` into the new repository — the per-feature pattern,
  recorded where it will outlive the skill.
- Builds and tests what it produced before reporting back.

## When to use it

Ask for it with phrases like "scaffold a .NET web API", "bootstrap a layered CQRS
web API", "new dotnet API with the heimdall structure", or "set up an API like
heimdall-api".

Use **scaffold-dotnet-project** instead when you want a *generic* .NET scaffold —
a class library, a console app, a worker, or a web API that is not built on this
stack. The two skills are mutually exclusive; each names the other.

The directory must be greenfield. The skill stops if a `.sln` or `.csproj` is
already there, and names any file it would overwrite before the interview starts.

## The core rule

> The scaffold is the shape, not an example.

Everything that exists is wiring the first feature will need; nothing exists that
the first feature would have to delete. There is no sample entity, no sample
command, no sample controller — a half-right `Widget` is exactly what the next
agent would copy.

Two things carry the pattern instead:

- **`docs/conventions.md`** in the generated repo, stating what a feature is made
  of, in what order, and which rules are not negotiable.
- **The health-check vertical**, which is real: query → handler →
  `IServiceHealthCheck` → output → controller → registration → a unit test and
  four functional tests. Not a domain sample, but a working slice — and the four
  functional tests are the proof that routing, DI, the mediator, the role
  attribute, the token pipeline, EF Core against a real PostgreSQL, and the
  response envelope all work.

## What it asks

| Decision | Question |
|---|---|
| Name | "What is the API called?" (PascalCase) |
| Prefix | "Company/org prefix for the solution and projects?" (blank for none) |
| Description | "One sentence — what does the API do?" |
| Env prefix | "Environment variable prefix?" (defaults to the name, upper-cased) |
| Schema | "PostgreSQL schema name?" (defaults to the name, lower-cased) |
| License | "Which license? MIT, AGPL, or Custom Commercial." |
| Repository | "GitHub owner/repo, for the README badges and the docs site base URL?" |

## What you get

```
src/<Prefix>.<Name>.sln
  Domain/…Domain                 entities (empty), Roles enum
  Application/…Command           handlers, input, validation, output, services (all empty)
  Application/…Query             the health-check slice + PaginatedQueryValidator
  Application/…Shared            DataAccessMessageMap, PaginationMessages, actor abstractions
  Infrastructure/…Data           AppDbContext, design-time factory, seeder, maps (empty)
  Presentation/…WebApi           Startup, security, Swagger, binding, HealthCheckController
tests/                           six xUnit projects + the Testcontainers harness
tools/…OpenApiGen                writes docs/openapi/<name>.json (outside the solution)
docs/  scripts/  api-client/  docker/  .github/workflows/
Directory.Packages.props  Dockerfile  docker-compose.yml
README.md  CHANGELOG.md  CONTRIBUTING.md  LICENSE
```

## Two rules it enforces

The skill states these before its red flags, because they are what an agent
writing idiomatic C# from habit breaks first:

- **Errors are values, not exceptions.** Every outcome a caller can provoke —
  not found, already exists, not allowed, invalid input — is returned on an
  `ArturRios.Output` envelope: `DataOutput<T>` for one resource — with an
  empty `*CommandOutput` when a command returns nothing — and
  `PaginatedOutput<T>` for a listing.
  `Success` is derived from `Errors` being empty, and `ToActionResult` picks
  the HTTP status by looking the first error up in the entity's message map — so
  a thrown exception bypasses the whole mechanism and becomes a 500.
- **No try/catch in the request path.** `ExceptionMiddleware` is the single
  exception handler; a genuine fault propagates to it, gets logged with its
  stack trace, and is written as the same JSON envelope. Handlers, controllers,
  services and repositories catch nothing.

Two things still throw and are documented as such: start-up misconfiguration
(fail fast, no request in flight, no envelope anyone would read), and
`DatabaseHealthCheck` — the one sanctioned `catch`, because reporting the fault
*is* that operation's output. That is the stated test for any future one.

## The stack

`ArturRios.Output`, `ArturRios.Mediator`, `ArturRios.Data.Relational.Core`,
`ArturRios.Data.PostgreSql`, `ArturRios.Util`, `ArturRios.Util.WebApi`,
`ArturRios.Util.Test`, FluentValidation, EF Core 10 with
`EFCore.NamingConventions`, Serilog, Swashbuckle, xUnit, Moq, Bogus,
Testcontainers.

These are not optional — the patterns are made of them. A project that does not
want them wants `scaffold-dotnet-project`.

## Version discovery

Versions are queried from `api.nuget.org` when the skill runs, never carried in
the skill. Two rules keep the graph coherent:

- `Microsoft.*` packages that version with the runtime — every EF Core sibling,
  DataProtection, `Microsoft.Extensions.*` — all take the **same** highest stable
  `10.x`. That includes the ones no project references directly; listing them is
  what stops one project resolving EF Core a patch ahead of another and failing
  with CS1705.
- Everything else takes the highest stable version. Prerelease is skipped, and a
  package that resolves to nothing is a stop condition rather than a guess.

## Branching and releases

`feature/<name>` and `fix/<name>` branches are cut from `develop` and merged back
into it. A release is a `release/x.y.z` branch cut from `develop` with no commits
of its own — the CHANGELOG is finalized on `develop` first — merged into `main`
with a merge commit and tagged `vx.y.z`. The generated `branch-policy.yml` (the
same workflow `heimdall-api` runs) enforces all of it.

Creating `develop`, making it the default branch and adding the rulesets
(*Develop: PRs only*, *Main: release PRs only*, *Version tags*, with the required
checks `test`, `docker` and `branch-policy`) are remote changes, so the skill
lists them in its report for the user to make rather than making them.

## The docs site does not copy the root documents

The site's Changelog and Contributing pages render `CHANGELOG.md` and
`CONTRIBUTING.md` from the repository root through a `repo-file` shortcode and
two Hugo mounts, and the docs workflow rebuilds when either changes. There is no
Testing or Releases page: that content has one home, `CONTRIBUTING.md`.

## Verification

Before reporting, the skill runs `dotnet restore`, `dotnet build`, the unit
suite, and — if a Docker daemon is reachable — the functional suite. If Docker is
unavailable it says the functional suite was skipped and why; it never reports it
as passing.

It then verifies the tooling, none of whose failure modes surface in a build: the
Python helper tests, the vulnerability scan, `openapi.py` and its `--check`, and
`docker build` followed by actually **running** the image against a PostgreSQL
container — a successful build proves nothing about the entrypoint or the
migrations bundle.

The reference files were validated by scaffolding a throwaway API from them
against the package versions current when they were written. Versions resolve
live, so the skill re-reads the restored packages' public surface before writing
code (step 2b) and lets the package win wherever a reference file disagrees.

## Files

| File | Contents |
|---|---|
| `SKILL.md` | Overview, precondition, stack, naming, red flags, the procedure, quick reference, common mistakes. |
| `references/layout.md` | Directory tree, `dotnet new` commands, reference graph, every `.csproj`. |
| `references/packages.md` | Version discovery rules and the `Directory.Packages.props` template. |
| `references/data.md` | `AppDbContext`, diagnostics options, design-time factory, seeder, the entity-map convention. |
| `references/shared.md` | `DataAccessMessageMap`, `PaginationMessages`, the actor abstractions, the message-pair convention. |
| `references/observability.md` | The health-check slice, `PaginatedQueryValidator`, the Serilog configuration. |
| `references/startup.md` | `Program`, `Startup` on Util.WebApi 5.x's `WebApiStartup`, the standard pipeline, JWT key rotation, rate limiting, CORS, model binding, Swagger, settings and env templates. |
| `references/security.md` | `Roles`, identity user and mapper, token issuer, actor plumbing, `HealthCheckController`. |
| `references/testing.md` | Test `.csproj` files, `PostgresFixture`, the collection, test tokens, run settings, the health-check tests. |
| `references/docker.md` | Dockerfile with the migrations bundle, entrypoint, Compose, env examples. |
| `references/tooling.md` | The Python scripts, the OpenAPI generator, the four workflows, the docs site and its mounts, the API client. |
| `references/repo-docs.md` | The README outline and the `CHANGELOG.md` and `CONTRIBUTING.md` templates. |
| `references/conventions-template.md` | The `docs/conventions.md` written into the generated repository. |
| `references/files/` | Copied verbatim to the repository root: `.editorconfig`, `.gitignore`, `.gitattributes`, `.dockerignore`, `.github/workflows/branch-policy.yml`, and the docs site's `repo-file` shortcode with its Changelog and Contributing pages. |
