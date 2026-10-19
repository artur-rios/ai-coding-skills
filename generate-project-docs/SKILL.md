---
name: generate-project-docs
description: Use when the user wants documentation generated for an existing project in any stack — a library published as packages (NuGet, npm, PyPI, crates.io, Maven Central, pub.dev, Go modules) or an application (a web API, a web front end, a CLI, a worker, a mobile app). Covers a README, a CHANGELOG.md and a CONTRIBUTING.md, and a Hugo docs site on the Docsy theme deployed to GitHub Pages by CI. Triggers on "generate docs", "create documentation", "document this project", "make a readme and docs site", "set up a Hugo / Docsy docs site", "add a docs site on GitHub Pages". Not for writing requirements documents from notes — that is generate-specs-from-brainstorm.
---

# Generate Project Docs

## Overview

Generates three deliverables for the current project, whatever its stack:

1. A **README.md** for the project's users — what it is, and then either how to install and use it (a
   **library**: package table, registry badges, install commands, a quick start from the real API) or how to
   configure, run and deploy it (an **application**). It ends with the fixed **Upgrading**, **Changelog**,
   **Contributing** and **Legal** sections (the first and last are conditional).
2. A **CHANGELOG.md** (Keep a Changelog 1.1.0, Semantic Versioning, `## [Unreleased]`, compare links, upgrade guides)
   and a **CONTRIBUTING.md** (prerequisites, build, tests, branching, commits, versioning, releasing) — the homes of
   everything the README does not carry.
3. A **Hugo docs site** under `docs/` on the **Docsy** theme (the `@docsy/theme` npm package), with Changelog and
   Contributing pages that render the two root files, plus a **GitHub Actions workflow** that builds the site —
   with a test coverage report when one is published — and deploys it to GitHub Pages.

Author identity (name, email, site, copyright holder) is resolved from the project's git configuration at runtime —
nothing is hardcoded (`references/identity.md`). The stack-specific facts — how to tell a package from an
application, install commands, badges, build / test / coverage commands, CI setup — are in `references/stacks.md`.

**Core principle:** ask only what can't be inferred; infer everything else from the project itself. And write
each thing once: the README for users, `CONTRIBUTING.md` for contributors, `CHANGELOG.md` for release history —
the docs site renders the latter two rather than repeating them.

## When to Use

**Precondition: an existing project with code to document.** An empty or greenfield directory wants
**scaffold-project** first; this skill documents what is there.

- "Generate docs / documentation", "document this project", "write a README and a docs site", "set up a
  Hugo / Docsy site on GitHub Pages" — for a project in any stack.
- A project whose README, CHANGELOG or CONTRIBUTING is missing, or whose docs site repeats them.

Skip / adapt if:
- The user wants requirements and design documents from notes — **generate-specs-from-brainstorm**.
- The user wants the NuGet publish workflow, not docs — **create-nuget-publish-workflow** (this skill only
  writes documentation, and points at it in the report when a .NET library has no publish workflow).
- The project is a .NET web API scaffolded by **scaffold-project**'s layered path — it already has a Docsy site with
  its own pages. Treat it as an existing site (step 6), not a fresh one.

## Library or application

The kind decides the README and the site's pages. Step 1 decides it from `references/stacks.md`
(*Package or application*): a repository that publishes **at least one package** is a library; one that publishes
none is an application. Ask only when the signals disagree.

| | Library | Application |
|---|---|---|
| README body | overview, package table (more than one package), installation, quick start, docs index | overview, docs index, configure, run, deploy (and the API, for a service) |
| README links to CHANGELOG / CONTRIBUTING / LICENSE | **absolute** GitHub URLs — the README is packed into the package and shown on the registry, where a relative link is broken | relative (`./CHANGELOG.md`) |
| Site pages | a single package: one page (overview, install, usage); a family: an index plus one page per package (or major subsystem); architecture when there is one to show | overview, getting started, configuration, architecture, API reference (a service), operations / deployment |
| Versions shown | registry badges — never a version typed into the README | none in the README; `CHANGELOG.md` holds the releases |

A repository with both (a library plus a demo app) is a library; the app is a sample and gets at most a page.

## Red Flags — STOP and Re-read the Procedure

- "I'll write a plausible usage example and refine it later" → NO. Read the real API.
  A wrong example is worse than none — it is the first thing a reader copies.
- "The folder is `src/Acme.Http`, so the package is `Acme.Http`" → NO. Read the id from the manifest
  (`<PackageId>`, `name`, `[project] name`, `[package] name`). A wrong install line is a broken install.
- "It has a `package.json` / `pyproject.toml`, so it is a package" → NO. Apply the rule in
  `references/stacks.md`; a private or unpublished project is an application, and when it is unclear, ask.
