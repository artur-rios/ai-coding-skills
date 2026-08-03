# scaffold-dotnet-project

Bootstraps a **new .NET project or solution from scratch** in the current
directory — picking the right `dotnet new` template, laying out the folders,
wiring the solution, and dropping in a README, a LICENSE, and the standard
editor/VCS config files.

## What it does

- Runs a short Q&A to collect **every** decision up front: project type, project
  name, solution name, optional org prefix, folder structure, and license.
- Maps a plain-English description ("a web API", "a background worker") to the
  matching `dotnet new` template short name.
- Scaffolds in one shot — `dotnet new`, `dotnet sln add`, and the project
  references — in a fixed order.
- Copies `.editorconfig`, `.gitignore`, and `.wakatime-project` into the repo root
  on every scaffold.
- Writes `README.md` and `LICENSE`, then runs `dotnet build` to prove the scaffold
  actually compiles before reporting back.

## When to use it

Ask for it with phrases like "scaffold a .NET project", "create a new dotnet
solution", "bootstrap a .NET project", or "start a new C# project".

Skip it if you're **adding** a project to an existing solution — follow that
solution's own conventions instead. This skill creates a whole new solution from
an empty (or intended-to-be-empty) directory.

Before asking anything, it checks the directory. If a `.sln` or `.csproj` is
already there it stops; if any file it would write — `README.md`, `LICENSE`,
`.editorconfig`, `.gitignore`, `.wakatime-project` — already exists, it names them
and asks per file before overwriting. Nothing is clobbered silently.

## The core rule

> Collect every answer first, then scaffold in one shot.

Questions and file creation are never interleaved. If `dotnet new` runs before all
the answers are in, the output has to be deleted and the process restarted — so
the skill front-loads the entire interview.

## What it asks

| Decision | Question |
|---|---|
| Project type | "What kind of .NET project is this?" → mapped to a template short name |
| Project name | "What should the project be named?" (PascalCase) |
| Solution name | "What should the solution be named?" (defaults to the project name) |
| Prefix | "Should the solution and projects use a company/org prefix?" (e.g. `Acme.`) |
| Structure | "Do you want a Domain-Driven Design folder structure?" |
| License | "Which license? MIT, AGPL, or Custom Commercial." |

Choosing **Custom Commercial** triggers follow-ups for the copyright holder, the
license grant, and any additional restrictions — the `LICENSE` file is written
from those answers rather than a one-line stub.

## What you get

**DDD structure** — exactly two `dotnet new` projects (the presentation project
and a Domain class library), plus empty scaffolding directories:

```
docs/
src/
  Application/        ← empty directory
  Domain/
    <Prefix.>Name.Domain/
      <Prefix.>Name.Domain.csproj      ← dotnet new classlib
  Infrastructure/     ← empty directory
  Presentation/
    <Prefix.>Name.WebApi/
      <Prefix.>Name.WebApi.csproj      ← the chosen template
  <Prefix.>Solution.sln
tests/                ← empty directory
README.md
LICENSE
```

**Basic structure** — one project under `src/`, plus the solution:

```
docs/
src/
  <Prefix.>Name/
    <Prefix.>Name.csproj
  <Prefix.>Solution.sln
tests/                ← empty directory
README.md
LICENSE
```

Two details that are easy to get wrong and that the skill pins down: the solution
file lives in **`src/`**, not the repo root, and it is created with
`--format sln` so modern SDKs produce a classic `.sln` rather than `.slnx`.

`Application/`, `Infrastructure/`, and `tests/` are **empty scaffolding
directories** — no extra `.csproj` files, no `Commands/` or `Entities/`
subfolders. You add those as the project grows. Each gets a `.gitkeep`, because
git doesn't track directories and the layout would otherwise disappear on your
first commit.

## How it works

1. **Check** the directory is safe to scaffold into; stop or ask if it isn't.
2. **Ask** all six questions (plus license follow-ups) before creating anything.
3. **Create** `docs/` and `tests/`.
4. **Run** `dotnet new <template>` for the main project.
5. **In DDD mode**, run `dotnet new classlib` for the Domain project and add a
   project reference from the presentation project to it.
6. **Create** the solution with `dotnet new sln --format sln -o src` and add every
   project to it.
7. **In DDD mode**, create the empty `src/Application` and `src/Infrastructure`
   directories, and drop a `.gitkeep` into every empty folder.
8. **Copy** all three files from `references/` into the repo root.
9. **Write** `README.md` and `LICENSE`.
10. **Build** with `dotnet build` to verify the scaffold, then report the template
    used, the layout created, the license chosen, and the build result.

## Files in this skill

| Path | Purpose |
|---|---|
| `SKILL.md` | The skill instructions, question order, and scaffold commands. |
| `references/.editorconfig` | The standard editor/formatting rules, copied into every scaffolded repo. |
| `references/.gitignore` | The full .NET gitignore (also ignores `.env*`), copied into every scaffolded repo. |
| `references/.wakatime-project` | WakaTime project marker, copied into every scaffolded repo. |

## What you get back

A building solution, the folder layout for your chosen structure, the config files
in place, and a report naming the template, the layout, the license, and whether
`dotnet build` succeeded.
