# Fixed README sections (verbatim, adapt only the bracketed bits)

Append these to the README **in this order**, each only when its condition holds.

The README is packed into the NuGet package and shown on nuget.org, where a relative link resolves to nothing. Links to
`CHANGELOG.md` and `CONTRIBUTING.md` are therefore **absolute** GitHub URLs on `main`:
`https://github.com/<owner>/<repo>/blob/main/<FILE>`.

The README holds consumer content only. Building from source, testing, branching, versioning and releasing belong in
`CONTRIBUTING.md` (see `references/repo-files.md`); release notes and upgrade guides belong in `CHANGELOG.md`. None of
them is repeated in the README.

## Upgrading — include only if CHANGELOG.md has an upgrade guide

Placed after the usage sections, before Changelog. One line per `### Upgrading from <X>.x to <Y>.0` subsection in
`CHANGELOG.md`, newest first. The anchor is GitHub's: lowercase, dots dropped, spaces to hyphens
(`### Upgrading from 1.x to 2.0` → `#upgrading-from-1x-to-20`).

```markdown
## Upgrading

- From <X>.x to <Y>.0: [Upgrading from <X>.x to <Y>.0](https://github.com/<owner>/<repo>/blob/main/CHANGELOG.md#upgrading-from-<x>x-to-<y>0)
```

## Changelog — always include

```markdown
## Changelog

Notable changes in each release are recorded in [CHANGELOG.md](https://github.com/<owner>/<repo>/blob/main/CHANGELOG.md). Releases follow
[Semantic Versioning](https://semver.org/).
```

## Contributing — always include

```markdown
## Contributing

Building from source, running the tests, the branching model and the release process are described in
[CONTRIBUTING.md](https://github.com/<owner>/<repo>/blob/main/CONTRIBUTING.md).
```

## Legal — include only if a license exists or was just created

Adapt the license name, the Wikipedia link, and the badge to the chosen license. The link is absolute, like the
Changelog and Contributing ones: the README is packed into the NuGet package, where a relative link is broken.

```markdown
## Legal Details

This project is licensed under the [MIT License](https://en.wikipedia.org/wiki/MIT_License). A copy of the license is available at [LICENSE](https://github.com/<owner>/<repo>/blob/main/LICENSE) in the repository.
```

Common variants:
- Apache-2.0 → `[Apache License 2.0](https://en.wikipedia.org/wiki/Apache_License)`
- GPL-3.0 → `[GNU GPL v3](https://en.wikipedia.org/wiki/GNU_General_Public_License)`
- BSD-3-Clause → `[BSD 3-Clause License](https://en.wikipedia.org/wiki/BSD_licenses)`
