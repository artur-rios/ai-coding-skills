# Tests

Two suites, separated by trait rather than by project: `[UnitFact]` /
`[UnitTheory]` and `[FunctionalFact]` from `ArturRios.Util.Test` set
`Category=Unit` / `Category=Functional`, so `dotnet test --filter` picks a suite
without any per-project configuration.

## Naming

`GivenSomeCondition_WhenSomeAction_ThenSomeOutcome`. Bodies are commented
`// Given`, `// When`, `// Then` when the sections are not obvious from the
shape.

## Assert on envelopes, not on thrown exceptions

Handlers return outcomes, so a failure test asserts on what came back:

```csharp
Assert.False(output.Success);
Assert.Contains(ThingMessages.ThingNotFound, output.Errors);
```

`Assert.ThrowsAsync` in a handler test is a sign the handler throws for a
business rule, which this codebase does not do — fix the handler, not the test.
Functional tests assert the status the message map produces (404, 409, 403),
which is the same rule seen from the other end.

## Project files

Every test project: `net10.0`, `Nullable`, `ImplicitUsings`,
`<IsPackable>false</IsPackable>`, a `<Using Include="Xunit"/>`, and:

```xml
  <ItemGroup>
    <PackageReference Include="ArturRios.Util.Test" />
    <PackageReference Include="Bogus" />
    <PackageReference Include="Moq" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" />
    <PackageReference Include="xunit" />
    <PackageReference Include="coverlet.collector">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <PackageReference Include="xunit.runner.visualstudio">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
  </ItemGroup>
```

`WebApi.Tests` additionally references `Testcontainers.PostgreSql` and needs
this target — without it the suite silently runs against a developer's local
database:

```xml
  <!--
    The Web API copies Environments\.env* to its output, and content items with
    CopyToOutputDirectory flow transitively into ours. The configuration loader would then load a
    developer's .env.local and overwrite the container connection string PostgresFixture publishes,
    silently pointing the whole functional suite at a real local database. Functional tests are
    configured only by the fixture, so drop the inherited files.
  -->
  <Target Name="RemoveInheritedEnvironmentFiles" AfterTargets="Build">
    <ItemGroup>
      <InheritedEnvironmentFiles Include="$(OutDir)Environments\.env*"/>
    </ItemGroup>
    <Delete Files="@(InheritedEnvironmentFiles)"/>
  </Target>
```

## tests/Directory.Build.props

A runsettings file does nothing until a test run is pointed at it. This props
file points every test project at it — every test project lives under `tests/`
and no production project does, so nothing under `src/` is affected:

```xml
<Project>
  <PropertyGroup>
    <RunSettingsFilePath>$(MSBuildThisFileDirectory)default.runsettings</RunSettingsFilePath>
  </PropertyGroup>
</Project>
```

## tests/default.runsettings

Enables the trx logger, so an intermittent failure names itself instead of
vanishing with the log — and the tests workflow's `**/TestResults/*.trx` upload
has something to upload. `ResultsDirectory` stays at its default, each project's
own `TestResults/`, so projects running concurrently cannot overwrite each other's
results.

```xml
<?xml version="1.0" encoding="utf-8"?>
<RunSettings>
  <LoggerRunSettings>
    <Loggers>
      <Logger friendlyName="trx" enabled="True" />
    </Loggers>
  </LoggerRunSettings>
</RunSettings>
```

## Support/PostgresFixture.cs

Starts one throwaway PostgreSQL container for the whole functional suite,
migrates it, and publishes the environment the API under test reads at startup.
Everything the API refuses to start without is set here.

