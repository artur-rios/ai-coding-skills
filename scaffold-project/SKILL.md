---
name: scaffold-project
description: Use when the user wants to create, scaffold, bootstrap or start a new project or repository from scratch in an empty or greenfield directory, in any stack — .NET (web API, NuGet library, console, worker, Blazor…), Spring Boot, Python, Node.js / TypeScript, React with shadcn/ui, Angular with spartan/ui, Rust, Flutter, or another one. Triggers on "scaffold a new project", "bootstrap a .NET web API", "create a NuGet library", "new dotnet API with the heimdall structure", "start a Spring Boot service", "new React app with shadcn", "set up a Rust crate", "create a Flutter app". Not for adding a project to an existing solution or repository — it stops if one is already there.
---

# Scaffold Project

## Overview

Creates a new repository from nothing, in whichever technology the user picks, through
one interview followed by one scaffold. Every stack lands on the **same repository
shape** — the code in `src/`, the tests in `tests/`, the documentation in `docs/`, and the
same root files — so a reader who has opened one of these repositories knows their way
around all of them.

**Core principle:** collect every answer first, then scaffold in one shot — never mix
questions with file creation. Generators that run before the interview is finished
produce output that has to be deleted and redone.

The skill is a router: this file holds the interview, the shared structure and the
procedure; each stack's specifics — its questions, its generator, how it is bent into
`src/` + `tests/`, how it is verified — live in a reference file loaded only for that
stack.

## When to Use

**Precondition: the target directory holds no project and none of the files this skill
writes.** Check before asking anything (step 0).

- The user asks to "scaffold / create / bootstrap / start a new project, app, API,
  library, service or repository".
- A greenfield repository needs initializing, in any stack.
- The user points at `heimdall-api` and asks for a new API with the same structure — the
  .NET layered Web API path.

Skip / adapt if:
- The user is adding a project, package or module to an **existing** repository —
  follow that repository's own conventions instead.
- The repository exists and the user only wants a piece of it: tests
  (**create-unit-tests**), a NuGet publish workflow (**create-nuget-publish-workflow**),
  a README and docs site (**generate-project-docs**), or project
  documentation from notes (**generate-specs-from-brainstorm**).

## The shared repository shape

Every stack produces this, whatever else it adds:

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
README.md                              for the people who use the project — nothing contributor-facing
```

Where a stack's tooling expects another layout (Maven's `src/test/java`, Angular's
co-located `*.spec.ts`, Flutter's `test/`), the stack reference **reconfigures the tool**
so the tests still live in `tests/`. It never moves the shared folders to suit the tool.

## Stacks

| Stack | Kinds the reference asks about | Reference |
|---|---|---|
| .NET | Web API (layered DDD + CQRS, or minimal), NuGet library, any other `dotnet new` template | `references/dotnet.md` |
| Spring Boot | Java or Kotlin service | `references/spring-boot.md` |
| Python | application / CLI, or library | `references/python.md` |
| Node.js / TypeScript | application / CLI, or npm library | `references/node-typescript.md` |
| React + shadcn/ui | web app | `references/react-shadcn.md` |
| Angular + spartan/ui | web app | `references/angular-spartan.md` |
| Rust | binary or library crate | `references/rust.md` |
| Flutter | app | `references/flutter.md` |
| Anything else (Go, Elixir, …) | asked | `references/other.md` |

## Red Flags — STOP and Re-read the Procedure

- "The user said 'a .NET web API', but I'll ask the technology question anyway" → NO. A
  stated stack (or kind) is an answer. Say what you inferred in one line and move on.
- "I'll run the generator now and ask the rest afterwards" → NO. Every answer first.
- "The tool wants `src/test/java` / co-located specs / `test/`, so `tests/` can stay
  empty" → NO. Reconfigure the tool; the shared shape is the point of this skill.
- "This stack doesn't need a CHANGELOG / CONTRIBUTING / branch policy / `.wakatime-project`"
  → NO. The shared files are the same for every stack.
- "There's already a README here, mine is better" → NO. Step 0 asks before overwriting
  anything.
- "I'll leave the generator's demo page / counter / sample controller in" → NO. Strip
  demo content; the scaffold is the shape, not an example. The stack reference says what
  stays.
- "I remember the current version of this framework" → NO. Generators and package
  managers resolve versions at scaffold time. Never pin from memory.
- "The build is obviously fine, I'll skip verification" → NO. A scaffold that has not been
  built and tested is not a scaffold.

| Rationalization | Reality |
|---|---|
| "Asking the stack again is just being careful" | It makes the user repeat themselves. If the request names the stack, the question is answered. |
| "The tool's default layout is the idiomatic one" | The user chose one shape for every repository. The references show how each tool is configured to honour it. |
| "A new repo doesn't need a CHANGELOG yet" | The first pull request already has something to record under `## [Unreleased]`. |
| "The README is the obvious place for build and test commands" | They are contributor material and go in `CONTRIBUTING.md`; the README links it. |
| "A `.gitkeep` is clutter" | Git does not track directories. Without it `tests/` or `docs/` vanishes on the first commit. |