- "I'll list the environment variables it probably needs" → NO. Read them from the config files and the code that
  reads them. A documented variable the app ignores, or a missing required one, costs a deployment.
- "There's a README already, I'll rewrite it properly" → NO. Diff it mentally and preserve what was hand-written;
  confirm before replacing substance.
- "The Hugo site exists, so CI must exist too" → Check. A repo can have a site and no workflow, and the workflow step
  runs either way.
- "Build and test instructions in the README are helpful" → NO. They are contributor material and go in
  `CONTRIBUTING.md`; the README links to it.
- "The docs site should have its own Testing / Versioning / Release notes page" → NO. The Changelog and Contributing
  pages render the root files; a copy drifts.
- "`./CHANGELOG.md` is fine in a library's README" → NO. The README ships inside the package, where a relative link
  resolves to nothing. Use the absolute GitHub URL on `main`.
- "The coverage command is standard, I don't need to check the tool is there" → Check. A coverage step that needs
  `pytest-cov` or `cargo-llvm-cov` the project doesn't use fails the first docs deploy.

| Rationalization | Reality |
|---|---|
| "The user will notice if an example is wrong" | They will notice it failed, after pasting it. Read the entry points and write something that runs. |
| "The repo has no versioning statement, so I'll ask which scheme" | SemVer is the policy for every project here. State it in CHANGELOG.md and CONTRIBUTING.md; only a scheme the repository already documents overrides it. |
| "`package-lock.json` is noise, I'll leave it out" | CI installs with `npm ci`, which fails without it — every time, only in CI. |
| "The release history is in the tags, a CHANGELOG is redundant" | Tags say *when*, not *what changed for me*. The CHANGELOG is the user's upgrade decision. |
| "One page per package is over-engineering for a small library" | Then it is a single-package library and one page is right. Let the package count decide, not the mood. |
| "An application doesn't need a CHANGELOG" | Operators upgrade applications too, and need to know what changed in configuration and behaviour. |

## Procedure

Create a todo per step.

### 1. Analyze the project (no user input)

Gather these facts before asking anything:

| Fact | How to detect |
|---|---|
| Repo name and owner | `git remote get-url origin` → owner and last path segment without `.git`. Used in the Pages URL and GitHub links. If there is no remote, ask for the intended `owner/repo`. |
| Components and their stacks | The manifests (`references/stacks.md`, *Identify the stack*), from the repository root. |
| Kind | Package or application per component (`references/stacks.md`); library if any package. |
| Package ids (library) | From each package's manifest. Used for badges and install commands. |
| Requirement | The runtime / toolchain version each component declares. |
| Application facts (application) | Configuration, run command and port, containers, migrations, API surface (`references/stacks.md`, *Application facts to read*). |
| Tests and coverage | Where the tests are, how they run, whether a coverage tool is already configured or a report already published. |
| Existing LICENSE? | `LICENSE` / `LICENSE.md` / `LICENSE.txt` at root. |
| Existing README? | `README.md` at root (you will replace or extend it — confirm before overwriting substantial content). |
| Existing CHANGELOG / CONTRIBUTING? | `CHANGELOG.md` / `CONTRIBUTING.md` at root. Extend them; never replace. |
| Released versions | `git tag --list`, and the version in each manifest — the CHANGELOG entries and compare links are built from them. |
| Branching and CI as they are | `git branch -r` (is there a `develop`?), `.github/workflows/` (`branch-policy.yml`, test jobs and their filters, publish workflows). CONTRIBUTING describes what exists. |
| Existing Hugo docs? | `docs/hugo.toml` (or `config.toml`) present, and its theme. |
| Public API / usage (library) | Read the main entry points of each package to write real usage examples — never invent an API. |

### 2. Ask the user (batch into one question round)

Ask ONLY these, and only when the analysis leaves them open:

- **Kind** — only when `references/stacks.md` can't decide whether a component is published.
- **License** — only if no LICENSE was found: "Add a license?" If yes, "Which one?" (offer the Artur Rios
  Attribution License as the default, then MIT, Apache-2.0, GPL-3.0, BSD-3-Clause, or Other). See
  `references/licenses.md`.
- **Coverage report** — only when the project has tests and no report is published yet: "Publish a test coverage
  report on the docs site?" (default yes when the stack's coverage tool is already configured). A project with no
  tests gets no report and no question — say in the report that one can be added once tests exist.
- **Author site** — only when creating a new site and `references/identity.md` can't find one: "A personal site URL
  for the docs site's Author link? (blank for none)".
- **Mermaid diagrams?** If yes, offer the common types (multi-select) — see `references/mermaid-types.md` — and let
  them pick one or more. If no, use plain prose and tables only.