```csharp
using <Prefix>.<Name>.Data.Configuration;
using <Prefix>.<Name>.Data.Seeding;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Testcontainers.PostgreSql;

namespace <Prefix>.<Name>.WebApi.Tests.Support;

/// <summary>
///     Starts a throwaway PostgreSQL container once for the whole functional suite, applies the EF
///     migrations to it, and exposes its connection string, so functional tests run end-to-end
///     against a real database that closely matches production. Shared via
///     <see cref="FunctionalCollection" /> so the container is created once, not per test class.
/// </summary>
public sealed class PostgresFixture : IAsyncLifetime
{
    private const string ConnectionStringVariable = "<NAME>_DATA_CONNECTIONSTRING";
    private const string DatabaseTypeVariable = "<NAME>_DATA_DATABASETYPE";
    private const string TokenSecretVariable = "<NAME>_AUTH_TOKEN_SECRET";
    private const string PreviousTokenSecretVariable = "<NAME>_AUTH_TOKEN_SECRET_PREVIOUS";
    private const string TokenIssuerVariable = "<NAME>_AUTH_TOKEN_ISSUER";
    private const string TokenAudienceVariable = "<NAME>_AUTH_TOKEN_AUDIENCE";

    /// <summary>
    ///     The retired signing secret the host under test still accepts, so the suite can prove a
    ///     token signed before a rotation keeps working. Published here rather than in a test
    ///     because the API reads its key material once, at start-up: a test that set this afterwards
    ///     would be configuring a host that had already decided which keys it accepts.
    /// </summary>
    public const string PreviousTokenSecret = "functional-tests-previous-signing-secret";

    public const string TokenSecret = "functional-tests-signing-secret-key";
    public const string TokenIssuer = "<name>-tests";
    public const string TokenAudience = "<name>-tests";

    private readonly PostgreSqlContainer _container = new PostgreSqlBuilder("postgres:16-alpine").Build();

    /// <summary>The connection string of the running container's database.</summary>
    public string ConnectionString => _container.GetConnectionString();

    public async Task InitializeAsync()
    {
        await _container.StartAsync();

        // Point the API under test at the container instead of a developer's local database.
        Environment.SetEnvironmentVariable(ConnectionStringVariable, ConnectionString);
        Environment.SetEnvironmentVariable(DatabaseTypeVariable, "PostgreSql");

        // Startup refuses to boot without a signing secret, since an empty one makes every request
        // fail inside the token validator. These values are for tests only.
        Environment.SetEnvironmentVariable(TokenSecretVariable, TokenSecret);

        // Configuring the previous key here means every functional test runs against a host that
        // accepts two keys, so the ordinary suite doubles as proof that doing so breaks nothing.
        Environment.SetEnvironmentVariable(PreviousTokenSecretVariable, PreviousTokenSecret);
        Environment.SetEnvironmentVariable(TokenIssuerVariable, TokenIssuer);
        Environment.SetEnvironmentVariable(TokenAudienceVariable, TokenAudience);

        // The seeder warns when the master user is not configured; set it so the log stays clean.
        Environment.SetEnvironmentVariable(MasterUserOptions.NameVariable, "Master User");
        Environment.SetEnvironmentVariable(MasterUserOptions.EmailVariable, "master@<name>.test");
        Environment.SetEnvironmentVariable(MasterUserOptions.PasswordVariable, "Str0ng-Master-Pass!");

        // The API refuses to start against a schema with pending migrations, so apply them here.
        await using var context = CreateContext();

        await context.Database.MigrateAsync();
    }

    /// <summary>
    ///     Creates a context bound to the container, for tests that assert on database state
    ///     directly rather than through the API.
    /// </summary>
    public AppDbContext CreateContext() => new(
        new DbContextOptionsBuilder<AppDbContext>().UseNpgsql(ConnectionString).Options,
        NullLoggerFactory.Instance,
        DbContextDiagnosticsOptions.Disabled);

    public Task DisposeAsync() => _container.DisposeAsync().AsTask();
}
```

`MigrateAsync()` applies the initial migration the scaffold created, so the
container carries the Data Protection key-ring table the API expects — and every
later migration lands here automatically.

## Support/FunctionalCollection.cs

```csharp
namespace <Prefix>.<Name>.WebApi.Tests.Support;

/// <summary>
///     xUnit collection that shares a single <see cref="PostgresFixture" /> across every functional
///     test class, so the PostgreSQL container is started once for the suite. Apply
///     <c>[Collection(nameof(FunctionalCollection))]</c> to functional test classes to join it.
/// </summary>
[CollectionDefinition(nameof(FunctionalCollection))]
public sealed class FunctionalCollection : ICollectionFixture<PostgresFixture>;
```

## Support/TestTokens.cs

Mints a bearer token for a role, signed with the secret the fixture published and
carrying the claim names the registered mapper reads. Build the claims through
`TokenClaimKeys` rather than string literals — that constant is the one thing
keeping the token the suite mints and the token the API validates in agreement.

```csharp
using ArturRios.Jwt;
using ArturRios.Util.WebApi.Security.Constants;

namespace <Prefix>.<Name>.WebApi.Tests.Support;

/// <summary>
///     Mints bearer tokens for the functional suite, signed with the secret
///     <see cref="PostgresFixture" /> publishes and carrying the claim names
///     <c>DefaultAuthenticatedUserMapper</c> reads.
/// </summary>
public static class TestTokens
{
    /// <summary>A token for a caller holding <paramref name="roleId" /> and an arbitrary identity.</summary>
    public static string ForRole(int roleId) => For(Guid.NewGuid(), roleId);

    /// <summary>A token for a specific caller — use this once tests seed their own identities.</summary>
    public static string For(Guid publicId, int roleId)
    {
        var configuration = new JwtConfiguration(
            3600,
            PostgresFixture.TokenIssuer,
            PostgresFixture.TokenAudience,
            PostgresFixture.TokenSecret,
            new Dictionary<string, string>
            {
                [TokenClaimKeys.Id] = publicId.ToString(),
                [TokenClaimKeys.RoleId] = roleId.ToString()
            });

        return new JwtHandler().CreateToken(configuration);
    }
}
```

