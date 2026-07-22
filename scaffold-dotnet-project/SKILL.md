---
name: scaffold-dotnet-project
description: Use when the user wants to create or scaffold a new .NET project or solution from scratch in the current directory — running `dotnet new` with the right template, picking folder structure (DDD or basic), and creating docs/src/tests layout with README and LICENSE. Triggers on "scaffold a .NET project", "create a new dotnet solution", "bootstrap a .NET project", "start a new C# project".
---

# Scaffold .NET Project

## Overview

Guides the creation of a new .NET project or solution through a structured Q&A
flow. Asks the user everything needed **before** any file is created, then runs
`dotnet new` to scaffold the project in the current directory.

**Core principle:** collect every answer first, then scaffold in one shot —
never mix questions with file creation. If you `dotnet new` before all answers
are collected, you must delete the output and start over.

**This skill scaffolds exactly two `dotnet new` projects in DDD mode** (the
WebApi presentation project and the Domain class library) and one project in
basic mode. The Application and Infrastructure folders are empty scaffolding
directories — no extra `.csproj` projects beyond those specified.

## When to Use

- The user asks to "scaffold / create / bootstrap / start a new .NET project or
  solution".
- A greenfield .NET repo needs to be initialized from scratch.
- The user pointed at an empty (or intended-to-be-empty) directory and wants a
  .NET project in it.

Skip / adapt if:
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

| Rationalization | Reality |
|---|---|
| "DDD means creating separate class libraries for each layer" | This skill creates the Domain project as a class library and the WebApi as a presentation project. Application and Infrastructure are empty scaffolding directories. |
| "I should set up a proper multi-project DDD solution with all layers" | The user can add those later. This skill bootstraps the starting point with Domain + WebApi. |
| ".slnx is the modern default, .sln is legacy" | `--format sln` ensures tooling compatibility. The user asked for .sln. |
| "I know what questions to ask without reading the procedure" | The procedure specifies exact question ordering and wording. Follow it. |

## Procedure

Create a todo per step. **Collect every answer before touching `dotnet new`.**

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
| `blazor` | Blazor Web App (server + WASM) |
| `blazorserver` | Blazor Server |
| `blazorserver-empty` | Blazor Server (empty) |
| `blazorwasm` | Blazor WebAssembly standalone |
| `blazorwasm-empty` | Blazor WebAssembly (empty) |
| `angular` | ASP.NET Core with Angular |
| `react` | ASP.NET Core with React.js |
| `classlib` | Class library |
| `grpc` | ASP.NET Core gRPC service |
| `worker` | Worker Service (background) |
| `winforms` | Windows Forms app |
| `wpf` | WPF application |
| `mcpserver` | MCP Server App |
| `xunit` | xUnit test project |
| `nunit` | NUnit test project |
| `mstest` | MSTest test project |

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
README.md
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

# 6. Create empty DDD scaffolding directories
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
README.md
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

### 7. Scaffold — execute in this exact order

1. Create `docs/` and `tests/` directories at the repo root.
2. Run `dotnet new <template> …` to create the WebApi project.
3. If DDD mode, run `dotnet new classlib …` to create the Domain project, then
   add a project reference from WebApi to Domain with `dotnet add … reference …`.
4. Run `dotnet new sln --format sln …` and `dotnet sln … add …` to wire up the solution.
5. If DDD mode, create the empty scaffolding directories (`src/Application`,
   `src/Infrastructure`).
6. Copy **all files** from `references/` in this skill's directory into the repo
   root: `.editorconfig`, `.gitignore`, and `.wakatime-project`. These files are
   always included in every scaffolded project.
7. Write `README.md` with project name, description, build instructions
   (`dotnet build`, `dotnet test`), and license reference.
8. Write `LICENSE` per the user's choice.
9. Run `dotnet build src/<Prefix.>SolutionName.sln` to verify the scaffold builds.

### 8. Report

Tell the user:
- The template used and the project/solution names.
- The folder structure created.
- The license chosen.
- That `dotnet build` succeeded (or any issues found).

## Quick Reference

| Decision | Question to ask |
|---|---|
| Project type | "What kind of .NET project is this?" → map to short name |
| Project name | "What should the project be named?" (PascalCase) |
| Solution name | "What should the solution be named?" (default: project name) |
| Prefix | "Should the solution and projects use a company/org prefix?" |
| DDD structure | "Do you want a Domain-Driven Design folder structure?" |
| License | "Which license? MIT, AGPL, or Custom Commercial." |

## Common Mistakes

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
