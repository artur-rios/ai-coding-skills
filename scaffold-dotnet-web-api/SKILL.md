---
name: scaffold-dotnet-web-api
description: Use when the user wants a new .NET 10 ASP.NET Core web API scaffolded from scratch with a layered DDD + CQRS structure — Domain / Application (Command, Query, Shared) / Infrastructure (EF Core + PostgreSQL) / Presentation, mediator-dispatched handlers returning DataOutput, FluentValidation, canonical message-to-status maps, JWT role authorization, Serilog, health checks, Testcontainers test projects, Docker, OpenAPI, a Hugo docs site, and CI. Triggers on "scaffold a .NET web API", "new dotnet API with the heimdall structure", "bootstrap a layered CQRS web API", "set up an API like heimdall-api". Requires a greenfield directory — stops if a `.sln` or `.csproj` already exists.
---

# Scaffold .NET Web API

## Overview

Creates a complete, buildable, runnable .NET 10 web API repository: six source
projects across four layers, six test projects, Docker, CI, an OpenAPI
generator, a documentation site, and every cross-cutting concern wired up —
**with no domain**. No sample entity, no sample command, no sample controller.
The only endpoints that exist are the health checks, which are infrastructure.

**Core principle:** the scaffold is the shape, not an example. Everything that
exists is wiring the first feature will need; nothing exists that the first
feature would have to delete.

Two things carry the per-feature pattern forward, since no sample slice does:

- **`docs/conventions.md`**, written into the generated repository, states the
  pattern a feature follows (see `references/conventions-template.md`). It is
  project documentation, so it outlives this skill.
- **The health-check vertical is real** — query → handler → `IServiceHealthCheck`
  → output → controller → DI registration → unit test → functional test. It is
  not a domain sample, but it is a working read-side slice, so the shape is
  demonstrated by infrastructure the project actually keeps.

## When to Use

**Precondition: the target directory holds no .NET solution and none of the files
this skill writes.** Check before asking anything (step 0).

- The user asks to scaffold / bootstrap / create a new .NET **web API**, and
  wants the layered DDD + CQRS structure described here.
- The user points at `heimdall-api` (or an API built from this skill) and asks
  for "the same patterns" / "the same structure" in a new project.

Skip / adapt if:
- The user wants a **generic** .NET scaffold — a class library, a console app, a
  worker, or a web API without this stack — use **scaffold-dotnet-project**,
  which asks for a `dotnet new` template and produces a minimal layout.
- The user is adding a feature to an **existing** project of this shape — this
  skill scaffolds a whole repository. Follow the project's own
  `docs/conventions.md`, or use **implement-use-case** when the project has
  workflow and use case specification documents.
- The user wants documentation or a NuGet publish workflow for an existing
  solution — that is **generate-nuget-lib-docs** / **create-nuget-publish-workflow**.

## The stack this skill scaffolds

Non-negotiable — the patterns are made of these packages. If the user does not
want them, they want **scaffold-dotnet-project**, not this skill.

| Package | What it provides |
| --- | --- |
| `ArturRios.Mediator` | `CommandMediator` / `QueryMediator`, `BaseCommand` / `BaseQuery`, `ICommandHandlerAsync` / `IQueryHandlerAsync` / `IPaginatedQueryHandlerAsync`, `CommandOutput` / `QueryOutput` |
| `ArturRios.Data.Relational.Core` | `Entity`, `BaseDbContext`, `IAsyncRepository<T>` / `IAsyncReadOnlyRepository<T>`, `RelationalErrors` |
| `ArturRios.Data.PostgreSql` | `AddPostgreSqlProvider()`, the Npgsql wiring |
| `ArturRios.Util.WebApi` | `WebApiStartup`, `ResponseResolver`, `[RoleRequirement]`, `ExceptionMiddleware`, `AuthenticationMiddleware`, `AddTokenAuthentication`, Swagger helpers |
| `ArturRios.Util` | `DataOutput<T>`, `PaginatedOutput<T>`, `HttpStatusCodes` |
| `ArturRios.Util.Test` | `[UnitFact]` / `[UnitTheory]` / `[FunctionalFact]`, `WebApiTest<TProgram>`, `FakeRepository<T>` |
| `FluentValidation`, EF Core 10, `EFCore.NamingConventions`, Serilog, Swashbuckle, xUnit, Moq, Bogus, Testcontainers.PostgreSql | the rest |

