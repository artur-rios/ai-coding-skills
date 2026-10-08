---
name: scaffold-dotnet-project
description: Use when the user wants to create or scaffold a new .NET project or solution from scratch in an empty or greenfield directory — running `dotnet new` with the right template, picking folder structure (DDD or basic), and creating docs/src/tests layout with a consumer-facing README, CHANGELOG.md, CONTRIBUTING.md, LICENSE and the develop/release branch policy workflow. Triggers on "scaffold a .NET project", "create a new dotnet solution", "bootstrap a .NET project", "start a new C# project". Not for adding a project to an existing solution — it stops if the directory already contains a `.sln` or `.csproj`, and asks before overwriting any file it would write. Not for a layered DDD + CQRS web API in the heimdall style — that is scaffold-dotnet-web-api.
---

# Scaffold .NET Project

## Overview

Guides the creation of a new .NET project or solution through a structured Q&A
flow. Asks the user everything needed **before** any file is created, then runs
`dotnet new` to scaffold the project in the current directory.

**Core principle:** collect every answer first, then scaffold in one shot —
never mix questions with file creation. If you `dotnet new` before all answers
are collected, you must delete the output and start over.

Alongside the code it writes the repository's three root documents — a README for
the people who use the project, a `CHANGELOG.md` and a `CONTRIBUTING.md` for the
people who build it — and the `branch-policy.yml` workflow that enforces the
`develop` / `release/<version>` / `main` branching model.

**This skill scaffolds exactly two `dotnet new` projects in DDD mode** (the
WebApi presentation project and the Domain class library) and one project in
basic mode. The Application and Infrastructure folders are empty scaffolding
directories — no extra `.csproj` projects beyond those specified.

## When to Use

**Precondition: the target directory holds no .NET solution and none of the files
this skill writes.** Check before asking anything (step 0).

- The user asks to "scaffold / create / bootstrap / start a new .NET project or
  solution".
- A greenfield .NET repo needs to be initialized from scratch.
- The user pointed at an empty (or intended-to-be-empty) directory and wants a
  .NET project in it.

Skip / adapt if:
- The user wants a **layered DDD + CQRS web API** in the heimdall style —
  Domain / Application (Command, Query, Shared) / Infrastructure / Presentation,
  `ArturRios.Mediator`, EF Core + PostgreSQL, JWT role attributes, Testcontainers
  tests, Docker and CI — use **scaffold-dotnet-web-api**, which builds the whole
  repository rather than a `dotnet new` skeleton. This skill stays the generic
  scaffolder: class libraries, console apps, workers, and web APIs that are not
  built on that stack.
- The user is adding a project to an **existing** solution — use the solution's
  own conventions instead.
- The user already has a `.csproj` or `.sln` and just wants a test project or
  CI workflow — this skill scaffolds a whole new solution.

## Red Flags — STOP and Re-read the Procedure

- "I'll add an Application or Infrastructure class library project too" → NO.
  Only the Domain project is a class library. Application and Infrastructure
  are empty directories.
- "Let me scaffold the project first and ask questions later" → NO. Collect
  every answer before running `dotnet new`.
- "Modern SDKs use .slnx so I'll just use that" → NO. Use `--format sln`.
- "I'll create a test project while I'm at it" → NO. The `tests/` folder is
  empty scaffolding — no extra `dotnet new` calls.
- "The solution name doesn't need the prefix" → If the user gave a prefix, it
  goes in the solution name too.
- "There's already a README here, mine is better" → NO. Step 0 asks before
  overwriting anything. A scaffold that destroys existing work is not recoverable
  outside git.
- "A `.gitkeep` counts as adding files to the empty folders" → It is not a
  subdirectory and not a project; it is the only way git keeps the folder. Add it.

