# Stacks: what to detect, and the commands each one uses

`SKILL.md` step 1 identifies the stack of each component from its manifest, and whether the component is a
**package** (published to a registry, for others to install) or an **application** (run or deployed: an API, a
web app, a CLI, a worker, a mobile app). This file is the per-stack lookup for everything the generated docs
name: the install command and badge of a package, the requirement line, and the build, test and coverage
commands CONTRIBUTING and the Pages workflow use.

**Every command is checked against the repository before it is written** — the real solution or project path,
the scripts in `package.json`, the test runner actually configured, the coverage tool already installed. The
table rows are the defaults when the repository says nothing more specific.

## Identify the stack

| Manifest at the component's root | Stack |
|---|---|
| `*.sln` / `*.slnx` / `*.csproj` | .NET |
| `package.json` (with `angular.json`, `vite.config.*`, `next.config.*` → a front end) | Node.js / TypeScript |
| `pyproject.toml` / `setup.py` / `setup.cfg` | Python |
| `Cargo.toml` | Rust |
| `build.gradle*` / `pom.xml` | JVM (Java / Kotlin) |
| `pubspec.yaml` | Dart / Flutter |
| `go.mod` | Go |
| anything else | ask the user for the build, test and install commands |

A repository can hold several components (an API in `src/api` and its front end in `src/web`). Identify each.

## Package or application

A component is a **package** when the repository publishes it to a registry. The signals, per stack:

| Stack | It is a package when | It is not when |
|---|---|---|
| .NET | the packable rule below holds | — |
| Node.js | `package.json` has a `name` and no `"private": true` | `"private": true`, or it is a front-end app |
| Python | it has a `[build-system]` **and** is published — a PyPI page exists or a publish workflow does (`pypa/gh-action-pypi-publish`, `uv publish`, `twine upload`) | a `Private :: Do Not Upload` classifier |
| Rust | the crate has no `publish = false`, and a crates.io page or a publish workflow (`cargo publish`) exists | `publish = false` |
| JVM | the build applies `maven-publish` / `com.vanniktech.maven.publish`, or the POM has `<distributionManagement>` | none of those |
| Dart / Flutter | `publish_to` is absent or a URL | `publish_to: none` |
| Go | the module has importable (non-`main`) packages meant for others — say so if unsure | only `package main` |

When the signals disagree or are absent — a Python project with a build backend but no PyPI page — **ask**
whether it is published; never decide by guess. A repository with at least one package is documented as a
**library**; a repository with none, as an **application**. Sample and test projects are neither.

### .NET: what counts as a packable project

*(This rule is shared verbatim with `create-nuget-publish-workflow` so the two skills never disagree
about what a repository ships. Change it in both or neither.)*

A `.csproj` ships a NuGet package when it **opts in** and is **not excluded**:

| | Signal |
|---|---|
| **Opts in** | An explicit `<PackageId>`, or `<IsPackable>true</IsPackable>`, or `<GeneratePackageOnBuild>true</GeneratePackageOnBuild>` |
| **Excluded** | `<IsPackable>false</IsPackable>`; a test project (references `Microsoft.NET.Test.Sdk`); an executable (`<OutputType>Exe</OutputType>`) that has no `<PackageId>` |

An executable *with* a `<PackageId>` is legitimate — that is how .NET tools ship — so do not exclude it
on `OutputType` alone.

Detect from the **repository root**, not just `src/` — not every repo has one:

```bash
grep -rl -e "<PackageId>" -e "<IsPackable>true</IsPackable>" \
        -e "<GeneratePackageOnBuild>true</GeneratePackageOnBuild>" \
        --include=*.csproj . | sort
```

Then read each match and drop the ones the exclusion column catches.

**The package id** is the `<PackageId>` when set; otherwise it defaults to the assembly name, which
defaults to the project file name. Read it — never infer it from the folder name.

## Package id, install command, badge and requirement

Read the id from the manifest — never from the folder name.

