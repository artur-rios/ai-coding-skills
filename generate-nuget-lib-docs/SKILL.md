---
name: generate-nuget-lib-docs
description: Use when the user wants to generate documentation for a .NET library that ships as one or more NuGet packages — a README (overview, package table with NuGet badges, install, usage, and the Versioning / Build-test-publish / Legal sections) plus a Hugo docs site using the Docsy theme, deployed to GitHub Pages by CI. Triggers on "generate docs" / "create documentation" / "document this project" / "make a readme and docs site" when the project is a .NET solution with packable projects (`<IsPackable>`, `<PackageId>`, or a nupkg-producing csproj).
---

# Generate NuGet Library Docs

## Overview

Generates two deliverables for the current NuGet library project:

1. A **README.md** — overview, package table with NuGet version badges, `dotnet add package` install
   commands, usage examples, and the fixed **Versioning**, **Build, test and publish**, and **Legal**
   sections (see below for which are conditional).
2. A **Hugo docs site** under `docs/` using the **Docsy** theme as a submodule,
   plus a **GitHub Actions workflow** under `.github/workflows/` that builds the site and deploys it
   to GitHub Pages.

Author identity (name, email, site, copyright holder) is resolved from the project's git configuration
at runtime — nothing is hardcoded. See `references/identity.md` for exactly how each value is obtained;
only the repo name and project-specific content change per project.

**Core principle:** ask only what can't be inferred; infer everything else from the project itself.

## When to Use

**Precondition: the repo is a .NET library that ships at least one NuGet package.** Verify it with the
detection below before writing anything.

If the project is .NET but ships no packages (an app, a service, a sample), or is not .NET at all, say
so and ask whether to proceed anyway — the package table, NuGet badges and install commands won't apply,
and the rest of the workflow (README overview + Hugo site + Pages workflow) still works if the user
wants it. Do not add `<PackageId>` to a project to make this skill fit; that is the user's decision.

Related: `create-nuget-publish-workflow` generates the *publishing* CI for the same kind of project;
this skill only writes documentation.

### What counts as a packable project

*(This rule is shared verbatim with `create-nuget-publish-workflow` so the two skills never disagree
about what a repository ships. Change it in both or neither.)*

A `.csproj` ships a NuGet package when it **opts in** and is **not excluded**:

| | Signal |
|---|---|
| **Opts in** | An explicit `<PackageId>`, or `<IsPackable>true</IsPackable>`, or `<GeneratePackageOnBuild>true</GeneratePackageOnBuild>` |
| **Excluded** | `<IsPackable>false</IsPackable>`; a test project (references `Microsoft.NET.Test.Sdk`); an executable (`<OutputType>Exe</OutputType>`) that has no `<PackageId>` |

An executable *with* a `<PackageId>` is legitimate — that is how .NET tools ship — so do not exclude it
on `OutputType` alone.

Detect from the **repository root**, not just `src/` — not every repo has one:

```bash
grep -rl -e "<PackageId>" -e "<IsPackable>true</IsPackable>" \
        -e "<GeneratePackageOnBuild>true</GeneratePackageOnBuild>" \
        --include=*.csproj . | sort
```

Then read each match and drop the ones the exclusion column catches.

**The package id** is the `<PackageId>` when set; otherwise it defaults to the assembly name, which
defaults to the project file name. Read it — never infer it from the folder name.

## Red Flags — STOP and Re-read the Procedure

- "I'll write a plausible usage example and refine it later" → NO. Read the real API.
  A wrong example is worse than none — it is the first thing a reader copies.
- "The folder is `src/Acme.Http`, so the package is `Acme.Http`" → Usually, but read
  `<PackageId>`. A wrong `dotnet add package` line is a broken install.
- "The test project has no `IsPackable`, so it's part of the family" → NO. Apply the
  packable rule; test, sample and app projects are not packages.
- "This repo has no package, but the docs would still be nice" → Say so and ask
  first. Do not add `<PackageId>` to make the skill fit.
- "There's a README already, I'll rewrite it properly" → NO. Diff it mentally and
  preserve what was hand-written; confirm before replacing substance.
