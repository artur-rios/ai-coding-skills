# Application — Shared

Namespace `<Prefix>.<Name>.Shared`. This project holds what Command and Query
both need and neither owns: the canonical message vocabulary, the message →
HTTP status maps, and the actor abstractions. It references no other project.

## Messages/DataAccessMessageMap.cs

The persistence layer classifies its failures into a small set of fixed,
caller-safe strings (`RelationalErrors`). Folding them into every use case's map
is what makes a lost unique-index race answer 409 instead of the resolver's 400
default.

```csharp
using ArturRios.Data.Relational.Core.Repositories;
using ArturRios.Util.Http;

namespace <Prefix>.<Name>.Shared.Messages;

/// <summary>
///     HTTP status codes for the failures the persistence layer classifies, folded into every use
///     case's own map so a repository failure answers with a status that describes it.
/// </summary>
/// <remarks>
///     Only the classified failures are listed. <see cref="RelationalErrors.GenericMessage" /> is
///     deliberately absent: it covers everything the library could not place, which spans both
///     causes the caller can fix (a value longer than its column, when a validator failed to bound
///     it) and causes only the operator can, so neither 400 nor 500 is right for all of it. It keeps
///     the resolver's 400 default, the safer of the two — a 500 would tell a caller their request
///     was blameless when it may not have been.
/// </remarks>
public static class DataAccessMessageMap
{
    private static readonly IReadOnlyDictionary<string, int> StatusCodes = new Dictionary<string, int>
    {
        // A write lost a race against a unique index — the state the caller asked for conflicts with
        // state that already exists, which is exactly 409.
        [RelationalErrors.UniqueViolationMessage] = HttpStatusCodes.Conflict,

        // A foreign key, NOT NULL, or CHECK the request would have broken. Also a conflict with
        // existing state rather than a malformed request.
        [RelationalErrors.IntegrityViolationMessage] = HttpStatusCodes.Conflict,

        // Someone else changed the row between the read and the write. The caller's request was
        // valid when they made it and may well succeed on a retry.
        [RelationalErrors.ConcurrencyMessage] = HttpStatusCodes.Conflict,

        // The database is unreachable or overloaded. 503 rather than 500: it says the condition is
        // temporary, which is the one thing a client needs to know to decide whether to retry.
        [RelationalErrors.TransientMessage] = HttpStatusCodes.ServiceUnavailable
    };

    /// <summary>
    ///     Combines a use case's own message-to-status map with the persistence failures above. The
    ///     use case's entries win on a collision: a use case owns its own vocabulary, and a map
    ///     assembled here should never be able to override it.
    /// </summary>
    public static IReadOnlyDictionary<string, int> CombinedWith(IReadOnlyDictionary<string, int> useCaseStatusCodes)
    {
        var combined = new Dictionary<string, int>(StatusCodes);

        foreach (var (message, statusCode) in useCaseStatusCodes)
        {
            combined[message] = statusCode;
        }

        return combined;
    }
}
```

## Messages/PaginationMessages.cs

```csharp
namespace <Prefix>.<Name>.Shared.Messages;

/// <summary>
///     Canonical messages for the pagination/filter validation shared by every paginated list
///     query. Reused across every entity's list query rather than duplicated per entity, since the
///     rule itself — page number at least 1, page size within a bounded range, filter strings within
///     the length of the column they search — does not vary by entity.
/// </summary>
public static class PaginationMessages
{
    /// <summary><c>PageNumber</c> was less than 1.</summary>
    public const string InvalidPageNumber = "Page number must be at least 1.";

    /// <summary>
    ///     <c>PageSize</c> was less than 1 or greater than the maximum allowed page size. The upper
    ///     bound exists so a caller cannot force an unbounded query merely by asking for it.
    /// </summary>
    public const string InvalidPageSize = "Page size must be between 1 and 100.";

    /// <summary>
    ///     A free-text filter exceeded the length of the column it searches — such a filter could
    ///     never match a row, so it is rejected as malformed rather than executed.
    /// </summary>
    public const string FilterTooLong = "Filter value is longer than the field it searches.";
}
```

## The per-entity message pair — convention, not a file

Each entity gets `<Entity>Messages` (every user-facing string as a `const`) and
`<Entity>MessageMap` (each of those mapped to a status, built with
`DataAccessMessageMap.CombinedWith`). Nothing is scaffolded here; the shape is
stated in `docs/conventions.md`:

```csharp
public static class ThingMessageMap
{
    public static readonly IReadOnlyDictionary<string, int> StatusCodes =
        DataAccessMessageMap.CombinedWith(new Dictionary<string, int>
        {
            [ThingMessages.ThingCreatedSuccessfully] = HttpStatusCodes.Created,
            [ThingMessages.ThingNotFound] = HttpStatusCodes.NotFound,
            [ThingMessages.NameAlreadyExists] = HttpStatusCodes.Conflict,
            [PaginationMessages.InvalidPageNumber] = HttpStatusCodes.BadRequest,
            [PaginationMessages.InvalidPageSize] = HttpStatusCodes.BadRequest,
            [PaginationMessages.FilterTooLong] = HttpStatusCodes.BadRequest
        });
}
```

## Security/IActorAccessor.cs

```csharp
namespace <Prefix>.<Name>.Shared.Security;

/// <summary>
///     Reads the authenticated caller without the Application layer depending on Presentation-layer
///     types. Unlike <see cref="IActorScoped" />, this is resolved by the infrastructure (from the
///     request) rather than populated by a controller onto a command.
/// </summary>
public interface IActorAccessor
{
    /// <summary>The acting caller's public identifier, or <c>null</c> for an anonymous request.</summary>
    Guid? ActingPersonId { get; }

    /// <summary>The acting caller's role value, or <c>null</c> for an anonymous request.</summary>
    int? ActingRole { get; }
}
```

## Security/IActorScoped.cs

```csharp
namespace <Prefix>.<Name>.Shared.Security;

/// <summary>
///     A command or query whose authorization depends on the acting caller. The controller populates
///     these fields from the authenticated user — never from the request — so the handler can
///     enforce caller-dependent rules.
/// </summary>
public interface IActorScoped
{
    /// <summary>
    ///     The acting caller's public identifier, taken from their token. Internal <c>bigint</c> ids
    ///     never leave the data layer, so authorization compares public identifiers.
    /// </summary>
    Guid ActingPersonId { get; set; }

    /// <summary>The acting caller's role value.</summary>
    int ActingRole { get; set; }
}
```

Mark both properties `[JsonIgnore]` on every command or query that implements
`IActorScoped`. `ModelBindingConfiguration` (see `references/startup.md`) turns
that attribute into a non-bindable property, which is what stops a caller from
supplying their own actor in the query string.