## Procedure

Create a todo per step. **Collect every answer before creating any file.**

### 0. Check the directory is safe to scaffold into

```bash
ls -a
find . -path ./.git -prune -o \( -name "*.sln" -o -name "*.slnx" -o -name "*.csproj" \
  -o -name package.json -o -name pyproject.toml -o -name Cargo.toml -o -name pom.xml \
  -o -name "build.gradle*" -o -name pubspec.yaml -o -name go.mod \) -print
git remote get-url origin
```

- **A project manifest already exists** → not greenfield. Stop, say what you found, and
  point at *Skip / adapt if*.
- **Any file this skill writes already exists** (the shared files above, plus any the stack
  reference lists) → name each one and ask whether to overwrite or keep it, before the
  interview. Honour the answer per file; keeping an existing `LICENSE` also skips the
  license question.
- **Empty, or only unrelated files** → proceed.

Never overwrite silently. If the directory is not a git repository yet, note it: step 5 starts
with `git init -b main` — the branch policy, the placeholder check in step 6 and `.gitignore` all
assume one.

### 1. Technology — only if the request doesn't name it

If the user's request already names the stack — ".NET web API", "a NuGet package", "a
Rust CLI", "Spring service", "React app with shadcn", "like heimdall-api" (→ .NET layered
Web API) — **do not ask**; state the inference in one line ("Scaffolding a .NET Web API.")
and continue. Otherwise ask:

*"Which technology? .NET, Spring Boot, Python, Node.js / TypeScript, React (shadcn/ui),
Angular (spartan/ui), Rust, Flutter — or another one."*

Then **read that stack's reference file** from the table above. From here on it supplies
the stack's questions and commands.

### 2. Project kind — from the stack reference

Ask the reference's kind question (for .NET: Web API, NuGet library, or another template),
again **only if the request didn't already answer it**. Some kinds route to a further
reference (.NET layered Web API → `references/dotnet-web-api/overview.md`; NuGet library →
`references/dotnet-nuget-library.md`) — read it now, before the next question.

### 3. The shared questions

Ask these in one round, together with step 4's:

| Question | Default |
|---|---|
| "What is the project called?" — in the stack's naming form (the reference says which: PascalCase for .NET, kebab-case for npm / Cargo, snake_case for Python and Dart packages) | — |
| "One sentence: what does it do?" | — |
| "Which license? Artur Rios Attribution License, MIT, AGPL, or Custom Commercial." | Artur Rios Attribution License |
| "Which GitHub owner/repo will this live in? (e.g. acme/order-service)" — **only when `git remote get-url origin` gave nothing**; otherwise parse it | — |

For **Custom Commercial**, also ask the copyright holder, the license grant, and any
additional restrictions or permissions.

### 4. The stack's own questions

Ask everything the stack reference (and the kind reference from step 2) lists under its
*Interview* section, in the same round as step 3. Offer each default; never invent a value
the user didn't give and the reference doesn't default — a prefix, a group id, an org.