Versions are **discovered at scaffold time**, never hardcoded here — see
`references/packages.md`.

## Naming

Everything derives from two answers: the **prefix** (e.g. `ArturRios`, optional)
and the **name** (e.g. `Heimdall`).

| Thing | Form | Example |
| --- | --- | --- |
| Solution | `<Prefix>.<Name>.sln` in `src/` | `ArturRios.Heimdall.sln` |
| Project | `<Prefix>.<Name>.<Layer>` | `ArturRios.Heimdall.Command` |
| Test project | `<Prefix>.<Name>.<Layer>.Tests` | `ArturRios.Heimdall.Command.Tests` |
| Env var prefix | `<NAME>` upper-cased | `HEIMDALL_DATA_CONNECTIONSTRING` |
| Database schema | `<name>` lower-cased | `heimdall` |
| Docker image | `<name>-api` | `heimdall-api` |

Throughout the reference files, `<Prefix>.<Name>` means the full project prefix,
`<NAME>` the env-var prefix, and `<name>` the lower-cased schema/image name.

## Red Flags — STOP and Re-read the Procedure

- "I'll add a sample `Widget` entity so the pattern is visible" → NO. The
  scaffold has no domain. The pattern lives in `docs/conventions.md` and in the
  health-check vertical.
- "I'll pin the package versions I remember from heimdall" → NO. Versions are
  queried from nuget.org at scaffold time. A version you remember is a version
  that is already wrong.
- "EF Core resolves fine transitively, I don't need to list Relational /
  Abstractions / Analyzers" → NO. Listing them **is** the point of central
  package management here; without them a project resolves EF Core one patch
  ahead of another and the build fails with CS1705.
- "Only the WebApi needs a csproj, the other layers can be folders" → NO. Six
  source projects, each with its own csproj. This is not `scaffold-dotnet-project`.
- "I'll skip `dotnet build` — the templates are known-good" → NO. A scaffold
  that has not been built is not a scaffold. Verify (step 9).
- "I'll write a real `docker/local.env` so it runs immediately" → NO. Only
  `*.env.example` files are written. A committed secret is not recoverable.
- "`.slnx` is the modern format" → NO. `--format sln`.
- "There are no entities, so there is no migration to create" → NO. The context
  declares the Data Protection key ring and `Startup` persists keys to it. Create
  the initial migration (step 4); without it the API builds, tests green, and
  fails the first time Data Protection writes a key.
- "I'll write the handler and mediator calls from the shapes in the reference
  files" → NO, not without checking. Versions are resolved live, so a major bump
  since these files were written changes signatures — `HandleAsync` gained a
  `CancellationToken`, the claims-mapper interface was renamed. Step 2b verifies
  them against what actually restored.
- "Docker isn't available, so I'll report the functional tests as passing" → NO.
  Say they were skipped and why.

| Rationalization | Reality |
|---|---|
| "A scaffold with no domain is useless to test" | The health-check vertical is a real slice with real tests. That is what proves the wiring. |
| "Handlers throwing exceptions is more idiomatic C#" | Handlers return `DataOutput<T>` and never throw. The whole message-to-status mechanism depends on it. |
| "Exposing the entity `Id` is simpler than a `PublicId`" | Internal `Id` is a bigint that leaks row counts and never leaves the data layer. Routes and payloads use the `PublicId` GUID. |
| "I'll register handlers with assembly scanning instead of by hand" | Explicit registration in `Startup.AddDependencies` is how the codebase states its surface. Scanning hides a missing validator until runtime. |
| "The docs site and api-client are optional extras" | The user asked for the heimdall patterns. They are part of them. |
| "The reference files show the code, so I can copy it straight in" | They show the shape at the version they were written against. The skill resolves versions live; verify signatures first (step 2b). |

