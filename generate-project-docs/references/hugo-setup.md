# Hugo docs site setup

Creates a Hugo site under `docs/` using the **Docsy** theme (see `references/identity.md`), installed as the
`@docsy/theme` npm package, and deployed to GitHub Pages by a workflow.

Docsy is a technical-documentation theme: the left sidebar is generated automatically from the page
tree under the docs section (ordered by `weight`), so pages are *not* listed one by one in a menu.
`[[menu.main]]` only controls the top navbar.

## What the site holds — and what it never repeats

The site is for **usage and reference**: for a library, overview, installation, usage, per-package pages,
architecture, diagrams; for an application, getting started, configuration, architecture, the API reference and
operations (§Application pages).
Content whose home is the README, `CONTRIBUTING.md` or `CHANGELOG.md` is **not copied** into it:

- No Testing, Build/test/publish, Branching and releases, Versioning or project-info pages — that is `CONTRIBUTING.md`.
- No release history and no migration/upgrade pages — that is `CHANGELOG.md` (upgrade guides live under
  `### Upgrading from <X>.x to <Y>.0` there; link the anchor instead of keeping a page).
- The site gets two pages, **Changelog** and **Contributing**, that render the real root files through the
  `repo-file` shortcode (step 5). The files are written once and shown in both places.

## If a site already exists

If `docs/hugo.toml` (or `docs/config.toml`) exists, do NOT re-init. Only:
- Add/update content pages under `docs/content/en/docs/` to match the chosen structure (library pages or
  §Application pages), and their `weight` ordering. Keep pages the site already has that hold real content.
- Remove contributor and release material from site pages (list above) — check that it now lives in
  `CONTRIBUTING.md` / `CHANGELOG.md` first, and link the new Changelog/Contributing pages wherever a page linked the
  removed section.
- Add the `repo-file` shortcode, the two mounts and the Changelog/Contributing pages (step 5) if missing.
- Leave the theme installation alone unless broken. A site that still installs Docsy as a git submodule
  (`docs/themes/docsy`) keeps working; mention the npm package in the report rather than migrating unasked.
- If the existing site uses a different theme, say so and ask before switching — swapping themes
  moves content directories and rewrites the config.
- Still ensure the GitHub Actions workflow exists (step 7) — a site can exist without CI. Create it if
  missing; fix it if it is stale (e.g. its `paths` miss `CHANGELOG.md` / `CONTRIBUTING.md`).

## Creating from scratch

Run from the repo root. Docsy needs **Hugo Extended** at the version its release requires (the release notes of the
`@docsy/theme` version you install; Docsy 0.17 and later need **v0.160.1 or newer**), **Dart Sass** on the `PATH`
(0.17 and later compile their SCSS with it — the standalone Dart Sass: `choco install sass`, `brew install sass/sass/sass`,
`sudo snap install dart-sass`, or the release archive from <https://github.com/sass/dart-sass/releases>; the npm `sass`
package cannot serve Hugo), and **Node.js ≥ 18**. Check `hugo version` and `sass --version` before building, and
list Hugo Extended, Dart Sass and Node.js under the docs site in CONTRIBUTING's Prerequisites.

### 1. Init the site

```bash
hugo new site docs --format toml
```

When `docs/` holds only a `.gitkeep` (a repository from **scaffold-project**), delete the `.gitkeep` first — or run
with `--force` — since `hugo new site` refuses a non-empty directory. Anything else already in `docs/` is handled by
`SKILL.md` step 6.

### 2. Install Docsy and its build dependencies with npm

Write `docs/package.json` (fill `<repo>`, `<Project Title>`, and the license — `SEE LICENSE IN ../LICENSE` for the
Artur Rios Attribution License, the SPDX id such as `MIT` for a standard one):

```json
{
  "name": "<repo>-docs",
  "version": "1.0.0",
  "description": "Documentation site for <Project Title>",
  "private": true,
  "license": "SEE LICENSE IN ../LICENSE",
  "scripts": {
    "build": "hugo --minify --cleanDestinationDir --gc",
    "serve": "hugo server"
  },
  "devDependencies": {
    "@docsy/theme": "^0.18.0"
  }
}
```

