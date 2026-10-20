# docs/conventions.md — template

Write this into the generated repository, substituting the project's own names.
It is the only place the per-feature pattern is recorded, since the scaffold
ships no sample slice. Keep it in the repository, not in the skill: the project
will outgrow this skill.

---

```markdown
# Conventions

How a feature is built in this codebase. Read this before adding one.

The scaffold ships no domain: no entities and no commands, and the only
migration is the one creating the Data Protection key ring. The only complete
vertical slice is the health check — query → handler → output → controller →
registration → tests — and it is the shape everything else follows.

## Layers

| Project | Holds |
| --- | --- |
| `<Prefix>.<Name>.Domain` | Entities and enums. Entities are anemic (data + navigation) unless a behaviour is genuinely domain logic. |
| `<Prefix>.<Name>.Command` | Write use cases: `*Command` (extends `BaseCommand`), `Input/Validation/*Validator` (FluentValidation), `*CommandHandler` (`ICommandHandlerAsync<TCommand, TOutput>`), `Output/*CommandOutput`. |
| `<Prefix>.<Name>.Query` | Read use cases: `*Query` (extends `BaseQuery`), `*QueryHandler` (`IQueryHandlerAsync` / `IPaginatedQueryHandlerAsync`), `Output/*Output`. |
| `<Prefix>.<Name>.Shared` | Canonical message strings and their HTTP status maps; the actor abstractions. |
| `<Prefix>.<Name>.Data` | `AppDbContext`, one `*DbMap` per entity, migrations, seeding. |
| `<Prefix>.<Name>.WebApi` | Controllers, security, DI registration in `Startup.AddDependencies`. |

Dependencies point inwards: `Command` and `Query` know `Domain` and `Shared`;
`Data` knows `Domain`; `WebApi` knows all four. Nothing points back. (The
scaffold's one exception, `Query` → `Data` for `DatabaseHealthCheck`, is
temporary: switch it to a repository and drop the reference with the first
entity.)

## The shape of one write use case

Adding "create a thing" means adding, in this order:

1. `Domain/Entities/Thing.cs` — extends `Entity<long>`, carries a `PublicId` GUID, an
   `IsDeleted` flag if it is soft-deletable, `CreatedAt` / `UpdatedAt`.
2. `Data/EntityMaps/ThingDbMap.cs` — `ToTable`, key, the unique index on
   `PublicId`, defaults, and any index that holds an invariant. Register it in
   `AppDbContext.OnModelCreating` and add the `DbSet`.
3. A migration, through `python scripts/migrations.py`. **Never** edit the
   database by hand, and never migrate on startup.
4. `Shared/Messages/ThingMessages.cs` — every user-facing string as a `const`,
   one per outcome, including each failure.
5. `Shared/Messages/ThingMessageMap.cs` — each of those mapped to a status, built
   with `DataAccessMessageMap.CombinedWith`.
6. `Command/Input/CreateThingCommand.cs` — extends `BaseCommand`. Properties the
   server populates (route ids, the acting caller) are `[JsonIgnore]`.
7. `Command/Input/Validation/CreateThingCommandValidator.cs` — shape only:
   required fields, and the lengths the columns impose, so an overlong value is
   a named 400 rather than an unclassified data-access failure. Business rules
   that need data access belong in the handler.
8. `Command/Output/CreateThingCommandOutput.cs` — extends `CommandOutput`.
   `PublicId`s only.
9. `Command/Handlers/CreateThingCommandHandler.cs`.
10. `WebApi/Controllers/ThingController.cs` — one thin action.
11. Registration in `Startup.AddDependencies` — the validator and the handler,
    explicitly.
12. Tests: a unit test per handler branch, a functional test per endpoint
    outcome.

A read use case is the same list without steps 4–9's write half: query,
optional validator (always one for a paginated list), output, handler,
controller action, registration, tests.

## Rules that are not negotiable

**Errors are values, not exceptions.** Every outcome a caller can provoke — not
found, already exists, not allowed, invalid input, precondition unmet — is
returned on an output envelope. `Success` is derived: it is `true` exactly when
`Errors` is empty, so adding an error *is* how failure is signalled.

Pick the envelope by what the operation returns. All three are in
`ArturRios.Output`:

| Returns | Envelope |
|---|---|
| nothing — a delete, a toggle, a command with no payload | `DataOutput<TOutput?>` with an empty `*CommandOutput` — the mediator's handler interfaces always return `DataOutput`; `ProcessOutput` is for code outside the mediator |
| one resource | `DataOutput<T>` |
| a listing | `PaginatedOutput<T>` |

Failures use `output.AddError(...)` / `output.WithErrors(...)` with a `const`
from the entity's `*Messages`; success uses
`output.WithData(...).WithMessage(...)`. The message is what selects the HTTP
status, so a string typed inline rather than referenced from `*Messages` silently
falls through to the resolver's 400 default.

```csharp
var thing = await reader.Query().FirstOrDefaultAsync(x => x.PublicId == command.Id);

if (thing is null)
{
    return output.WithError(ThingMessages.ThingNotFound);   // → 404 via ThingMessageMap
}
```

**Nothing in the request path catches.** Handlers, controllers, services and
repositories contain no `try`/`catch`. A genuine exception — a bug, a dependency
that broke its contract — propagates to `ExceptionMiddleware`, which logs it and
writes the same JSON envelope every other failure uses. A `catch` here either
swallows a defect or re-encodes it as a worse message than the middleware would
produce, and costs the stack trace.

Two things still throw, and neither is an exception to the rule:

- **Startup misconfiguration** — a missing signing secret, an unset connection
  string, a schema behind its migrations. No request is in flight and no envelope
  has a reader, so failing fast is the only way the problem is seen at all.
- **`DatabaseHealthCheck`** — the one sanctioned `catch` in the codebase, because
  reporting the fault *is* the operation's output. That is the test for any
  future one: catch only where the caught failure is the result, never where it
  is an error path.

`CustomException(string[] messages)` — abstract, so a throw derives its own
exception from it — exists for a throw that must carry caller-safe text to the
middleware. Reaching for it in a handler means the
outcome belonged on an envelope.

**Repositories, not `DbContext`, in handlers.** Depend on
`IAsyncReadOnlyRepository<T, long>` for reads and `IAsyncRepository<T, long>` for writes, and
use `.Query()` with EF Core LINQ. This is also what makes handlers unit-testable
with `AsyncFakeRepository<T, long>` (the async fake — `FakeRepository<T, long>` backs the
synchronous interfaces).

**Public ids out, internal ids in.** Inputs, outputs, and routes use `PublicId`
(GUID). Foreign keys and joins use the internal `Id` (bigint). An internal id
never leaves the data layer — it leaks row counts and creation order.

**Controllers are thin.** Bind input, dispatch through `CommandMediator` /
`QueryMediator`, return `result.ToActionResult(statusMap: …)`. Nothing
else. Authorization a role attribute can decide is declared at the door with
`[RoleRequirement((int)Roles.X)]` or `[AllowAnonymous]`; authorization that
depends on data — "does this caller own that record?" — belongs in the handler,
which is the only place that can read it.

**Register dependencies explicitly.** No assembly scanning. A missing validator
should break the build's DI graph, not a request in production.

**Comparisons on names and e-mails are case-insensitive** (`.ToLower()` on both
sides, which becomes `LOWER()` in SQL), and every paginated listing has a
deterministic total order — a tiebreaker after the sort key. Without one,
PostgreSQL is free to break a tie differently on each page's query, so a row can
appear on two pages and another on none.

## Documentation comments

Every handler, command, output, message class, and controller action carries an
XML doc comment saying what it does and why. Handler steps are commented with the
rule they implement. The controllers' comments are not decoration: they are the
source of the published OpenAPI document.

## Tests

Named `GivenSomeCondition_WhenSomeAction_ThenSomeOutcome`.

- **Unit** — `[UnitFact]` / `[UnitTheory]`, `AsyncFakeRepository<T, long>`, Moq, Bogus.
  One per handler branch, including every failure. Assert on the returned
  envelope — `Assert.False(output.Success)` and the expected `*Messages` const in
  `output.Errors`. A test written with `Assert.ThrowsAsync` is testing behaviour
  this codebase does not have.
- **Functional** — `[FunctionalFact]`, `WebApiTest<Program>`, the shared
  `PostgresFixture` container. Assert both the response and the resulting
  database state. Every endpoint gets its authorization outcomes covered: no
  token → 401, wrong role → 403.

```bash
dotnet test src/<Prefix>.<Name>.sln --filter "Category=Unit"
dotnet test src/<Prefix>.<Name>.sln --filter "Category=Functional"   # needs Docker
```

## After changing a controller

Regenerate the OpenAPI document, or CI fails:

```bash
python scripts/openapi.py
```
```