- "The Hugo site exists, so CI must exist too" → Check. A repo can have a site and
  no workflow, and the workflow step runs either way.
- "The versions belong in the README too, for convenience" → NO. The Technology
  Stack Document owns versions; everything else links to it.

| Rationalization | Reality |
|---|---|
| "The user will notice if an example is wrong" | They will notice it failed, after pasting it. Read the entry points and write something that compiles. |
| "SemVer is the obvious default, no need to ask" | Versioning policy is a promise to consumers. Ask; omit the section if the answer is no. |
| "`submodules: recursive` is a detail" | Without it the theme is absent on CI and the docs build fails — every time, only in CI. |
| "One page per package is over-engineering for a small library" | Then it is a single-package library and one page is right. Let the package count decide, not the mood. |

## Procedure

Create a todo per step.

### 1. Analyze the project (no user input)

Gather these facts before asking anything:

| Fact | How to detect |
|---|---|
| Repo name | `git remote get-url origin` → last path segment without `.git`. Used in Pages URL and GitHub links. |
| Packable projects | Every `*.csproj` matching the rule in **When to use** above. This is the package family. |
| Package ids | `<PackageId>` per packable project, falling back to the assembly/project name. Used for badges and `dotnet add package`. |
| Target framework(s) | `<TargetFramework>` / `<TargetFrameworks>` — states the runtime requirement in Installation. |
| Existing LICENSE? | `LICENSE` / `LICENSE.md` / `LICENSE.txt` at root. |
| Existing README? | `README.md` at root (you will replace or extend it — confirm before overwriting substantial content). |
| Existing Hugo docs? | `docs/hugo.toml` (or `config.toml`) present. |
| Solution layout | Scan `src/` and the project files to write an accurate overview and the package table. |
| Public API / usage | Read the main entry points of each package to write real usage examples — never invent an API. |

If no git remote exists, ask the user for the intended `owner/repo`.

### 2. Ask the user (batch into one AskUserQuestion call where possible)

Ask ONLY these, and only when the analysis leaves them open:

- **Semantic versioning?** Yes → include the **Versioning** section. No → omit it.
- **License** — only if no LICENSE was found: "Add a license?" If yes, "Which one?" (offer MIT,
  Apache-2.0, GPL-3.0, BSD-3-Clause, or Other). See `references/licenses.md`.
- **Mermaid diagrams?** If yes, offer the common types (multi-select) — see `references/mermaid-types.md`
  — and let them pick one or more. If no, use plain prose/tables only.

Do NOT ask about: the overview content, or whether to split docs into multiple pages — decide those
yourself in step 3.

### 3. Decide structure (no user input)

- **Overview:** write it from the analysis — what the library is, the problem it solves, its package
  layout, install steps, and a minimal quick-start. Match the tone of `references/readme-template.md`.
- **Package table:** one row per packable project — package id, what it does, status. Include it whenever
  there is more than one package; for a single package, fold it into the overview instead.
- **Single vs. multi-page docs:** one docs page (`docs/_index.md`) for a single-package library; for a
  multi-package family, `docs/_index.md` + one page per package (or per major subsystem when a package
  is large enough to warrant it). Docsy builds the sidebar from the page tree — order pages with
  `weight`, don't add a `[[menu.main]]` entry per page.

### 4. Write the README

Use `references/readme-template.md` as the skeleton. Fill the overview and usage from step 1/3. Append the
fixed sections **in this order, each only if its condition holds**:

- **Versioning** — only if semantic versioning (verbatim block in `references/fixed-sections.md`).
- **Build, test and publish** — always for a NuGet library (verbatim block in `references/fixed-sections.md`).
- **Legal** — only if a license exists or was just created (verbatim block, adapted to the chosen license).

Add the docs-site and license badges at the top, plus one shields.io NuGet version badge per package
(`references/identity.md`). Installation uses the real `dotnet add package <PackageId>` command for every
package, with the target framework as the runtime requirement.

### 5. Create or verify the license (if requested)

