# Identity & configurable values

This skill does not hardcode any author identity. Resolve each field below from the project's own
git configuration, asking the user only for what git can't provide.

| Field | How to resolve |
|---|---|
| Author name | `git config user.name`. If unset, ask the user. Also used as the copyright holder. |
| Author email | `git config user.email`. If unset, ask the user. |
| Author site (menu "Author") | Ask the user for a personal/site URL. Optional — omit the "Author" menu item if they don't have one. |
| GitHub owner | Parse from `git remote get-url origin` (the segment before the repo). If no remote, ask the user. |
| GitHub repo URL | `https://github.com/<owner>/<repo>` |
| GitHub Pages base URL | `https://<owner>.github.io/<repo>` |
| Copyright holder | Same as author name. |

## Docs theme submodule

The Hugo site uses **Docsy**, Google's technical-documentation theme, added as a git submodule:

```
https://github.com/google/docsy.git
```

Docsy is the default for this skill — don't substitute another theme unless the user asks. If they do,
adjust the submodule URL, `theme = ` in `hugo.toml`, and the content layout in `references/hugo-setup.md`.

## Helper toolsets (optional, referenced in "Build, test and publish")

These are optional public helper repos linked from the README's "Build, test and publish" section. Keep
them as defaults or drop/replace them per the project:

- Dotnet Tools — `https://github.com/artur-rios/dotnet-tools`
- Python Dotnet Tools — `https://github.com/artur-rios/python-dotnet-tools`

## Badges (top of README)

Docs and license badges are always applicable when those things exist:

```markdown
[![Docs](https://img.shields.io/badge/docs-website-blue)](https://<owner>.github.io/<repo>)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)
```

Add one shields.io NuGet version badge per published package:

```markdown
[![<PkgShortName>](https://img.shields.io/nuget/v/<PackageId>.svg?label=<PkgShortName>)](https://www.nuget.org/packages/<PackageId>)
```

Swap the license badge label/color to match the chosen license (e.g. `License-Apache_2.0-blue`).
