---
name: generate-nuget-lib-docs
description: Use when the user wants to generate documentation for a .NET library that ships as one or more NuGet packages — a consumer-facing README (overview, package table with NuGet badges, install, usage, and short Upgrading / Changelog / Contributing / Legal sections), a CHANGELOG.md (Keep a Changelog, SemVer) and a CONTRIBUTING.md (build, tests, branching, versioning, releasing), plus a Hugo docs site using the Docsy theme that renders those two files instead of copying them, deployed to GitHub Pages by CI. Triggers on "generate docs" / "create documentation" / "document this project" / "make a readme and docs site" when the project is a .NET solution with packable projects (`<IsPackable>`, `<PackageId>`, or a nupkg-producing csproj).
---

# Generate NuGet Library Docs

## Overview

Generates three deliverables for the current NuGet library project:

1. A **README.md** for the package's consumers — overview, package table with NuGet version badges,
   `dotnet add package` install commands, usage examples, and the fixed **Upgrading**, **Changelog**,
   **Contributing** and **Legal** sections (see below for which are conditional). The README is packed into the
   package, so its links to the other two files are absolute GitHub URLs.
2. A **CHANGELOG.md** (Keep a Changelog 1.1.0, Semantic Versioning, `## [Unreleased]`, compare links, upgrade guides)
   and a **CONTRIBUTING.md** (prerequisites, build, tests, branching, commits, versioning, releasing) — the homes of
   everything the README no longer carries.
3. A **Hugo docs site** under `docs/` using the **Docsy** theme (the `@docsy/theme` npm package), with Changelog and
   Contributing pages that render the two root files, plus a **GitHub Actions workflow** under `.github/workflows/`
   that builds the site and deploys it to GitHub Pages.

Author identity (name, email, site, copyright holder) is resolved from the project's git configuration
at runtime — nothing is hardcoded. See `references/identity.md` for exactly how each value is obtained;
only the repo name and project-specific content change per project.

**Core principle:** ask only what can't be inferred; infer everything else from the project itself. And write
each thing once: the README for consumers, `CONTRIBUTING.md` for contributors, `CHANGELOG.md` for release history —
the docs site renders the latter two rather than repeating them.

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
- "The versions belong in the README too, for convenience" → NO. The NuGet badges
  show the current version and `CHANGELOG.md` holds every release; a version number
  typed into the README is stale after the next release.
- "Build and test instructions in the README are helpful" → NO. They are contributor
  material and go in `CONTRIBUTING.md`; the README links to it. The README is what
  nuget.org shows a consumer.
- "The docs site should have its own Testing / Versioning / Release notes page" → NO.
  The Changelog and Contributing pages render the root files; a copy drifts.
- "`./CHANGELOG.md` is fine in the README" → NO. The README ships inside the package,
  where a relative link resolves to nothing. Use the absolute GitHub URL on `main`.

| Rationalization | Reality |
|---|---|
| "The user will notice if an example is wrong" | They will notice it failed, after pasting it. Read the entry points and write something that compiles. |
| "The repo has no versioning statement, so I'll ask which scheme" | SemVer is the policy for every library here. State it in CHANGELOG.md and CONTRIBUTING.md; only a scheme the repository already documents overrides it. |
| "`package-lock.json` is noise, I'll leave it out" | CI installs with `npm ci`, which fails without it — every time, only in CI. |
| "The release history is in the tags, a CHANGELOG is redundant" | Tags say *when*, not *what changed for me*. The CHANGELOG is the consumer's upgrade decision. |
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
| Existing CHANGELOG / CONTRIBUTING? | `CHANGELOG.md` / `CONTRIBUTING.md` at root. Extend them; never replace. |
| Released versions | `git tag --list` and the csproj `<Version>` — the CHANGELOG entries and compare links are built from them. |
| Branching and CI as they are | `git branch -r` (is there a `develop`?), `.github/workflows/` (`branch-policy.yml`, test jobs and their `Category` filters, `publish-package.yml`). CONTRIBUTING describes what exists. |
| Existing Hugo docs? | `docs/hugo.toml` (or `config.toml`) present. |
| Solution layout | Scan `src/` and the project files to write an accurate overview and the package table. |
| Public API / usage | Read the main entry points of each package to write real usage examples — never invent an API. |

If no git remote exists, ask the user for the intended `owner/repo`.

### 2. Ask the user (batch into one AskUserQuestion call where possible)

Ask ONLY these, and only when the analysis leaves them open:

