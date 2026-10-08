---
name: scaffold-dotnet-web-api
description: Use when the user wants a new .NET 10 ASP.NET Core web API scaffolded from scratch with a layered DDD + CQRS structure — Domain / Application (Command, Query, Shared) / Infrastructure (EF Core + PostgreSQL) / Presentation, mediator-dispatched handlers returning DataOutput, FluentValidation, canonical message-to-status maps, JWT role authorization, Serilog, health checks, Testcontainers test projects, Docker, OpenAPI, a Hugo docs site, CI, a README / CHANGELOG / CONTRIBUTING set, and the develop / release branching model with its branch-policy check. Triggers on "scaffold a .NET web API", "new dotnet API with the heimdall structure", "bootstrap a layered CQRS web API", "set up an API like heimdall-api". Requires a greenfield directory — stops if a `.sln` or `.csproj` already exists.
---

# Scaffold .NET Web API

## Overview

Creates a complete, buildable, runnable .NET 10 web API repository: six source
projects across four layers, six test projects, Docker, CI, an OpenAPI
generator, a documentation site, a README / CHANGELOG / CONTRIBUTING set, the
`develop` → `release/x.y.z` → `main` branching model with its Branch Policy check,
and every cross-cutting concern wired up — **with no domain**. No sample entity, no sample command, no sample controller.
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
| `ArturRios.Data.Relational.Core` | `Entity<TKey>`, `BaseDbContext`, `IAsyncRepository<T, TKey>` / `IAsyncReadOnlyRepository<T, TKey>`, `RelationalErrors` |
| `ArturRios.Data.PostgreSql` | `AddPostgreSqlProvider()`, the Npgsql wiring |
| `ArturRios.Util.WebApi` | `WebApiStartup`, `ToActionResult`, `[RoleRequirement]`, `ExceptionMiddleware`, `AuthenticationMiddleware`, `AddTokenAuthentication`, Swagger helpers |
| `ArturRios.Output` | `ProcessOutput`, `DataOutput<T>`, `PaginatedOutput<T>`, `CustomException` — the envelopes every handler returns |
| `ArturRios.Util` | `HttpStatusCodes` |
| `ArturRios.Util.Test` | `[UnitFact]` / `[UnitTheory]` / `[FunctionalFact]`, `WebApiTest<TProgram>`, `AsyncFakeRepository<T, TKey>` |
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

## Errors are values, not exceptions

Two rules. They are the ones an agent writing idiomatic C# from habit breaks
first, so they are stated before the red flags rather than buried in a reference
file.

### 1. Business rules and application flow never throw

Every outcome a caller can provoke — not found, already exists, not allowed,
invalid input, precondition unmet — is a **value on an output envelope**, never
an exception. `Success` is derived: it is `true` exactly when `Errors` is empty,
so adding an error *is* how failure is signalled.

Pick the envelope by what the operation returns:

| The operation returns | Use | Lives in |
|---|---|---|
| nothing — a delete, a toggle, a command with no payload | `DataOutput<TOutput?>` whose `TOutput` is an empty `*CommandOutput` — the mediator's handler interfaces always return `DataOutput`; `ProcessOutput` is for code outside the mediator (a service, a filter) | `ArturRios.Output` |
| one resource | `DataOutput<T>` | `ArturRios.Output` |
| a listing | `PaginatedOutput<T>` | `ArturRios.Output` |

All three carry `AddError`/`WithError(s)`, `AddMessage`/`WithMessage(s)`,
`Success` and `Timestamp`. Every error string is a `const` from the entity's
`*Messages` class, because `ToActionResult` picks the HTTP status by looking
the first error up in the `*MessageMap` — a string typed inline silently falls
through to the 400 default.

```csharp
// Not found is an outcome, not an exception.
var thing = await reader.Query().FirstOrDefaultAsync(x => x.PublicId == command.Id);

if (thing is null)
{
    return output.WithError(ThingMessages.ThingNotFound);   // → 404 via the map
}
```

### 2. No try/catch in the request path — `ExceptionMiddleware` owns exceptions

A genuine exception — a bug, a dependency that broke its contract — propagates
untouched to `ExceptionMiddleware`, which logs it and writes the same JSON error
envelope every other failure uses. Handlers, controllers, services and
repositories catch **nothing**. A `catch` in the request path either swallows a
defect or re-encodes it as a worse message than the middleware would produce.

