# README skeleton & tone

Model the README on a well-structured library repo: a strong one-paragraph overview, a package/module
table, install steps, a minimal quick-start with real code, a short docs index, then the fixed sections.

Keep prose tight and concrete. Prefer tables for package/status lists. Use fenced ```mermaid blocks only
for the diagram types the user picked.

## Skeleton

```markdown
# <Project Title>

<badges — see references/identity.md>

**`<PrimaryId>`** — <one-paragraph overview: what it is, the core problem it solves, the shape of its
public surface. Written from real analysis of the code, not guessed.>

- 📚 **Full documentation:** <https://<owner>.github.io/<repo>>
- <optional extra quick links to key docs pages>

## <Package family / Modules>   ← only if the project has multiple packages/modules

<optional mermaid diagram if picked>

| <Package/Module> | <What it does> | Status |
|---|---|---|
| ... | ... | ✅ |

## Installation

<real install commands for this ecosystem: dotnet add package… / npm install… / etc.>
<runtime/version requirement line>

## <Quick start>

<numbered, real, minimal end-to-end example pulled from the actual API>

## Documentation

| Page | What's there |
|---|---|
| [<Page>](https://<owner>.github.io/<repo>/<slug>/) | ... |

<-- fixed sections appended here, each conditional: Versioning, Build test and publish, Legal -->
```

## Overview-writing checklist

- Name the project and its ecosystem in the first sentence.
- State the problem it solves and the one idea that makes it distinctive.
- If it has multiple packages/modules, give the table + (optional) dependency diagram.
- Show install + a minimal, runnable quick-start from the real API.
- Link to the docs site and its key pages.