| Rationalization | Reality |
|---|---|
| "DDD means creating separate class libraries for each layer" | This skill creates the Domain project as a class library and the WebApi as a presentation project. Application and Infrastructure are empty scaffolding directories. |
| "I should set up a proper multi-project DDD solution with all layers" | The user can add those later. This skill bootstraps the starting point with Domain + WebApi. |
| ".slnx is the modern default, .sln is legacy" | `--format sln` ensures tooling compatibility. The user asked for .sln. |
| "I know what questions to ask without reading the procedure" | The procedure specifies exact question ordering and wording. Follow it. |
| "The README is the obvious place for `dotnet build` / `dotnet test`" | Build, test, branching and release instructions are contributor material. They go in `CONTRIBUTING.md`; the README links it. |
| "A new repo doesn't need a CHANGELOG yet" | The first pull request already has something to record under `## [Unreleased]`. Starting the file later means reconstructing what it missed. |

## Procedure

Create a todo per step. **Collect every answer before touching `dotnet new`.**

### 0. Check the directory is safe to scaffold into

This skill writes `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `LICENSE`,
`.editorconfig`, `.gitignore`, `.wakatime-project` and
`.github/workflows/branch-policy.yml`. **Overwriting any of them loses the user's
work**, so look before asking anything:

```bash
ls -a
find . -path ./.git -prune -o \( -name "*.sln" -o -name "*.slnx" -o -name "*.csproj" \) -print
```

- **A solution or project already exists** → this is not a greenfield directory.
  Stop, say what you found, and point at the two alternatives in *Skip / adapt*.
- **Any file this skill writes already exists** → name each one and ask whether to
  overwrite it or keep it, before the interview starts. Honour the answer per file;
  keeping an existing `LICENSE` also means skipping the license question.
- **Directory is empty or has unrelated files** → proceed.

Never overwrite silently. A scaffold that ate a hand-written README is not a
scaffold the user can undo without git.

### 1. Project type — match the user's description to a `dotnet new` template

Ask: *"What kind of .NET project is this? Describe it in a few words."*

Map the user's description to the best-matching short name from the table below.
If the description is ambiguous across multiple templates, ask a clarifying
question narrowing to the closest candidates (limit to 3 options).

If the user gives a short name directly (e.g. "webapi", "classlib"), confirm it
is what they intended, then use it.

**Project template short names:**

| Short name | Kind |
|---|---|
| `console` | Console app |
| `webapi` | ASP.NET Core Web API |
| `webapiaot` | ASP.NET Core Web API (native AOT) |
| `mvc` | ASP.NET Core MVC web app |
| `web` | ASP.NET Core Empty |
| `webapp` / `razor` | ASP.NET Core Razor Pages |
| `blazor` | Blazor Web App — `--interactivity Server` for a server-rendered app, `WebAssembly` or `Auto` otherwise; `--empty` omits the sample pages |
| `blazorwasm` | Blazor WebAssembly standalone (`--empty` omits the sample pages) |
| `classlib` | Class library |
| `grpc` | ASP.NET Core gRPC service |
| `worker` | Worker Service (background) |
| `winforms` | Windows Forms app |
| `wpf` | WPF application |
| `mcpserver` | MCP Server App |
| `xunit` | xUnit test project |
| `nunit` | NUnit test project |
| `mstest` | MSTest test project |

The table matches the .NET 10 SDK. Before running, confirm the short name exists
with `dotnet new list <short name>` — the SDK no longer ships `blazorserver`,
`blazorserver-empty`, `blazorwasm-empty`, `angular` or `react`. Map a request for
one of those to `blazor` / `blazorwasm` with the options above, or, for an Angular
or React front end, say there is no SDK template and ask how to proceed.

### 2. Project name

Ask: *"What should the project be named? (PascalCase, e.g. OrderService)"*

If the project type is a test project (`xunit`, `nunit`, `mstest`), suggest
appending `.Tests` to the main project name, but follow the user's choice.

### 3. Solution name

Ask: *"What should the solution be named? (default: same as the project name)"*

If the user accepts the default, the solution name equals the project name.
The prefix (if any) is appended in step 4.

### 4. Prefix

Ask: *"Should the solution and projects use a company/org prefix? (e.g. 'Acme' →
Acme.OrderService, Acme.OrderService.sln). Leave blank for no prefix."*

If a prefix is given:
- Solution file: `Prefix.SolutionName.sln`
- Project name in `dotnet new -n`: `Prefix.ProjectName` (or `Prefix.ProjectName.WebApi` in DDD)
- Project folder under `src/`: matches the `-n` value
- Project file: matches the `-n` value with `.csproj`

If no prefix, omit it entirely — do not add a placeholder.

### 5. Folder structure — DDD or basic

Ask: *"Do you want a Domain-Driven Design folder structure?"*

**If yes (DDD):** Create exactly TWO `dotnet new` projects (the WebApi and
the Domain class library), plus empty scaffolding directories.

```
docs/
src/
  Application/        ← empty directory
  Domain/
    <Prefix.>ProjectName.Domain/
      <Prefix.>ProjectName.Domain.csproj   ← dotnet new classlib
  Infrastructure/     ← empty directory
  Presentation/
    <Prefix.>ProjectName.WebApi/
      <Prefix.>ProjectName.WebApi.csproj   ← the WebApi dotnet new project
  <Prefix.>SolutionName.sln
