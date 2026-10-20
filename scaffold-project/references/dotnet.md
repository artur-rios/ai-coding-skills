# .NET

Read after the user picked .NET (step 1 of `SKILL.md`). `<Prefix.>` below means `Prefix.` when the
user gave a prefix and nothing otherwise.

## Kind — ask only if the request didn't say

*"What kind of .NET project is it? A Web API, a library published to NuGet, or something else (console
app, worker, Blazor, MVC, gRPC, desktop, MCP server, plain class library…)?"*

| Answer | Then |
|---|---|
| **Web API** | Ask: *"Layered DDD + CQRS on the ArturRios stack — the heimdall-api structure: six projects, EF Core + PostgreSQL, JWT roles, Docker, CI, a docs site — or a minimal `dotnet new webapi`?"* "Like heimdall" in the request answers it. **Layered** → stop reading this file and follow `references/dotnet-web-api/overview.md`. **Minimal** → template `webapi` below, and the DDD question applies. |
| **NuGet library** | Template `classlib`, basic layout. Read `references/dotnet-nuget-library.md` too — it adds the package metadata questions, the csproj properties and the pack check. |
| **Something else** | Map the description to a template short name from the table below. If it is ambiguous, offer the closest candidates (at most 3). If the user gives a short name directly, confirm it. |

### Template short names (.NET 10 SDK)

| Short name | Kind |
|---|---|
| `console` | Console app |
| `webapi` | ASP.NET Core Web API |
| `webapiaot` | ASP.NET Core Web API (native AOT) |
| `mvc` | ASP.NET Core MVC web app |
| `web` | ASP.NET Core Empty |
| `webapp` / `razor` | ASP.NET Core Razor Pages |
| `blazor` | Blazor Web App — `--interactivity Server` for a server-rendered app, `WebAssembly` or `Auto` otherwise; `--empty` omits the sample pages |
| `blazorwasm` | Blazor WebAssembly standalone (`--empty` omits the sample pages) |
| `classlib` | Class library |
| `grpc` | ASP.NET Core gRPC service |
| `worker` | Worker Service (background) |
| `winforms` | Windows Forms app |
| `wpf` | WPF application |
| `mcpserver` | MCP Server App |

Before running, confirm the short name exists with `dotnet new list <short name>` — the SDK no longer
ships `blazorserver`, `blazorserver-empty`, `blazorwasm-empty`, `angular` or `react`. Map a request for
one of those to `blazor` / `blazorwasm` with the options above; for an Angular or React front end,
offer the Angular (spartan/ui) or React (shadcn/ui) stack of this skill instead.

## Interview

Asked with the shared questions (step 3 of `SKILL.md`):

| Question | Default |
|---|---|
| "What should the project be named? (PascalCase, e.g. OrderService)" — this is the shared name question | — |
| "What should the solution be named?" | the project name |
| "Should the solution and projects use a company/org prefix? (e.g. 'Acme' → Acme.OrderService, Acme.OrderService.sln) Leave blank for no prefix." | none |
| *Web templates only* (`webapi`, `webapiaot`, `mvc`, `web`, `webapp`/`razor`, `blazor`, `grpc`): "Do you want a Domain-Driven Design folder structure?" | no |

If a prefix is given: the solution file is `Prefix.SolutionName.sln`, every `-n` value starts with
`Prefix.`, and the folders under `src/` match the `-n` values. If not, omit it entirely — never a
placeholder.

## Generate

Read the SDK first — `dotnet --version` — its major version is the target framework and goes in the
README and CONTRIBUTING.

**Basic layout** — one project:

```bash
dotnet new <template> -n <Prefix.>ProjectName -o src/<Prefix.>ProjectName
dotnet new sln --format sln -n <Prefix.>SolutionName -o src
dotnet sln src/<Prefix.>SolutionName.sln add src/<Prefix.>ProjectName/<Prefix.>ProjectName.csproj
```

**DDD layout** — exactly two projects: the presentation project and a Domain class library. The
presentation project's suffix is `.WebApi` for `webapi` / `webapiaot`, `.Grpc` for `grpc`, `.Web` for
the others.

