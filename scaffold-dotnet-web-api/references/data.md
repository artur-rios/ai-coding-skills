# Infrastructure — Data

Namespace `<Prefix>.<Name>.Data`. `<NAME>` is the env-var prefix, `<name>` the
schema name.

## Configuration/DbContextDiagnosticsOptions.cs

```csharp
namespace <Prefix>.<Name>.Data.Configuration;

/// <summary>
///     Controls the EF Core diagnostics that expose data values in logs and exception messages.
///     Both flags default to <c>false</c>, so an environment we fail to classify is treated as
///     production and leaks nothing.
/// </summary>
public sealed class DbContextDiagnosticsOptions
{
    /// <summary>Diagnostics fully disabled — the production-safe default.</summary>
    public static readonly DbContextDiagnosticsOptions Disabled = new();

    /// <summary>Whether query parameter values — password hashes, salts, e-mails — may be logged.</summary>
    public bool SensitiveDataLogging { get; init; }

    /// <summary>Whether column values may be included in EF exception messages.</summary>
    public bool DetailedErrors { get; init; }
}
```

## Configuration/AppDbContext.cs

`BaseDbContext` comes from `ArturRios.Data.Relational.Core`. The context starts
with **no entity `DbSet`s** except the Data Protection key ring — the first
feature adds the first one.

```csharp
using ArturRios.Data.Relational.Core.Configuration;
using Microsoft.AspNetCore.DataProtection.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace <Prefix>.<Name>.Data.Configuration;

public class AppDbContext(
    DbContextOptions options,
    ILoggerFactory loggerFactory,
    DbContextDiagnosticsOptions diagnostics) : BaseDbContext(options), IDataProtectionKeyContext
{
    private const string Schema = "<name>";

    // Entity DbSets go here, one per domain entity, each configured by its own *DbMap
    // in OnModelCreating below.

    /// <summary>
    ///     ASP.NET Core's Data Protection key ring, kept in the database rather than on a local
    ///     filesystem (<see cref="IDataProtectionKeyContext" />).
    /// </summary>
    /// <remarks>
    ///     Not a domain table, and the only one here that no entity map configures — its shape
    ///     belongs to Data Protection. It is in this context because the keys have to outlive the
    ///     container and be reachable from every instance: anything the application encrypts at rest
    ///     with Data Protection becomes undecryptable if the key ring is lost or not shared, and the
    ///     default is a directory on the local filesystem, which the image does not persist and two
    ///     instances do not share.
    /// </remarks>
    public DbSet<DataProtectionKey> DataProtectionKeys { get; init; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        optionsBuilder
            .UseLoggerFactory(loggerFactory)
            .UseSnakeCaseNamingConvention()
            .EnableDetailedErrors(diagnostics.DetailedErrors)
            .EnableSensitiveDataLogging(diagnostics.SensitiveDataLogging);
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema(Schema);

        // modelBuilder.Entity<Thing>().Configure();  ← one line per entity map
    }
}
```

## Configuration/DesignTimeDbContextFactory.cs

```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Logging.Abstractions;

namespace <Prefix>.<Name>.Data.Configuration;

/// <summary>
///     Builds an <see cref="AppDbContext" /> for the EF Core command-line tools, which have no
///     access to the application's dependency-injection container. The connection string comes from
///     <c><NAME>_DATA_CONNECTIONSTRING</c>; <c>scripts/migrations.py</c> loads it from the selected
///     environment file before invoking <c>dotnet ef</c>. Diagnostics are disabled — design time
///     never needs them, and the tools may well be pointed at production.
/// </summary>
public class DesignTimeDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
{
    private const string ConnectionStringVariable = "<NAME>_DATA_CONNECTIONSTRING";

    public AppDbContext CreateDbContext(string[] args)
    {
        var connectionString = Environment.GetEnvironmentVariable(ConnectionStringVariable);

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                $"Environment variable '{ConnectionStringVariable}' is unset. Run scripts/migrations.py, " +
                "which loads it from the environment file you select, or set it manually before " +
                "invoking dotnet ef.");
        }

        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql(connectionString)
            .Options;

        return new AppDbContext(options, NullLoggerFactory.Instance, DbContextDiagnosticsOptions.Disabled);
    }
}
```

## Seeding/MasterUserOptions.cs

```csharp
namespace <Prefix>.<Name>.Data.Seeding;

/// <summary>
///     Credentials for the master system administrator, read from the <c><NAME>_MASTER_USER_*</c>
///     environment variables. They are used only when the database holds no system administrator
///     yet — see <see cref="DatabaseSeeder" />.
/// </summary>
public sealed record MasterUserOptions(string Name, string Email, string Password)
{
    public const string NameVariable = "<NAME>_MASTER_USER_NAME";
    public const string EmailVariable = "<NAME>_MASTER_USER_EMAIL";
    public const string PasswordVariable = "<NAME>_MASTER_USER_PASSWORD";

    /// <summary>Whether all three values are present, so a master user could be created.</summary>
    public bool IsComplete =>
        !string.IsNullOrWhiteSpace(Name) &&
        !string.IsNullOrWhiteSpace(Email) &&
        !string.IsNullOrWhiteSpace(Password);

    public static MasterUserOptions FromEnvironment() => new(
        Environment.GetEnvironmentVariable(NameVariable) ?? string.Empty,
        Environment.GetEnvironmentVariable(EmailVariable) ?? string.Empty,
        Environment.GetEnvironmentVariable(PasswordVariable) ?? string.Empty);
}
```

