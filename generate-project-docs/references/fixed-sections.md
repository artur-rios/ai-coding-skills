# Fixed README sections (verbatim, adapt only the bracketed bits)

Append these to the README **in this order**, each only when its condition holds.

**Links to `CHANGELOG.md`, `CONTRIBUTING.md` and `LICENSE`** depend on the kind (`SKILL.md`, *Library or
application*):

- **Library** — **absolute** GitHub URLs on `main`, `https://github.com/<owner>/<repo>/blob/main/<FILE>`. The README
  is packed into the package and shown on the registry (nuget.org, npm, PyPI, crates.io, pub.dev), where a relative
  link resolves to nothing. The blocks below show this form.
- **Application** — relative links, `./<FILE>`: the README is only read on GitHub and in clones.

The README holds consumer content only. Building from source, testing, branching, versioning and releasing belong in
`CONTRIBUTING.md` (see `references/repo-files.md`); release notes and upgrade guides belong in `CHANGELOG.md`. None of
them is repeated in the README.

## Upgrading — include only if CHANGELOG.md has an upgrade guide

Placed after the usage (library) or deploy (application) sections, before Changelog. One line per `### Upgrading from <X>.x to <Y>.0` subsection in
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

Adapt the block and the badge to the license the repository actually has. Links follow the same rule as the
Changelog and Contributing ones: absolute for a library, relative for an application.

For the **Artur Rios Attribution License** (the default; its `LICENSE` starts with that title):

```markdown
## Legal Details

This project is licensed under the [Artur Rios Attribution License](https://github.com/<owner>/<repo>/blob/main/LICENSE). It is free and open source: you may view, use, fork, modify, and extend it, provided you credit the author, Artur Rios, with a link to [artur-rios.tech](https://artur-rios.tech) or [github.com/artur-rios](https://github.com/artur-rios).
```

For a standard license, name it with its Wikipedia link:

```markdown
## Legal Details

This project is licensed under the [MIT License](https://en.wikipedia.org/wiki/MIT_License). A copy of the license is available at [LICENSE](https://github.com/<owner>/<repo>/blob/main/LICENSE) in the repository.
```

Common variants:
- MIT → `[MIT License](https://en.wikipedia.org/wiki/MIT_License)`
- Apache-2.0 → `[Apache License 2.0](https://en.wikipedia.org/wiki/Apache_License)`
- GPL-3.0 → `[GNU GPL v3](https://en.wikipedia.org/wiki/GNU_General_Public_License)`
- BSD-3-Clause → `[BSD 3-Clause License](https://en.wikipedia.org/wiki/BSD_licenses)`
