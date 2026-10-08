# scaffold-dotnet-project

Bootstraps a **new .NET project or solution from scratch** in the current
directory — picking the right `dotnet new` template, laying out the folders,
wiring the solution, and dropping in a README, a CHANGELOG, a CONTRIBUTING guide,
a LICENSE, the branch policy workflow, and the standard editor/VCS config files.

## What it does

- Runs a short Q&A to collect **every** decision up front: project type, project
  name, solution name, optional org prefix, folder structure, and license.
- Maps a plain-English description ("a web API", "a background worker") to the
  matching `dotnet new` template short name.
- Scaffolds in one shot — `dotnet new`, `dotnet sln add`, and the project
  references — in a fixed order.
- Copies `.editorconfig`, `.gitignore`, and `.wakatime-project` into the repo root
  on every scaffold.
- Writes a `README.md` for the project's users — what it is, its requirements,
  and short **Changelog** / **Contributing** sections linking the other two files —
  plus `LICENSE`.
- Writes `CHANGELOG.md` (Keep a Changelog 1.1.0, Semantic Versioning,
  `## [Unreleased]`) and `CONTRIBUTING.md` (prerequisites, build, tests with
  Given/When/Then names and a `Category` trait, branching, commits, versioning,
  releasing). Build and test instructions live there, not in the README.
- Writes `.github/workflows/branch-policy.yml`, which enforces the `develop` →
  `release/<version>` → `main` branching model on every pull request: the
  **library** variant (`classlib`; version in the csproj, release branches carry the
  bump, back-merge from `main`) or the **application** variant (any other template;
  release branches are snapshots of `develop`, tagged `vX.Y.Z`).
- Runs `dotnet build` to prove the scaffold actually compiles before reporting
  back, and lists the remote setup the branching model still needs.

## When to use it

Ask for it with phrases like "scaffold a .NET project", "create a new dotnet
solution", "bootstrap a .NET project", or "start a new C# project".

Skip it if you're **adding** a project to an existing solution — follow that
solution's own conventions instead. This skill creates a whole new solution from
an empty (or intended-to-be-empty) directory.

Before asking anything, it checks the directory. If a `.sln` or `.csproj` is
already there it stops; if any file it would write — `README.md`, `CHANGELOG.md`,
`CONTRIBUTING.md`, `LICENSE`, `.editorconfig`, `.gitignore`, `.wakatime-project`,
`.github/workflows/branch-policy.yml` — already exists, it names them
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
| Repository | "Which GitHub owner/repo will this live in?" — only when there is no git remote |

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
.github/workflows/branch-policy.yml
README.md
CHANGELOG.md
CONTRIBUTING.md
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
.github/workflows/branch-policy.yml
README.md
CHANGELOG.md
CONTRIBUTING.md
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
2. **Ask** all six questions (plus license follow-ups, and the repository when
   there is no git remote) before creating anything.
3. **Create** `docs/` and `tests/`.
4. **Run** `dotnet new <template>` for the main project.
5. **In DDD mode**, run `dotnet new classlib` for the Domain project and add a
   project reference from the presentation project to it.
6. **Create** the solution with `dotnet new sln --format sln -o src` and add every
   project to it.
7. **In DDD mode**, create the empty `src/Application` and `src/Infrastructure`
   directories, and drop a `.gitkeep` into every empty folder.
8. **Copy** all three files from `references/` into the repo root.
9. **Write** `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md` (library or
   application variant), `.github/workflows/branch-policy.yml` and `LICENSE`.
10. **Build** with `dotnet build` to verify the scaffold, then report the template
    used, the layout created, the license chosen, the variant, the build result,
    and the remote setup to do after the first push: create `develop` from `main`
    and make it the default branch, and create the rulesets "Develop: PRs only",
    "Main: release PRs only" and "Version tags".

## Files in this skill

| Path | Purpose |
|---|---|
| `SKILL.md` | The skill instructions, question order, and scaffold commands. |
| `references/.editorconfig` | The standard editor/formatting rules, copied into every scaffolded repo. |
| `references/.gitignore` | The full .NET gitignore (also ignores `.env*`), copied into every scaffolded repo. |
| `references/.wakatime-project` | WakaTime project marker, copied into every scaffolded repo. |
| `templates/CHANGELOG.md` | The initial CHANGELOG. |
| `templates/CONTRIBUTING.md` | CONTRIBUTING, with a library and an application variant. |
| `templates/branch-policy-library.yml` | Branch policy for a library: work branches into `develop`, `release/<version>` matching the csproj `<Version>` into `main`, back-merges. |
| `templates/branch-policy-app.yml` | Branch policy for an application: `feature/` and `fix/` into `develop`, `release/x.y.z` snapshots of `develop` into `main`. |

## What you get back

A building solution, the folder layout for your chosen structure, the config files,
root documents and branch policy in place, and a report naming the template, the
layout, the license, the branching variant, whether `dotnet build` succeeded, and
the remote setup left for you.