If the user asked for a license and none exists, write it to `LICENSE` using `references/licenses.md`
(fill copyright holder = the author name, year = current year). Then the Legal section becomes applicable.

### 6. Create or verify the Hugo docs site

If `docs/hugo.toml` already exists, only update the content pages to match step 3. Otherwise create it
from scratch — follow `references/hugo-setup.md` exactly (init site, add Docsy as a submodule and run
`npm install` inside it, write `hugo.toml`, archetype, and content pages under `content/en/`).

If an existing site uses a theme other than Docsy, say so and ask before switching — the swap moves
content directories and rewrites the config.

### 7. Create the GitHub Actions workflow (always)

Write the Pages workflow: on push to `main` touching `docs/**` (and `workflow_dispatch`), it checks out
with `submodules: recursive`, installs the Docsy npm dependencies, sets up Hugo Extended, builds `docs/`,
and deploys `docs/public` to the `gh-pages` branch. Use the verbatim YAML in `references/hugo-setup.md`
step 7, filling `<owner>`/`<repo>`.

Name the file for what it does: `build-docs-and-coverage-report.yml` when the solution publishes a
coverage report into the site, `build-docs.yml` when it does not. The file name and the workflow's
`name:` must agree.

**Ensure this file exists even when the docs site already existed** — a repo can have a Hugo site but no
CI. If the file is already present and correct, leave it; if it's missing or stale, create/fix it.

### 8. Report

Summarize: files created/changed (including the workflow), which conditional sections were included and
why, and the commands to preview (`hugo -s docs server`) and to finish wiring the theme
(`git submodule update --init --recursive`, then `npm install` inside `docs/themes/docsy`). Remind the user to enable GitHub Pages (Settings → Pages → deploy from
the `gh-pages` branch) if this is the repo's first docs deploy.

## Quick Reference

| Question | Answer |
|---|---|
| Is the repo in scope? | At least one packable project. None → say so and ask. |
| What is asked? | SemVer, license (only if none exists), mermaid diagrams. Nothing else. |
| What is never asked? | The overview content and the page split — decide those. |
| One page or many? | One per package for a family; one total for a single package. |
| Where do versions live? | The Technology Stack Document only. Everything links to it. |
| Who owns identity? | `references/identity.md`, resolved from git — never hardcoded. |

### Conditional README sections

| Section | Included when |
|---|---|
| Versioning | The user uses semantic versioning |
| Build, test and publish | Always — the project is a .NET library |
| Legal | A license exists or was just created |

### Reference files

- `references/identity.md` — how author/links/URLs are resolved from git. Use verbatim.
- `references/readme-template.md` — README skeleton and tone.
- `references/fixed-sections.md` — verbatim Versioning / Build-test-publish / Legal blocks.
- `references/hugo-setup.md` — Hugo site + Docsy submodule + Pages workflow.
- `references/mermaid-types.md` — common diagram types to offer, with examples.
- `references/licenses.md` — how to fetch/fill license text.

## Common Mistakes

- **Inventing usage examples.** Read the real code first; a wrong example is worse than none.
- **Guessing package ids from folder names.** Read `<PackageId>` from the csproj; the folder and the
  published id often differ, and a wrong `dotnet add package` line is a broken install.
- **Listing non-packable projects as packages.** Test, sample and app projects are not part of the
  package family — apply the packable rule before adding a row or a badge.
- **Including Versioning when the user isn't using SemVer.** Skip it entirely; don't water it down.
- **Overwriting an existing README without confirming.** Diff mentally; preserve anything hand-written.
- **Forgetting `submodules: recursive` in the Pages workflow** — the theme won't be there on CI and the
  build fails.
- **Skipping `npm install` inside `docs/themes/docsy`** — Docsy builds its CSS with PostCSS, so the
  build fails locally and in CI without it.
- **Listing every docs page under `[[menu.main]]`** — Docsy generates the sidebar from the page tree;
  the navbar is for top-level links only. Order pages with `weight`.
- **Hardcoding a different identity.** Author, email, and personal links always come from
  `references/identity.md`.
