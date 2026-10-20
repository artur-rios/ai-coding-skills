# README skeletons & tone

The README is for the project's **users** — a library's consumers (and the registry page that renders the README),
or an application's callers and operators. Contributor material (building from source, tests, branching,
versioning, releasing) goes in `CONTRIBUTING.md`, and release history and upgrade guides in `CHANGELOG.md`
(`references/repo-files.md`); the README only links to them.

Keep prose tight and concrete. Prefer tables for package, page and variable lists. Use fenced ```mermaid blocks
only for the diagram types the user picked.

## Library skeleton

````markdown
# <Project Title>

<badges — docs, license, one registry version badge per package (references/identity.md, references/stacks.md)>

**`<PrimaryPackageId>`** — <one-paragraph overview: what the library is, the core problem it solves, the
shape of its public surface. Written from real analysis of the code, not guessed.>

- 📚 **Full documentation:** <https://<owner>.github.io/<repo>>
- <optional extra quick links to key docs pages>

## <Package family>   ← only if the repository ships multiple packages

<optional mermaid diagram if picked>

| Package | What it does | Status |
|---|---|---|
| [`<PackageId>`](<registry page>) | ... | ✅ |

## Installation

```bash
<the stack's install command for the package>
```

<one line per additional package, then the requirement line, e.g. "Requires .NET 8.0 or later." / "Requires
Python 3.12 or later.">

## <Quick start>

<numbered, real, minimal end-to-end example pulled from the actual API, in the project's language>

## Documentation

| Page | What's there |
|---|---|
| [<Page>](https://<owner>.github.io/<repo>/docs/<slug>/) | ... |

<!-- fixed sections appended here (references/fixed-sections.md): Upgrading (conditional), Changelog, Contributing, Legal (conditional) -->
````

### Library checklist

- Name the library and its primary package id in the first sentence.
- State the problem it solves and the one idea that makes it distinctive.
- If the repository ships multiple packages, give the table + (optional) dependency diagram.
- Show the install command + a minimal, runnable quick start from the real API.
- Link to the docs site and its key pages.
- No version number typed anywhere — the badges show the current one, `CHANGELOG.md` every release.

## Application skeleton

````markdown
# <Project Title>

<badges — docs and license (references/identity.md)>

<one-paragraph overview: what the application does, for whom, and what it is built with — "an ASP.NET Core
(.NET 10) web API", "a React single-page app", "a Rust CLI". Written from the code, not guessed.>

- 📚 **Full documentation:** <https://<owner>.github.io/<repo>>

## Overview

<bullets: the main capabilities, and for a service the architecture in one line each — layers, data store,
authentication, integrations. Optional mermaid diagram if picked.>

## Documentation

| Page | What's there |
|---|---|
| [<Page>](https://<owner>.github.io/<repo>/docs/<slug>/) | ... |

## Configure   ← only if it reads configuration

<where the configuration lives (the `.env.example` to copy, the settings file), then a table of the variables a
user must or may set, read from the real config and code:>

| Variable | Required | What it sets |
|---|---|---|
| `<NAME>` | yes | ... |

## Run

<the shortest way to run it: the command, the URL / port it listens on, the interactive API docs when a service
exposes them (Swagger UI, `/docs`), the health endpoint. For a CLI: install and a usage example. For a mobile app:
the platforms and how to launch it.>

## Deploy   ← only if the repository has containers or deploy configuration

<the container image or compose files, the env files they take, the commands. Nothing the repository doesn't have.>

<!-- fixed sections appended here (references/fixed-sections.md): Upgrading (conditional), Changelog, Contributing, Legal (conditional) -->
````

### Application checklist

- Say what it does and what it is built with in the first paragraph.
- Every variable in *Configure* is one the code reads; every required one is listed.
- *Run* works from a fresh clone with the documented configuration — the command, the URL, the health check.
- A use-case, backlog or milestone table, if the README tracks work, stays — between *Documentation* and
  *Configure*.
- No build, test, migration-authoring, branching or release instructions — those live in `CONTRIBUTING.md`.
  (*Applying* migrations to deploy is operator material and may stay in *Deploy*.)
