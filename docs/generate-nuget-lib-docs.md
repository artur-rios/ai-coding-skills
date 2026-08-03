# generate-nuget-lib-docs

Generates documentation for a **.NET library that ships as one or more NuGet
packages**: a **README** plus a **Hugo docs site** wired to GitHub Pages via CI.

## What it does

It produces two deliverables:

1. A **`README.md`** — an overview and usage examples written from the library
   itself, a package table with NuGet version badges and `dotnet add package`
   install commands, followed by fixed **Versioning**, **Build, test and
   publish**, and **Legal** sections.
2. A **Hugo docs site** under `docs/` using the `re-terminal` theme fork as a git
   submodule, plus a GitHub Actions workflow that builds the site and deploys it
   to GitHub Pages.

Author identity (name, email, site, copyright holder) is resolved from the
project's git configuration at runtime — nothing is hardcoded.

**Core principle:** ask only what can't be inferred; infer everything else from
the project itself.

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
   LICENSE / README / Hugo site, and the real public API for accurate usage
   examples.
2. **Ask only the open questions** (batched): SemVer? License (only if none
   exists)? Mermaid diagrams?
3. **Decide structure**: write the overview from the analysis, build the package
   table, and choose single- vs. multi-page docs (one page per package for a
   package family).
4. **Write the README** from the template, with NuGet badges and install
   commands, appending the conditional fixed sections in order.
5. **Create the license** if requested and none exists.
6. **Create or update the Hugo site** (theme submodule, `hugo.toml`, content).
7. **Create the Pages workflow** (always — even when the site already existed).
8. **Report** what changed, which sections were included and why, and the preview
   / submodule commands.

## Conditional sections

| Section | Included when |
|---|---|
| **Versioning** | The project uses semantic versioning. |
| **Build, test and publish** | Always — the project is a .NET library. |
| **Legal** | A license exists or was just created. |

## What it refuses to do

| Temptation | What the skill does instead |
|---|---|
| Write a plausible usage example | Reads the real entry points — a wrong example is the first thing a reader copies |
| Infer the package id from the folder name | Reads `<PackageId>`; a wrong `dotnet add package` line is a broken install |
| Treat every csproj as part of the package family | Applies the packable rule; tests, samples and apps are excluded |
| Add `<PackageId>` so the skill applies | Says the repo ships nothing and asks |
| Rewrite an existing README wholesale | Preserves what was hand-written and confirms before replacing substance |
| Restate versions in the README | Links to the Technology Stack Document, which owns them |

## Files in this skill

| Path | Purpose |
|---|---|
| `SKILL.md` | The skill instructions. |
| `references/identity.md` | How author / owner / URL / badge fields are resolved from git. |
| `references/readme-template.md` | README skeleton and tone. |
| `references/fixed-sections.md` | Verbatim Versioning / Build-test-publish / Legal blocks. |
| `references/hugo-setup.md` | Hugo site + theme submodule + Pages workflow. |
| `references/mermaid-types.md` | Common diagram types to offer, with examples. |
| `references/licenses.md` | How to fetch and fill license text. |

## What you get back

A README written from the real API — package table, NuGet badges, working
`dotnet add package` lines — a Hugo site with a page per package, a Pages workflow
that actually builds (`submodules: recursive` included, without which the theme is
missing on CI every time), and a report naming which conditional sections were
included and why.