## Seeding/DatabaseSeeder.cs

Runs on every startup and is idempotent. With no domain yet it refuses to run
against a schema that is behind, and warns when the master-user credentials are
absent. The `Role`-row and system-admin blocks arrive with the first feature that
has entities to write; leave the guard in place so that feature fills a body
rather than inventing the shape.

`masterUser` is consumed by `WarnIfMasterUserIncomplete` rather than left for
later. An unread primary-constructor parameter is **CS9113**, and a scaffold that
ships with a warning teaches whoever reads it next that warnings are normal
here.

```csharp
using System.ComponentModel;
using <Prefix>.<Name>.Data.Configuration;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace <Prefix>.<Name>.Data.Seeding;

/// <summary>
///     Brings a migrated database to the state the application assumes. Idempotent, so it runs on
///     every startup. It never applies migrations — that is <c>scripts/migrations.py</c>'s job, or
///     the container entrypoint's — and refuses to seed a schema that is behind.
/// </summary>
public class DatabaseSeeder(
    AppDbContext context,
    MasterUserOptions masterUser,
    ILogger<DatabaseSeeder> logger)
{
    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        await EnsureSchemaIsUpToDateAsync(cancellationToken);

        WarnIfMasterUserIncomplete();

        // Add EnsureRolesAsync / EnsureSystemAdminAsync here once the entities exist.
    }

    /// <summary>
    ///     Says so at startup when the master-user variables are unset. Once there is an entity to
    ///     write, this becomes the guard on seeding the first system administrator; until then it is
    ///     what tells an operator their configuration is incomplete before the first login fails.
    /// </summary>
    private void WarnIfMasterUserIncomplete()
    {
        if (masterUser.IsComplete)
        {
            return;
        }

        logger.LogWarning(
            "Master user is not fully configured ({Name} / {Email} / {Password}); no system "
            + "administrator will be seeded",
            MasterUserOptions.NameVariable,
            MasterUserOptions.EmailVariable,
            MasterUserOptions.PasswordVariable);
    }

    /// <summary>
    ///     Fails fast when the database is behind the code. Starting against a stale schema produces
    ///     an unrelated error on the first query instead of naming the actual problem.
    /// </summary>
    private async Task EnsureSchemaIsUpToDateAsync(CancellationToken cancellationToken)
    {
        var pending = (await context.Database.GetPendingMigrationsAsync(cancellationToken)).ToList();

        if (pending.Count == 0)
        {
            return;
        }

        var names = string.Join(", ", pending);

        logger.LogCritical("Database is behind by {Count} migration(s): {Migrations}", pending.Count, names);

        throw new InvalidOperationException(
            $"The database is missing {pending.Count} migration(s): {names}. Apply them with " +
            "scripts/migrations.py before starting the API.");
    }
}
```

## EntityMaps/ — the convention, not a file

Empty, with a `.gitkeep`. Each entity gets one `internal static class
<Entity>DbMap` exposing a `Configure` extension on
`EntityTypeBuilder<TEntity>`, called from `OnModelCreating`. This is the shape
the first feature copies — it is stated in `docs/conventions.md`:

```csharp
internal static class ThingDbMap
{
    public static void Configure(this EntityTypeBuilder<Thing> thing)
    {
        thing.ToTable("thing");
        thing.HasKey(x => x.Id);

        thing.Property(x => x.PublicId).IsRequired();
        thing.HasIndex(x => x.PublicId).IsUnique();

        thing.Property(x => x.IsDeleted).HasDefaultValue(false);
        thing.Property(x => x.CreatedAt).HasDefaultValueSql("now()");
        thing.Property(x => x.UpdatedAt).HasDefaultValueSql("now()");

        // Relationships are configured from the dependent side's own map.
    }
}
```

`UseSnakeCaseNamingConvention()` on the context means column names follow from
the property names; `ToTable` is explicit anyway so a rename in code cannot
silently rename a table.

## Migrations/ — create the initial one

The scaffold **does** create a first migration, and it is not an empty one. The
context declares `DataProtectionKeys`, and `Startup` registers
`AddDataProtection().PersistKeysToDbContext<AppDbContext>()`, so the table has to
exist before the key ring is first written. Skipping it produces a scaffold that
builds, tests green, and then fails the first time Data Protection persists a
key — the worst kind of failure, because nothing in the suite touches that path.

```bash
<NAME>_DATA_CONNECTIONSTRING="Host=localhost;Port=5432;Database=<name>;Username=postgres;Password=postgres"   dotnet ef migrations add InitialCreate     --project src/Infrastructure/<Prefix>.<Name>.Data     --startup-project src/Infrastructure/<Prefix>.<Name>.Data
```

The connection string is a placeholder — nothing connects while a migration is
generated. The result creates the schema and `data_protection_keys`, and nothing
else. Every migration after it comes from `python scripts/migrations.py`.