- **License** — only if no LICENSE was found: "Add a license?" If yes, "Which one?" (offer MIT,
  Apache-2.0, GPL-3.0, BSD-3-Clause, or Other). See `references/licenses.md`.
- **Mermaid diagrams?** If yes, offer the common types (multi-select) — see `references/mermaid-types.md`
  — and let them pick one or more. If no, use plain prose/tables only.

Do NOT ask about: the overview content, whether to split docs into multiple pages, or the versioning scheme —
decide the first two yourself in step 3; versioning is SemVer unless the repository already documents another
scheme, in which case keep that one and say so.

### 3. Decide structure (no user input)

- **Overview:** write it from the analysis — what the library is, the problem it solves, its package
  layout, install steps, and a minimal quick-start. Match the tone of `references/readme-template.md`.
- **Package table:** one row per packable project — package id, what it does, status. Include it whenever
  there is more than one package; for a single package, fold it into the overview instead.
- **Single vs. multi-page docs:** one docs page (`docs/_index.md`) for a single-package library; for a
  multi-package family, `docs/_index.md` + one page per package (or per major subsystem when a package
  is large enough to warrant it). Docsy builds the sidebar from the page tree — order pages with
  `weight`, don't add a `[[menu.main]]` entry per page.

### 4. Write the README, CHANGELOG.md and CONTRIBUTING.md

**README.** Use `references/readme-template.md` as the skeleton. Fill the overview and usage from step 1/3. Append
the fixed sections from `references/fixed-sections.md` **in this order, each only if its condition holds**:

- **Upgrading** — only if `CHANGELOG.md` has an `### Upgrading from <X>.x to <Y>.0` guide; one link per guide.
- **Changelog** — always.
- **Contributing** — always.
- **Legal** — only if a license exists or was just created (verbatim block, adapted to the chosen license).

Links to `CHANGELOG.md` and `CONTRIBUTING.md` are absolute (`https://github.com/<owner>/<repo>/blob/main/...`):
the README is packed into the package. Contributor material an existing README carries — Testing, Build/test/publish,
Branching and releases, Versioning — moves to `CONTRIBUTING.md`; an "Upgrading to N.0" section moves into the
CHANGELOG entry of that version. Use-case, backlog or milestone tables, if the README tracks work, stay where they are.

**CHANGELOG.md and CONTRIBUTING.md.** Follow `references/repo-files.md`: Keep a Changelog 1.1.0 with the SemVer
statement, `## [Unreleased]` and compare links built from the real tags; CONTRIBUTING with Prerequisites, Build,
Testing, Branching and pull requests, Versioning and Releasing — each describing what the repository actually does.

Add the docs-site and license badges at the top, plus one shields.io NuGet version badge per package
(`references/identity.md`). Installation uses the real `dotnet add package <PackageId>` command for every
package, with the target framework as the runtime requirement.

### 5. Create or verify the license (if requested)

If the user asked for a license and none exists, write it to `LICENSE` using `references/licenses.md`
(fill copyright holder = the author name, year = current year). Then the Legal section becomes applicable.

### 6. Create or verify the Hugo docs site

If `docs/hugo.toml` already exists, update the content pages to match step 3, remove contributor and release
material the site repeats, and add the Changelog / Contributing pages, the `repo-file` shortcode and the two mounts
if they are missing (`references/hugo-setup.md` §If a site already exists). Otherwise create it from scratch — follow
`references/hugo-setup.md` exactly (init site, `docs/package.json` with `@docsy/theme` and `npm install`, `hugo.toml`
with the mounts, archetype, content pages under `content/en/`, the shortcode).

If an existing site uses a theme other than Docsy, say so and ask before switching — the swap moves
content directories and rewrites the config.

### 7. Create the GitHub Actions workflow (always)

Write the Pages workflow: on push to `main` touching `docs/**`, `CHANGELOG.md` or `CONTRIBUTING.md` (and
`workflow_dispatch`), it builds the coverage report when one is published, runs `npm ci` in `docs/`, sets up Hugo
Extended, builds `docs/`, and deploys `docs/public` through the GitHub Pages deployment API. Use the verbatim YAML in
`references/hugo-setup.md` step 7, filling the placeholders.

Name the file for what it does: `build-docs-and-coverage-report.yml` when the solution publishes a
coverage report into the site, `build-docs.yml` when it does not. The file name and the workflow's
`name:` must agree.