tests/                ← empty directory
.github/workflows/branch-policy.yml
README.md
CHANGELOG.md
CONTRIBUTING.md
LICENSE
```

Commands to scaffold DDD mode (substitute placeholders):

```bash
# 1. Create the WebApi project
dotnet new <template> -n <Prefix.>ProjectName.WebApi -o src/Presentation/<Prefix.>ProjectName.WebApi

# 2. Create the Domain class library
dotnet new classlib -n <Prefix.>ProjectName.Domain -o src/Domain/<Prefix.>ProjectName.Domain

# 3. Create the solution (IN src/, NOT repo root)
dotnet new sln --format sln -n <Prefix.>SolutionName -o src

# 4. Add both projects to solution
dotnet sln src/<Prefix.>SolutionName.sln add src/Presentation/<Prefix.>ProjectName.WebApi/<Prefix.>ProjectName.WebApi.csproj
dotnet sln src/<Prefix.>SolutionName.sln add src/Domain/<Prefix.>ProjectName.Domain/<Prefix.>ProjectName.Domain.csproj

# 5. Add project reference from WebApi to Domain
dotnet add src/Presentation/<Prefix.>ProjectName.WebApi/<Prefix.>ProjectName.WebApi.csproj reference src/Domain/<Prefix.>ProjectName.Domain/<Prefix.>ProjectName.Domain.csproj

# 6. Create empty DDD scaffolding directories (bash; see step 7 for PowerShell)
mkdir -p src/Application
mkdir -p src/Infrastructure
```

**If no (basic):** Create ONE `dotnet new` project inside its own folder under
`src/`, plus a solution.

```
docs/
src/
  <Prefix.>ProjectName/
    <Prefix.>ProjectName.csproj   ← the ONLY dotnet new project
  <Prefix.>SolutionName.sln
tests/                 ← empty directory
.github/workflows/branch-policy.yml
README.md
CHANGELOG.md
CONTRIBUTING.md
LICENSE
```

Commands to scaffold basic mode:

```bash
# 1. Create the project
dotnet new <template> -n <Prefix.>ProjectName -o src/<Prefix.>ProjectName

# 2. Create the solution (IN src/, NOT repo root)
dotnet new sln --format sln -n <Prefix.>SolutionName -o src

