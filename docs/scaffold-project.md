# scaffold-project

Bootstraps a **new repository from scratch, in any stack** — .NET, Spring Boot, Python,
Node.js / TypeScript, React with shadcn/ui, Angular with spartan/ui, Rust, Flutter, or another one —
and lands every stack on the same repository shape: code in `src/`, tests in `tests/`, documentation in
`docs/`, and the same root files.

It replaces the earlier `scaffold-dotnet-project` and `scaffold-dotnet-web-api` skills: the generic
`dotnet new` scaffold and the layered DDD + CQRS web API are now two of its .NET paths.

## What it does

- Asks for the **technology** first — unless the request already names it ("a .NET web API", "a Rust
  CLI", "an API like heimdall-api"), in which case it says what it inferred and moves on.
- Asks for the **kind of project** within the stack — for .NET: a Web API (layered or minimal), a
  NuGet library, or any other `dotnet new` template — again only if the request didn't say.
- For a **NuGet library**, asks for the package metadata nuget.org needs (package id, version, authors,
  tags, target frameworks, project URL, icon) and writes it into the csproj together with Source Link,
  symbol packages and XML docs; then offers to run **create-nuget-publish-workflow** and
  **generate-project-docs**.
- Collects **every** answer in one round before creating anything, then runs the stack's own
  generator (`dotnet new`, start.spring.io, `uv init`, `npm create vite`, `ng new`, `cargo init`,
  `flutter create`).
- Bends the generator's output into the shared shape — reconfiguring the tool where it expects
  another layout — and strips its demo content.
- Writes the shared root files and the `develop` → `release/<version>` → `main` branch policy.
- Builds and tests what it produced, reading real exit codes, before reporting back.

## The shared repository shape

```
docs/                                  .gitkeep unless the stack writes a docs site there
src/                                   all production code
tests/                                 all tests
.github/workflows/branch-policy.yml    enforces develop / release/<version> / main
.editorconfig
.gitattributes
.gitignore                             the generator's, plus the shared lines
.wakatime-project                      one line: the repository name
CHANGELOG.md                           Keep a Changelog 1.1.0, SemVer, ## [Unreleased]
CONTRIBUTING.md                        prerequisites, build, tests, branching, versioning, releasing
LICENSE
README.md                              for the people who use the project
```

Where a stack's tooling expects another layout, the tool is reconfigured, not the shape:

| Stack | How `src/` + `tests/` is met |
|---|---|
| .NET | Natural: projects under `src/`, the `.sln` in `src/`, test projects under `tests/`. |
| Spring Boot | Code stays in `src/main/…`; the Gradle / Maven test source set is pointed at `tests/java` and `tests/resources`. |
| Python | uv's `src/` layout; pytest's `testpaths = ["tests"]`. |
| Node.js / TypeScript | `src/` compiled by `tsconfig.build.json`; Vitest includes `tests/**/*.test.ts`. |
| React + shadcn/ui | Vite's `src/`; Vitest (jsdom) includes `tests/**/*.test.tsx`; one smoke test. |
| Angular + spartan/ui | The CLI's `src/`, helm components in `src/app/ui`; the test target and `tsconfig.spec.json` read `tests/`. |
| Rust | Natural: `src/`, with integration tests in `tests/`; unit tests stay inline. |
| Flutter | The app is the Flutter project in `src/`; `tests/` is a test-only package depending on it by path. |

## When to use it

Ask for it with phrases like "scaffold a new project", "bootstrap a .NET web API", "create a NuGet
library", "new dotnet API with the heimdall structure", "start a Spring Boot service", "new React app
with shadcn", "set up a Rust crate", or "create a Flutter app".

Skip it when you're adding to an existing repository — it stops if it finds a project manifest
(`.sln`, `.csproj`, `package.json`, `pyproject.toml`, `Cargo.toml`, `pom.xml`, `build.gradle*`,
`pubspec.yaml`, `go.mod`). If any file it would write already exists, it names each one and asks before
overwriting.

## The core rule

> Collect every answer first, then scaffold in one shot.

Questions and file creation are never interleaved.

## What it asks

| Step | Question | When |
|---|---|---|
| Technology | ".NET, Spring Boot, Python, Node.js / TypeScript, React (shadcn/ui), Angular (spartan/ui), Rust, Flutter — or another one?" | Only if the request doesn't name it |
| Kind | The stack's kind question — for .NET: Web API (layered or minimal), NuGet library, or another template | Only if the request doesn't say |
| Name | In the stack's naming form (PascalCase for .NET, kebab-case for npm / Cargo, snake_case for Dart) | Always |
| Description | One sentence | Always |
| License | Artur Rios Attribution License (default), MIT, AGPL, or Custom Commercial (with follow-ups) | Always |
| Repository | GitHub owner/repo | Only when there is no git remote |
| Stack questions | e.g. .NET prefix and DDD layout; NuGet metadata; Spring language, build tool and group id; Flutter org and platforms | Per the stack reference |

## Branching variants

| Kind | Variant |
|---|---|
| A library — NuGet, PyPI, npm, Rust library crate, a .NET `classlib` | **Library**: the version lives in a file (csproj, `pyproject.toml`, `package.json`, `Cargo.toml`), the release branch bumps it, `main` is merged back into `develop`, tags are `<version>`. |
| Anything else | **Application**: the version is the release branch name and its `v` tag; release branches are snapshots of `develop`. |

The branch policy, the rulesets and the "Version tags" ruleset are listed in the report as remote
setup for the user to do; the skill never pushes.

## The .NET layered Web API

Choosing .NET → Web API → layered (or asking for "the heimdall structure") builds a complete .NET 10
repository: six source projects across four layers, six test projects, an OpenAPI generator, Docker,
CI, a Hugo / Docsy docs site, `api-client/` collections and Python helper scripts, on the
`ArturRios.*` stack (Mediator, Output, Data, Util.WebApi), with **no domain** — the only endpoints are
the health checks. Package versions are resolved from nuget.org at scaffold time. Its rules —
errors are values, not exceptions; no try/catch in the request path — and its full procedure are in
`references/dotnet-web-api/overview.md`.

## Files in this skill

| Path | Purpose |
|---|---|
| `SKILL.md` | The interview, the shared shape, the procedure, red flags, quick reference, common mistakes. |
| `references/dotnet.md` | .NET kinds, `dotnet new` templates, basic and DDD layouts. |
| `references/dotnet-nuget-library.md` | NuGet metadata questions, the csproj properties, the pack check. |
| `references/dotnet-web-api/` | The layered DDD + CQRS Web API path: `overview.md` plus its layout, packages, data, shared, observability, startup, security, testing, docker, tooling, repo-docs, license and conventions references, and `files/` copied verbatim. |
| `references/spring-boot.md` | start.spring.io generation, the `tests/` source set for Gradle and Maven. |
| `references/python.md` | uv, the `src/` layout, pytest and ruff. |
| `references/node-typescript.md` | TypeScript, ES modules, Vitest, application vs npm library. |
| `references/react-shadcn.md` | Vite + React + TypeScript, Tailwind, shadcn/ui, Vitest + Testing Library. |
| `references/angular-spartan.md` | Angular CLI, Tailwind, spartan/ui, specs in `tests/`. |
| `references/rust.md` | `cargo init`, binary vs library crate, clippy and rustfmt. |
| `references/flutter.md` | `flutter create --empty` into `src/`, the `tests/` path-dependency package. |
| `references/other.md` | The fallback for any other stack. |
| `templates/README.md`, `CHANGELOG.md`, `CONTRIBUTING.md` | The root documents, with stack fill-ins and library / application variants. |
| `templates/LICENSE` | The Artur Rios Attribution License text. |
| `templates/branch-policy-app.yml`, `branch-policy-library.yml` | The two branch policies; the library one takes a version file and pattern. |
| `templates/.editorconfig`, `.gitattributes`, `.gitignore-shared` | The shared editor, line-ending and ignore settings. |
| `templates/dotnet/.editorconfig`, `.gitignore` | The .NET editor rules and gitignore. |

## What you get back

A repository that builds and passes its tests, in the shared shape, with the root documents and
branch policy in place, and a report naming the stack, the kind, the resolved versions, the license,
the branching variant, what each verification command printed, and the remote setup left for you.
