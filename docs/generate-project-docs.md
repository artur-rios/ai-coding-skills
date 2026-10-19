# generate-project-docs

Generates documentation for an **existing project in any stack** — a library published as packages (NuGet, npm,
PyPI, crates.io, Maven Central, pub.dev, Go modules) or an application (a web API, a web front end, a CLI, a worker,
a mobile app): a **README** for its users, a **CHANGELOG.md** and a **CONTRIBUTING.md**, plus a **Hugo docs site**
on the Docsy theme, wired to GitHub Pages via CI.

It was `generate-nuget-lib-docs`, which covered .NET libraries only. The .NET library behaviour is unchanged; the
skill now detects the stack and the kind of project and documents each accordingly.

## What it does

It produces three deliverables:

1. A **`README.md`** for the project's users:
   - a **library** gets an overview and usage examples written from the real API, a package table with registry
     version badges and the stack's install commands — and, because the README is packed into the package and shown
     on the registry, absolute GitHub links;
   - an **application** gets an overview, a docs index, and how to configure (the environment variables its code
     actually reads), run and deploy it.

   Both end with short fixed **Upgrading** (when there is an upgrade guide), **Changelog**, **Contributing** and
   **Legal** sections.
2. A **`CHANGELOG.md`** in [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) format with the Semantic
   Versioning statement, `## [Unreleased]`, compare links built from the real tags, and upgrade guides under
   `### Upgrading from <X>.x to <Y>.0`; and a **`CONTRIBUTING.md`** with prerequisites, build, tests, branching and
   pull requests, versioning and releasing — the stack's commands, checked against the repository, and the release
   model (library or application) the repository actually enforces.
3. A **Hugo docs site** under `docs/` using the **Docsy** theme (the `@docsy/theme` npm package), with Changelog and
   Contributing pages that render the two root files through a `repo-file` shortcode instead of copying them — for an
   application, getting-started, configuration, architecture, API (Swagger UI over a committed OpenAPI document) and
   operations pages — plus a GitHub Actions workflow that builds the site, with an optional test coverage report,
   and deploys it to GitHub Pages.

Author identity (name, email, site, copyright holder) is resolved from the project's git configuration at runtime —
nothing is hardcoded.

**Core principle:** ask only what can't be inferred; infer everything else from the project itself. Write each
thing once: the README for users, CONTRIBUTING.md for contributors, CHANGELOG.md for release history.

## When to use it

Ask for it with phrases like "generate docs", "create documentation", "make a readme and docs site", "document this
project", or "set up a Hugo / Docsy site on GitHub Pages", in a repository with code to document.

Not for a greenfield directory — scaffold it with [scaffold-project](scaffold-project.md) first — nor for
requirements documents from notes, which is [generate-specs-from-brainstorm](generate-specs-from-brainstorm.md).
For the *publishing* CI of a .NET library, see [create-nuget-publish-workflow](create-nuget-publish-workflow.md).

## Library or application

| | Library | Application |
|---|---|---|
| Decided by | the repository publishes at least one package | it publishes none |
| README | overview, package table, install, quick start | overview, configure, run, deploy |
| README links to the root files | absolute GitHub URLs (the README ships in the package) | relative |
| Site pages | overview, one page per package, architecture | getting started, configuration, architecture, API, operations |

What counts as a published package is decided per stack (`references/stacks.md`): the .NET packable rule — shared
verbatim with [create-nuget-publish-workflow](create-nuget-publish-workflow.md), so the two skills always agree on
what a repository ships — `"private"` in `package.json`, `publish = false` in `Cargo.toml`, `publish_to: none` in
`pubspec.yaml`, a publish plugin in a Gradle or Maven build, and a PyPI page or publish workflow for Python. When
the signals don't decide, the skill asks.

## How it works

1. **Analyze the project** (no input): repo name from the git remote, the components and their stacks, library or
   application, package ids and requirements, the configuration / run / deploy facts of an application, the tests
   and any coverage tool, existing LICENSE / README / CHANGELOG / CONTRIBUTING / Hugo site, the tags, the branches
   and workflows as they are, and the real public API for accurate usage examples.
