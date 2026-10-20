# Layout, Projects, and the Solution

`<Prefix>.<Name>` is the full project prefix (e.g. `ArturRios.Heimdall`), or just
`<Name>` when the user gave no prefix. `<NAME>` is the env-var prefix, `<name>`
the lower-cased schema/image name.

## Directory tree

```
.config/dotnet-tools.json
.github/workflows/{tests,check-openapi,build-docs,branch-policy}.yml
api-client/
  http/{healthcheck.http,http-client.env.json}
  bruno/{bruno.json,collection.bru,environments/Local.bru,Health/*.bru}
  README.md
docker/{entrypoint.sh,local.env.example,development.env.example,production.env.example}
docs/
  conventions.md
  hugo.toml
  archetypes/default.md
  assets/scss/_styles_project.scss
  content/en/{_index.md,docs/_index.md,docs/overview.md,docs/getting-started.md,
              docs/architecture.md,docs/api-explorer.md,docs/operations.md,
              docs/changelog/_index.md,docs/contributing/_index.md}
  layouts/_shortcodes/repo-file.html
  openapi/.gitkeep
  themes/docsy/                       git submodule
scripts/{migrations.py,coverage.py,openapi.py,vulnerabilities.py,test_migrations.py,test_vulnerabilities.py}
src/
  <Prefix>.<Name>.sln
  Domain/<Prefix>.<Name>.Domain/
    Entities/.gitkeep
    Enums/Roles.cs
  Application/
    <Prefix>.<Name>.Command/
      Handlers/.gitkeep  Input/.gitkeep  Input/Validation/.gitkeep
      Output/.gitkeep    Services/.gitkeep
    <Prefix>.<Name>.Query/
      Handlers/GetDetailedHealthQueryHandler.cs
      HealthChecks/{IServiceHealthCheck.cs,DatabaseHealthCheck.cs,HealthStatuses.cs}
      Input/DetailedHealthQuery.cs
      Input/Validation/PaginatedQueryValidator.cs
      Output/{HealthCheckOutput.cs,ServiceHealthOutput.cs}
    <Prefix>.<Name>.Shared/
      Messages/{DataAccessMessageMap.cs,PaginationMessages.cs}
      Security/{IActorAccessor.cs,IActorScoped.cs}
  Infrastructure/<Prefix>.<Name>.Data/
    Configuration/{AppDbContext.cs,DbContextDiagnosticsOptions.cs,DesignTimeDbContextFactory.cs}
    EntityMaps/.gitkeep
    Migrations/.gitkeep
    Seeding/{DatabaseSeeder.cs,MasterUserOptions.cs}
  Presentation/<Prefix>.<Name>.WebApi/
    Program.cs  Startup.cs
    Binding/ModelBindingConfiguration.cs
    Controllers/HealthCheckController.cs
    Documentation/SwaggerConfiguration.cs
    Environments/.env.example
    Properties/launchSettings.json
    Security/{HttpContextActorAccessor.cs,ActorExtensions.cs}
    Settings/appsettings.json
tests/
  Directory.Build.props          applies default.runsettings to every test project
  default.runsettings
  Domain/<Prefix>.<Name>.Domain.Tests/
  Application/<Prefix>.<Name>.Command.Tests/
  Application/<Prefix>.<Name>.Query.Tests/GetDetailedHealthQueryHandlerTests.cs
  Application/<Prefix>.<Name>.Shared.Tests/
  Infrastructure/<Prefix>.<Name>.Data.Tests/
  Presentation/<Prefix>.<Name>.WebApi.Tests/
    HealthCheckTests.cs
    Support/{PostgresFixture.cs,FunctionalCollection.cs,TestTokens.cs}
tools/<Prefix>.<Name>.OpenApiGen/{Program.cs,<Prefix>.<Name>.OpenApiGen.csproj}
Directory.Packages.props  Dockerfile  docker-compose.yml
.editorconfig  .gitattributes  .gitignore  .dockerignore
README.md  CHANGELOG.md  CONTRIBUTING.md  LICENSE
```

`tools/` is deliberately **outside** the solution: it references the WebApi to
read its Swagger configuration, and including it would make every solution-wide
`dotnet test` build a console app nothing tests.

## Project reference graph

```
Domain      → (nothing)
Shared      → (nothing)
Command     → Domain, Shared
Query       → Domain, Shared, Data*
Data        → Domain
WebApi      → Command, Query, Shared, Data
OpenApiGen  → WebApi
```

`*` Query → Data is a **scaffold-only** edge. `DatabaseHealthCheck` needs
something to round-trip against, and with no entities there is no repository to
inject, so it takes `AppDbContext` directly. The moment the first entity exists,
switch that class to `IAsyncReadOnlyRepository<T, long>` and drop the reference —
handlers depend on repositories, not on the context. Say so in a comment on the
`ProjectReference` itself, not only in the class.

Test projects reference their subject; `WebApi.Tests` references `WebApi`.

## Creating them