**Stop asking here.** Nothing below may need another answer.

### 5. Run the generator

If the directory is not a git repository, `git init -b main` first. Never commit — the user makes
the first commit.

Follow the stack reference's *Generate* section. Generators run **before** the shared
files are written, because most of them refuse a non-empty directory or write their own
README and `.gitignore`. When a generator refuses a directory the user chose to keep files
in, generate into a temporary directory and move its contents in, never over a file the
user chose to keep in step 0.

Then apply the reference's *Shape* section: move the code into `src/` and the tests into
`tests/`, reconfigure the tool to find them there, and strip the generator's demo content.

### 6. Write the shared files

1. `src/`, `tests/`, `docs/` exist; put a `.gitkeep` in each that is still empty.
2. `.editorconfig` — `templates/dotnet/.editorconfig` for .NET, `templates/.editorconfig`
   for every other stack. When the generator wrote one, keep its language sections the template
   lacks (Angular's `[*.ts] quote_type = single`) below the template's.
3. `.gitattributes` — `templates/.gitattributes`, plus any lines the stack reference adds.
4. `.gitignore` — the generator's own when it wrote one (Flutter's stays next to its
   project in `src/`), `templates/dotnet/.gitignore` for .NET; then append the
   *Shared ignores* block from `templates/.gitignore-shared` to the root one, skipping lines
   already present — and a comment header whose lines were all skipped.
5. `.wakatime-project` — a single line: the repository name — the `<repo>` part of owner/repo,
   not the project name (`orders`, not `Acme.Orders`).
6. `LICENSE` — `templates/LICENSE` verbatim with `__YEAR__` set to the current year for the
   default license (the copyright holder and attribution clause stay Artur Rios — never
   substitute another name); the standard text for MIT or AGPL v3 (never paraphrase a
   license), with `Copyright (c) <year> <holder>` where the holder is the authors the stack
   interview gave, else `git config user.name`; for Custom Commercial, a file written from the
   follow-up answers.
7. `README.md` — from `templates/README.md`, with the stack reference's *README* fill-ins.
8. `CHANGELOG.md` — from `templates/CHANGELOG.md`.
9. `CONTRIBUTING.md` — from `templates/CONTRIBUTING.md`, with the stack reference's
   *CONTRIBUTING* fill-ins and the variant below.
10. `.github/workflows/branch-policy.yml` — the variant below.

| Kind | Variant | Branch policy |
|---|---|---|
| A library — NuGet, PyPI, npm, Rust library crate, or a .NET `classlib` | **Library**: the version lives in a file, the release branch bumps it and finalizes the CHANGELOG, `main` is merged back into `develop`, tags are `<version>` | `templates/branch-policy-library.yml`, with `__VERSION_FILE__` and `__VERSION_PATTERN__` from the stack reference |
| Anything else | **Application**: the version is the release branch name and its `v` tag, release branches are snapshots of `develop` | `templates/branch-policy-app.yml`, verbatim |

**Exception — .NET layered Web API.** Its own reference writes README, CHANGELOG,
CONTRIBUTING and LICENSE from `references/dotnet-web-api/repo-docs.md` and `license.md`,
and its `.gitignore` from `references/dotnet-web-api/files/`. Everything else comes from this step:
the application branch policy, `templates/dotnet/.editorconfig`, `templates/.gitattributes` with
the lines of `references/dotnet-web-api/files/.gitattributes` appended, the shared ignores, the
`.gitkeep`s and `.wakatime-project`.

Delete every guidance comment and unused `VARIANT` block from the templates in the
generated files. No `{{…}}` or `__…__` placeholder may survive — over the files git would track
(so `node_modules/`, build output and binaries are skipped), this must print nothing:

```bash
git ls-files -co --exclude-standard -z | xargs -0 grep -nIE '\{\{[A-Za-z]+\}\}|__[A-Z][A-Z_]*__'
```

The template placeholders are written without spaces (`{{Project}}`, `__VERSION_FILE__`), so
GitHub Actions' `${{ github.… }}`, Angular's `{{ title }}` and JSX's `style={{…}}` don't match.