The persistence layer is the shape to copy: repositories return a classified
result and `DataAccessMessageMap` maps it, so a unique-index race is a 409 rather
than a caught-and-rethrown anything.

### What still throws, and why that is not an exception to the rule

| Case | Throws? | Why |
|---|---|---|
| Business rule, validation, authorization, not found | **Never** | The caller provoked it; it is an outcome. |
| Misconfiguration at startup — missing signing secret, unset connection string, schema behind | **Yes, fail fast** | No request is in flight and no envelope has a reader. Starting half-configured fails later, opaquely, in front of a user. |
| A bug or a broken dependency mid-request | **Yes, uncaught** | It reaches `ExceptionMiddleware`, which is the single place that turns it into a response. |

`CustomException(string[] messages)` in `ArturRios.Output` — abstract, so a throw
derives its own exception from it — exists for the rare
throw that must carry caller-safe text to the middleware. Reaching for it in a
handler means the outcome belonged on an envelope instead.

### The one sanctioned `catch` in the whole scaffold

`DatabaseHealthCheck` catches, because **reporting the fault is the operation's
entire output** — the endpoint exists to answer "is the database reachable?", and
an exception escaping it would turn a health report into a 500. That is the test
for any future exception: catching is allowed only where the caught failure *is*
the result, never where it is an error path. Nothing else in the scaffold
catches, and a second one needs the same sentence written next to it.

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
- "Throwing `NotFoundException` here is cleaner than threading an error through
  the output" → NO. Not found is an outcome. `output.WithError(ThingMessages.ThingNotFound)`
  is what makes it a 404 instead of a 500.
- "I'll wrap this repository call in a try/catch so the error message is nicer"
  → NO. Nothing in the request path catches. `ExceptionMiddleware` runs ahead of
  every request for exactly this, and the persistence layer already classifies its own
  failures.
- "A `catch` that logs and rethrows is harmless" → NO. It is a second log line
  for an exception the middleware already logs, at a place that knows less about
  it. Delete it.
- "This handler returns nothing, so it can be `Task` / throw on failure" → NO.
  A command with no payload returns `DataOutput<TOutput?>` with an empty
  `*CommandOutput`. Failure is an error on it.
- "I'll write the handler and mediator calls from the shapes in the reference
  files" → NO, not without checking. Versions are resolved live, so a major bump
  since these files were written changes signatures — `HandleAsync` gained a
  `CancellationToken`, the claims-mapper interface was renamed. Step 2b verifies
  them against what actually restored.
- "Docker isn't available, so I'll report the functional tests as passing" → NO.
  Say they were skipped and why.
- "The README is the obvious place for the test commands and the branching
  rules" → NO. The README is for whoever calls or operates the API.
  Build, tests, migrations, branching and releasing go in `CONTRIBUTING.md`;
  release history goes in `CHANGELOG.md`.
- "The docs site should have a Testing page too" → NO. The site renders
  `CONTRIBUTING.md` and `CHANGELOG.md` through the `repo-file` shortcode; a copy
  is a second source of truth that drifts.

| Rationalization | Reality |
|---|---|
| "A scaffold with no domain is useless to test" | The health-check vertical is a real slice with real tests. That is what proves the wiring. |
| "Handlers throwing exceptions is more idiomatic C#" | Handlers return `DataOutput<T>` and never throw. The whole message-to-status mechanism depends on it. |
| "Exposing the entity `Id` is simpler than a `PublicId`" | Internal `Id` is a bigint that leaks row counts and never leaves the data layer. Routes and payloads use the `PublicId` GUID. |
| "I'll register handlers with assembly scanning instead of by hand" | Explicit registration in `Startup.AddDependencies` is how the codebase states its surface. Scanning hides a missing validator until runtime. |
| "The docs site and api-client are optional extras" | The user asked for the heimdall patterns. They are part of them. |
| "A new repository can work on `main` until it needs releases" | The branching model is cheapest on day one. Retrofitting it means re-pointing every open branch, workflow trigger and document later. |
| "The reference files show the code, so I can copy it straight in" | They show the shape at the version they were written against. The skill resolves versions live; verify signatures first (step 2b). |
| "Exceptions are the idiomatic way to signal failure in C#" | Not here. `Success` is derived from `Errors`, `ToActionResult` picks the status from the first error, and the whole message-to-status mechanism only works on returned values. |
| "A try/catch makes the failure message clearer" | It makes it *different* — and hides the stack trace `ExceptionMiddleware` would have logged. Clearer messages come from the `*Messages` const you return, not from a catch. |
| "The health check catches, so catching must be fine" | It catches because the caught failure *is* its output. That is the entire test, and it is met in exactly one class. |
| "Startup throws, so throwing is allowed" | Startup throws with no request in flight and no envelope to return. A request-path throw has both. |

