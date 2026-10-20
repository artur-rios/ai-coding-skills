# Identity & configurable values

This skill does not hardcode any author identity. Resolve each field below from the project's own
git configuration, asking the user only for what git can't provide.

| Field | How to resolve |
|---|---|
| Author name | The project's own authors when it declares them — `<Authors>` in the csproj, `author` in `package.json`, `authors` in `pyproject.toml` / `Cargo.toml` — else `git config user.name`. If neither, ask the user. |
| Author email | `git config user.email`. If unset, ask the user. |
| Author site (menu "Author") | Ask the user for a personal/site URL. Optional — omit the "Author" menu item if they don't have one. |
| GitHub owner | Parse from `git remote get-url origin` (the segment before the repo). If no remote, ask the user. |
| GitHub repo URL | `https://github.com/<owner>/<repo>` |
| GitHub Pages base URL | `https://<owner>.github.io/<repo>` |
| Copyright holder | The holder named in an existing `LICENSE` (its copyright line); otherwise the author name. |

## Docs theme package

The Hugo site uses **Docsy**, Google's technical-documentation theme, installed from npm as `@docsy/theme`
(declared in `docs/package.json`, loaded with `theme = '@docsy/theme'` and `themesDir = 'node_modules'`).

Docsy is the default for this skill — don't substitute another theme unless the user asks. If they do,
adjust `docs/package.json`, `theme = ` in `hugo.toml`, and the content layout in `references/hugo-setup.md`.

## Helper toolsets (optional, .NET only, referenced in CONTRIBUTING.md)

These are optional public helper repos linked from the Prerequisites section of a **.NET** project's
`CONTRIBUTING.md` (`references/repo-files.md`). Keep them as defaults or drop/replace them per the project; other
stacks don't list them:

- Dotnet Tools — `https://github.com/artur-rios/dotnet-tools`
- Python Dotnet Tools — `https://github.com/artur-rios/python-dotnet-tools`

## Badges (top of README)

Docs and license badges are always applicable when those things exist:

```markdown
[![Docs](https://img.shields.io/badge/docs-website-blue)](https://<owner>.github.io/<repo>)
[![License: Attribution](https://img.shields.io/badge/License-Attribution-blue.svg)](https://github.com/<owner>/<repo>/blob/main/LICENSE)
```

The license badge links like the README's other links to root files: absolute for a library (shown above), `./LICENSE`
for an application.

For a library, add one registry version badge per published package — the badge and its link for each stack are
in `references/stacks.md` (*Package id, install command, badge and requirement*), e.g. for NuGet:

```markdown
[![<PkgShortName>](https://img.shields.io/nuget/v/<PackageId>.svg?label=<PkgShortName>)](https://www.nuget.org/packages/<PackageId>)
```

An application gets no version badge.

The badge above is for the Artur Rios Attribution License (the default). Swap the license badge label/color to
match any other license (e.g. `License: MIT` with `License-MIT-green`, `License-Apache_2.0-blue`).