| Stack | Package id from | Install | Version badge (link) | Requirement line, from |
|---|---|---|---|---|
| .NET | `<PackageId>` (rule above) | `dotnet add package <id>` | `https://img.shields.io/nuget/v/<id>.svg` (`https://www.nuget.org/packages/<id>`) | `<TargetFramework(s)>` → "Requires .NET 8.0 or later." |
| Node.js | `name` | `npm install <name>` | `https://img.shields.io/npm/v/<name>.svg` (`https://www.npmjs.com/package/<name>`) | `engines.node`, else `.nvmrc` / `.node-version` / `volta.node` (recommend adding `engines` in the report when none exists) |
| Python | `[project] name` | `pip install <name>` | `https://img.shields.io/pypi/v/<name>.svg` (`https://pypi.org/project/<name>/`) | `requires-python` |
| Rust | `[package] name` | `cargo add <name>` (a binary: `cargo install <name>`) | `https://img.shields.io/crates/v/<name>.svg` (`https://crates.io/crates/<name>`) | `rust-version` |
| JVM | `group:artifact` | the Gradle `implementation("<group>:<artifact>:<version>")` and Maven `<dependency>` snippets, with "the version in the badge above" in place of a number | `https://img.shields.io/maven-central/v/<group>/<artifact>.svg` (`https://central.sonatype.com/artifact/<group>/<artifact>`) | the Java toolchain / `release` version |
| Dart / Flutter | `name` | `dart pub add <name>` (`flutter pub add <name>` for a Flutter package) | `https://img.shields.io/pub/v/<name>.svg` (`https://pub.dev/packages/<name>`) | `environment.sdk` / `environment.flutter` |
| Go | `module` | `go get <module>` | `https://pkg.go.dev/badge/<module>.svg` (`https://pkg.go.dev/<module>`) | the `go` directive |

A package that **will be** published but has not been yet keeps its registry install command and badge — the docs
describe the released package, and the badge reads "not found" only until the first release. Say in the report that
the package is not on the registry yet. Only when the user says it will not be published is it an application, or a
library installed from the repository (`npm install github:<owner>/<repo>`, `pip install
git+https://github.com/<owner>/<repo>`, `cargo add --git https://github.com/<owner>/<repo>`).

## Build, test, format and coverage

The first three columns fill CONTRIBUTING's Prerequisites, Build and Testing sections. The coverage column is
used only when the site publishes a coverage report: it must write an HTML report whose `index.html` ends up in
`docs/coverage-report/`.