## Procedure

Create a todo per step. **Collect every answer before creating any file.**

### 0. Check the directory is safe to scaffold into

```bash
ls -a
find . -path ./.git -prune -o \( -name "*.sln" -o -name "*.slnx" -o -name "*.csproj" \) -print
```

- **A solution or project exists** → not greenfield. Stop, say what you found,
  and point at the alternatives in *Skip / adapt if*.
- **Any file this skill writes exists** (`README.md`, `CHANGELOG.md`,
  `CONTRIBUTING.md`, `LICENSE`, `.editorconfig`, `.gitignore`, `.gitattributes`,
  `.dockerignore`, `Dockerfile`, `docker-compose.yml`, `Directory.Packages.props`,
  anything under `.github/workflows/`) → name each one and ask whether to
  overwrite, before the interview. Honour the answer per file.
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
for p in ArturRios.Mediator ArturRios.Util.WebApi ArturRios.Data.Relational.Core ArturRios.Util.Test; do
  v=$(grep -oP "Include=\"$p\" Version=\"\K[^\"]+" Directory.Packages.props)
  echo "== $p $v"
  grep -o 'name="[TMP]:[^"]*"' ~/.nuget/packages/${p,,}/$v/lib/net10.0/*.xml | sed 's/name="//;s/"$//' | sort -u
done
```

Read the version `Directory.Packages.props` resolved, not `*/`: the package cache
keeps every version ever restored on the machine, and an older one lists types the
resolved version no longer has.

These have moved across major versions and will not fail until compile time, or —
worse — until run time:

| Check | Why |
|---|---|
| `ICommandHandlerAsync` / `IQueryHandlerAsync` / `IPaginatedQueryHandlerAsync`'s `HandleAsync` parameters | 2.x added a `CancellationToken`; a 1.x-shaped handler is CS0535. |
| The claims-mapper interface and whether `AddTokenAuthentication` registers a default | 4.x's is `IAuthenticatedUserMapper`, and the non-generic overload already registers `DefaultAuthenticatedUserMapper` — so the scaffold needs no mapper of its own. |
| `WebApiStartup`'s shape, and how a controller turns an envelope into a response | 5.x replaced the overridable `BuildAndRun` / `ConfigureApp` / `AddMiddlewares` sequence with `ConfigureServices(WebApplicationBuilder)` plus a fixed pipeline (`UseStandardMiddlewares`), and `ResponseResolver.Resolve` with the `ToActionResult(statusCode, statusMap)` extensions. |
| `FakeRepository<T, TKey>` vs `AsyncFakeRepository<T, TKey>` (both keyed by the entity's id type, `long` here) | The async repository interfaces need the async fake. |

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
  `IActorAccessor`, `IActorScoped`.
- Domain holds `Enums/Roles.cs` and an empty `Entities/` folder.
- **Create the initial migration.** `EntityMaps/` is empty, but the context
  declares the Data Protection key ring and `Startup` persists keys to it, so the
  table has to exist. `references/data.md` has the command.

### 5. Write the Application query layer (health checks)

`references/observability.md` — `IServiceHealthCheck`, `DatabaseHealthCheck`,
`HealthStatuses`, `DetailedHealthQuery`, `GetDetailedHealthQueryHandler`,
`HealthCheckOutput`, `ServiceHealthOutput`, `PaginatedQueryValidator` (in the
Query project), and the Serilog configuration.

This is the first code that returns an envelope, so it is where *Errors are
values, not exceptions* starts being enforced: the handler returns
`DataOutput<HealthCheckOutput?>` and never throws, and `DatabaseHealthCheck` is
the only class in the scaffold permitted a `catch`.

`Command/` gets its `Handlers/`, `Input/`, `Input/Validation/`, `Output/`, and
`Services/` folders with a `.gitkeep` in each — empty, because there is no
domain yet.

### 6. Write the Presentation layer

`references/startup.md` — `Program`, `Startup` (constructor and
`ConfigureStandardSequence`, `CreateApplication`, `ConfigureServices`,
`EdgePipeline`, `AddDependencies`, `ConfigureCors`, `ConfigureSecurity`), the
pipeline Util.WebApi's `UseStandardMiddlewares` fixes and what sits around it,
`Settings/appsettings.json`, `Environments/.env.example`, `launchSettings.json`,
`ModelBindingConfiguration`, `SwaggerConfiguration`.

`references/security.md` — `Roles` wiring, the authenticated caller (no identity
class, mapper or token issuer of its own), `HttpContextActorAccessor`, `ActorExtensions`, and the
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
  `scripts/openapi.py`, `scripts/vulnerabilities.py`, the `OpenApiGen` tool,
  `.config/dotnet-tools.json`,
  `.github/workflows/{tests,check-openapi,build-docs,branch-policy}.yml`, the
  Hugo/Docsy site under `docs/`, and the `api-client/` `.http` + Bruno
  collections.
- `references/conventions-template.md` — write it to `docs/conventions.md`,
  substituting the project's own names.
- Copy `references/files/` to the repository root, preserving its tree:
  `.editorconfig`, `.gitignore`, `.gitattributes`, `.dockerignore`,
  `.github/workflows/branch-policy.yml`, and the docs site's
  `layouts/_shortcodes/repo-file.html` plus its Changelog and Contributing pages.
- `references/repo-docs.md` — write `README.md` (consumer and operator content
  only, ending with short *Changelog* and *Contributing* sections),
  `CHANGELOG.md` and `CONTRIBUTING.md`. Then write `LICENSE`.
- If the directory is a git repository, create a local `develop` branch from the
  current branch once the user has committed — or tell them to; never commit for
  them.
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
`<NAME>_DATA_DATABASETYPE=PostgreSql`, `<NAME>_DATA_CONNECTIONSTRING`
(**`Search Path=public`**), `<NAME>_AUTH_TOKEN_SECRET` and the three master-user
variables set — the image sets none of them, and the API refuses to start without
the database type; `GET /healthcheck` must answer 200 and
`GET /healthcheck/detailed` must answer 401 without a token.

### 10. Report

Tell the user: the solution and project names, the resolved versions of the
`ArturRios.*` packages, the folder structure, the license, what the build and
each test run actually printed, and the three things they must do before the API
will start — copy an env file from its `.example`, set the master-user and token
secrets, and apply the initial migration with `python scripts/migrations.py` (the
API never migrates on startup; the first entity they add brings its own
migration).

Then the repository settings this skill cannot make — they are remote writes,
and the branching model in `CONTRIBUTING.md` is only enforced once they exist:

1. Push `main`, then create `develop` from it (`git push origin main:refs/heads/develop`).
2. Make `develop` the default branch.
3. Create the three rulesets, each bypassable by the repository admin role
   (`RepositoryRole` 5, always):
   - **Develop: PRs only** on `refs/heads/develop` — deletion, non-fast-forward,
     pull request with 0 approvals and merge or squash, required checks
     `test`, `docker` and `branch-policy`;
   - **Main: release PRs only** on `refs/heads/main` — the same, merge commits
     only;
   - **Version tags** on `refs/tags/v*` — creation, update and deletion.

The required check names are the job ids in `tests.yml` and `branch-policy.yml`.
`check-openapi` is not required: its path filter means it does not run on every
pull request. Enable GitHub Pages with source "GitHub Actions" for the docs site.

## Quick Reference

| Decision | Rule |
|---|---|
| Sample entity / command / controller | None. Health checks only. |
| Package versions | Queried from nuget.org at scaffold time; `Microsoft.*` runtime packages all share one 10.x version. |
| Solution file | `src/<Prefix>.<Name>.sln`, created with `--format sln`. |
| Handler failure | `output.AddError(...)`, never `throw`. |
| Output envelope | `DataOutput<T>` (one resource, or an empty `*CommandOutput` when a command has no payload) / `PaginatedOutput<T>` (a listing), all from `ArturRios.Output`; `ProcessOutput` only outside the mediator. |
| try/catch in the request path | None. `ExceptionMiddleware` owns exceptions. The one sanctioned catch is `DatabaseHealthCheck`. |
| Throwing | Startup misconfiguration only — fail fast, before any request. |
| Identifiers | `PublicId` (GUID) outside, `Id` (bigint) inside. |
| DI registration | Explicit, in `Startup.AddDependencies`. No assembly scanning. |
| Migrations | One initial migration, for the Data Protection key ring. Never applied on startup — the entrypoint or `scripts/migrations.py` applies them. |
| Secrets | `*.env.example` only. |
| Verification | `restore` → `build` → unit tests → functional tests if Docker is up. |
| README | Consumer and operator content only, ending with *Changelog* and *Contributing*. |
| Build, tests, migrations, branching, releasing | `CONTRIBUTING.md`. |
| Release history | `CHANGELOG.md`, Keep a Changelog 1.1.0, SemVer, `## [Unreleased]` first. |
| Docs site vs. the root files | Renders `CHANGELOG.md` / `CONTRIBUTING.md` through `repo-file`; never copies them. |
| Branches | `feature/<name>`, `fix/<name>` → `develop`; `release/x.y.z` (a snapshot of `develop`) → `main`, merge commit, tag `vx.y.z`. |
| Required checks | `test`, `docker`, `branch-policy`. |

