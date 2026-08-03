# Creating a LICENSE

Only when the user asked for a license and none exists. Write to `LICENSE` at the repo root.

- Copyright holder: the author name (see `references/identity.md`)
- Year: current year (from the system date)

## Getting the exact text

Use the canonical SPDX text. If you can fetch it, pull from
`https://raw.githubusercontent.com/spdx/license-list-data/main/text/<SPDX-ID>.txt` (e.g. `MIT.txt`,
`Apache-2.0.txt`, `GPL-3.0-only.txt`, `BSD-3-Clause.txt`) and fill placeholders. Otherwise use the
templates below / your own knowledge of the standard text — never paraphrase a license.

## MIT (a common default)

```
MIT License

Copyright (c) <year> <author-name>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Other licenses

- **Apache-2.0** — full standard text; the copyright line goes in the appendix. Add a `NOTICE` file if
  the user wants attribution notices.
- **GPL-3.0** — full standard text; add the standard per-file header notice if the user asks.
- **BSD-3-Clause** — fill `<year>` and `<author-name>` in the copyright line.

After writing the file, the README's **Legal** section becomes applicable — add it (see
`fixed-sections.md`) and set the license badge accordingly (see `identity.md`).