### 7. Verify — never skip, never assume

Run the stack reference's *Verify* commands and read their real exit codes (redirect to a
file instead of piping into `tail` or `grep`, which swallows the exit code). Every command
must pass. A test runner that finds no tests is acceptable only where the reference says
so. If a structural reconfiguration from step 5 fails here, fix it, re-run, and say what
you changed in the report.

### 8. Follow-up skills — only those the user said yes to

The NuGet library interview asks whether to also run **create-nuget-publish-workflow**
and **generate-project-docs**. Run each one the user accepted, now that the scaffold
builds.

### 9. Report

Tell the user:
- The stack, kind, names, and the versions the generator or package manager resolved.
- The tree that was created.
- The license, and the CONTRIBUTING / branch-policy variant and why.
- What each verification command actually printed — anything skipped, and why.
- The stack reference's *Report* items (secrets to set, migrations to apply, …).
- The remote setup the branching model needs, which this skill does not do — after the
  first commit is pushed to `main`:
  1. create `develop` from `main` (`git push origin main:refs/heads/develop`) and make it
     the default branch;
  2. create the rulesets "Develop: PRs only" (on `develop`: no deletion, no force push,
     pull request with 0 approvals, merge or squash) and "Main: release PRs only" (on
     `main`: the same, merge commits only), both requiring the branch policy check —
     `Branch policy` for the library variant, `branch-policy` for the application variant —
     plus any CI job the stack added (the stack reference names them);
  3. create the "Version tags" tag ruleset (creation, update, deletion), with the
     repository admin role allowed to bypass all three.

## Quick Reference

| Decision | Rule |
|---|---|
| Stack question | Only when the request doesn't name the stack. |
| Kind question | Only when the request doesn't name the kind. |
| Order | Directory check → stack → kind → shared + stack questions in one round → generator → shape → shared files → verify → follow-ups → report. |
| Layout | `src/`, `tests/`, `docs/` for every stack; tools are reconfigured, never the layout. |
| Root files | README, CHANGELOG, CONTRIBUTING, LICENSE, `.wakatime-project`, `.editorconfig`, `.gitattributes`, `.gitignore`, branch policy. |
| `.wakatime-project` | One line, the repository name. |
| README | What the project is, requirements, how to install or run it, links to CHANGELOG / CONTRIBUTING, license. Nothing a contributor needs. |
| Branch-policy variant | Library kinds → library; everything else → application. |
| Versions | Resolved at scaffold time by the generator or package manager; never from memory. |
| Demo content | Stripped. The stack reference says what stays. |
| Verification | The reference's commands, real exit codes, all passing. |

## Common Mistakes

- **Asking for the technology when the user already named it.** It is the first thing the
  user notices, and it signals the request wasn't read.
- **Scaffolding into a directory that already has a project or a README.** Step 0 exists to
  catch that. Ask before overwriting anything.
- **Letting the tool's layout win.** Tests in `src/test/java`, specs beside components, a
  Flutter `test/` folder — each one breaks the shape the user asked every repository to
  share. The stack reference shows the configuration that moves them.
- **Leaving empty directories without a `.gitkeep`.** They vanish on the first commit.
- **Writing the shared files before the generator runs.** The generator then refuses the
  directory, or overwrites the README you just wrote.
- **Leaving template placeholders or guidance comments behind.** Grep for them (step 6).
- **Writing build and test instructions into the README.** They belong in
  `CONTRIBUTING.md`; a library README that is packed into a package (NuGet, npm, PyPI) links
  CHANGELOG and CONTRIBUTING by absolute GitHub URL, because relative links break on the
  registry's page.
- **Picking the wrong branch-policy variant**, or leaving `__VERSION_FILE__` /
  `__VERSION_PATTERN__` in the library one — every release pull request then fails its
  version check.
- **Guessing a prefix, group id or org.** Leave it out unless the user gives one or the
  reference has a default; never invent `Company`, `MyOrg` or `com.example`.
- **Reporting success without running the verification**, or reporting a skipped suite as
  passing.