## Common Mistakes

- **Throwing for a business outcome.** A `NotFoundException` becomes a 500 with
  no message map behind it; the same condition returned as an error on the
  envelope is a 404 with the exact text the caller needs. This is the single most
  likely thing to go wrong when someone writes a handler from C# habit.
- **Adding a try/catch "just in case".** It swallows the stack trace
  `ExceptionMiddleware` exists to log, and produces a message that knows less
  than the middleware's. Util.WebApi's standard pipeline (`UseStandardMiddlewares`)
  puts `ExceptionMiddleware` ahead of everything a request reaches, which is what
  makes the catch unnecessary.
- **Returning `Task` from a command handler with nothing to return.** The
  handler returns `DataOutput<TOutput?>` with an empty `*CommandOutput` —
  otherwise failure has nowhere to go but an exception.
- **Inventing a sample domain.** A `Widget` entity is a thing the first real
  feature has to delete, and its half-right shape is what the next agent copies.
- **Hardcoding versions.** The props file is generated from live nuget.org data.
  A skill that pins versions is a skill that is stale the week after it is written.
- **Letting the `Microsoft.*` versions drift apart.** Every EF Core sibling and
  every `Microsoft.Extensions.*` package takes the same 10.x version, including
  the ones no project references directly. That is what transitive pinning is for.
