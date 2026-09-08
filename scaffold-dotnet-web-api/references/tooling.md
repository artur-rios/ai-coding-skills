# Scripts, OpenAPI, CI, docs site, API client, README

## scripts/

Python 3, standard library only, runnable from the repository root.

### scripts/migrations.py

An interactive menu over `dotnet ef`, and the **only** supported way to touch the
schema. It exists so nobody has to remember which project is the startup project
or which environment file holds the connection string.

- Lists `src/Presentation/<Prefix>.<Name>.WebApi/Environments/.env*`, asks which
  to use, parses it, and puts `<NAME>_DATA_CONNECTIONSTRING` into the subprocess
  environment.
- Menu: **add** a migration (prompts for a name), **remove** the last one,
  **list** them, **apply** pending ones, **generate an idempotent SQL script**.
- Always passes `--project src/Infrastructure/<Prefix>.<Name>.Data
  --startup-project src/Infrastructure/<Prefix>.<Name>.Data` — the Data project
  is its own startup project, which is what `GenerateRuntimeConfigurationFiles`
  in its csproj enables.
- **Masks the password** before printing any connection string.
- Runs `dotnet tool restore` first, so the pinned `dotnet-ef` is used.

Two details the `.env` parser has to get right, because both fail silently:

```python
key, _, value = line.partition("=")     # partition, not split: a connection
                                        # string is full of "=" and only the
                                        # first one separates
```

and a password mask that keys on the whole field name (`password` / `pwd`), not a
substring — `PasswordFile=...` is not a secret.

Put both in module-level functions and cover them in `scripts/test_migrations.py`.
They are pure, they are the parts that leak a password or point at the wrong
database, and the tests workflow runs them before anything else.

### scripts/coverage.py

Runs the suites (or `--report-only`, reusing coverage files CI already wrote),
merges every `coverage.cobertura.xml` with ReportGenerator into
`docs/coverage-report/`, and **fails when merged line coverage is below a
minimum declared in the script**. The threshold lives in the script so a local
run and a CI run answer the same question, and raising it is one edit. Empty the
output directory first — otherwise a page for a deleted class survives forever.

Two things the scaffold has to get right, both measured:

- **Set the floor to what the scaffold actually measures, not to an aspiration.**
  A freshly scaffolded API with both suites collected sits at a little over
  **20%** — `Startup`, the seeder and the design-time factory are large and only
  partly exercised, and there is no domain yet. A 70% floor fails the very first
  CI run, which teaches everyone to ignore the check. Ship `20.0` with a comment
  calling it a ratchet, and raise it as features land.
- **Sum lines across reports; do not average `line-rate`.** Averaging lets a tiny
  fully-covered project offset a large bare one.
- Pass `-filefilters:-**/Migrations/**` — nobody reviews a coverage page for
  EF-generated code, and the model snapshot alone is a fifth of the line count.

### scripts/openapi.py

Runs `tools/<Prefix>.<Name>.OpenApiGen`, writes `docs/openapi/<name>.json`, and
supports `--check`, which regenerates into a temporary directory and **compares
bytes**, exiting non-zero on a difference. That comparison is why
`LineEndingDocumentFilter` exists.

**Pass the output path absolute.** `dotnet run --project` runs with the project's
own directory as the working directory, not the repository root, so a relative
path silently writes `tools/<Prefix>.<Name>.OpenApiGen/docs/openapi/<name>.json`
and `--check` then compares a fresh document against a file nothing updated.

### scripts/vulnerabilities.py

Wraps `dotnet list package --vulnerable --include-transitive`, which exits 0
whether or not it found anything — the script parses what it printed and exits
non-zero on a hit.

The parsing is the check, and it has one trap worth stating: a **top-level** row
carries five columns and a **transitive** row only four, because a package no
project asked for has no "Requested" version. A regex written against the
five-column shape misses every transitive advisory — which are precisely the ones
this exists to catch, since a direct dependency's advisory tends to be noticed
when the version is bumped. Anchor on the right-hand side and make the requested
version optional:

```python
FINDING = re.compile(
    r"^\s*>\s+(?P<package>\S+)"
    r"(?:\s+(?P<requested>\S+))??"
    r"\s+(?P<resolved>\S+)\s+(?P<severity>\S+)\s+(?P<advisory>https?://\S+)\s*$"
)
```

Cover it in `scripts/test_vulnerabilities.py`, with a fixture containing one row
of each shape.

## tools/<Prefix>.<Name>.OpenApiGen

A console app that builds its own minimal host — `AddControllers` with
`ModelBindingConfiguration.Configure`, `AddEndpointsApiExplorer`,
`AddSwaggerGen(SwaggerConfiguration.Configure)` — resolves `ISwaggerProvider`,
serializes the `v1` document as OpenAPI 3.0 JSON, and writes it to the path given
on the command line.

It builds its own host rather than running `Startup` deliberately: `Startup`
requires a database and a signing secret, and generating a document must not. The
cost is that any MVC configuration must be applied in both places — which is
exactly why `ModelBindingConfiguration` and `SwaggerConfiguration` are separate
static classes rather than inline lambdas.

Three things it must get right:

- **`Microsoft.NET.Sdk.Web`, not `Microsoft.NET.Sdk`**, with `<OutputType>Exe</OutputType>`.
  `WebApplication.CreateBuilder` and `ISwaggerProvider` need the ASP.NET Core
  shared framework; a plain console SDK does not reference it.