Do NOT ask about: the overview content, whether to split docs into multiple pages, or the versioning scheme —
decide the first two yourself in step 3; versioning is SemVer unless the repository already documents another
scheme, in which case keep that one and say so.

### 3. Decide structure (no user input)

- **Overview:** write it from the analysis — what the project is, the problem it solves, and its shape. Match the
  tone of `references/readme-template.md`.
- **Library:** a package table whenever there is more than one package (one row per package: id, what it does,
  status); a single package folds into the overview. A package with no public API yet gets no quick start — the
  README says the API is documented as it lands, and the report says why the section is missing. One docs page for a single package; `docs/_index.md` + one page
  per package (or per major subsystem when a package is large enough) for a family.
- **Application:** the page set in `references/hugo-setup.md` §Application pages — getting started, configuration,
  architecture, the API reference for a service, operations. A page only when the analysis has something true to put
  on it; a project with no containers gets no Deployment-with-Docker section.
- **Several components:** a page (or section) per component, each documented by its own kind.
- Docsy builds the sidebar from the page tree — order pages with `weight`, don't add a `[[menu.main]]` entry per page.

### 4. Write the README, CHANGELOG.md and CONTRIBUTING.md

**README.** Use the library or application skeleton in `references/readme-template.md`. Fill it from step 1/3.
Append the fixed sections from `references/fixed-sections.md` **in this order, each only if its condition holds**:

- **Upgrading** — only if `CHANGELOG.md` has an `### Upgrading from <X>.x to <Y>.0` guide; one link per guide.
- **Changelog** — always.
- **Contributing** — always.
- **Legal** — only if a license exists or was just created.

Links to `CHANGELOG.md`, `CONTRIBUTING.md` and `LICENSE` are absolute for a library and relative for an
application (*Library or application* above). Contributor material an existing README carries — Testing,
Build/test/publish, Branching and releases, Versioning — moves to `CONTRIBUTING.md`; an "Upgrading to N.0" section
moves into the CHANGELOG entry of that version. Use-case, backlog or milestone tables, if the README tracks work,
stay where they are.

Add the docs-site and license badges at the top, plus — for a library — one registry version badge per published
package (`references/identity.md`, `references/stacks.md`). Installation uses the stack's real install command for
every package, with the requirement line.

**CHANGELOG.md and CONTRIBUTING.md.** Follow `references/repo-files.md`: Keep a Changelog 1.1.0 with the SemVer
statement, `## [Unreleased]` and compare links built from the real tags; CONTRIBUTING with Prerequisites, Build,
Testing, Branching and pull requests, Versioning and Releasing — each describing what the repository actually does,
with the commands from `references/stacks.md` checked against the repository.

### 5. Create or verify the license (if requested)

If the user asked for a license and none exists, write it to `LICENSE` using `references/licenses.md`
(fill copyright holder = the author name, year = current year; the Artur Rios Attribution License fills only the
year). Then the Legal section becomes applicable.

### 6. Create or verify the Hugo docs site

If `docs/hugo.toml` already exists, update the content pages to match step 3, remove contributor and release
material the site repeats, and add the Changelog / Contributing pages, the `repo-file` shortcode and the two mounts
if they are missing (`references/hugo-setup.md` §If a site already exists). Otherwise create it from scratch — follow
`references/hugo-setup.md` exactly (init site, `docs/package.json` with `@docsy/theme` and `npm install`, `hugo.toml`
with the mounts, archetype, content pages under `content/en/`, the shortcode).

If `docs/` already holds something that is not a Hugo site (plain Markdown notes, a `docs/requirements/` set from
generate-specs-from-brainstorm), keep it: say so, and put the site's sources where they don't collide — move the
existing files under the site's content only if the user agrees.

If an existing site uses a theme other than Docsy, say so and ask before switching — the swap moves
content directories and rewrites the config.

### 7. Create the GitHub Actions workflow (always)