2. **Ask only the open questions** (batched): the kind (only when unclear)? License (only if none exists)?
   Coverage report (only when there are tests and no report)? Mermaid diagrams? Versioning is SemVer unless the
   repository documents another scheme.
3. **Decide structure**: write the overview from the analysis, build the package table or the application page
   set, and choose single- vs. multi-page docs.
4. **Write the README** from the library or application skeleton, appending the fixed sections in order — and
   **CHANGELOG.md and CONTRIBUTING.md**, moving any contributor material and upgrade guides the README carried into
   them.
5. **Create the license** if requested and none exists — the Artur Rios Attribution License by default.
6. **Create or update the Hugo site** (`docs/package.json` with `@docsy/theme`, `hugo.toml` with the CHANGELOG /
   CONTRIBUTING mounts, content under `content/en/`, the Changelog and Contributing pages and the `repo-file`
   shortcode). An existing site loses its Testing / Versioning / release-history / migration pages once their content
   lives in the root files.
7. **Create the Pages workflow** (always — even when the site already existed), rebuilding when `CHANGELOG.md` or
   `CONTRIBUTING.md` change, with the stack's coverage steps when a report is published.
8. **Build the site once and report** what changed, what moved where, which sections were included and why, and the
   preview command.

## Conditional sections

| Section | Included when |
|---|---|
| **Upgrading** | CHANGELOG.md has an `### Upgrading from <X>.x to <Y>.0` guide — one link per guide. |
| **Changelog** | Always. |
| **Contributing** | Always. |
| **Legal** | A license exists or was just created. |

## What it refuses to do

| Temptation | What the skill does instead |
|---|---|
| Write a plausible usage example | Reads the real entry points — a wrong example is the first thing a reader copies |
| List the environment variables an app "probably" needs | Reads them from the config files and the code that reads them |
| Infer the package id from the folder name | Reads it from the manifest; a wrong install line is a broken install |
| Call every manifest a package | Applies the stack's publish rule; private, unpublished, test and sample projects are not packages |
| Rewrite an existing README wholesale | Preserves what was hand-written and confirms before replacing substance |
| Restate versions in the README | Shows them through registry badges, with every release in CHANGELOG.md |
| Put build, test or release steps in the README | Writes them in CONTRIBUTING.md and links it |
| Give the docs site its own Testing or release-notes page | Renders CONTRIBUTING.md and CHANGELOG.md on the site |
| Document a branching model the repo doesn't enforce | Describes what exists and recommends the rest in the report |

## Files in this skill

| Path | Purpose |
|---|---|
| `SKILL.md` | The skill instructions. |
| `references/stacks.md` | Stack detection, the package-or-application rule per stack (with the .NET packable rule), install commands, badges, build / test / coverage commands, CI setup steps, and the application facts to read. |
| `references/identity.md` | How author / owner / URL / badge fields are resolved from git. |
| `references/readme-template.md` | Library and application README skeletons and tone. |
| `references/fixed-sections.md` | Verbatim Upgrading / Changelog / Contributing / Legal blocks. |
| `references/repo-files.md` | CHANGELOG.md and CONTRIBUTING.md templates, the library and application release models, and what moves into them. |
| `references/hugo-setup.md` | Hugo site + Docsy npm package + `repo-file` shortcode + application pages + Pages workflow. |
| `references/mermaid-types.md` | Common diagram types to offer, with examples. |
| `references/licenses.md` | The default Artur Rios Attribution License text, and how to fetch and fill the standard ones. |

## What you get back

A README written from the real code — for a library, a package table, registry badges and working install lines;
for an application, configuration that matches what the code reads and a run command that works — a CHANGELOG and a
CONTRIBUTING that hold what the README no longer does, a Docsy site with Changelog and Contributing pages rendered
from the root files, a Pages workflow that actually builds (`docs/package-lock.json` committed for its `npm ci`), and
a report naming which conditional sections were included and why.
