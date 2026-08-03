# README skeleton & tone

Model the README on a well-structured NuGet library repo: a strong one-paragraph overview, a package
table, install steps, a minimal quick-start with real C#, a short docs index, then the fixed sections.

Keep prose tight and concrete. Prefer tables for package/status lists. Use fenced ```mermaid blocks only
for the diagram types the user picked.

## Skeleton

```markdown
# <Project Title>

<badges — see references/identity.md>

**`<PrimaryPackageId>`** — <one-paragraph overview: what the library is, the core problem it solves, the
shape of its public surface. Written from real analysis of the code, not guessed.>

- 📚 **Full documentation:** <https://<owner>.github.io/<repo>>
- <optional extra quick links to key docs pages>

## <Package family>   ← only if the solution ships multiple packages

<optional mermaid diagram if picked>

| Package | What it does | Status |
|---|---|---|
| [`<PackageId>`](https://www.nuget.org/packages/<PackageId>) | ... | ✅ |

## Installation

```bash
dotnet add package <PackageId>
```

<one line per additional package, then the target-framework requirement, e.g. "Requires .NET 8.0 or later.">

## <Quick start>

<numbered, real, minimal end-to-end example pulled from the actual API>

## Documentation

| Page | What's there |
|---|---|
| [<Page>](https://<owner>.github.io/<repo>/<slug>/) | ... |

<-- fixed sections appended here, each conditional: Versioning, Build test and publish, Legal -->
```

## Overview-writing checklist

- Name the library and its primary package id in the first sentence.
- State the problem it solves and the one idea that makes it distinctive.
- If the solution ships multiple packages, give the table + (optional) dependency diagram.
- Show `dotnet add package` + a minimal, runnable quick-start from the real API.
- Link to the docs site and its key pages.