| Stack | Prerequisite | Build | Test | Lint / format check | Coverage → `docs/coverage-report/` |
|---|---|---|---|---|---|
| .NET | [.NET SDK](https://dotnet.microsoft.com/download) `<major>` | `dotnet build <sln>` | `dotnet test <sln>` (with `--filter "Category=Unit"` / `"Category=Functional"` when the tests carry the trait) | `dotnet format <sln> --verify-no-changes` | `dotnet test <sln> --collect:"XPlat Code Coverage" --results-directory coverage` (needs `coverlet.collector` in each test project — the xUnit template has it), then ReportGenerator `-reports:coverage/**/coverage.cobertura.xml -targetdir:docs/coverage-report -reporttypes:Html` |
| Node.js | [Node.js](https://nodejs.org/) `<engines>` | `npm ci && npm run build` | `npm test` | `npm run lint` when the script exists | Vitest: `npx vitest run --coverage --coverage.reporter=html --coverage.reportsDirectory=docs/coverage-report` (needs `@vitest/coverage-v8`); Jest: `npx jest --coverage --coverageReporters=html --coverageDirectory=docs/coverage-report` |
| Python | [uv](https://docs.astral.sh/uv/) or Python `<requires-python>` | `uv build` (`python -m build`) | `uv run pytest` | `uv run ruff check` when ruff is configured | `uv run pytest --cov=<package> --cov-report=html:docs/coverage-report` (needs `pytest-cov`) |
| Rust | [Rust](https://rustup.rs/) `<rust-version>` | `cargo build` | `cargo test` | `cargo clippy --all-targets -- -D warnings`, `cargo fmt --check` | `cargo llvm-cov --html --output-dir coverage && mkdir -p docs/coverage-report && cp -r coverage/html/. docs/coverage-report/` (needs `cargo-llvm-cov`) |
| JVM | a JDK `<version>` | `./gradlew build -x test` / `./mvnw -DskipTests package` | `./gradlew test` / `./mvnw test` | the configured checker (Spotless, Checkstyle), if any | JaCoCo (configured below if absent): `./gradlew test jacocoTestReport && mkdir -p docs/coverage-report && cp -r build/reports/jacoco/test/html/. docs/coverage-report/`; Maven: `./mvnw verify`, then `cp -r target/site/jacoco/. docs/coverage-report/` |
| Dart / Flutter | [Flutter](https://docs.flutter.dev/get-started/install) / [Dart](https://dart.dev/get-dart) `<sdk>` | `flutter build <platform>` / `dart compile` | `flutter test` / `dart test` | `flutter analyze` / `dart analyze`, `dart format --set-exit-if-changed .` | `flutter test --coverage` then `genhtml coverage/lcov.info -o docs/coverage-report` (`lcov` package) |
| Go | [Go](https://go.dev/dl/) `<go directive>` | `go build ./...` | `go test ./...` | `go vet ./...`, `gofmt -l .` | `go test -coverprofile=coverage.out ./...` then `go tool cover -html=coverage.out -o docs/coverage-report/index.html` |

Only the .NET row has optional helper toolsets to mention in Prerequisites:
[Dotnet Tools](https://github.com/artur-rios/dotnet-tools) and
[Python Dotnet Tools](https://github.com/artur-rios/python-dotnet-tools).

**JaCoCo, when a JVM project has no coverage set up yet** — Gradle (Kotlin DSL):

```kotlin
plugins {
    jacoco
}

tasks.jacocoTestReport {
    dependsOn(tasks.test)
    reports { html.required = true }
}
```

Maven: add `org.jacoco:jacoco-maven-plugin` with the `prepare-agent` and `report` goals (the latter bound to `verify`).
Other stacks name their coverage dependency in the table above; add it as a dev / test dependency when it is missing.

## CI setup steps for the Pages workflow's coverage job

The workflow in `references/hugo-setup.md` step 7 has a marked block for the coverage report. Fill it with the
stack's setup action and the coverage command above:

| Stack | Setup step(s) |
|---|---|
| .NET | `actions/setup-dotnet` with `dotnet-version: '<major>.x'`; then `dotnet tool install --global dotnet-reportgenerator-globaltool` and `echo "$HOME/.dotnet/tools" >> "$GITHUB_PATH"` |
| Node.js | `actions/setup-node` with the `engines` version, `cache: npm`; `npm ci` at the component root |
| Python | `astral-sh/setup-uv` (or `actions/setup-python` + `pip install -e .[test]`) |
| Rust | `dtolnay/rust-toolchain@stable` with `components: llvm-tools-preview`; `taiki-e/install-action` with `tool: cargo-llvm-cov` |
| JVM | `actions/setup-java` with `distribution: temurin` and the toolchain version; `gradle/actions/setup-gradle` for Gradle; `chmod +x gradlew` (or `mvnw`) unless the repository commits the wrapper as executable — a wrapper committed from Windows is `100644`, and `./gradlew` is then denied |
| Dart / Flutter | `subosito/flutter-action` (or `dart-lang/setup-dart`); `sudo apt-get install -y lcov` |
| Go | `actions/setup-go` with `go-version-file: go.mod` |

Use the major versions of these actions that the repository's other workflows already use; otherwise the
current major of each.

## Application facts to read

For an application, the README and the site describe how to **configure, run and deploy** it. Read these from
the repository — never invent a variable or an endpoint:

| Fact | Where to look |
|---|---|
| Configuration and environment variables | `.env.example` / `*.env.example`, `appsettings*.json`, `application.yml` / `.properties`, settings classes (`IOptions<T>`, pydantic `BaseSettings`, `@ConfigurationProperties`), `process.env.*` reads; for a front end, `import.meta.env.*` / `VITE_*` (Vite), Angular `environment*.ts`, and the `.env*` files the bundler loads — all build-time, so say so. Spring Boot reads any property from the environment by relaxed binding — `server.port` → `SERVER_PORT`, `spring.datasource.url` → `SPRING_DATASOURCE_URL` — so document each property with its environment-variable form |
| How to run it locally | the run script or command (`dotnet run --project …`, `npm run dev`, `uv run …`, `./gradlew bootRun`, `cargo run`, `flutter run`), its port (`launchSettings.json`, `server.port`, the dev server config — Vite's default is 5173, Angular's 4200, unless configured) |
| Containers and deployment | `Dockerfile`, `docker-compose*.yml`, `docker/`, Helm charts, deploy workflows |
| Database and migrations | EF Core `Migrations/`, Flyway / Liquibase, Alembic, Prisma; migration scripts |
| HTTP API surface | a committed OpenAPI document (`openapi*.json` / `*.yaml`, `docs/openapi/`), else the controllers / routes; health endpoints |
| Front-end entry | the routes and top-level pages, the API it calls, the production build's output folder (`dist/`, `dist/<name>/browser`) and its preview command (`npm run preview`) |

### A front end is documented as a static site

A web front end has no health endpoint, no Swagger and usually no container: its *Run* is the dev server and its URL,
its *Deploy* is "build, then serve the output folder from any static host" (and the repository's own hosting config,
if any — `vercel.json`, `netlify.toml`, `staticwebapp.config.json`, a Pages workflow), and its *Configure* is the
build-time variables above. Write the getting-started page around opening the app in a browser, not around a first
request.