Use the current release: check `npm view @docsy/theme version` and write that range. Docsy 0.17 and later run PostCSS
only when the site has a `postcss.config.*`, so `autoprefixer`, `postcss` and `postcss-cli` are added only together
with one — an older Docsy (0.16 and earlier, which an existing site may pin) still needs all three. Then install,
which writes `docs/package-lock.json`:

```bash
(cd docs && npm install)
```

(`npm install --prefix docs` fails on Windows with npm 10 — ENOENT on the root `package.json`; `npm ci --prefix docs`
works everywhere.) If Dart Sass can't be installed where the site is built, pin `"@docsy/theme": "^0.16.0"` with the
three PostCSS packages instead, and say so in the report.

**Commit `docs/package-lock.json`** — CI installs with `npm ci`, which refuses to run without it. Ignore the rest of
what the build produces; add to the root `.gitignore` the lines it doesn't already cover:

```
node_modules/
# Hugo build output
/docs/public/
/docs/resources/_gen/
/docs/.hugo_build.lock
# Coverage results and report (generated by the docs pipeline)
/coverage/
/docs/coverage-report/
```

(The coverage lines only when a coverage report is published, and `/coverage/` only for the stacks whose command writes
there — .NET and Rust; Gradle and Maven already ignore `build/` / `target/`.)

**Tools that scan the whole repository** pick up `docs/` once it holds a site: Tailwind CSS v4's automatic source
detection adds Docsy's class names to the app's CSS, and a linter or type checker with no `include` may read
`docs/node_modules`. For each such tool at the repository root, exclude `docs/` — for Tailwind v4, add
`@source not "../docs";` (the path relative to the CSS file) next to its `@import "tailwindcss";` — and rebuild the
app to confirm its output did not change.

### 3. Write `docs/hugo.toml`

Fill `<owner>`, `<repo>`, `<Project Title>`, `<one-line project description>`, `<author-name>`, `<author-site-url>`.
The `coverage-report` mount and the Test Coverage navbar item apply only when the site publishes a coverage report
into `docs/coverage-report` — omit both otherwise.

```toml
baseURL = 'https://<owner>.github.io/<repo>/'
title = '<Project Title>'

# Docsy is installed as the @docsy/theme NPM package (see package.json)
theme = '@docsy/theme'
themesDir = 'node_modules'

enableRobotsTXT = true
enableGitInfo = false

defaultContentLanguage = 'en'
defaultContentLanguageInSubdir = false
locale = 'en-us'

# Highlighting and Markdown
[markup]
  [markup.goldmark.renderer]
    unsafe = true
  [markup.highlight]
    style = 'tango'
    guessSyntax = true
    lineNos = false
    noClasses = false

[taxonomies]
  tag = 'tags'
  category = 'categories'

# Declaring [module] replaces Hugo's default mounts, so content and static are mounted explicitly.
[module]
  [[module.mounts]]
    source = 'content/en'
    target = 'content'
  # Only if a coverage report is published:
  [[module.mounts]]
    source = 'coverage-report'
    target = 'static/coverage-report'
  [[module.mounts]]
    source = 'static'
    target = 'static'
  # Mounting into assets/ (below) replaces Hugo's default assets mount; keep the project's own.
  [[module.mounts]]
    source = 'assets'
    target = 'assets'
  # CHANGELOG.md and CONTRIBUTING.md live at the repository root; the site renders them
  # (see layouts/_shortcodes/repo-file.html) instead of keeping copies.
  [[module.mounts]]
    source = '../CHANGELOG.md'
    target = 'assets/repo/CHANGELOG.md'
  [[module.mounts]]
    source = '../CONTRIBUTING.md'
    target = 'assets/repo/CONTRIBUTING.md'

[languages]
  [languages.en]
    label = 'English'
    weight = 1
    title = '<Project Title>'
    [languages.en.params]
      description = "<one-line project description>"

[params]
  copyright.authors = '<author-name> | [Artur Rios Attribution License](https://github.com/<owner>/<repo>/blob/main/LICENSE)'
  privacy_policy = ''
  # github_repo and github_branch also tell the repo-file shortcode where to point relative links
  github_repo = 'https://github.com/<owner>/<repo>'
  github_branch = 'main'
  # points "Edit this page" at the right folder, since the site lives in docs/
  github_subdir = 'docs'
  offlineSearch = true
  prism_syntax_highlighting = false

  [params.ui]
    breadcrumb_disable = false
    navbar_logo = false
    navbar_translucent_over_cover_disable = false
    sidebar_menu_compact = false
    sidebar_menu_foldable = true
    sidebar_search_disable = false
    showLightDarkModeMenu = true

    [params.ui.feedback]
      enable = false

    [params.ui.readingtime]
      enable = false

  [params.links]
    # omit this [[params.links.user]] entry if the user has no site; keep the developer link
    [[params.links.user]]
      name = 'Author'
      url = '<author-site-url>'
      icon = 'fa fa-user'
      desc = "The author's website"
    [[params.links.developer]]
      name = 'GitHub'
      url = 'https://github.com/<owner>/<repo>'
      icon = 'fab fa-github'
      desc = 'Source code, issues and releases'

# Top navbar. Docsy builds the sidebar from the page tree — do NOT list docs pages here.
[[menu.main]]
  name = 'Documentation'
  weight = 10
  url = '/docs/'

# only if a coverage report is published:
[[menu.main]]
  name = 'Test Coverage'
  weight = 20
  url = '/coverage-report/'

[[menu.main]]
  name = 'GitHub'
  weight = 30
  url = 'https://github.com/<owner>/<repo>'
  pre = '<i class="fab fa-github"></i>'
```