```bash
# Source projects
dotnet new classlib -n <Prefix>.<Name>.Domain  -o src/Domain/<Prefix>.<Name>.Domain
dotnet new classlib -n <Prefix>.<Name>.Command -o src/Application/<Prefix>.<Name>.Command
dotnet new classlib -n <Prefix>.<Name>.Query   -o src/Application/<Prefix>.<Name>.Query
dotnet new classlib -n <Prefix>.<Name>.Shared  -o src/Application/<Prefix>.<Name>.Shared
dotnet new classlib -n <Prefix>.<Name>.Data    -o src/Infrastructure/<Prefix>.<Name>.Data
dotnet new webapi --use-controllers -n <Prefix>.<Name>.WebApi -o src/Presentation/<Prefix>.<Name>.WebApi

# Test projects
dotnet new xunit -n <Prefix>.<Name>.Domain.Tests  -o tests/Domain/<Prefix>.<Name>.Domain.Tests
dotnet new xunit -n <Prefix>.<Name>.Command.Tests -o tests/Application/<Prefix>.<Name>.Command.Tests
dotnet new xunit -n <Prefix>.<Name>.Query.Tests   -o tests/Application/<Prefix>.<Name>.Query.Tests
dotnet new xunit -n <Prefix>.<Name>.Shared.Tests  -o tests/Application/<Prefix>.<Name>.Shared.Tests
dotnet new xunit -n <Prefix>.<Name>.Data.Tests    -o tests/Infrastructure/<Prefix>.<Name>.Data.Tests
dotnet new xunit -n <Prefix>.<Name>.WebApi.Tests  -o tests/Presentation/<Prefix>.<Name>.WebApi.Tests

# Tool project (outside the solution)
dotnet new console -n <Prefix>.<Name>.OpenApiGen -o tools/<Prefix>.<Name>.OpenApiGen

# Solution — in src/, classic format
dotnet new sln --format sln -n <Prefix>.<Name> -o src
dotnet sln src/<Prefix>.<Name>.sln add \
  src/Domain/<Prefix>.<Name>.Domain/<Prefix>.<Name>.Domain.csproj \
  src/Application/<Prefix>.<Name>.Command/<Prefix>.<Name>.Command.csproj \
  src/Application/<Prefix>.<Name>.Query/<Prefix>.<Name>.Query.csproj \
  src/Application/<Prefix>.<Name>.Shared/<Prefix>.<Name>.Shared.csproj \
  src/Infrastructure/<Prefix>.<Name>.Data/<Prefix>.<Name>.Data.csproj \
  src/Presentation/<Prefix>.<Name>.WebApi/<Prefix>.<Name>.WebApi.csproj \
  tests/Domain/<Prefix>.<Name>.Domain.Tests/<Prefix>.<Name>.Domain.Tests.csproj \
  tests/Application/<Prefix>.<Name>.Command.Tests/<Prefix>.<Name>.Command.Tests.csproj \
  tests/Application/<Prefix>.<Name>.Query.Tests/<Prefix>.<Name>.Query.Tests.csproj \
  tests/Application/<Prefix>.<Name>.Shared.Tests/<Prefix>.<Name>.Shared.Tests.csproj \
  tests/Infrastructure/<Prefix>.<Name>.Data.Tests/<Prefix>.<Name>.Data.Tests.csproj \
  tests/Presentation/<Prefix>.<Name>.WebApi.Tests/<Prefix>.<Name>.WebApi.Tests.csproj
```

Delete the files the templates generate that this scaffold replaces:
`Class1.cs` from each `classlib`, `UnitTest1.cs` from each `xunit` project, and
the web template's `Program.cs`, `WeatherForecast*`, `Controllers/`,
`appsettings*.json` (`appsettings.json` is rewritten under `Settings/`; the
per-environment files are local and gitignored), and
`<Prefix>.<Name>.WebApi.http`.

## Project files

Central package management means **no `Version` attribute on any
`PackageReference`**. Every project targets `net10.0` with `Nullable` and
`ImplicitUsings` enabled.

### Domain

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="ArturRios.Data.Relational.Core" />
  </ItemGroup>
</Project>
```

### Shared

Same property group; references `ArturRios.Data.Relational.Core` (for
`RelationalErrors`) and `ArturRios.Util` (for `HttpStatusCodes`). No project
references.

### Command

```xml
  <ItemGroup>
    <PackageReference Include="ArturRios.Mediator" />
    <PackageReference Include="ArturRios.Data.Relational.Core" />
    <!-- The handlers return DataOutput<T> / ProcessOutput, so this is a direct dependency even
         though ArturRios.Mediator also brings it. -->
    <PackageReference Include="ArturRios.Output" />
    <PackageReference Include="ArturRios.Util" />
    <PackageReference Include="FluentValidation" />
    <!-- Declared although ArturRios.Data.Relational.Core also brings it: the handlers use
         EntityFrameworkCore's async query operators directly, so it is a real dependency of this
         project rather than an implementation detail of another one. -->
    <PackageReference Include="Microsoft.EntityFrameworkCore" />
    <PackageReference Include="Microsoft.Extensions.DependencyInjection.Abstractions" />
    <PackageReference Include="Microsoft.Extensions.Logging.Abstractions" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\Domain\<Prefix>.<Name>.Domain\<Prefix>.<Name>.Domain.csproj" />
    <ProjectReference Include="..\<Prefix>.<Name>.Shared\<Prefix>.<Name>.Shared.csproj" />
  </ItemGroup>
