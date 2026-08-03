# Fixed README sections (verbatim, adapt only the bracketed bits)

Append these to the README **in this order**, each only when its condition holds.

## Versioning — include only if the user uses semantic versioning

```markdown
## Versioning

Semantic Versioning (SemVer). Breaking changes bump the major version; new non-breaking behavior bumps
the minor; fixes bump the patch.
```

## Build, test and publish — always include for a NuGet library

Keep the wording verbatim.

```markdown
## Build, test and publish

Use the official [.NET CLI](https://learn.microsoft.com/en-us/dotnet/core/tools/) to build, test and
publish, and Git for source control. Optional helper toolsets:
[Dotnet Tools](https://github.com/artur-rios/dotnet-tools) ·
[Python Dotnet Tools](https://github.com/artur-rios/python-dotnet-tools).
```

## Legal — include only if a license exists or was just created

Adapt the license name, the Wikipedia link, and the badge to the chosen license.

```markdown
## Legal

Licensed under the [MIT License](https://en.wikipedia.org/wiki/MIT_License) — see [LICENSE](./LICENSE).
```

Common variants:
- Apache-2.0 → `[Apache License 2.0](https://en.wikipedia.org/wiki/Apache_License)`
- GPL-3.0 → `[GNU GPL v3](https://en.wikipedia.org/wiki/GNU_General_Public_License)`
- BSD-3-Clause → `[BSD 3-Clause License](https://en.wikipedia.org/wiki/BSD_licenses)`
