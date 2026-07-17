# generate-project-docs

Generates structured project documentation for the current project: a **README**
plus a **Hugo docs site** wired to GitHub Pages via CI.

## What it does

It produces two deliverables:

1. A **`README.md`** — an overview and usage examples written from the project
   itself, followed by fixed **Versioning**, **Build, test and publish**, and
   **Legal** sections (each included only when its condition holds).
2. A **Hugo docs site** under `docs/` using the `re-terminal` theme fork as a git
   submodule, plus `.github/workflows/build-docs-and-coverage-report.yml`, which
   builds the site and deploys it to GitHub Pages.

Author identity (name, email, site, copyright holder) is resolved from the
project's git configuration at runtime — nothing is hardcoded.

**Core principle:** ask only what can't be inferred; infer everything else from
the project itself.

## When to use it

Ask for it with phrases like "generate docs", "create documentation", "make a
readme and docs site", or "document this project".

## How it works

1. **Analyze the project** (no input): repo name from the git remote, whether it's
   .NET, existing LICENSE / README / Hugo site, package layout, and the real
   public API for accurate usage examples.
2. **Ask only the open questions** (batched): SemVer? License (only if none
   exists)? Mermaid diagrams?
3. **Decide structure**: write the overview from the analysis and choose single-
   vs. multi-page docs.
4. **Write the README** from the template, appending the conditional fixed
   sections in order.
5. **Create the license** if requested and none exists.
6. **Create or update the Hugo site** (theme submodule, `hugo.toml`, content).
7. **Create the Pages workflow** (always — even when the site already existed).
8. **Report** what changed, which sections were included and why, and the preview
   / submodule commands.

## Conditional sections

| Section | Included when |
|---|---|
| **Versioning** | The project uses semantic versioning. |
| **Build, test and publish** | The project is .NET. |
| **Legal** | A license exists or was just created. |

## Files in this skill

| Path | Purpose |
|---|---|
| `SKILL.md` | The skill instructions. |
| `references/identity.md` | How author / owner / URL fields are resolved from git. |
| `references/readme-template.md` | README skeleton and tone. |
| `references/fixed-sections.md` | Verbatim Versioning / Build-test-publish / Legal blocks. |
| `references/hugo-setup.md` | Hugo site + theme submodule + Pages workflow. |
| `references/mermaid-types.md` | Common diagram types to offer, with examples. |
| `references/licenses.md` | How to fetch and fill license text. |

## Common mistakes it avoids

- Inventing usage examples — it reads the real code first.
- Including .NET-only or SemVer-only sections where they don't apply.
- Overwriting a hand-written README without confirming.
- Forgetting `submodules: recursive` in the Pages workflow (the theme would be
  missing on CI and the build would fail).
