# Hugo docs site setup

Creates a Hugo site under `docs/` using the re-terminal theme fork (see `references/identity.md`) as a
git submodule, deployed to GitHub Pages via a workflow.

## If a site already exists

If `docs/hugo.toml` (or `docs/config.toml`) exists, do NOT re-init. Only:
- Update `[menu]` entries and content pages to match the chosen single/multi-page structure.
- Leave the theme submodule alone unless broken.
- Still ensure the GitHub Actions workflow exists (step 6) — a site can exist without CI. Create it if
  missing; leave it if already present and correct.

## Creating from scratch

Run from the repo root. The theme requires **Hugo Extended ≥ v0.128.0**.

### 1. Init the site

```bash
hugo new site docs --format toml
```

### 2. Add the theme fork as a submodule

```bash
git submodule add https://github.com/artur-rios/hugo-theme-re-terminal.git docs/themes/hugo-theme-re-terminal
git submodule update --init --recursive
```

This writes/updates `.gitmodules` at the repo root:

```
[submodule "docs/themes/hugo-theme-re-terminal"]
	path = docs/themes/hugo-theme-re-terminal
	url = https://github.com/artur-rios/hugo-theme-re-terminal.git
```

### 3. Write `docs/hugo.toml`

Fill `<owner>`, `<repo>`, `<Project Title>`, and one `[[menu.main]]` per content page. Keep the Author
and GitHub menu items. The `[module]` mount block and the Test Coverage menu item apply only when the
solution publishes a coverage report into `docs/coverage-report` — omit both otherwise.

```toml
baseURL = 'https://<owner>.github.io/<repo>'
locale = 'en-us'
title = '<Project Title>'
theme = 'hugo-theme-re-terminal'

# Only if the solution publishes a coverage report — mounts it as static files. Omit otherwise.
[module]
[[module.mounts]]
source = 'coverage-report'
target = 'static/coverage-report'

[params]
author_email = '<author-email>'
name = '<author-name>'

[params.logo]
logoText = '<Project Title>'

[menu]
# one block per docs content page, weight ascending in steps of 10
[[menu.main]]
identifier = "<slug>"
name = "<Page Name>"
url = "/<slug>/"
weight = 10

# fixed trailing items:
[[menu.main]]
identifier = "author"
name = "Author"
url = "<author-site-url>"   # omit this whole block if the user has no site
weight = 90
[[menu.main]]
identifier = "github"
name = "GitHub"
url = "https://github.com/<owner>/<repo>"
weight = 100
# only if a coverage report is published:
[[menu.main]]
identifier = "test-coverage"
name = "Test Coverage"
url = "https://<owner>.github.io/<repo>/coverage-report"
weight = 110
```

### 4. Archetype (`docs/archetypes/default.md`)

```
+++
date = '{{ .Date }}'
draft = true
title = '{{ replace .File.ContentBaseName "-" " " | title }}'
+++
```

### 5. Content pages (`docs/content/`)

- `_index.md` — the landing page (overview, package table, install, "where to next"). Frontmatter:

```
+++
title = '<Project Title>'
+++
```

- One page per major component for multi-page docs (e.g. `content/architecture.md`), each:

```
+++
title = '<Page Name>'
+++
```

The filename (minus `.md`) is the slug used in the menu `url` and Pages links. Reuse and expand the
README's content here — the docs can go deeper than the README.

### 6. GitHub Pages workflow

File name: `.github/workflows/build-docs-and-coverage-report.yml` when a coverage report is published
into the site, `.github/workflows/build-docs.yml` when it is not. Keep it in step with the `name:` below.

`submodules: recursive` is required or the theme is missing on CI.

```yaml
name: Build Docs & Coverage Report

on:
  push:
    branches:
      - main
    paths:
      - 'docs/**'
  workflow_dispatch:
    inputs:
      reason:
        description: 'Reason for manual run'
        required: false
        default: 'Test run from GitHub UI'

permissions:
  contents: write
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          submodules: recursive
          fetch-depth: 0

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v3
        with:
          hugo-version: 'latest'
          extended: true

      - name: Build Hugo site
        run: hugo -s docs --environment production --minify --cleanDestinationDir --gc --baseURL "https://<owner>.github.io/<repo>/"

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: docs/public
          publish_branch: gh-pages
```

Name the workflow "Build Docs & Coverage Report" when a coverage report is published; otherwise just
"Build Docs".

### 7. Verify locally

```bash
hugo -s docs server
```

Then remind the user: enable GitHub Pages for the repo (Settings → Pages → deploy from `gh-pages`
branch), and that clones need `git submodule update --init --recursive`.