## Procedure

Create a todo per step. **Collect every answer before creating any file.**

### 0. Check the directory is safe to scaffold into

```bash
ls -a
find . -name "*.sln" -o -name "*.slnx" -o -name "*.csproj" -not -path "./.git/*"
```

- **A solution or project exists** → not greenfield. Stop, say what you found,
  and point at the alternatives in *Skip / adapt if*.
- **Any file this skill writes exists** (`README.md`, `LICENSE`, `.editorconfig`,
  `.gitignore`, `.gitattributes`, `.dockerignore`, `Dockerfile`,
  `docker-compose.yml`, `Directory.Packages.props`) → name each one and ask
  whether to overwrite, before the interview. Honour the answer per file.
- **Empty or unrelated files only** → proceed.

Never overwrite silently.

### 1. Interview — ask everything, then stop asking

Ask these in one round. Do not create a file until all are answered.

| Question | Default |
| --- | --- |
| "What is the API called? (PascalCase, e.g. `Heimdall`)" | — |
| "Company/org prefix for the solution and projects? (e.g. `ArturRios`; blank for none)" | none |
| "One-sentence description of what the API does?" | — |
| "Environment variable prefix?" | the name, upper-cased |
| "PostgreSQL schema name?" | the name, lower-cased |
| "Which license? MIT, AGPL, or Custom Commercial." | — |
| "GitHub owner/repo, for the README badges and the docs site base URL?" | — |

For **Custom Commercial**, ask the copyright holder, the license grant, and any
additional restrictions, then write `LICENSE` from the answers.

### 2. Resolve package versions

Read `references/packages.md` and follow it. It queries nuget.org, applies the
runtime-versioning rule for `Microsoft.*` packages, and produces
`Directory.Packages.props`. **Stop and report** if any package resolves to
nothing rather than guessing a version.

### 2b. Verify the library surface against what actually restored

The reference files were written against one set of versions; step 2 resolved
whatever is current. **Before writing any code that calls these libraries**, read
the public surface out of the restored packages' XML documentation:

```bash
for p in arturrios.mediator arturrios.util.webapi arturrios.data.relational.core arturrios.util.test; do
  echo "== $p"
  grep -o 'name="[TMP]:[^"]*"' ~/.nuget/packages/$p/*/lib/net10.0/*.xml | sed 's/name="//;s/"$//' | sort -u
done
```

Three things have moved across major versions and will not fail until compile
time, or — worse — until run time:

| Check | Why |
|---|---|
| `ICommandHandlerAsync` / `IQueryHandlerAsync` / `IPaginatedQueryHandlerAsync`'s `HandleAsync` parameters | 2.x added a `CancellationToken`; a 1.x-shaped handler is CS0535. |
| The claims-mapper interface and whether `AddTokenAuthentication` registers a default | 4.x's is `IAuthenticatedUserMapper`, and the non-generic overload already registers `DefaultAuthenticatedUserMapper` — so the scaffold needs no mapper of its own. |
| `FakeRepository<T>` vs `AsyncFakeRepository<T>` | The async repository interfaces need the async fake. |

If any reference file disagrees with the package, **the package wins** — write
what compiles and say so in step 10.

### 3. Create the projects and the solution

Read `references/layout.md`. It has the directory tree, the exact `dotnet new`
and `dotnet sln` commands, the project reference graph, and the contents of
every `.csproj`.

Six source projects — `Domain`, `Command`, `Query`, `Shared`, `Data`, `WebApi` —
and six test projects mirroring them. The `OpenApiGen` tool project is
deliberately **outside** the solution.

### 4. Write the Domain, Shared, and Data layers

