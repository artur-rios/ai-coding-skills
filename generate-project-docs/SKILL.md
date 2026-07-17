---
name: generate-project-docs
description: Use when the user wants to generate structured project documentation — a README (overview, usage, and the Versioning / Build-test-publish / Legal sections) plus a Hugo docs site using the re-terminal theme fork. Triggers on "generate docs", "create documentation", "make a readme and docs site", "document this project".
---

# Generate Project Docs

## Overview

Generates two deliverables for the current project:

1. A **README.md** — overview, usage examples, and the fixed **Versioning**, **Build, test and
   publish**, and **Legal** sections (each conditional, see below).
2. A **Hugo docs site** under `docs/` using the `re-terminal` theme fork as a submodule,
   plus a **GitHub Actions workflow** (`.github/workflows/build-docs-and-coverage-report.yml`) that
   builds the site and deploys it to GitHub Pages.

Author identity (name, email, site, copyright holder) is resolved from the project's git configuration
at runtime — nothing is hardcoded. See `references/identity.md` for exactly how each value is obtained;
only the repo name and project-specific content change per project.

**Core principle:** ask only what can't be inferred; infer everything else from the project itself.

## Workflow

Create a todo per step.

### 1. Analyze the project (no user input)

Gather these facts before asking anything:

| Fact | How to detect |
|---|---|
| Repo name | `git remote get-url origin` → last path segment without `.git`. Used in Pages URL and GitHub links. |
| Is it .NET? | Any `*.csproj` / `*.sln` / `*.fsproj` present. |
| Existing LICENSE? | `LICENSE` / `LICENSE.md` / `LICENSE.txt` at root. |
| Existing README? | `README.md` at root (you will replace or extend it — confirm before overwriting substantial content). |
| Existing Hugo docs? | `docs/hugo.toml` (or `config.toml`) present. |
| Package / module layout | Scan `src/`, project files, `package.json`, etc. to write an accurate overview. |
| Public API / usage | Read the main entry points to write real usage examples — never invent an API. |

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

- **Overview:** write it from the analysis — what the project is, the problem it solves, its module/package
  layout, install steps, and a minimal quick-start. Match the tone of `references/readme-template.md`.
- **Single vs. multi-page docs:** one content page (`_index.md`) if the project is a single small unit;
  split into `_index.md` + one page per major component/package/subsystem if there are several distinct
  areas (e.g. one page per major subsystem). Add a matching menu
  entry in `hugo.toml` for each page.

### 4. Write the README

Use `references/readme-template.md` as the skeleton. Fill the overview and usage from step 1/3. Append the
fixed sections **in this order, each only if its condition holds**:

- **Versioning** — only if semantic versioning (verbatim block in `references/fixed-sections.md`).
- **Build, test and publish** — only if it's a .NET project (verbatim block in `references/fixed-sections.md`).
- **Legal** — only if a license exists or was just created (verbatim block, adapted to the chosen license).

Add the docs-site and license badges at the top, plus any per-package/version badges that apply.

### 5. Create or verify the license (if requested)

If the user asked for a license and none exists, write it to `LICENSE` using `references/licenses.md`
(fill copyright holder = the author name, year = current year). Then the Legal section becomes applicable.

### 6. Create or verify the Hugo docs site

If `docs/hugo.toml` already exists, only update content/menu to match step 3. Otherwise create it from
scratch — follow `references/hugo-setup.md` exactly (init site, add the theme fork as a submodule, write
`hugo.toml`, archetype, and content pages).

### 7. Create the GitHub Actions workflow (always)

Write `.github/workflows/build-docs-and-coverage-report.yml` — the same workflow this skill's source
project uses: on push to `main` touching `docs/**` (and `workflow_dispatch`), it checks out with
`submodules: recursive`, sets up Hugo Extended, builds `docs/`, and deploys `docs/public` to the
`gh-pages` branch. Use the verbatim YAML in `references/hugo-setup.md` step 6, filling `<owner>`/`<repo>`.

**Ensure this file exists even when the docs site already existed** — a repo can have a Hugo site but no
CI. If the file is already present and correct, leave it; if it's missing or stale, create/fix it. Drop
`& Coverage Report` from the workflow name for non-.NET projects.

### 8. Report

Summarize: files created/changed (including the workflow), which conditional sections were included and
why, and the two commands to preview (`hugo -s docs server`) and to finish wiring the submodule
(`git submodule update --init`). Remind the user to enable GitHub Pages (Settings → Pages → deploy from
the `gh-pages` branch) if this is the repo's first docs deploy.

## Reference files

- `references/identity.md` — hardcoded author/links/URLs. Use verbatim.
- `references/readme-template.md` — README skeleton and tone.
- `references/fixed-sections.md` — verbatim Versioning / Build-test-publish / Legal blocks.
- `references/hugo-setup.md` — Hugo site + theme submodule + Pages workflow.
- `references/mermaid-types.md` — common diagram types to offer, with examples.
- `references/licenses.md` — how to fetch/fill license text.

## Common mistakes

- **Inventing usage examples.** Read the real code first; a wrong example is worse than none.
- **Including Build/test/publish for a non-.NET project.** It's .NET-specific — omit it otherwise.
- **Including Versioning when the user isn't using SemVer.** Skip it entirely; don't water it down.
- **Overwriting an existing README without confirming.** Diff mentally; preserve anything hand-written.
- **Forgetting `submodules: recursive` in the Pages workflow** — the theme won't be there on CI and the
  build fails.
- **Hardcoding a different identity.** Author, email, and personal links always come from
  `references/identity.md`.
