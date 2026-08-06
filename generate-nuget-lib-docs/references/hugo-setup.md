# Hugo docs site setup

Creates a Hugo site under `docs/` using the **Docsy** theme (see `references/identity.md`) as a git
submodule, deployed to GitHub Pages via a workflow.

Docsy is a technical-documentation theme: the left sidebar is generated automatically from the page
tree under the docs section (ordered by `weight`), so pages are *not* listed one by one in a menu.
`[[menu.main]]` only controls the top navbar.

## If a site already exists

If `docs/hugo.toml` (or `docs/config.toml`) exists, do NOT re-init. Only:
- Add/update content pages under `docs/content/en/docs/` to match the chosen single/multi-page
  structure, and their `weight` ordering.
- Leave the theme submodule alone unless broken.
- If the existing site uses a different theme, say so and ask before switching — swapping themes
  moves content directories and rewrites the config.
- Still ensure the GitHub Actions workflow exists (step 7) — a site can exist without CI. Create it if
  missing; leave it if already present and correct.

## Creating from scratch

Run from the repo root. Docsy requires **Hugo Extended ≥ v0.146.0** and **Node.js ≥ 18** (its CSS is
built with PostCSS/Autoprefixer).

### 1. Init the site

```bash
hugo new site docs --format toml
```

### 2. Add Docsy as a submodule and install its npm dependencies

```bash
git submodule add https://github.com/google/docsy.git docs/themes/docsy
git submodule update --init --recursive
(cd docs/themes/docsy && npm install)
```

This writes/updates `.gitmodules` at the repo root:

```
[submodule "docs/themes/docsy"]
	path = docs/themes/docsy
	url = https://github.com/google/docsy.git
```

`npm install` inside the theme is required — without it Hugo fails with a PostCSS/Autoprefixer error
when building Docsy's stylesheets.

### 3. Write `docs/hugo.toml`

Fill `<owner>`, `<repo>`, `<Project Title>`, `<author-name>`. The `[module]` mount block and the Test
Coverage navbar item apply only when the solution publishes a coverage report into `docs/coverage-report`
— omit both otherwise.

```toml
baseURL = 'https://<owner>.github.io/<repo>/'
title = '<Project Title>'
theme = 'docsy'

enableRobotsTXT = true
enableGitInfo = true

contentDir = 'content/en'
defaultContentLanguage = 'en'

# Docsy needs these output formats for its section pages and print view
[outputs]
home = ['HTML']
page = ['HTML']
section = ['HTML', 'print', 'RSS']

# Docsy renders HTML inside markdown (shortcodes, alerts) — required
[markup]
[markup.goldmark.renderer]
unsafe = true
[markup.highlight]
noClasses = false
style = 'tango'

# Only if the solution publishes a coverage report — mounts it as static files. Omit otherwise.
[module]
[[module.mounts]]
source = 'content/en'
target = 'content'
[[module.mounts]]
source = 'coverage-report'
target = 'static/coverage-report'

[languages]
[languages.en]
languageName = 'English'
title = '<Project Title>'
[languages.en.params]
description = '<one-line project description>'

[params]
copyright = '<author-name>'
github_repo = 'https://github.com/<owner>/<repo>'
github_branch = 'main'
# points "Edit this page" at the right folder, since the site lives in docs/
github_subdir = 'docs'
offlineSearch = true

[params.ui]
sidebar_menu_compact = false
sidebar_search_disable = false
breadcrumb_disable = false
navbar_logo = false

[params.links]
[[params.links.user]]
name = '<author-name>'
url = '<author-site-url>'   # omit this whole block if the user has no site
icon = 'fa fa-user'
[[params.links.developer]]
name = 'GitHub'
url = 'https://github.com/<owner>/<repo>'
icon = 'fab fa-github'

# Top navbar. Docsy builds the sidebar from the page tree — do NOT list docs pages here.
[menu]
[[menu.main]]
identifier = 'docs'
name = 'Documentation'
url = '/docs/'
weight = 10
[[menu.main]]
identifier = 'github'
name = 'GitHub'
url = 'https://github.com/<owner>/<repo>'
weight = 100
# only if a coverage report is published:
[[menu.main]]
identifier = 'test-coverage'
name = 'Test Coverage'
url = 'https://<owner>.github.io/<repo>/coverage-report'
weight = 110
```

If no coverage report is published, drop the `[module]` block entirely — `contentDir` already points
Hugo at `content/en`.

### 4. Archetype (`docs/archetypes/default.md`)

```
+++
date = '{{ .Date }}'
draft = true
title = '{{ replace .File.ContentBaseName "-" " " | title }}'
+++
```

### 5. Content pages (`docs/content/en/`)

Docsy expects a landing page plus a docs section:

- `content/en/_index.md` — the site landing page (project pitch, package table, install). Frontmatter:

```
+++
title = '<Project Title>'
linkTitle = '<Project Title>'
+++
```

- `content/en/docs/_index.md` — the docs section root (overview, "where to next"):

```
+++
title = 'Documentation'
linkTitle = 'Docs'
menu.main.weight = 10
weight = 10
+++
```

- One page per package/major component under `content/en/docs/` for multi-page docs (e.g.
  `content/en/docs/architecture.md`), each:

```
+++
title = '<Page Name>'
linkTitle = '<Page Name>'
weight = 20
description = '<one line — shown in section listings>'
+++
```

Sidebar order comes from `weight` (ascending, in steps of 10). The filename (minus `.md`) is the slug,
so the page URL is `/docs/<slug>/`. Reuse and expand the README's content here — the docs can go deeper
than the README.

### 6. Commit the generated lockfile

`docs/themes/docsy` is a submodule, so its `node_modules/` and lockfile stay inside the submodule and
are not committed by this repo. Nothing extra to add — just don't `.gitignore` the submodule path.

### 7. GitHub Pages workflow

File name: `.github/workflows/build-docs-and-coverage-report.yml` when a coverage report is published
into the site, `.github/workflows/build-docs.yml` when it is not. Keep it in step with the `name:` below.

`submodules: recursive` is required or the theme is missing on CI. The Node step is required or Docsy's
PostCSS pipeline fails.

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

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install theme dependencies
        run: npm install
        working-directory: docs/themes/docsy

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

### 8. Verify locally

```bash
hugo -s docs server
```

Then remind the user: enable GitHub Pages for the repo (Settings → Pages → deploy from `gh-pages`
branch), and that clones need `git submodule update --init --recursive` followed by
`npm install` inside `docs/themes/docsy`.
