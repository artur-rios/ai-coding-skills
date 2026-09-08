# Observability — Serilog and the health-check vertical

The health checks are the one complete slice the scaffold ships. They are
infrastructure, not a domain sample, but they exercise every layer: query →
handler → output → controller → DI registration → unit test → functional test.

## Application/Query — HealthChecks/IServiceHealthCheck.cs

```csharp
namespace <Prefix>.<Name>.Query.HealthChecks;

/// <summary>
///     A single verifiable dependency of the API. Each implementation reports its own name and
///     whether it is currently reachable. The detailed health check folds every registered check
///     into the aggregate status, so a new dependency (cache, email, external provider, …) is added
///     by registering another implementation — no change to the response contract or to
///     <see cref="Handlers.GetDetailedHealthQueryHandler" />.
/// </summary>
public interface IServiceHealthCheck
{
    /// <summary>Human-readable name of the verified service (e.g. <c>Database</c>).</summary>
    string ServiceName { get; }

    /// <summary>Returns <c>true</c> when the service is reachable, <c>false</c> otherwise.</summary>
    Task<bool> IsHealthyAsync();
}
```

## HealthChecks/HealthStatuses.cs

```csharp
namespace <Prefix>.<Name>.Query.HealthChecks;

/// <summary>
///     Canonical health status strings. Kept as literals — not an enum — so they serialize as
///     <c>"Healthy"</c> / <c>"Unhealthy"</c> without depending on global JSON enum-converter
///     configuration.
/// </summary>
public static class HealthStatuses
{
    public const string Healthy = "Healthy";
    public const string Unhealthy = "Unhealthy";
}
```

## HealthChecks/DatabaseHealthCheck.cs

With no entities yet, the round-trip goes through the context rather than a
repository. Once the first entity exists, switch to
`IAsyncReadOnlyRepository<T>.Query().AnyAsync()` — the same shape everything else
uses — and say so in a comment here.

```csharp
using <Prefix>.<Name>.Data.Configuration;
using Microsoft.EntityFrameworkCore;

namespace <Prefix>.<Name>.Query.HealthChecks;

/// <summary>
///     Verifies the database connection with a trivial round-trip.
/// </summary>
/// <remarks>
///     This is the one class in the codebase that catches. Reporting the fault <em>is</em> this
///     operation's output — the endpoint exists to answer "is the database reachable?", and an
///     exception escaping it would turn a health report into a 500. That is the test for any future
///     catch: allowed only where the caught failure is the result, never where it is an error path.
///     Everything else lets exceptions reach <c>ExceptionMiddleware</c>.
/// </remarks>
public class DatabaseHealthCheck(AppDbContext context) : IServiceHealthCheck
{
    public string ServiceName => "Database";

    public async Task<bool> IsHealthyAsync()
    {
        try
        {
            // Succeeds only if the connection is usable. Once the first entity exists, prefer
            // IAsyncReadOnlyRepository<T>.Query().AnyAsync() — handlers depend on repositories,
            // not on the context.
            return await context.Database.CanConnectAsync();
        }
        catch
        {
            return false;
        }
    }
}
```

Referencing `Data` from `Query` for this one class is the exception the scaffold
makes; when the switch to a repository happens, remove the project reference
again.

Note what the handler above does **not** do: it never throws, and the aggregate
status is computed from returned values. `GetDetailedHealthQueryHandler` returns
`DataOutput<HealthCheckOutput?>` like every other query handler — an unhealthy
dependency is data on a successful envelope, not an error, because the request to
report health succeeded. The controller maps the reported status to 503; see
`references/security.md`.

## Input/DetailedHealthQuery.cs

```csharp
using ArturRios.Mediator.Query;

namespace <Prefix>.<Name>.Query.Input;

/// <summary>
///     Request for the detailed health check. Carries no parameters — the response is derived
///     entirely from the registered service checks. The pagination members inherited from
///     <see cref="BaseQuery" /> are unused.
/// </summary>
public class DetailedHealthQuery : BaseQuery;
```

## Output/ServiceHealthOutput.cs and Output/HealthCheckOutput.cs

```csharp
namespace <Prefix>.<Name>.Query.Output;

/// <summary>Status of one verified service.</summary>
public class ServiceHealthOutput
{
    public string Name { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}
```

```csharp
using ArturRios.Mediator.Query;

namespace <Prefix>.<Name>.Query.Output;

/// <summary>
///     Detailed health check response. Reports the aggregate <see cref="Status" /> — Healthy when
///     every verified service is up, Unhealthy otherwise — and the per-service breakdown. Adding a
///     verification appends an entry rather than changing this contract.
/// </summary>
public class HealthCheckOutput : QueryOutput
{
    public string Status { get; set; } = string.Empty;
    public IEnumerable<ServiceHealthOutput> Services { get; set; } = new List<ServiceHealthOutput>();
}
```