- **Putting the `.sln` at the repository root.** It goes in `src/`.
- **Turning on `Options.Swagger.JwtAuthentication`.** `SwaggerConfiguration`
  already defines the `"Bearer"` scheme; the library's second
  `AddSecurityDefinition` throws on the duplicate key, and because the Swagger
  middleware resolves the generator on every request, every request in
  `Local`/`Development` answers 500. Nor add ASP.NET Core's
  `AddAuthentication` / `UseAuthentication` / `UseAuthorization` —
  `AddTokenAuthentication` and `AuthenticationMiddleware` are the whole stack.
- **Migrating on startup.** Migrations are applied by the entrypoint or by
  `scripts/migrations.py`, never by `Startup`.
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
- **Putting build, test or branching instructions in the README.** They belong
  in `CONTRIBUTING.md`; the README is for whoever calls or operates the API, and
  ends by pointing at the other two files.
- **Adding a Testing or Releases page to the docs site.** The site renders
  `CONTRIBUTING.md` and `CHANGELOG.md`; it does not keep copies of them.
- **Declaring the two root-file mounts without the others.** A `[module]` block
  replaces Hugo's default mounts, so without the explicit `content/en` and
  `assets` mounts the site loses its pages and its stylesheet.
- **Renaming a CI job without updating the rulesets.** The required checks are
  matched by job name; a renamed job is simply no longer required.
- **Triggering CI only on `main`.** Work lands on `develop`; `tests.yml` must run
  on pull requests into, and pushes to, both.
