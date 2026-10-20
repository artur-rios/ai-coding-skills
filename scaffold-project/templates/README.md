<!--
GUIDANCE — delete this comment block, and every "VARIANT" block that does not
apply, in the generated file.

The README is for the people who USE the project — callers, operators, package
consumers. Build, test, branching and release instructions are contributor
material and go in CONTRIBUTING.md; the README only links it.

Substitutions:
  {{Project}}        the project name as the stack writes it (with its prefix, for .NET)
  {{Description}}    the one-sentence description from the interview
  {{Requirements}}   from the stack reference's README fill-ins, as a bullet list
                     (e.g. "- .NET 10 or later", "- Python 3.13 or later")
  {{Usage}}          from the stack reference's README fill-ins: how to install the
                     package (library) or how to run the app (application) — the
                     shortest command that works, nothing contributor-facing
  {{License}}        the license's full name, e.g. "MIT License", "GNU Affero General
                     Public License v3.0", or the Custom Commercial license's title
  {{LinkBase}}       "." — or, for a library whose README is packed into its package
                     (NuGet, npm, PyPI, crates.io), the absolute
                     https://github.com/{{owner}}/{{repo}}/blob/main, because the
                     registry renders the README where relative links break
-->
# {{Project}}

{{Description}}

## Requirements

{{Requirements}}

## Usage

{{Usage}}

## Changelog

Notable changes in each release are recorded in [CHANGELOG.md]({{LinkBase}}/CHANGELOG.md). Releases follow
[Semantic Versioning](https://semver.org/).

## Contributing

Building from source, running the tests, the branching model and the release process are described in
[CONTRIBUTING.md]({{LinkBase}}/CONTRIBUTING.md).

<!-- VARIANT: ARTUR RIOS ATTRIBUTION LICENSE (the default) -->
## Legal Details

This project is licensed under the [Artur Rios Attribution License]({{LinkBase}}/LICENSE). It is free and open source: you may view, use, fork, modify, and extend it, provided you credit the author, Artur Rios, with a link to [artur-rios.tech](https://artur-rios.tech) or [github.com/artur-rios](https://github.com/artur-rios).
<!-- END VARIANT -->

<!-- VARIANT: ANY OTHER LICENSE -->
## Legal Details

This project is licensed under the {{License}}. A copy of the license is available at [LICENSE]({{LinkBase}}/LICENSE) in
the repository.
<!-- END VARIANT -->