`ArturRios.Jwt` arrives transitively through `ArturRios.Util.WebApi`, so the test
project needs no extra `PackageReference` for it.

`ForRole` invents a GUID, which is fine while nothing looks the caller up. Once
the API grows a filter that rejects a token naming an identity that does not
exist, it has to name a seeded stand-in instead. Note that in
`docs/conventions.md`, because it is the kind of change that silently breaks every
existing test at once.

## The two health-check tests

`tests/Application/<Prefix>.<Name>.Query.Tests/GetDetailedHealthQueryHandlerTests.cs`
— a unit test with mocked checks, no database:

```csharp
public class GetDetailedHealthQueryHandlerTests
{
    [UnitFact]
    public async Task GivenAllChecksHealthy_WhenHandled_ThenAggregateIsHealthy() { /* … */ }

    [UnitFact]
    public async Task GivenOneCheckUnhealthy_WhenHandled_ThenAggregateIsUnhealthy() { /* … */ }
}
```

`tests/Presentation/<Prefix>.<Name>.WebApi.Tests/HealthCheckTests.cs` — the
functional test, against the real container:

```csharp
using System.Net;
using <Prefix>.<Name>.Domain.Enums;
using <Prefix>.<Name>.Query.HealthChecks;
using <Prefix>.<Name>.Query.Output;
using <Prefix>.<Name>.WebApi.Tests.Support;
using ArturRios.Configuration.Enums;
using ArturRios.Output;
using ArturRios.Util.Test.Attributes;
using ArturRios.Util.Test.Functional;

namespace <Prefix>.<Name>.WebApi.Tests;

// Joining the collection is what matters here: xUnit initializes the collection fixture before
// constructing any test class in it, so the container is running and migrated by the time the base
// constructor boots the API and reads the connection details the fixture publishes.
[Collection(nameof(FunctionalCollection))]
public class HealthCheckTests() : WebApiTest<Program>(EnvironmentType.Local)
{
    private const string HealthCheckRoute = "/HealthCheck";
    private const string DetailedHealthCheckRoute = "/HealthCheck/detailed";

    [FunctionalFact]
    public async Task GivenApiWorking_WhenHealthCheckEndpointCalled_ThenEndpointReturnsOk()
    {
        var output = await Gateway.GetAsync<DataOutput<string>>(HealthCheckRoute);

        Assert.Equal(HttpStatusCode.OK, output.StatusCode);
        Assert.Equal("Hello world!", output.Body?.Data);
    }

    [FunctionalFact]
    public async Task GivenSystemAdmin_WhenDetailedHealthCheckCalled_ThenReturnsHealthy()
    {
        // Given
        Authorize(TestTokens.ForRole((int)Roles.SystemAdmin));

        // When
        var output = await Gateway.GetAsync<DataOutput<HealthCheckOutput>>(DetailedHealthCheckRoute);

        // Then — the database is up (Testcontainers), so the aggregate and the Database service are Healthy
        Assert.Equal(HttpStatusCode.OK, output.StatusCode);
        Assert.Equal(HealthStatuses.Healthy, output.Body!.Data!.Status);

        var database = Assert.Single(output.Body.Data.Services);
        Assert.Equal("Database", database.Name);
        Assert.Equal(HealthStatuses.Healthy, database.Status);
    }

    [FunctionalFact]
    public async Task GivenNonSystemAdmin_WhenDetailedHealthCheckCalled_ThenForbidden()
    {
        Authorize(TestTokens.ForRole((int)Roles.User));

        var output = await Gateway.GetAsync<DataOutput<HealthCheckOutput>>(DetailedHealthCheckRoute);

        Assert.Equal(HttpStatusCode.Forbidden, output.StatusCode);
    }

    [FunctionalFact]
    public async Task GivenNoToken_WhenDetailedHealthCheckCalled_ThenUnauthorized()
    {
        var output = await Gateway.GetAsync<DataOutput<HealthCheckOutput>>(DetailedHealthCheckRoute);

        Assert.Equal(HttpStatusCode.Unauthorized, output.StatusCode);
    }
}
```

These four are the proof that the wiring works: routing, the mediator, DI, the
role attribute, the token pipeline, EF Core against a real PostgreSQL, and the
response envelope. If they pass, the scaffold is sound.

## The other four test projects

`Domain.Tests`, `Command.Tests`, `Shared.Tests`, and `Data.Tests` are created,
referenced, and left empty apart from a `.gitkeep`. Delete the template's
`UnitTest1.cs`. They exist so the first feature has somewhere obvious to put its
tests, and so the solution-wide filter already covers every layer.