```

### Query

Same packages as Command — `ArturRios.Output` included, for the same reason —
minus `Microsoft.Extensions.DependencyInjection.Abstractions`. Three project
references — `Domain`, `Shared`, and, with the comment above, `Data`:

```xml
    <!-- Scaffold only: DatabaseHealthCheck takes AppDbContext directly because there is no entity
         yet, and so no repository to inject. Switch that class to IAsyncReadOnlyRepository<T, long> when
         the first entity lands, and drop this reference — handlers depend on repositories. -->
    <ProjectReference Include="..\..\Infrastructure\<Prefix>.<Name>.Data\<Prefix>.<Name>.Data.csproj" />
```

### Data

```xml
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <!-- Lets `dotnet ef` use this class library as its own startup project. -->
    <GenerateRuntimeConfigurationFiles>true</GenerateRuntimeConfigurationFiles>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="ArturRios.Data.PostgreSql" />
    <PackageReference Include="ArturRios.Util" />
    <PackageReference Include="EFCore.NamingConventions" />
    <PackageReference Include="Microsoft.AspNetCore.DataProtection.EntityFrameworkCore" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Design">
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\Domain\<Prefix>.<Name>.Domain\<Prefix>.<Name>.Domain.csproj" />
  </ItemGroup>
```

### WebApi

```xml
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <!-- The controllers carry the per-endpoint documentation the published OpenAPI document is
         built from (tools/<Prefix>.<Name>.OpenApiGen); without the XML file those summaries never
         leave the source. CS1591 is off because the target is the controllers, which are
         documented — not every public member in the assembly. -->
    <GenerateDocumentationFile>true</GenerateDocumentationFile>
    <NoWarn>$(NoWarn);CS1591</NoWarn>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="ArturRios.Mediator" />
    <!-- The controllers name DataOutput<T> / PaginatedOutput<T> in their action signatures. -->
    <PackageReference Include="ArturRios.Output" />
    <PackageReference Include="ArturRios.Util.WebApi" />
    <!-- Declared although ArturRios.Data.Relational.Core also brings it: this project uses
         EntityFrameworkCore's async query operators directly. -->
    <PackageReference Include="Microsoft.EntityFrameworkCore" />
    <!-- Not Microsoft.AspNetCore.DataProtection: that one ships in the Web SDK's shared framework,
         and referencing it explicitly here is NU1510. This package does not, and Startup calls its
         PersistKeysToDbContext extension directly. -->
    <PackageReference Include="Microsoft.AspNetCore.DataProtection.EntityFrameworkCore" />
    <PackageReference Include="Microsoft.IdentityModel.JsonWebTokens" />
    <PackageReference Include="Serilog" />
    <PackageReference Include="Serilog.AspNetCore" />
    <PackageReference Include="Serilog.Sinks.Map" />
    <PackageReference Include="Swashbuckle.AspNetCore" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\Application\<Prefix>.<Name>.Command\<Prefix>.<Name>.Command.csproj" />
    <ProjectReference Include="..\..\Application\<Prefix>.<Name>.Query\<Prefix>.<Name>.Query.csproj" />
    <ProjectReference Include="..\..\Application\<Prefix>.<Name>.Shared\<Prefix>.<Name>.Shared.csproj" />
    <ProjectReference Include="..\..\Infrastructure\<Prefix>.<Name>.Data\<Prefix>.<Name>.Data.csproj" />
  </ItemGroup>
  <ItemGroup>
    <!-- The configuration loader resolves Environments/.env.<environment> relative to the
         application base path, so the folder must sit next to the built assembly. The Web SDK
         already copies Settings/appsettings*.json via its default **/*.json glob; .env has no
         extension to match, so it needs an explicit item. -->
    <Content Include="Environments\.env*" CopyToOutputDirectory="PreserveNewest" />
  </ItemGroup>
</Project>
```

### OpenApiGen (tools/)

**`Microsoft.NET.Sdk.Web`** with `<OutputType>Exe</OutputType>` — not
`Microsoft.NET.Sdk`. It is a console app, but `WebApplication.CreateBuilder` and
`ISwaggerProvider` need the ASP.NET Core shared framework, which the plain
console SDK does not reference.

```xml
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Swashbuckle.AspNetCore" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\src\Presentation\<Prefix>.<Name>.WebApi\<Prefix>.<Name>.WebApi.csproj" />
  </ItemGroup>
</Project>
```

Not in the solution.