Write the Pages workflow from `references/hugo-setup.md` step 7: on push to `main` touching `docs/**`,
`CHANGELOG.md` or `CONTRIBUTING.md` (and `workflow_dispatch`), it builds the coverage report when one is published
(the stack's setup and coverage steps from `references/stacks.md`), runs `npm ci` in `docs/`, sets up Hugo Extended,
builds `docs/`, and deploys `docs/public` through the GitHub Pages deployment API.

Name the file for what it does: `build-docs-and-coverage-report.yml` when the site publishes a coverage report,
`build-docs.yml` when it does not. The file name and the workflow's `name:` must agree.

**Ensure this file exists even when the docs site already existed** — a repo can have a Hugo site but no
CI. If the file is already present and correct, leave it; if it's missing or stale, create/fix it.

### 8. Verify and report

Build the site once (`npm ci --prefix docs && hugo -s docs`) and confirm zero `ERROR` lines and that the Changelog
and Contributing pages contain the root files' text. When a coverage report is published, run the coverage
command locally once and confirm `docs/coverage-report/index.html` exists — then delete the generated report, which
is git-ignored.

Summarize: the kind and stacks detected, files created/changed (including the workflow), which conditional sections
were included and why, what moved out of the README or the site into `CONTRIBUTING.md` / `CHANGELOG.md`, anything
CONTRIBUTING could not describe because the repository lacks it (no `develop` branch or branch policy, no publish
workflow — for a .NET library point at `create-nuget-publish-workflow`), packages documented as unpublished, and the
command to preview (`npm ci --prefix docs && hugo -s docs server`). Remind the user to set GitHub Pages to deploy from
**GitHub Actions** (Settings → Pages → Source) if this is the repo's first docs deploy.

## Quick Reference

| Question | Answer |
|---|---|
| Library or application? | Library if the repository publishes at least one package (`references/stacks.md`); ask only when unclear. |
| What is asked? | Kind (only when unclear), license (only if none exists), coverage report (only when there are tests and no report), author site (new site only, when unknown), mermaid diagrams. Nothing else. |
| What is never asked? | The overview content, the page split, the versioning scheme (SemVer). |
| Where does build/test/branching/release go? | `CONTRIBUTING.md`. The README links it; the site renders it. |
| Where do release notes and upgrade guides go? | `CHANGELOG.md`, `### Upgrading from <X>.x to <Y>.0` in the version's entry. |
| README links to CHANGELOG / CONTRIBUTING? | Library: absolute GitHub URLs on `main` (the README ships in the package). Application: relative. |
| One page or many? | Library: one per package for a family, one total for a single package. Application: one per topic that has content. |
| Where do versions live? | The manifest. A library's README shows them through registry badges; `CHANGELOG.md` lists every release. No version number typed into the README. |
| Which commands? | `references/stacks.md`, checked against the repository. |
| Who owns identity? | `references/identity.md`, resolved from git — never hardcoded. |

### Conditional README sections

| Section | Included when |
|---|---|
| Upgrading | CHANGELOG.md has an `### Upgrading from <X>.x to <Y>.0` guide |
| Changelog | Always |
| Contributing | Always |
| Legal | A license exists or was just created |

### Reference files

- `references/stacks.md` — stack detection, package-or-application rule, install / badge / build / test / coverage
  commands, CI setup steps, application facts to read.
- `references/identity.md` — how author/links/URLs are resolved from git. Use verbatim.
- `references/readme-template.md` — library and application README skeletons and tone.
- `references/fixed-sections.md` — verbatim Upgrading / Changelog / Contributing / Legal blocks.
- `references/repo-files.md` — CHANGELOG.md and CONTRIBUTING.md templates, and what moves into them.
- `references/hugo-setup.md` — Hugo site + Docsy npm package + repo-file shortcode + page sets + Pages workflow.
- `references/mermaid-types.md` — common diagram types to offer, with examples.
- `references/licenses.md` — how to fetch/fill license text.

## Common Mistakes

- **Inventing usage examples, environment variables or endpoints.** Read the real code and config first; a wrong
  example is worse than none.
- **Guessing package ids from folder names.** Read the id from the manifest.
- **Calling an unpublished project a package.** Apply the rule in `references/stacks.md` — and ask when unclear —
  before adding an install line or a badge.
- **Keeping build, test, branching or release instructions in the README.** They belong in `CONTRIBUTING.md`; the
  README ends with short Changelog and Contributing sections that link the files.
- **Relative links in a library's README.** The README is packed into the package; use the absolute GitHub URL.
- **Copying CHANGELOG or CONTRIBUTING content into the docs site.** Render the files with the `repo-file`
  shortcode; delete the site's Testing / Versioning / release-history / migration pages once their content has a home.
- **Documenting a branching model the repository does not enforce.** Describe what exists; recommend the rest in the
  report.
- **Overwriting an existing README without confirming.** Diff mentally; preserve anything hand-written.
- **Not committing `docs/package-lock.json`** — the workflow's `npm ci` fails without it.
- **Forgetting the `[module]` mounts for `content` and `static`** — declaring any mount replaces Hugo's defaults, so
  the site loses its pages.
- **Leaving `CHANGELOG.md` / `CONTRIBUTING.md` out of the workflow's `paths`** — the site keeps showing the old text.
- **A coverage step for a tool the project doesn't have.** Add the tool as a dev dependency, or leave the report out.
- **Listing every docs page under `[[menu.main]]`** — Docsy generates the sidebar from the page tree;
  the navbar is for top-level links only. Order pages with `weight`.
- **Hardcoding a different identity.** Author, email, and personal links always come from
  `references/identity.md`.