# 3. Add project to solution
dotnet sln src/<Prefix.>SolutionName.sln add src/<Prefix.>ProjectName/<Prefix.>ProjectName.csproj
```

### 6. License

Ask: *"Which license? Options: MIT, AGPL, or Custom Commercial."*

- **MIT** — create `LICENSE` with the standard MIT text (year = current year,
  copyright holder = user-provided prefix/name or "the contributors").
- **AGPL** — create `LICENSE` with the GNU AGPLv3 text.
- **Custom Commercial** — ask follow-ups:
  - *"Who is the copyright holder (company/individual name)?"*
  - *"What is the license grant? (e.g. 'All rights reserved', 'Source available
    for evaluation only', etc.)"*
  - *"Any additional restrictions or permissions?"*
  
  Then write a `LICENSE` file from the answers.

### 6b. GitHub repository — only when there is no git remote

Run `git remote get-url origin`. If it answers, take the owner and repository name
from it and skip this question. Otherwise ask: *"Which GitHub owner/repo will this
live in? (e.g. acme/order-service)"* — the CHANGELOG's links need it.

### 7. Scaffold — execute in this exact order

1. Create `docs/` and `tests/` directories at the repo root.
2. Run `dotnet new <template> …` to create the main project — in DDD mode that is
   the presentation project under `src/Presentation/`, in basic mode the single
   project under `src/`.
3. If DDD mode, run `dotnet new classlib …` to create the Domain project, then
   add a project reference from the presentation project to Domain with
   `dotnet add … reference …`.
4. Run `dotnet new sln --format sln …` and `dotnet sln … add …` to wire up the solution.
5. If DDD mode, create the empty scaffolding directories (`src/Application`,
   `src/Infrastructure`).
6. Put a `.gitkeep` in every empty directory (`tests/`, `docs/` if nothing else
   lands there, and in DDD mode `src/Application` and `src/Infrastructure`).
   **Git does not track directories** — without this the layout you just built
   disappears on the first commit, and the next clone has no `tests/` at all.
7. Copy **all files** from `references/` in this skill's directory into the repo
   root: `.editorconfig`, `.gitignore`, and `.wakatime-project`. These files are
   always included in every scaffolded project — subject to the overwrite answers
   from step 0.
8. Write `README.md` for the project's users, in this order: `# <Prefix.>ProjectName`,
   the one-paragraph description from step 1, `## Requirements` (the .NET version the
   projects target), then the two closing pointer sections and the license:

   ```markdown
   ## Changelog

   Notable changes in each release are recorded in [CHANGELOG.md](./CHANGELOG.md). Releases follow
   [Semantic Versioning](https://semver.org/).

   ## Contributing

   Building from source, running the tests, the branching model and the release process are described in
   [CONTRIBUTING.md](./CONTRIBUTING.md).

   ## Legal Details

   This project is licensed under the <license>. A copy of the license is available at [LICENSE](./LICENSE) in the repository.
   ```

   **No build, test, branching or release instructions in the README** — they go in
   `CONTRIBUTING.md`. If the project will ship as a NuGet package, the README is
   packed into it and those two links must be absolute
   (`https://github.com/<owner>/<repo>/blob/main/CHANGELOG.md`); say so in the report
   and point at `generate-nuget-lib-docs`.