- **Dispose the writer before the process exits.** `OpenApiJsonWriter` wraps a
  buffering `StreamWriter`; without disposing it the document is silently
  truncated at 4096 bytes, which looks like a valid file until something parses
  it:

  ```csharp
  await using (var stream = File.Create(outputPath))
  {
      await using var text = new StreamWriter(stream);

      document.SerializeAsV3(new OpenApiJsonWriter(text));
  }
  ```

- **Resolve the argument with `Path.GetFullPath`** and refuse to run without one,
  for the working-directory reason above.

Outside the solution, so a solution-wide `dotnet test` never builds it.

## .github/workflows/

### tests.yml

On `push` to `main` and on `pull_request`. **No path filters** — a test suite is
the one workflow that should run for every change; a filter lets a change to an
unlisted path merge without evidence that anything still passes.

One job, in this order, so the cheapest signal arrives first:

1. `python3 -m unittest discover -s scripts -p "test_*.py"` — milliseconds, no build.
2. `dotnet restore src/<Prefix>.<Name>.sln`
3. `python3 scripts/vulnerabilities.py` — needs the resolved graph and nothing else.
4. `dotnet build --configuration Release --no-restore` — once, so both test steps use `--no-build`.
5. `dotnet test --filter "Category=Unit" --collect:"XPlat Code Coverage"`
6. `dotnet test --filter "Category=Functional" --collect:"XPlat Code Coverage"` —
   these start a real PostgreSQL container through Testcontainers, which is why
   the job must stay on `ubuntu-latest`.
7. Install `dotnet-reportgenerator-globaltool` and add `$HOME/.dotnet/tools` to
   `$GITHUB_PATH` — `setup-dotnet` does not.
8. `python3 scripts/coverage.py --report-only`
9. Upload `docs/coverage-report` as `coverage-report`, and `**/TestResults/*.trx`,
   both with `if: always()` — a coverage failure is exactly the run whose report
   somebody needs to open.

A second job builds the container image (`push: false`). Nothing else in CI does,
and the Dockerfile restores from a hand-listed set of project files rather than
the whole tree — so a new file restore depends on is missing from the build
context and fails there while every other job stays green.

Set `concurrency: { group: tests-${{ github.ref }}, cancel-in-progress: true }`.

### check-openapi.yml

Runs `python3 scripts/openapi.py --check` and fails when the committed document
is stale. Without it a controller change keeps being published with the old
document, because the docs site only rebuilds on changes under `docs/`.

### build-docs.yml

On pushes to `main` that touch `docs/`. Checks out with
`submodules: recursive` (the Docsy theme), `npm install --prefix docs/themes/docsy`,
downloads the `coverage-report` artifact from the latest successful `tests` run
on `main` into `docs/coverage-report`, runs Hugo, and deploys to GitHub Pages.
**Renaming the artifact breaks this job** — say so in a comment in both files.

## docs/ — the Hugo site

Docsy as a git submodule at `docs/themes/docsy`:

```bash
git submodule add https://github.com/google/docsy.git docs/themes/docsy
```

`docs/hugo.toml` sets `baseURL` to `https://<owner>.github.io/<repo>/`, the
theme, and mounts `docs/coverage-report` at `static/coverage-report`. Content
pages under `docs/content/en/docs/`: `overview`, `getting-started`,
`architecture`, `api-explorer` (Swagger UI over `docs/openapi/<name>.json`),
`operations`, `testing`. Each starts as a short page saying what belongs there —
a stub with a heading is honest; a stub that reads as finished documentation is
not.

`docs/openapi/` gets a `.gitkeep`; the document appears the first time
`scripts/openapi.py` runs.

## api-client/

Ready-to-send requests for every endpoint, in both formats, covering the two
health endpoints and nothing else.

- `api-client/http/healthcheck.http` and `http-client.env.json` (JetBrains HTTP
  Client). The private overlay `http-client.private.env.json` is gitignored.
- `api-client/bruno/` — `bruno.json`, `collection.bru`, `environments/Local.bru`,
  and a `Health/` folder with one `.bru` per endpoint. Bruno reads real values
  from `bruno/.env`, which is gitignored.
- `api-client/README.md` explaining both and where the credential overlays go.

## README.md

Sections, in order:

1. Title, a docs-site badge and a license badge.
2. A link to the documentation site.
3. One paragraph: what the API is, built with ASP.NET Core (.NET 10).
4. **Overview** — bullets for the architecture and the cross-cutting features.
5. **Project structure** — the annotated tree from `references/layout.md`.
6. **Getting started** — prerequisites (.NET 10 SDK, PostgreSQL, Docker for the
   functional suite, Python 3 for the scripts), copying `Environments/.env.example`
   to `.env.local`, setting the token secret and master-user variables, running
   `python scripts/migrations.py` once entities exist, and `dotnet run`.
7. **Testing** — the two filters, and that the functional suite needs Docker.
8. **Deploy with Docker** — the three `docker compose --env-file …` commands.
9. **Documentation** — the site, and how to preview it locally.
10. **Conventions** — a pointer to `docs/conventions.md`, described as the thing
    to read before adding a feature.
11. **License**.

State plainly in *Getting started* that the project ships with **no domain
entities** — the only migration is the one creating the Data Protection key ring
— and that the first feature adds both an entity and its migration. A reader who
does not know that will assume the scaffold is broken.