Adapt the license in `copyright.authors` to the chosen one (e.g. `[MIT License](…)`). Hugo skips a mount whose source
does not exist, so a missing `docs/static/`, `docs/assets/` or `docs/coverage-report/` does not fail the build — but git
does not keep empty directories, so put a `.gitkeep` in `docs/static/` and `docs/assets/` if the project's own files are
meant to go there.

### 4. Archetype (`docs/archetypes/default.md`)

```
+++
date = '{{ .Date }}'
draft = true
title = '{{ replace .File.ContentBaseName "-" " " | title }}'
+++
```

### 5. Content pages (`docs/content/en/`) and the repo-file shortcode

Docsy expects a landing page plus a docs section:

- `content/en/_index.md` — the site landing page (project pitch, links to the docs and GitHub):

```
---
title: <Project Title>
linkTitle: Home
---

{{< blocks/cover title="<Project Title>" height="auto" color="primary" >}}
<p class="lead mt-4">
<one-line project description>
</p>
<a class="btn btn-lg btn-secondary me-3 mb-4" href="docs/">
  Documentation <i class="fas fa-arrow-alt-circle-right ms-2"></i>
</a>
<a class="btn btn-lg btn-secondary me-3 mb-4" href="https://github.com/<owner>/<repo>">
  GitHub <i class="fab fa-github ms-2"></i>
</a>
{{< /blocks/cover >}}

{{% blocks/lead color="light" %}}
<one-line project description>
{{% /blocks/lead %}}
```

- `content/en/docs/_index.md` — the docs section root. For a library: overview, installation, usage, "where to
  next". For an application, whose overview has its own page: one paragraph and a "where to next" list linking the
  pages below — no second overview.

```
---
title: Documentation
linkTitle: Documentation
weight: 20
description: >-
  <one-line project description>
---
```

- One page per package/major component (library) or per topic (application, §Application pages) under
  `content/en/docs/` (e.g. `content/en/docs/architecture.md`), each:

```
---
title: <Page Name>
weight: 20
description: >-
  <one line — shown in section listings>
---
```

Sidebar order comes from `weight` (ascending, in steps of 10). The filename (minus `.md`) is the slug,
so the page URL is `/docs/<slug>/`. Reuse and expand the README's usage content here — the docs can go deeper
than the README.

#### Application pages

For an application, the docs section holds these pages — each only when the analysis has something true to put on
it (`references/stacks.md`, *Application facts to read*):