```bash
dotnet new <template> -n <Prefix.>ProjectName.<Suffix> -o src/Presentation/<Prefix.>ProjectName.<Suffix>
dotnet new classlib -n <Prefix.>ProjectName.Domain -o src/Domain/<Prefix.>ProjectName.Domain
dotnet new sln --format sln -n <Prefix.>SolutionName -o src
dotnet sln src/<Prefix.>SolutionName.sln add src/Presentation/<Prefix.>ProjectName.<Suffix>/<Prefix.>ProjectName.<Suffix>.csproj
dotnet sln src/<Prefix.>SolutionName.sln add src/Domain/<Prefix.>ProjectName.Domain/<Prefix.>ProjectName.Domain.csproj
dotnet add src/Presentation/<Prefix.>ProjectName.<Suffix>/<Prefix.>ProjectName.<Suffix>.csproj reference src/Domain/<Prefix.>ProjectName.Domain/<Prefix.>ProjectName.Domain.csproj
```

## Shape

- The `.sln` lives in `src/`, never at the root, and is created with `--format sln` — modern SDKs
  default to `.slnx`.
- DDD layout: create `src/Application/` and `src/Infrastructure/` as **empty directories** with a
  `.gitkeep` each. No Application or Infrastructure `.csproj`, no `Commands/`, `Queries/` or
  `Entities/` subfolders — the user adds those as the project grows.
- `tests/` stays empty (`.gitkeep`). No `dotnet new xunit` unprompted — **create-unit-tests** adds
  the first test project when there is something to test.
- Library kinds (`classlib`, NuGet library): add `<Version>0.1.0</Version>` (or the starting
  version the user names) to the csproj's `<PropertyGroup>` — `dotnet new classlib` writes none, and
  the CONTRIBUTING text and the library branch policy both read it.
- Strip template samples the user didn't ask for: `Class1.cs` in a `classlib`, the
  `WeatherForecast` endpoint or controller and the `.http` file in a `webapi`. Keep what the app
  needs to start.

Shared-file overrides: `.editorconfig` and `.gitignore` come from `templates/dotnet/`.

## README fill-ins

- **Requirements:** `- .NET <SDK major> or later`.
- **Usage:** an application → `dotnet run --project src/<path to the startable project>`; a NuGet
  library → `dotnet add package <PackageId>`; a plain class library → how to reference it.

## CONTRIBUTING fill-ins

- **Prerequisites:** `- [.NET SDK <SDK major>](https://dotnet.microsoft.com/download) or later`
- **Build:**

  ````markdown
  ```bash
  dotnet build src/<Prefix.>SolutionName.sln
  ```
  ````

- **Testing:**

  ````markdown
  Tests live under `tests/`, one test project per project under test, and are written with xUnit. Every test is named
  with the Given / When / Then pattern (`GivenSomeCondition_WhenSomeAction_ThenSomeOutput`), and every test class carries
  a `Category` trait — `[Trait("Category", "Unit")]` or `[Trait("Category", "Functional")]` — so the two kinds can be run,
  and reported, separately:

  ```bash
  dotnet test src/<Prefix.>SolutionName.sln --filter "Category=Unit"
  dotnet test src/<Prefix.>SolutionName.sln --filter "Category=Functional"
  ```

  Unit tests exercise the code in isolation against test doubles; functional tests exercise it end to end.
  ````

- **VersionFile** (library variant): ``the `<Version>` in `src/<path>/<Project>.csproj` ``

## Branch policy (library variant)

- `__VERSION_FILE__` → the csproj path, e.g. `src/Acme.Orders/Acme.Orders.csproj`
- `__VERSION_PATTERN__` → `<Version>\K[^<]+`

## Verify

```bash
dotnet build src/<Prefix.>SolutionName.sln
```

There are no tests yet; say so rather than running an empty `dotnet test`. A NuGet library adds the
pack check from `references/dotnet-nuget-library.md`.

## Red flags

- "I'll add Application and Infrastructure class libraries too" → NO. Only Domain is a project; the
  other two are empty folders.
- "`.slnx` is the modern default" → NO. `--format sln`.
- "I'll create a test project while I'm at it" → NO. `tests/` is empty until there is something to
  test.
- "The solution name doesn't need the prefix" → if the user gave one, it goes on the solution too.
- "I'll forget the project reference, the build passes anyway" → the Domain project is then dead
  weight. Add `dotnet add … reference …` in DDD mode.
