# Presentation — Security and the health-check controller

## Domain/Enums/Roles.cs

The one thing the Domain project ships. Values are explicit and stable: they are
written as `Role` row ids by the seeder and compared as foreign keys, so
renumbering them silently reassigns everyone's authority.

```csharp
using System.ComponentModel;

namespace <Prefix>.<Name>.Domain.Enums;

public enum Roles
{
    [Description("The system administrator, with full access")]
    SystemAdmin = 1,

    [Description("Regular user")]
    User = 2
}
```

Add roles the API actually needs. Two is the floor — a role that gates
administration and a role that does not.

## The authenticated caller

The scaffold writes no identity class of its own. The non-generic
`AddTokenAuthentication` (see below) attaches an `AuthenticatedUser(Guid Id, int RoleId)`
record to the request, and `HttpContext.GetUser()` returns it as
`IAuthenticatedUser`. `Id` is the caller's **public** identifier: internal bigint
ids never leave the data layer, so a token that carried one would leak row counts
to anyone who decoded it.

Read the caller with the **non-generic** `GetUser()`. `GetUser<TUser>()` is a plain
`as TUser` cast, so with the default mapper `GetUser<MyIdentityUser>()` is always
`null` — every caller would look anonymous. The generic form is only for an API
that registers its own mapper (below) whose `FromClaims` returns that type.

## No custom claims mapper — and no token issuer

The scaffold writes **neither**. The non-generic
`AddTokenAuthentication(options => …)` already registers
`DefaultAuthenticatedUserMapper`, which maps `IAuthenticatedUser.Id` and
`.RoleId` through `TokenClaimKeys.Id` / `TokenClaimKeys.RoleId` in both
directions. That is exactly what the scaffold needs, and a hand-written mapper
that only restates it is a class whose sole contribution is a chance to write a
claim under one name and read it under another.

Two things follow, and both are worth stating in `docs/conventions.md`:

- **A custom mapper is a later decision.** When the token has to carry more than
  id and role, implement `IAuthenticatedUserMapper` — `ToClaims(IAuthenticatedUser)`,
  `FromClaims(IReadOnlyDictionary<string, string>)`, `IdFromClaims(…)`, all
  keyed by claim name — and switch to the generic
  `AddTokenAuthentication<TMapper>(…)`. One implementation owns both directions.
- **Token issuing belongs with the first authentication feature.** There is no
  login endpoint yet, so there is nothing for an issuer to serve. When one
  arrives, mint through `JwtHandler.CreateToken(JwtConfiguration)` with the
  claims dictionary keyed by the same `TokenClaimKeys` the mapper reads.

**Verify this against the resolved `ArturRios.Util.WebApi` before writing any of
it** — the interface and its members have changed across major versions:

```bash
grep -o 'name="[TMP]:ArturRios.Util.WebApi.Security[^"]*"'   ~/.nuget/packages/arturrios.util.webapi/<version>/lib/net10.0/*.xml
```

## Security/HttpContextActorAccessor.cs

The Presentation-side implementation of `IActorAccessor` (declared in Shared).
It is how the Application layer reads the caller without referencing ASP.NET
Core types.

```csharp
using <Prefix>.<Name>.Shared.Security;
using ArturRios.Util.WebApi.Security.Extensions;
using ArturRios.Util.WebApi.Security.Interfaces;

namespace <Prefix>.<Name>.WebApi.Security;

/// <summary>
///     Reads the authenticated caller off the current request. Returns nulls for an anonymous
///     request rather than throwing — an anonymous caller is a legitimate state, not a failure.
/// </summary>
public class HttpContextActorAccessor(IHttpContextAccessor accessor) : IActorAccessor
{
    private IAuthenticatedUser? Actor => accessor.HttpContext?.GetUser();

    public Guid? ActingPersonId => Actor?.Id;

    public int? ActingRole => Actor?.RoleId;
}
```

## Security/ActorExtensions.cs

```csharp
using <Prefix>.<Name>.Shared.Security;
using ArturRios.Util.WebApi.Security.Extensions;

namespace <Prefix>.<Name>.WebApi.Security;

/// <summary>
///     Bridges the authenticated caller on the request to the actor-scoped commands and queries
///     whose authorization depends on who is acting.
/// </summary>
public static class ActorExtensions
{
    /// <summary>
    ///     Copies the authenticated caller onto an actor-scoped command or query, so the handler can
    ///     enforce caller-dependent authorization. The acting fields are always taken from the token,
    ///     never from the request.
    /// </summary>
    public static void ApplyActor(this HttpContext httpContext, IActorScoped actorScoped)
    {
        var actor = httpContext.GetUser()!;

        actorScoped.ActingPersonId = actor.Id;
        actorScoped.ActingRole = actor.RoleId;
    }
}
```

## Controllers/HealthCheckController.cs

The only controller. It is also the reference shape for every controller the
first feature writes: thin, dispatching through a mediator, resolving the
response through `ToActionResult`, declaring authorization with an attribute.

```csharp
using <Prefix>.<Name>.Domain.Enums;
using <Prefix>.<Name>.Query.HealthChecks;
using <Prefix>.<Name>.Query.Input;
using <Prefix>.<Name>.Query.Output;
using ArturRios.Mediator.Query;
using ArturRios.Output;
using ArturRios.Util.Http;
using ArturRios.Util.WebApi.AspNetCore;
using ArturRios.Util.WebApi.Security.Attributes;
using Microsoft.AspNetCore.Mvc;

namespace <Prefix>.<Name>.WebApi.Controllers;

[Route("[controller]")]
public class HealthCheckController(QueryMediator queryMediator) : Controller
{
    /// <summary>
    ///     Basic liveness check: confirms the API process is up and responding. Public — no
    ///     authentication required.
    /// </summary>
    [HttpGet]
    [Route("")]
    [AllowAnonymous]
    public ActionResult<DataOutput<string?>> HelloWorld()
    {
        var result = DataOutput<string?>.New
            .WithData("Hello world!")
            .WithMessage("<Name> API is working.");

        return result.ToActionResult(HttpStatusCodes.Ok);
    }

    /// <summary>
    ///     Detailed health check: reports the status of each verified service plus an aggregate
    ///     general status. Restricted to System Admins. Returns <c>200 OK</c> when healthy and
    ///     <c>503 Service Unavailable</c> when any verified service is down.
    /// </summary>
    [HttpGet]
    [Route("detailed")]
    [RoleRequirement((int)Roles.SystemAdmin)]
    public async Task<ActionResult<DataOutput<HealthCheckOutput?>>> Detailed()
    {
        var result = await queryMediator
            .ExecuteQueryAsync<DetailedHealthQuery, HealthCheckOutput>(new DetailedHealthQuery());

        var statusCode = result.Data?.Status == HealthStatuses.Healthy
            ? HttpStatusCodes.Ok
            : HttpStatusCodes.ServiceUnavailable;

        return result.ToActionResult(statusCode);
    }
}
```

Two things to carry forward from it:

- **Authorization that a role attribute can decide is declared at the door.**
  Anything data-dependent — "does this caller own that record?" — belongs in the
  handler, which is the only place that can read the data.
- **`result.ToActionResult(statusMap: …)`** is the normal form once
  an entity has a message map. The health controller passes an explicit status
  because its two outcomes are not a message-driven decision.