- `references/data.md` — `AppDbContext`, `DbContextDiagnosticsOptions`,
  `DesignTimeDbContextFactory`, `DatabaseSeeder`, `MasterUserOptions`, and the
  entity-map convention the (empty) `EntityMaps/` folder will hold.
- `references/shared.md` — `DataAccessMessageMap`, `PaginationMessages`,
  `IActorAccessor`, `IActorScoped`, `PaginatedQueryValidator`.
- Domain holds `Enums/Roles.cs` and an empty `Entities/` folder.
- **Create the initial migration.** `EntityMaps/` is empty, but the context
  declares the Data Protection key ring and `Startup` persists keys to it, so the
  table has to exist. `references/data.md` has the command.

### 5. Write the Application query layer (health checks)

`references/observability.md` — `IServiceHealthCheck`, `DatabaseHealthCheck`,
`HealthStatuses`, `DetailedHealthQuery`, `GetDetailedHealthQueryHandler`,
`HealthCheckOutput`, `ServiceHealthOutput`, and the Serilog configuration.

`Command/` gets its `Handlers/`, `Input/`, `Input/Validation/`, `Output/`, and
`Services/` folders with a `.gitkeep` in each — empty, because there is no
domain yet.

### 6. Write the Presentation layer

`references/startup.md` — `Program`, `Startup` (`Build`, `AddDependencies`,
`ConfigureApp`, `ConfigureCors`, `ConfigureSecurity`), the middleware order and
why it is that order, `appsettings*.json`, `Environments/.env.example`,
`launchSettings.json`, `ModelBindingConfiguration`, `SwaggerConfiguration`.

`references/security.md` — `Roles` wiring, `IdentityUser`, `IdentityUserMapper`,
`JwtAuthTokenIssuer`, `HttpContextActorAccessor`, `ActorExtensions`, and the
`HealthCheckController`.

### 7. Write the test projects

`references/testing.md` — the six test `.csproj` files, `PostgresFixture`,
`FunctionalCollection`, `TestTokens`, `default.runsettings`, the health-check
unit test and functional test, and the Given-When-Then naming rule.

### 8. Write the repository furniture

- `references/docker.md` — `Dockerfile`, `docker-compose.yml`,
  `docker/entrypoint.sh`, `docker/{local,development,production}.env.example`.
  **Only `.example` files.**
- `references/tooling.md` — `scripts/migrations.py`, `scripts/coverage.py`,
  `scripts/openapi.py`, the `OpenApiGen` tool, `.config/dotnet-tools.json`,
  `.github/workflows/{tests,check-openapi,build-docs}.yml`, the Hugo/Docsy site
  under `docs/`, and the `api-client/` `.http` + Bruno collections.
- `references/conventions-template.md` — write it to `docs/conventions.md`,
  substituting the project's own names.
- Copy `references/files/` to the repository root: `.editorconfig`,
  `.gitignore`, `.gitattributes`, `.dockerignore`.
- Write `README.md` (see `references/tooling.md` for its sections) and `LICENSE`.
- `.gitkeep` in every empty directory. **Git does not track directories** —
  without it the layout you just built vanishes on the first commit.

### 9. Verify — never skip, never assume

```bash
dotnet restore src/<Prefix>.<Name>.sln
dotnet build src/<Prefix>.<Name>.sln --configuration Release --no-restore
dotnet test src/<Prefix>.<Name>.sln --configuration Release --no-build --filter "Category=Unit"
```

Then, **only if a Docker daemon is reachable** (`docker info`):

```bash
dotnet test src/<Prefix>.<Name>.sln --configuration Release --no-build --filter "Category=Functional"
```

If Docker is unavailable, say the functional suite was skipped and why. Do not
report it as passing.

Then the tooling, which has its own failure modes and none of them surface in a
`dotnet build`:

