# generate-nuget-lib-docs

Generates documentation for a **.NET library that ships as one or more NuGet
packages**: a consumer-facing **README**, a **CHANGELOG.md** and a **CONTRIBUTING.md**, plus a **Hugo docs site**
wired to GitHub Pages via CI.

## What it does

It produces three deliverables:

1. A **`README.md`** for the package's consumers — an overview and usage examples
   written from the library itself, a package table with NuGet version badges and
   `dotnet add package` install commands, followed by short fixed **Upgrading**
   (when there is an upgrade guide), **Changelog**, **Contributing** and **Legal**
   sections. The README is packed into the NuGet package, so its links to
   CHANGELOG.md and CONTRIBUTING.md are absolute GitHub URLs.
2. A **`CHANGELOG.md`** in [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/)
   format with the Semantic Versioning statement, `## [Unreleased]`, compare links
   built from the real tags, and upgrade guides under
   `### Upgrading from <X>.x to <Y>.0`; and a **`CONTRIBUTING.md`** with
   prerequisites, build, tests (`Category` Unit / Functional), branching and pull
   requests, versioning and releasing — describing what the repository actually
   enforces.
3. A **Hugo docs site** under `docs/` using the **Docsy** theme (the
   `@docsy/theme` npm package), with Changelog and Contributing pages that render
   the two root files through a `repo-file` shortcode instead of copying them,
   plus a GitHub Actions workflow that builds the site and deploys it to GitHub
   Pages.

Author identity (name, email, site, copyright holder) is resolved from the
project's git configuration at runtime — nothing is hardcoded.

**Core principle:** ask only what can't be inferred; infer everything else from
the project itself. Write each thing once: the README for consumers,
CONTRIBUTING.md for contributors, CHANGELOG.md for release history.

## When to use it

Ask for it with phrases like "generate docs", "create documentation", "make a
readme and docs site", or "document this project" **in a .NET repository with at
least one packable project** — one that opts in with `<PackageId>`,
`<IsPackable>true</IsPackable>`, or `<GeneratePackageOnBuild>`, and isn't a test
project, an `<IsPackable>false</IsPackable>` project, or an executable without a
package id. The same rule lives verbatim in
[create-nuget-publish-workflow](create-nuget-publish-workflow.md), so the two
skills always agree on what a repository ships.

If the project ships no packages — an app, a service, a sample — the skill says
so and asks before continuing: the package table, badges and install commands
won't apply, though the README overview, Hugo site and Pages workflow still do.

For the *publishing* CI of the same kind of project, see
[create-nuget-publish-workflow](create-nuget-publish-workflow.md).

## How it works

1. **Analyze the project** (no input): repo name from the git remote, the
   packable projects and their `<PackageId>`s, target frameworks, existing
   LICENSE / README / CHANGELOG / CONTRIBUTING / Hugo site, the tags, the branches
   and workflows as they are, and the real public API for accurate usage examples.
2. **Ask only the open questions** (batched): License (only if none exists)?
   Mermaid diagrams? Versioning is SemVer unless the repository documents another
   scheme.
3. **Decide structure**: write the overview from the analysis, build the package
   table, and choose single- vs. multi-page docs (one page per package for a
   package family).
4. **Write the README** from the template, with NuGet badges and install
   commands, appending the fixed sections in order — and **CHANGELOG.md and
   CONTRIBUTING.md**, moving any contributor material and upgrade guides the
   README carried into them.
5. **Create the license** if requested and none exists.
6. **Create or update the Hugo site** (`docs/package.json` with `@docsy/theme`,
   `hugo.toml` with the CHANGELOG / CONTRIBUTING mounts, content under
   `content/en/`, the Changelog and Contributing pages and the `repo-file`
   shortcode). An existing site loses its Testing / Versioning / release-history /
   migration pages once their content lives in the root files.
7. **Create the Pages workflow** (always — even when the site already existed),
   rebuilding when `CHANGELOG.md` or `CONTRIBUTING.md` change.
8. **Build the site once and report** what changed, what moved where, which
   sections were included and why, and the preview command.

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
| Infer the package id from the folder name | Reads `<PackageId>`; a wrong `dotnet add package` line is a broken install |
| Treat every csproj as part of the package family | Applies the packable rule; tests, samples and apps are excluded |
| Add `<PackageId>` so the skill applies | Says the repo ships nothing and asks |
| Rewrite an existing README wholesale | Preserves what was hand-written and confirms before replacing substance |
| Restate versions in the README | Shows them through the NuGet badges, with every release in CHANGELOG.md |
| Put build, test or release steps in the README | Writes them in CONTRIBUTING.md and links it |
| Give the docs site its own Testing or release-notes page | Renders CONTRIBUTING.md and CHANGELOG.md on the site |
| Document a branching model the repo doesn't enforce | Describes what exists and recommends the rest in the report |

## Files in this skill

| Path | Purpose |
|---|---|
| `SKILL.md` | The skill instructions. |
| `references/identity.md` | How author / owner / URL / badge fields are resolved from git. |
| `references/readme-template.md` | README skeleton and tone. |
| `references/fixed-sections.md` | Verbatim Upgrading / Changelog / Contributing / Legal blocks. |
| `references/repo-files.md` | CHANGELOG.md and CONTRIBUTING.md templates, and what moves into them. |
| `references/hugo-setup.md` | Hugo site + Docsy npm package + `repo-file` shortcode + Pages workflow. |
| `references/mermaid-types.md` | Common diagram types to offer, with examples. |
| `references/licenses.md` | How to fetch and fill license text. |

## What you get back

A README written from the real API — package table, NuGet badges, working
`dotnet add package` lines — a CHANGELOG and a CONTRIBUTING that hold what the
README no longer does, a Docsy site with a page per package plus Changelog and
Contributing pages rendered from the root files, a Pages workflow that actually
builds (`docs/package-lock.json` committed for its `npm ci`), and a report naming
which conditional sections were included and why.
