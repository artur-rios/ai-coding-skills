# Package Versions

Versions are **discovered at scaffold time**, never carried in this skill. A
pinned list here is stale the week after it is written, and a stale
`Directory.Packages.props` fails restore in a way that looks like the user's
fault.

## Discovering a version

The flat-container index lists every published version of a package, oldest
first:

```bash
curl -s https://api.nuget.org/v3-flatcontainer/arturrios.mediator/index.json
```

The id in the URL is **lower-cased**. The response is `{"versions": [...]}`.

Rules for picking from that list:

1. **Skip prerelease** — anything containing `-` (`1.2.0-beta.1`, `10.0.0-rc.2`).
2. **`Microsoft.*` runtime-versioned packages take the highest stable `10.x`,
   and every one of them takes the *same* version.** This covers all EF Core
   packages, `Microsoft.AspNetCore.DataProtection*`, and every
   `Microsoft.Extensions.*`. Resolve `Microsoft.EntityFrameworkCore` first and
   reuse that exact version for its siblings; if a sibling has not published it,
   stop and report rather than mixing.
3. **Everything else takes the highest stable version overall.**
4. **A package that resolves to nothing** — renamed, unlisted, network down —
   is a stop condition. Report which id failed. Never substitute a version you
   remember.

`dotnet package search <id> --exact-match --format json` works too when the SDK
is available; the flat-container URL needs nothing but `curl`.

## Why the unreferenced packages are listed

`Microsoft.EntityFrameworkCore.Relational`, `.Abstractions`, and `.Analyzers`
appear in the props file although no project references them directly. They are
exactly the transitive dependencies that would otherwise sit a patch behind
`Microsoft.EntityFrameworkCore`: `ArturRios.Data.Relational.Core` carries its own
EF Core dependency, so a project referencing `Microsoft.EntityFrameworkCore.Design`
directly resolves one version while a project that only gets EF Core through the
library resolves another, and the two assemblies disagree at compile time
(CS1705). With `CentralPackageTransitivePinningEnabled`, the versions below win
over whatever a dependency asked for, so every assembly sees one EF Core.

**Do not remove them because "nothing references them".** That is the reason
they are there.

## Directory.Packages.props

Written to the repository root. `{{version}}` is what step 1 resolved.

```xml
<Project>
  <!--
    Central package management for every project in the repository — src/, tests/, and tools/.
    A PackageReference names a package; this file alone decides its version.

    Transitive pinning is on, which is what keeps the graph coherent rather than merely tidy: the
    ArturRios.Data.* packages carry their own EntityFrameworkCore dependency, so without it a
    project that references Microsoft.EntityFrameworkCore.Design directly resolves EF Core one patch
    ahead of a project that only gets EF Core through ArturRios.Data.Relational.Core, and the two
    disagree at compile time (CS1705).
  -->
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
    <CentralPackageTransitivePinningEnabled>true</CentralPackageTransitivePinningEnabled>
  </PropertyGroup>
  <!-- The libraries the API's patterns are built on. -->
  <ItemGroup>
    <PackageVersion Include="ArturRios.Data.PostgreSql" Version="{{version}}" />
    <PackageVersion Include="ArturRios.Data.Relational.Core" Version="{{version}}" />
    <PackageVersion Include="ArturRios.Mediator" Version="{{version}}" />
    <PackageVersion Include="ArturRios.Util" Version="{{version}}" />
    <PackageVersion Include="ArturRios.Util.WebApi" Version="{{version}}" />
  </ItemGroup>
  <!--
    EF Core. Relational, Abstractions, and Analyzers are listed although no project references them
    directly: they are exactly the transitive dependencies that would otherwise stay a patch behind
    Microsoft.EntityFrameworkCore and reintroduce the split described above.
  -->
  <ItemGroup>
    <PackageVersion Include="EFCore.NamingConventions" Version="{{version}}" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore" Version="{{version}}" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.Abstractions" Version="{{version}}" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.Analyzers" Version="{{version}}" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.Design" Version="{{version}}" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.Relational" Version="{{version}}" />
  </ItemGroup>
  <!-- Everything else the product depends on. -->
  <ItemGroup>
    <PackageVersion Include="FluentValidation" Version="{{version}}" />
    <PackageVersion Include="Microsoft.AspNetCore.DataProtection" Version="{{version}}" />
    <PackageVersion Include="Microsoft.AspNetCore.DataProtection.EntityFrameworkCore" Version="{{version}}" />
    <PackageVersion Include="Microsoft.Extensions.DependencyInjection.Abstractions" Version="{{version}}" />
    <PackageVersion Include="Microsoft.Extensions.Logging.Abstractions" Version="{{version}}" />
    <PackageVersion Include="Microsoft.IdentityModel.JsonWebTokens" Version="{{version}}" />
    <PackageVersion Include="Serilog" Version="{{version}}" />
    <PackageVersion Include="Serilog.AspNetCore" Version="{{version}}" />
    <PackageVersion Include="Serilog.Sinks.Map" Version="{{version}}" />
    <PackageVersion Include="Swashbuckle.AspNetCore" Version="{{version}}" />
  </ItemGroup>
  <!-- Test-only packages. -->
  <ItemGroup>
    <PackageVersion Include="ArturRios.Util.Test" Version="{{version}}" />
    <PackageVersion Include="Bogus" Version="{{version}}" />
    <PackageVersion Include="Microsoft.NET.Test.Sdk" Version="{{version}}" />
    <PackageVersion Include="Moq" Version="{{version}}" />
    <PackageVersion Include="Testcontainers.PostgreSql" Version="{{version}}" />
    <PackageVersion Include="coverlet.collector" Version="{{version}}" />
    <PackageVersion Include="xunit" Version="{{version}}" />
    <PackageVersion Include="xunit.runner.visualstudio" Version="{{version}}" />
  </ItemGroup>
</Project>
```

## .config/dotnet-tools.json

`dotnet-ef` is a local tool so the Dockerfile's migrations bundle and
`scripts/migrations.py` use one pinned version. Resolve it the same way
(`dotnet-ef` follows the runtime, so take the same 10.x as EF Core):

```bash
dotnet new tool-manifest -o .config
dotnet tool install dotnet-ef --version <the EF Core version>
```

**`-o .config` is required.** On the .NET 10 SDK, a bare `dotnet new tool-manifest`
writes `./dotnet-tools.json` in the current directory, not `.config/dotnet-tools.json`.
Both work for `dotnet tool restore`, which searches up the tree for either — so
the mistake does not surface locally. It surfaces in `docker build`, where the
Dockerfile copies `.config/dotnet-tools.json` explicitly and fails with
`"/.config/dotnet-tools.json": not found`. Put it where the Dockerfile looks.

## Vulnerability floors

`Directory.Packages.props` is also where a security floor goes — a
`PackageVersion` for a package nothing references directly, pinning it above a
known-vulnerable version a dependency would otherwise resolve. Add one with a
comment naming the advisory when `scripts/vulnerabilities.py` reports it, not
speculatively at scaffold time.