| Page (slug) | Weight | Holds |
|---|---|---|
| `overview` | 10 | What it does, for whom, the main capabilities, what it is built with. |
| `getting-started` | 20 | From a clone to a running instance: prerequisites to *run* it (not to develop it), configuration to copy, the run command, the URL, a first request or screen. |
| `configuration` | 30 | Every setting, from the real config: name, required or not, default, what it does; where each is read from (file, environment). Secrets are named, never valued. |
| `architecture` | 40 | Components and layers, data store, integrations, the path of a request; the diagrams the user picked. |
| `api` | 50 | A service's HTTP API — see below. |
| `operations` | 60 | Deploying (images, compose, env files), migrations, health checks, logs, backups — whatever the repository supports. |

**The API page.** When the repository commits an OpenAPI document, render it with Docsy's Swagger UI shortcode
instead of describing endpoints by hand — mount the document into the site, like the root files:

```toml
  [[module.mounts]]
    source = '../<path/to/openapi.json>'
    target = 'static/openapi/<name>.json'
```

`content/en/docs/api.md`:

```
---
title: API reference
weight: 50
type: swagger
description: Every endpoint, generated from the OpenAPI document.
---

{{< swaggerui src="/<repo>/openapi/<name>.json" >}}
```

`type: swagger` selects the Docsy layout the shortcode needs. The shortcode passes `src` to Swagger UI as is, so it
carries the repository path — the site is served from `https://<owner>.github.io/<repo>/` — and the build check in
step 8 opens `docs/public/docs/api/index.html` to confirm the URL. Swagger UI loads from unpkg, so the page needs
network access in the browser. Add the document's path to the workflow's `paths` so the page rebuilds when it
changes. Without a committed document, the page lists the endpoints from the controllers / routes — method, path,
what it does, the role it needs — and says where the running service serves its interactive docs (`/swagger`,
`/docs`, springdoc's `/swagger-ui.html`); a spec the service only generates at run time is not a committed document.
A service with no endpoints of its own — only framework ones such as Actuator's — gets no API page: its health and
management endpoints go on the operations page.

- **The Changelog and Contributing pages**, which render the root files. Give them weights above every other page so
  they sit last in the sidebar.

`content/en/docs/changelog/_index.md`:

```
---
title: Changelog
weight: 900
description: Notable changes in each release.
---

{{< repo-file "CHANGELOG.md" >}}
```

`content/en/docs/contributing/_index.md`:

```
---
title: Contributing
weight: 1000
description: Building from source, running the tests, branching and releasing.
---

{{< repo-file "CONTRIBUTING.md" >}}
```

`docs/layouts/_shortcodes/repo-file.html` (verbatim):

```go-html-template
{{- /*
  Renders a Markdown file from the repository root (CHANGELOG.md, CONTRIBUTING.md)
  so the site shows it without keeping a copy. hugo.toml mounts each file under
  assets/repo/. The file's own H1 is dropped (the page has a title) and relative
  links are pointed at the file on GitHub.
*/ -}}
{{- $name := .Get 0 -}}
{{- with resources.Get (path.Join "repo" $name) -}}
  {{- $text := replaceRE `^\x{FEFF}?# [^\n]*\n+` "" .Content -}}
  {{- $base := printf "%s/blob/%s/" site.Params.github_repo site.Params.github_branch -}}
  {{- $text = replaceRE `\]\((?:\./)?([^)/#:][^):]*)\)` (printf "](%s$1)" $base) $text -}}
  {{- $.Page.RenderString (dict "display" "block") $text -}}
{{- else -}}
  {{- errorf "repo-file: %q is not mounted under assets/repo (see hugo.toml)" $name -}}
{{- end -}}
```

The shortcode depends on the two `[[module.mounts]]` in step 3 and on `github_repo` / `github_branch` in `[params]`:
without the mounts the build fails with the `errorf` message, and without the params relative links (`./LICENSE`)
point nowhere.

### 6. Commit the lockfile, ignore the rest

`docs/package.json` and `docs/package-lock.json` are committed; `docs/node_modules/`, `docs/public/` and
`docs/resources/_gen/` are ignored (step 2). No submodule, so a clone needs only `npm ci --prefix docs`.

### 7. GitHub Pages workflow

File name: `.github/workflows/build-docs-and-coverage-report.yml` when a coverage report is published
into the site, `.github/workflows/build-docs.yml` when it is not. Keep it in step with the `name:` below
("Build Docs & Coverage Report" / "Build Docs").

It deploys through the GitHub Pages deployment API (`upload-pages-artifact` / `deploy-pages`), so the Pages source
setting is **GitHub Actions** — no `gh-pages` branch. `paths` lists `CHANGELOG.md` and `CONTRIBUTING.md` because the
site renders them. Use the `actions/*` major versions the repository's other workflows already use.

```yaml
name: Build Docs & Coverage Report

on:
  push:
    branches:
      - main
    paths:
      - 'docs/**'
      - 'CHANGELOG.md'
      - 'CONTRIBUTING.md'
      - 'src/**'
      - 'tests/**'
      - '.github/workflows/build-docs-and-coverage-report.yml'
  workflow_dispatch:
    inputs:
      reason:
        description: 'Reason for manual run'
        required: false
        default: 'Test run from GitHub UI'

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    name: Build site
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v7
        with:
          fetch-depth: 0

      # --- coverage report: only when one is published; drop this block otherwise ---
      # The stack's setup step(s) and coverage command, from references/stacks.md. For .NET:
      - name: Setup .NET SDK
        uses: actions/setup-dotnet@v6
        with:
          dotnet-version: '<sdk>.x'

      - name: Run tests with coverage
        run: |
          dotnet test src/<Solution>.sln \
            --configuration Release \
            --collect:"XPlat Code Coverage" \
            --results-directory coverage

      - name: Install ReportGenerator
        run: |
          dotnet tool install --global dotnet-reportgenerator-globaltool
          echo "$HOME/.dotnet/tools" >> "$GITHUB_PATH"

      - name: Generate coverage report
        run: |
          reportgenerator \
            "-reports:coverage/**/coverage.cobertura.xml" \
            "-targetdir:docs/coverage-report" \
            "-reporttypes:Html"
      # For another stack, e.g. Python:
      #   - uses: astral-sh/setup-uv@v7
      #   - run: uv run pytest --cov=<package> --cov-report=html:docs/coverage-report
      # Whatever the stack, the report's index.html must end up in docs/coverage-report/.
      # --- end of coverage report ---

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v3
        with:
          hugo-version: 'latest'
          extended: true

      # Docsy 0.17+ compiles its SCSS with Dart Sass; Hugo finds it on the PATH.
      - name: Setup Dart Sass
        run: sudo snap install dart-sass

      - name: Setup Node
        uses: actions/setup-node@v7
        with:
          node-version: 'lts/*'
          cache: 'npm'
          cache-dependency-path: docs/package-lock.json

      - name: Install docs dependencies (Docsy theme + PostCSS)
        run: npm ci
        working-directory: docs

      - name: Build Hugo site
        run: hugo -s docs --environment production --minify --cleanDestinationDir --gc --baseURL "https://<owner>.github.io/<repo>/"

      - name: Upload Pages artifact
        uses: actions/upload-pages-artifact@v5
        with:
          path: docs/public

  deploy:
    name: Deploy to GitHub Pages
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v5
```

With a coverage report, `paths` lists what the tests read — `src/**` and `tests/**` in the shared layout (the component
folders otherwise), plus the build manifests (`*.sln`/`*.csproj`, `package.json`, `pyproject.toml`, `Cargo.toml` and
`Cargo.lock`, …) when they sit outside those folders. Without one: name it "Build Docs", drop the marked block, drop those folders from
`paths`, and change the workflow's own entry in `paths` to `.github/workflows/build-docs.yml` — the file's new name.

(.NET only) If the user holds a ReportGenerator PRO license, the author's libraries pin the tool
(`--version "$REPORTGENERATOR_VERSION"`, set under `env:`) and pass `"-license:$REPORTGENERATOR_LICENSE"` from a
`REPORTGENERATOR_LICENSE` secret; add both only when the user says they have one.

### 8. Verify locally

```bash
npm ci --prefix docs
hugo -s docs server
```

Build once with `hugo -s docs` and check the output has zero `ERROR` lines and that the Changelog and Contributing
pages contain the root files' text. Then remind the user: set GitHub Pages to deploy from **GitHub Actions**
(Settings → Pages → Source) if this is the repo's first docs deploy.