**Ensure this file exists even when the docs site already existed** — a repo can have a Hugo site but no
CI. If the file is already present and correct, leave it; if it's missing or stale, create/fix it.

### 8. Report

Build the site once (`npm ci --prefix docs && hugo -s docs`) and confirm zero `ERROR` lines and that the Changelog
and Contributing pages contain the root files' text.

Summarize: files created/changed (including the workflow), which conditional sections were included and
why, what moved out of the README or the site into `CONTRIBUTING.md` / `CHANGELOG.md`, anything CONTRIBUTING
could not describe because the repository lacks it (no `develop` branch or branch policy, no publish workflow —
point at `create-nuget-publish-workflow`), and the command to preview (`npm ci --prefix docs && hugo -s docs server`).
Remind the user to set GitHub Pages to deploy from **GitHub Actions** (Settings → Pages → Source) if this is the
repo's first docs deploy.

## Quick Reference

| Question | Answer |
|---|---|
| Is the repo in scope? | At least one packable project. None → say so and ask. |
| What is asked? | License (only if none exists), mermaid diagrams. Nothing else. |
| What is never asked? | The overview content, the page split, the versioning scheme (SemVer). |
| Where does build/test/branching/release go? | `CONTRIBUTING.md`. The README links it; the site renders it. |
| Where do release notes and upgrade guides go? | `CHANGELOG.md`, `### Upgrading from <X>.x to <Y>.0` in the version's entry. |
| README links to CHANGELOG / CONTRIBUTING? | Absolute GitHub URLs on `main` — the README ships in the package. |
| One page or many? | One per package for a family; one total for a single package. |
| Where do versions live? | The csproj `<Version>`; the README shows them through the NuGet badges and `CHANGELOG.md` lists every release. No version number typed into the README. |
| Who owns identity? | `references/identity.md`, resolved from git — never hardcoded. |

### Conditional README sections

| Section | Included when |
|---|---|
| Upgrading | CHANGELOG.md has an `### Upgrading from <X>.x to <Y>.0` guide |
| Changelog | Always |
| Contributing | Always |
| Legal | A license exists or was just created |

### Reference files

- `references/identity.md` — how author/links/URLs are resolved from git. Use verbatim.
- `references/readme-template.md` — README skeleton and tone.
- `references/fixed-sections.md` — verbatim Upgrading / Changelog / Contributing / Legal blocks.
- `references/repo-files.md` — CHANGELOG.md and CONTRIBUTING.md templates, and what moves into them.
- `references/hugo-setup.md` — Hugo site + Docsy npm package + repo-file shortcode + Pages workflow.
- `references/mermaid-types.md` — common diagram types to offer, with examples.
- `references/licenses.md` — how to fetch/fill license text.

## Common Mistakes

- **Inventing usage examples.** Read the real code first; a wrong example is worse than none.
- **Guessing package ids from folder names.** Read `<PackageId>` from the csproj; the folder and the
  published id often differ, and a wrong `dotnet add package` line is a broken install.
- **Listing non-packable projects as packages.** Test, sample and app projects are not part of the
  package family — apply the packable rule before adding a row or a badge.
- **Keeping build, test, branching or release instructions in the README.** They belong in `CONTRIBUTING.md`; the
  README ends with short Changelog and Contributing sections that link the files.
- **Relative links to CHANGELOG.md / CONTRIBUTING.md in the README.** The README is packed into the NuGet package;
  use the absolute GitHub URL.
- **Copying CHANGELOG or CONTRIBUTING content into the docs site.** Render the files with the `repo-file`
  shortcode; delete the site's Testing / Versioning / release-history / migration pages once their content has a home.
- **Documenting a branching model the repository does not enforce.** Describe what exists; recommend the rest in the
  report.
- **Overwriting an existing README without confirming.** Diff mentally; preserve anything hand-written.
- **Not committing `docs/package-lock.json`** — the workflow's `npm ci` fails without it.
- **Forgetting the `[module]` mounts for `content` and `static`** — declaring any mount replaces Hugo's defaults, so
  the site loses its pages.
- **Leaving `CHANGELOG.md` / `CONTRIBUTING.md` out of the workflow's `paths`** — the site keeps showing the old text.
- **Listing every docs page under `[[menu.main]]`** — Docsy generates the sidebar from the page tree;
  the navbar is for top-level links only. Order pages with `weight`.
- **Hardcoding a different identity.** Author, email, and personal links always come from
  `references/identity.md`.
