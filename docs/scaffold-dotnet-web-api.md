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
  `docker-compose.yml`, env templates, three GitHub Actions workflows, a
  Hugo/Docsy documentation site, `.http` and Bruno API-client collections, and
  the Python scripts for migrations, coverage, OpenAPI, and vulnerability
  scanning.
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
Directory.Packages.props  Dockerfile  docker-compose.yml  README.md  LICENSE
```

## The stack

`ArturRios.Mediator`, `ArturRios.Data.Relational.Core`,
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

Every reference file in this skill was validated by scaffolding a throwaway API
from it against the current package versions and running all of the above.

## Files

| File | Contents |
|---|---|
| `SKILL.md` | Overview, precondition, stack, naming, red flags, the ten-step procedure, quick reference, common mistakes. |
| `references/layout.md` | Directory tree, `dotnet new` commands, reference graph, every `.csproj`. |
| `references/packages.md` | Version discovery rules and the `Directory.Packages.props` template. |
| `references/data.md` | `AppDbContext`, diagnostics options, design-time factory, seeder, the entity-map convention. |
| `references/shared.md` | `DataAccessMessageMap`, `PaginationMessages`, the actor abstractions, the message-pair convention. |
| `references/observability.md` | The health-check slice, `PaginatedQueryValidator`, the Serilog configuration. |
| `references/startup.md` | `Program`, `Startup`, middleware order, JWT key rotation, rate limiting, CORS, model binding, Swagger, settings and env templates. |
| `references/security.md` | `Roles`, identity user and mapper, token issuer, actor plumbing, `HealthCheckController`. |
| `references/testing.md` | Test `.csproj` files, `PostgresFixture`, the collection, test tokens, run settings, the health-check tests. |
| `references/docker.md` | Dockerfile with the migrations bundle, entrypoint, Compose, env examples. |
| `references/tooling.md` | The Python scripts, the OpenAPI generator, the three workflows, the docs site, the API client, the README outline. |
| `references/conventions-template.md` | The `docs/conventions.md` written into the generated repository. |
| `references/files/` | `.editorconfig`, `.gitignore`, `.gitattributes`, `.dockerignore`, copied verbatim. |