9. Write `CHANGELOG.md` from `templates/CHANGELOG.md` and `CONTRIBUTING.md` from
   `templates/CONTRIBUTING.md`, deleting the guidance comments. Pick the variant by
   the project template:

   | Template | Variant | Branch policy |
   |---|---|---|
   | `classlib` | **Library** — version in the csproj, release branch carries the bump and the CHANGELOG finalization, `main` merged back into `develop` | `templates/branch-policy-library.yml`, with `__CSPROJ_PATH__` set to the project's csproj |
   | anything else | **Application** — version is the release branch name and its `v` tag, release branches are snapshots of `develop`, CHANGELOG finalized on `develop` first | `templates/branch-policy-app.yml`, verbatim |

   Fill `{{owner}}`/`{{repo}}` from step 6b. For the **library** variant, also add
   `<Version>0.1.0</Version>` (or the starting version the user names) to the
   `<PropertyGroup>` of the csproj `__CSPROJ_PATH__` points at: `dotnet new classlib`
   writes no `<Version>`, and both the CONTRIBUTING text ("the version is the
   `<Version>` in …") and the branch policy's release check read it.
10. Write the chosen branch policy to `.github/workflows/branch-policy.yml`.
11. Write `LICENSE` per the user's choice.
12. Run `dotnet build src/<Prefix.>SolutionName.sln` to verify the scaffold builds.

Directory creation is shell-specific — `mkdir -p src/Application` in bash,
`New-Item -ItemType Directory -Force src/Application` in PowerShell. Use whichever
shell you are actually running; `mkdir -p` is not valid PowerShell.

### 8. Report

Tell the user:
- The template used and the project/solution names.
- The folder structure created.
- The license chosen.
- That `dotnet build` succeeded (or any issues found).
- Which CONTRIBUTING / branch-policy variant was used, and why.
- The remote setup the branching model needs, which this skill does not do — after
  the first commit is pushed to `main`:
  1. create `develop` from `main` and make it the default branch;
  2. create the rulesets "Develop: PRs only" (on `develop`: no deletion, no force
     push, pull request with 0 approvals, merge or squash) and "Main: release PRs
     only" (on `main`: the same, merge commits only), both requiring the branch
     policy check — `Branch policy` for the library variant, `branch-policy` for the
     application variant — plus any test job a CI workflow adds later;
  3. create the "Version tags" tag ruleset (creation, update, deletion), with the
     repository admin role allowed to bypass all three.

## Quick Reference

| Decision | Question to ask |
|---|---|
| Project type | "What kind of .NET project is this?" → map to short name |
| Project name | "What should the project be named?" (PascalCase) |
| Solution name | "What should the solution be named?" (default: project name) |
| Prefix | "Should the solution and projects use a company/org prefix?" |
| DDD structure | "Do you want a Domain-Driven Design folder structure?" |
| License | "Which license? MIT, AGPL, or Custom Commercial." |
| GitHub owner/repo | Only when there is no git remote — the CHANGELOG link needs it. |

| Decision | Rule |
|---|---|
| What goes in the README | What the project is, its requirements, links to CHANGELOG / CONTRIBUTING, license. Nothing a contributor needs. |
| CONTRIBUTING / branch-policy variant | `classlib` → library; any other template → application. |
| CHANGELOG | Keep a Changelog 1.1.0, SemVer, `## [Unreleased]` linked to `commits/develop`. |

## Common Mistakes

- **Scaffolding into a directory that already has a solution or a README.**
  Step 0 exists to catch that. Ask before overwriting anything.
- **Leaving the empty directories without a `.gitkeep`.** They vanish on the first
  commit, and the layout the user asked for is gone.
- **Scaffolding before asking all questions.** Never run `dotnet new` until every
  answer is collected.
- **Creating multiple `dotnet new` projects for DDD layers.** In DDD mode,
  only the WebApi presentation project and the Domain class library are created
  via `dotnet new`. Application and Infrastructure are empty directories.
- **Creating `Commands/` or `Queries/` folders inside `Application/`.** The
  Application folder is a single empty directory — no subdirectories.
- **Creating an `Entities/` folder inside `Domain/`.** The Domain folder
  contains a `classlib` project in its own subdirectory, not an `Entities/` folder.
- **Omitting `--format sln` when creating the solution.** Modern SDKs default to
  `.slnx`. Always pass `--format sln` to produce a classic `.sln` file.
- **Putting the `.sln` in the repo root.** It goes in `src/` in both modes.
- **Skipping the `dotnet build` verification.** Always build after scaffolding
  to catch mismatched SDK versions or template issues.
- **Guessing the prefix.** Leave it empty unless the user provides one; never
  invent a placeholder like `Company` or `MyOrg`.
- **Writing build and test instructions into the README.** They are contributor
  material and belong in `CONTRIBUTING.md`; the README ends with short Changelog
  and Contributing sections that link the files.
- **Picking the wrong branch-policy variant.** The library variant validates the
  csproj `<Version>` on release branches; the application variant refuses any
  commit on a release branch. Mixing a variant with the other's CONTRIBUTING text
  documents a release process the check rejects.
- **Leaving `__CSPROJ_PATH__` in the library branch policy.** Every release pull
  request then fails its version check.
- **Forgetting to copy reference files.** Always copy `.editorconfig`,
  `.gitignore`, and `.wakatime-project` from `references/` into the scaffolded
  project root.
- **Forgetting the project reference in DDD mode.** After creating both
  projects, add a reference from WebApi to Domain with
  `dotnet add … reference …`.
- **Forgetting the license follow-ups for custom commercial.** Ask for copyright
  holder, grant, and restrictions — don't write a one-line placeholder.
- **Creating a test project (`xunit`/`nunit`/`mstest`) unprompted.** The
  `tests/` folder is empty scaffolding. Only create a test project if the user
  explicitly chose a test template in step 1.