## Handlers/GetDetailedHealthQueryHandler.cs

```csharp
using <Prefix>.<Name>.Query.HealthChecks;
using <Prefix>.<Name>.Query.Input;
using <Prefix>.<Name>.Query.Output;
using ArturRios.Mediator.Query.Interfaces;
using ArturRios.Output;

namespace <Prefix>.<Name>.Query.Handlers;

/// <summary>
///     Runs every registered <see cref="IServiceHealthCheck" />, reports each service's status, and
///     computes the aggregate — Healthy only when all services are up. The set of checks is
///     injected, so new verifications participate without changing this handler.
/// </summary>
public class GetDetailedHealthQueryHandler(IEnumerable<IServiceHealthCheck> healthChecks)
    : IQueryHandlerAsync<DetailedHealthQuery, HealthCheckOutput>
{
    public async Task<DataOutput<HealthCheckOutput?>> HandleAsync(
        DetailedHealthQuery query, CancellationToken cancellationToken = default)
    {
        var services = new List<ServiceHealthOutput>();

        foreach (var check in healthChecks)
        {
            var healthy = await check.IsHealthyAsync();

            services.Add(new ServiceHealthOutput
            {
                Name = check.ServiceName,
                Status = healthy ? HealthStatuses.Healthy : HealthStatuses.Unhealthy
            });
        }

        // Any unhealthy service makes the whole API unhealthy.
        var aggregate = services.TrueForAll(service => service.Status == HealthStatuses.Healthy)
            ? HealthStatuses.Healthy
            : HealthStatuses.Unhealthy;

        return DataOutput<HealthCheckOutput?>.New.WithData(new HealthCheckOutput
        {
            Status = aggregate,
            Services = services
        });
    }
}
```

## Input/Validation/PaginatedQueryValidator.cs

Nothing derives from it yet; it is here because every list query the first
feature writes will.

```csharp
using <Prefix>.<Name>.Shared.Messages;
using ArturRios.Mediator.Query;
using FluentValidation;

namespace <Prefix>.<Name>.Query.Input.Validation;

/// <summary>
///     Shared pagination rules for every paginated list query: <c>PageNumber</c> at least 1, and
///     <c>PageSize</c> within <see cref="MaxPageSize" />. Concrete query validators derive from this
///     and add their own filter-length rules — FluentValidation accumulates rules added by both the
///     base and derived constructors into the same rule set.
/// </summary>
public abstract class PaginatedQueryValidator<TQuery> : AbstractValidator<TQuery> where TQuery : BaseQuery
{
    /// <summary>
    ///     Upper bound on <c>PageSize</c>. Matches <see cref="BaseQuery" />'s own default, so a
    ///     caller who never sets it is always within bounds.
    /// </summary>
    protected const int MaxPageSize = 100;

    protected PaginatedQueryValidator()
    {
        RuleFor(query => query.PageNumber)
            .GreaterThanOrEqualTo(1)
            .WithMessage(PaginationMessages.InvalidPageNumber);

        RuleFor(query => query.PageSize)
            .InclusiveBetween(1, MaxPageSize)
            .WithMessage(PaginationMessages.InvalidPageSize);
    }
}
```

## Serilog

Configured before anything else in `Startup.Build`, so a failure during
configuration loading is still logged. Console gets JSON so a container log
aggregator can parse it; the file sink is partitioned by year/month via
`Serilog.Sinks.Map` and rolls daily inside each partition.

```csharp
private const string LogDirectoryEnvironmentVariable = "<NAME>_LOG_DIRECTORY";
private const string DefaultLogDirectory = "logs";

private static void ConfigureLogging()
{
    var logDirectory = Environment.GetEnvironmentVariable(LogDirectoryEnvironmentVariable)
                       ?? DefaultLogDirectory;

    Log.Logger = new LoggerConfiguration()
        .WriteTo.Console(new JsonFormatter())
        .WriteTo.Map(
            keySelector: logEvent => logEvent.Timestamp.ToString("yyyy'/'MM"),
            configure: (yearMonth, sink) => sink.File(
                new JsonFormatter(),
                Path.Combine(logDirectory, yearMonth, "log-.json"),
                rollingInterval: RollingInterval.Day))
        .CreateLogger();
}
```

`Builder.Host.UseSerilog()` immediately after, so the framework's own logging
goes to the same place.