```bash
python3 -m unittest discover -s scripts -p "test_*.py"
python3 scripts/vulnerabilities.py
python3 scripts/openapi.py && python3 scripts/openapi.py --check
```

and, with Docker up, the image — **build it and run it**, because a successful
build proves nothing about the entrypoint or the migrations bundle:

```bash
docker build -t <name>-api:scaffold .
```

Beware: piping a build into `tail` swallows its exit code. Redirect to a file and
check `$?`, or the failure reads as success.

To run it, start a PostgreSQL container on a shared network, then the image with
`<NAME>_DATA_CONNECTIONSTRING` (**`Search Path=public`**), `<NAME>_AUTH_TOKEN_SECRET`
and the three master-user variables set; `GET /healthcheck` must answer 200 and
`GET /healthcheck/detailed` must answer 401 without a token.

### 10. Report

Tell the user: the solution and project names, the resolved versions of the
`ArturRios.*` packages, the folder structure, the license, what the build and
each test run actually printed, and the three things they must do before the API
will start — copy an env file from its `.example`, set the master-user and token
secrets, and create the first migration once they add their first entity.

## Quick Reference

| Decision | Rule |
|---|---|
| Sample entity / command / controller | None. Health checks only. |
| Package versions | Queried from nuget.org at scaffold time; `Microsoft.*` runtime packages all share one 10.x version. |
| Solution file | `src/<Prefix>.<Name>.sln`, created with `--format sln`. |
| Handler failure | `output.AddError(...)`, never `throw`. |
| Identifiers | `PublicId` (GUID) outside, `Id` (bigint) inside. |
| DI registration | Explicit, in `Startup.AddDependencies`. No assembly scanning. |
| Migrations | One initial migration, for the Data Protection key ring. Never applied on startup — the entrypoint or `scripts/migrations.py` applies them. |
| Secrets | `*.env.example` only. |
| Verification | `restore` → `build` → unit tests → functional tests if Docker is up. |

## Common Mistakes

- **Inventing a sample domain.** A `Widget` entity is a thing the first real
  feature has to delete, and its half-right shape is what the next agent copies.
- **Hardcoding versions.** The props file is generated from live nuget.org data.
  A skill that pins versions is a skill that is stale the week after it is written.
- **Letting the `Microsoft.*` versions drift apart.** Every EF Core sibling and
  every `Microsoft.Extensions.*` package takes the same 10.x version, including
  the ones no project references directly. That is what transitive pinning is for.
- **Putting the `.sln` at the repository root.** It goes in `src/`.
- **Registering `AuthenticationMiddleware` before `UseSwagger`.** It does not
  exempt the Swagger routes, so `/swagger` answers 401 to a browser that has no
  way to send a bearer token, and the UI is unreachable.
- **Migrating on startup.** Migrations are applied by the entrypoint or by
  `scripts/migrations.py`, never by `Build`.
- **Writing a real `.env` or `docker/*.env`.** Only `.example` files. The
  `.gitignore` this skill copies excludes the real ones for a reason.
- **Forgetting `.gitkeep` in the empty folders.** `Entities/`, `EntityMaps/`, and
  the five `Command/` folders are all empty by design and all disappear on the
  first commit without it.
- **Skipping the initial migration because there is no domain.** The Data
  Protection key ring is a real table the scaffold registers a writer for. No
  test covers that path, so the omission surfaces in production, not in CI.
- **Skipping the docs site, the api-client, or the workflows** because they feel
  peripheral. They are part of what the user asked for.
- **Reporting success without running the build.** Step 9 is not optional, and
  that includes the scripts and the container — the OpenAPI generator truncating
  its output, the vulnerability regex missing every transitive advisory, and the
  tool manifest landing in the wrong directory are all invisible to `dotnet build`.
- **Piping a verification command into `tail` or `grep`.** The pipeline's exit
  code is the last command's, so a failed `docker build` reports success.
- **Guessing the prefix.** Leave it empty unless the user gives one; never
  invent `Company` or `MyOrg`.
