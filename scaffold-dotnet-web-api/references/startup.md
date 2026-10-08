# Presentation — Program, Startup, and configuration

## Program.cs

The entry point does one thing. Everything else is `Startup`.

```csharp
namespace <Prefix>.<Name>.WebApi;

public class Program
{
    public static void Main(string[] args)
    {
        var app = new Startup(args).CreateApplication();

        app.Run();
    }
}
```

`Program` must be a **named, non-top-level class**: the functional tests boot the
API with `WebApiTest<Program>`, which needs the type.

## Startup.cs

`WebApiStartup` from `ArturRios.Util.WebApi` owns the build sequence. Its
`Build()` — not virtual, and callable once — runs, in this order:

1. `LoadConfiguration`, as the command-line parameters allow:
   `Environments/.env.<Environment>` into the process environment (falling back
   to `.env.local`), and `Settings/appsettings.<Environment>.json` (falling back
   to `appsettings.Local.json`).
2. `AddControllers()`, the invalid-model-state envelope (a 400 carrying a failed
   `DataOutput`), and the Swagger generator — registered only in the
   environments Swagger is allowed in, `Development` and `Local` by default.
3. The derived class's `ConfigureServices(WebApplicationBuilder)`.
4. `Builder.Build()`, then the pipeline: `UseStandardMiddlewares(Options.CorsPolicy)`,
   any `Options.Middlewares`, then `MapControllers()`.

It returns the `WebApplication` (`Run()` / `RunAsync()` are `Build()` plus
running it). Beyond its registrations in `ConfigureServices`, a derived class
has three levers and no others — there is no other step to override: the
`Action<WebApiStartupOptions>` its constructor hands to `base`,
`Options` while `ConfigureServices` runs (that is how CORS is switched on), and
the `WebApplication` that `Build()` returns. It also gets `Builder` and the
parsed command-line `Parameters`.

Two `using`s are easy to miss and both fail at compile time:
`Microsoft.AspNetCore.DataProtection` (that is the namespace
`PersistKeysToDbContext` lives in, even though it ships in the
`…DataProtection.EntityFrameworkCore` package) and `ArturRios.Jwt` for
`JwtConfiguration` / `JwtHandler` / `JwtKey`.

```csharp
using System.Threading.RateLimiting;
using <Prefix>.<Name>.Data.Configuration;
using <Prefix>.<Name>.Data.Seeding;
using <Prefix>.<Name>.Query.Handlers;
using <Prefix>.<Name>.Query.HealthChecks;
using <Prefix>.<Name>.Query.Input;
using <Prefix>.<Name>.Query.Output;
using <Prefix>.<Name>.Shared.Security;
using <Prefix>.<Name>.WebApi.Binding;
using <Prefix>.<Name>.WebApi.Documentation;
using <Prefix>.<Name>.WebApi.Security;
using ArturRios.Data.PostgreSql;
using ArturRios.Data.Relational.Core.DependencyInjection;
using ArturRios.Jwt;
using ArturRios.Mediator.Command;
using ArturRios.Mediator.Query;
using ArturRios.Mediator.Query.Interfaces;
using ArturRios.Util.WebApi.Configuration;
using ArturRios.Util.WebApi.Security.Enums;
using ArturRios.Util.WebApi.Security.Extensions;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.RateLimiting;
using Serilog;
using Serilog.Formatting.Json;

namespace <Prefix>.<Name>.WebApi;

/// <summary>
///     Builds the API on Util.WebApi's standard sequence: configuration, controllers, the
///     invalid-model-state envelope and Swagger, then <see cref="ConfigureServices" />, then the
///     standard pipeline and the controllers.
/// </summary>
/// <remarks>
///     What the standard pipeline has no slot for goes around it: the developer exception page and
///     HTTPS redirection ahead of it, through <see cref="EdgePipeline" />; rate limiting after it, in
///     <see cref="CreateApplication" />. Call <see cref="CreateApplication" />, not <c>Build</c>, to
///     get a complete API.
/// </remarks>
public class Startup : WebApiStartup
{
    private const string LogDirectoryEnvironmentVariable = "<NAME>_LOG_DIRECTORY";
    private const string DefaultLogDirectory = "logs";

    private const string TokenAudienceEnvironmentVariable = "<NAME>_AUTH_TOKEN_AUDIENCE";
    private const string TokenExpirationEnvironmentVariable = "<NAME>_AUTH_TOKEN_EXPIRATION_IN_SECONDS";
    private const string TokenIssuerEnvironmentVariable = "<NAME>_AUTH_TOKEN_ISSUER";
    private const string TokenSecretEnvironmentVariable = "<NAME>_AUTH_TOKEN_SECRET";
    private const string PreviousTokenSecretEnvironmentVariable = "<NAME>_AUTH_TOKEN_SECRET_PREVIOUS";
    private const double DefaultTokenExpirationInSeconds = 3600;

    private const string CorsAllowedOriginsEnvironmentVariable = "<NAME>_CORS_ALLOWED_ORIGINS";
    private const string CorsPolicyName = "<Name>FrontEnds";

    /// <summary>
    ///     Rate-limiting policy name applied with <c>[EnableRateLimiting(AnonymousEndpointRateLimitPolicy)]</c>
    ///     to anonymous, credential-checking endpoints. Public so the controllers and this
    ///     configuration stay in sync without duplicating the literal.
    /// </summary>
    public const string AnonymousEndpointRateLimitPolicy = "Anonymous";

    public Startup(string[] args) : base(args, ConfigureStandardSequence)
    {
        // Before anything else, so every later step has somewhere to log. LoadConfiguration has not
        // run yet — Build runs it — which is why ConfigureLogging reads its settings straight from
        // the process environment (see references/observability.md).
        ConfigureLogging();
        Builder.Host.UseSerilog();

        Log.Information("Building web api on {Environment} environment", Builder.Environment.EnvironmentName);
    }
```

### The standard sequence's options

```csharp
    /// <summary>
    ///     Tunes the parts of the standard sequence this API does not take as they come.
    /// </summary>
    private static void ConfigureStandardSequence(WebApiStartupOptions options)
    {
        // Swagger is described by SwaggerConfiguration alone — the same method the OpenApiGen tool
        // applies to produce docs/openapi/<name>.json, so the published page and the running API's are
        // one document. Swagger.JwtAuthentication is deliberately left false: SwaggerConfiguration
        // defines the "Bearer" scheme itself, and the library's own definition, added after this
        // callback with AddSecurityDefinition, throws on the duplicate key — and since the Swagger
        // middleware resolves the generator on every request, every request then answers 500
        // wherever Swagger is registered.
        options.Swagger.ConfigureGenerator = SwaggerConfiguration.Configure;

        // Both are the library's defaults, set here all the same because they are a decision about
        // personal data rather than a technicality: every request's log entry carries the client IP
        // address, and the request's activity is tagged with it as client.address. Turn them off here,
        // not by accident.
        options.TraceActivity.LogClientIp = true;
        options.TraceActivity.TagClientAddress = true;
    }
```

### CreateApplication — what `Build` has no slot for

```csharp
    /// <summary>
    ///     Builds the API and completes it: <c>Build</c>'s standard sequence, then rate limiting, then
    ///     the database seed — so nothing is served before the schema is known to be current.
    /// </summary>
    public WebApplication CreateApplication()
    {
        var app = Build();

        // After the standard pipeline, because it has no slot for it. Rate limiting still sees the
        // endpoint — WebApplication routes ahead of every middleware it is given — and still runs
        // before MVC: the endpoint itself is always the last step, however late this is added. The
        // rate-limited endpoints are anonymous, so AuthenticationMiddleware passes them through to
        // this point rather than spending anything on them first.
        app.UseRateLimiter();

        SeedDatabase(app);

        Log.Information("Ready to run!");

        return app;
    }
```

### The pipeline — the order is the library's

Nothing in `Startup` arranges middleware by hand. The order is fixed by
Util.WebApi's `UseStandardMiddlewares`, and the two additions sit outside it:

| # | Step | Added by |
|---|---|---|
| 1 | Developer exception page (`Local` / `Development` only), forwarded headers, HTTPS redirection | `EdgePipeline`, an `IStartupFilter` — it wraps the whole pipeline, so it runs first |
| 2 | Routing — the endpoint is selected here, so everything below can read its metadata | `WebApplication`, implicitly |
| 3 | Forwarded headers — a no-op until `ForwardedHeadersOptions` names a trusted proxy | `UseStandardMiddlewares` |
| 4 | `TraceActivityMiddleware` — the request's activity and its log entry | `UseStandardMiddlewares` |
| 5 | `ExceptionMiddleware` | `UseStandardMiddlewares` |
| 6 | Swagger JSON and UI — only where the generator was registered, never in Production | `UseStandardMiddlewares` |
| 7 | CORS, with the policy named in `Options.CorsPolicy` — absent when none is named | `UseStandardMiddlewares` |
| 8 | `AuthenticationMiddleware` — present only because `AddTokenAuthentication` registered its options | `UseStandardMiddlewares` |
| 9 | Rate limiter | `CreateApplication` |
| 10 | Controllers, with `[RoleRequirement]` as an MVC authorization filter | `Build` (`MapControllers`) |

What the order buys, and why none of it needs hand-placing any more:

- **`ExceptionMiddleware` is the codebase's only exception handler.** Nothing in
  the request path catches, so a bug or a broken dependency reaches it, gets
  logged with its stack trace, and is written as the same JSON envelope every
  other failure uses. Business outcomes never arrive as exceptions — those are
  errors on a returned `ProcessOutput` / `DataOutput<T>` / `PaginatedOutput<T>`,
  which `ToActionResult` maps to a status. It sits ahead of Swagger, CORS and
  authentication, so a failure in any of them still answers the envelope rather
  than a bare 500.
- **Swagger and CORS come before authentication.** `AuthenticationMiddleware`
  also exempts the Swagger routes itself (when Swagger is registered) and every
  endpoint marked `[AllowAnonymous]`, so the UI loads in a browser that has no
  way to send a bearer token, and a CORS preflight is answered without one.
- **No ASP.NET Core authentication or authorization middleware.** Nothing here
  reads `HttpContext.User` or carries ASP.NET Core's `[Authorize]`; the
  controllers use the library's attributes, which read the user
  `AuthenticationMiddleware` attaches. `AddAuthentication`, `UseAuthentication`
  and `UseAuthorization` would be a second, unused authentication stack.
- **Swagger is not exposed in production.** Util.WebApi registers the generator
  only in the environments it allows, and in Production it registers nothing at
  all — the OpenApiGen tool is what publishes the document for readers who are
  not running the API.

### ConfigureServices

Runs after `LoadConfiguration`, so every `Environment.GetEnvironmentVariable`
below already sees the `.env` file's values.

```csharp
    protected override void ConfigureServices(WebApplicationBuilder builder)
    {
        ConfigureWebApi();
        AddDependencies();

        builder.Services.AddSingleton<IStartupFilter>(new EdgePipeline(builder.Environment));

        ConfigureSecurity();
        ConfigureCors();
    }
```

### EdgePipeline

```csharp
    /// <summary>
    ///     The middlewares that must run ahead of the standard pipeline. A startup filter is how they
    ///     get there: ASP.NET Core wraps the application's whole pipeline in it, so what it adds runs
    ///     before anything <c>Build</c> adds.
    /// </summary>
    private sealed class EdgePipeline(IWebHostEnvironment environment) : IStartupFilter
    {
        public Action<IApplicationBuilder> Configure(Action<IApplicationBuilder> next) => app =>
        {
            // Local is included alongside Development because it is what a developer machine runs:
            // the configuration loader resolves Environments/.env.<environment>, so the launch
            // profiles name Local to reach .env.local. Testing IsDevelopment() alone would silently
            // cost the developer exception page in the one environment that exists to have it.
            if (environment.IsDevelopment() || environment.IsEnvironment("Local"))
            {
                app.UseDeveloperExceptionPage();
            }

            // Ahead of HTTPS redirection, which decides on the scheme: behind a TLS-terminating proxy
            // every request arrives as http, and only X-Forwarded-Proto says the caller used https.
            // A no-op until ForwardedHeadersOptions names the trusted proxy; the standard pipeline runs
            // it again later, which then changes nothing.
            app.UseForwardedHeaders();

            app.UseHttpsRedirection();

            next(app);
        };
    }
```

### ConfigureWebApi

```csharp
    private void ConfigureWebApi()
    {
        // The standard sequence has already called AddControllers(); calling it again adds this
        // configuration to the same MVC registration.
        Builder.Services.AddControllers(options =>
        {
            // Also applied by tools/<Prefix>.<Name>.OpenApiGen, which builds its own
            // AddControllers() rather than running this Startup — so a removal here cannot be
            // caught by that call site. Without it, [FromQuery] properties marked server-populated
            // become bindable from the query string again.
            ModelBindingConfiguration.Configure(options);
        });

        Builder.Services.AddEndpointsApiExplorer();
    }
```

Global MVC filters go in this same lambda as the application grows — an
authorization guard, a liveness check on the acting identity, an exception
filter that maps a saturated resource to 503. None is scaffolded, because each
needs a domain to guard.

### AddDependencies

The only registrations the scaffold makes. Every later feature adds its
validator, command handler, and query handler here **explicitly** — no assembly
scanning: it hides a missing validator until runtime.

```csharp
    private void AddDependencies()
    {
        // EF diagnostics expose parameter and column values — password hashes, salts, e-mails — so
        // they stay off in production.
        var diagnosticsEnabled = !Builder.Environment.IsProduction();

        Builder.Services.AddSingleton(new DbContextDiagnosticsOptions
        {
            SensitiveDataLogging = diagnosticsEnabled,
            DetailedErrors = diagnosticsEnabled
        });

        Builder.Services.AddPostgreSqlProvider();
        Builder.Services.AddDataConfigFromEnvironment<AppDbContext>("<NAME>_DATA");

        Builder.Services.AddScoped<CommandMediator>();
        Builder.Services.AddScoped<QueryMediator>();

        Builder.Services.AddHttpContextAccessor();
        Builder.Services.AddScoped<IActorAccessor, HttpContextActorAccessor>();

        // Command handlers and their validators are registered here, one pair per use case:
        //   Builder.Services.AddScoped<IValidator<CreateThingCommand>, CreateThingCommandValidator>();
        //   Builder.Services.AddScoped<ICommandHandlerAsync<CreateThingCommand, CreateThingCommandOutput>,
        //                              CreateThingCommandHandler>();
        // Query handlers likewise, with IQueryHandlerAsync / IPaginatedQueryHandlerAsync.

        // Health checks. Each IServiceHealthCheck is one verified dependency; the detailed handler
        // resolves them all as IEnumerable, so a new check is added by registering another.
        Builder.Services.AddScoped<IServiceHealthCheck, DatabaseHealthCheck>();
        Builder.Services
            .AddScoped<IQueryHandlerAsync<DetailedHealthQuery, HealthCheckOutput>, GetDetailedHealthQueryHandler>();

        // The Data Protection key ring goes in the database and the application name is fixed,
        // because the default is neither durable nor shared: keys land in a directory the image does
        // not persist and a second instance does not see, and anything encrypted with them silently
        // becomes undecryptable.
        Builder.Services.AddDataProtection()
            .PersistKeysToDbContext<AppDbContext>()
            .SetApplicationName("<Name>");

        Builder.Services.AddSingleton(MasterUserOptions.FromEnvironment());
        Builder.Services.AddScoped<DatabaseSeeder>();
    }
```

### ConfigureCors

Refusing by default is deliberate. A missing entry costs a browser front end its
access until an operator adds one — visible and quickly fixed. Defaulting to
"any origin" leaves a deployment wide open with nothing to indicate it.

The policy is **registered** here and **applied** by the standard pipeline, which
names it in `UseCors` ahead of `AuthenticationMiddleware`, so a preflight request
is answered without a token. With no origins configured no policy is named, and
the pipeline adds no CORS middleware at all.

```csharp
    private void ConfigureCors()
    {
        var origins = (Environment.GetEnvironmentVariable(CorsAllowedOriginsEnvironmentVariable) ?? string.Empty)
            .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

        if (origins.Length == 0)
        {
            Log.Warning(
                "No cross-origin front end is configured ({Variable}); every cross-origin request " +
                "will be refused by the browser's same-origin policy",
                CorsAllowedOriginsEnvironmentVariable);

            return;
        }

        Log.Information("Allowing cross-origin requests from {Origins}", origins);

        // Credentials are allowed because a front end sends the bearer token the API issued. That is
        // also why the origin list has to be explicit: AllowAnyOrigin and AllowCredentials are
        // mutually exclusive by specification, precisely to stop this combination from existing.
        Builder.Services.AddCors(cors => cors.AddPolicy(CorsPolicyName, policy => policy
            .WithOrigins(origins)
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials()));

        Options.CorsPolicy = CorsPolicyName;
    }
```

### ConfigureSecurity

`AddTokenAuthentication` is also what puts `AuthenticationMiddleware` in the
pipeline — `UseStandardMiddlewares` adds it only when the options this call
registers are in the container. Leave it out and nothing fails at startup:
endpoints without `[RoleRequirement]` are simply open.

```csharp
    private void ConfigureSecurity()
    {
        // Authentication is Util.WebApi's alone: ASP.NET Core's authentication and authorization
        // services and middlewares are not registered, because nothing here reads HttpContext.User or
        // carries ASP.NET Core's [Authorize] — the controllers use the library's attributes, which read
        // the user AuthenticationMiddleware attaches.
        //
        // AuthenticationMiddleware resolves AuthenticationOptions and the token validators from the
        // container; JwtTokenValidator additionally needs JwtConfiguration, JwtHandler, and a claims
        // mapper. The non-generic overload registers DefaultAuthenticatedUserMapper, which maps Id
        // and RoleId through TokenClaimKeys — exactly what this API needs, so it writes no mapper of
        // its own (see references/security.md). Defaults are kept otherwise — app JWT only, read
        // from the Authorization header, user rebuilt from claims — so no database read per request.
        Builder.Services.AddSingleton(BuildJwtConfiguration());
        Builder.Services.AddSingleton<JwtHandler>();
        Builder.Services.AddTokenAuthentication(options =>
        {
            options.Source = TokenSource.Header;
            options.EnableJwt = true;
            options.EnableGoogle = false;
            options.JwtMode = JwtValidationMode.ClaimsOnly;
        });

        AddAnonymousEndpointRateLimiting();
    }
```

### BuildJwtConfiguration — and why there are two keys

```csharp
    /// <summary>
    ///     Reads the token settings from the environment. The signing secret is required: with an
    ///     empty one every authenticated request dies inside the token validator with an opaque
    ///     IDX10703, so a missing secret fails startup instead.
    /// </summary>
    /// <remarks>
    ///     This throw is the sanctioned kind — start-up misconfiguration, with no request in flight
    ///     and no envelope to return. A business rule in a handler never throws; it returns an error
    ///     on its output.
    /// </remarks>
    /// <remarks>
    ///     The previous-secret variable is how a signing secret is replaced without signing everybody
    ///     out. Both secrets are handed to JwtConfiguration.Keys, so a token signed with either is
    ///     accepted while new tokens are signed with the current one. Rotating is then: set the
    ///     previous variable to the secret in use, set the current variable to a new one, restart;
    ///     and one token lifetime later, clear the previous variable and restart again.
    ///
    ///     No kid is written to the tokens. An identifier stamped on a token has to stay attached to
    ///     the same key forever, and these ids are positional — today's "current" is tomorrow's
    ///     "previous" — so stamping them would make every token issued before a rotation name the
    ///     wrong key afterwards, and be refused.
    /// </remarks>
    private static JwtConfiguration BuildJwtConfiguration()
    {
        var secret = Environment.GetEnvironmentVariable(TokenSecretEnvironmentVariable);

        if (string.IsNullOrWhiteSpace(secret))
        {
            throw new InvalidOperationException(
                $"Environment variable '{TokenSecretEnvironmentVariable}' is unset. The API cannot " +
                "validate tokens without a signing secret.");
        }

        var expiration = double.TryParse(
            Environment.GetEnvironmentVariable(TokenExpirationEnvironmentVariable),
            out var configuredExpiration)
            ? configuredExpiration
            : DefaultTokenExpirationInSeconds;

        var previousSecret = Environment.GetEnvironmentVariable(PreviousTokenSecretEnvironmentVariable);

        List<JwtKey> keys = [new("current", secret)];

        if (!string.IsNullOrWhiteSpace(previousSecret) && previousSecret != secret)
        {
            keys.Add(new JwtKey("previous", previousSecret));
        }

        return new JwtConfiguration(
            expiration,
            Environment.GetEnvironmentVariable(TokenIssuerEnvironmentVariable) ?? string.Empty,
            Environment.GetEnvironmentVariable(TokenAudienceEnvironmentVariable) ?? string.Empty,
            secret,
            [])
        {
            Keys = keys
        };
    }
```

### Rate limiting

```csharp
    /// <summary>
    ///     Throttles anonymous, credential-checking endpoints per calling IP address. Nothing else
    ///     stops a caller from firing an unbounded burst at an endpoint that requires no token.
    /// </summary>
    /// <remarks>
    ///     Partitioned by the connection's remote IP. Behind a reverse proxy that does not forward
    ///     the real client address, every caller shares one partition — this is a per-instance,
    ///     defence-in-depth throttle, not a substitute for a WAF or a gateway's own rate limiting.
    /// </remarks>
    private void AddAnonymousEndpointRateLimiting()
    {
        Builder.Services.AddRateLimiter(options =>
        {
            options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

            options.AddPolicy(AnonymousEndpointRateLimitPolicy, httpContext =>
                RateLimitPartition.GetFixedWindowLimiter(
                    partitionKey: httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown",
                    factory: _ => new FixedWindowRateLimiterOptions
                    {
                        PermitLimit = 10,
                        Window = TimeSpan.FromMinutes(1),
                        QueueLimit = 0
                    }));
        });
    }
```

### SeedDatabase

```csharp
    /// <summary>
    ///     Runs the database seeder before the host starts serving. Migrations are not applied
    ///     here — the seeder throws if any are pending.
    /// </summary>
    private static void SeedDatabase(WebApplication app)
    {
        using var scope = app.Services.CreateScope();

        scope.ServiceProvider.GetRequiredService<DatabaseSeeder>().SeedAsync().GetAwaiter().GetResult();
    }
}
```

## Binding/ModelBindingConfiguration.cs

Commands and queries double as the wire DTOs, so a property the controller
assigns from the route or from the token looks, to the framework, exactly like
one the client sends. `[JsonIgnore]` marks the difference — and this provider
extends that statement to the `[FromQuery]` path, where System.Text.Json
attributes otherwise mean nothing.

```csharp
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding.Metadata;

namespace <Prefix>.<Name>.WebApi.Binding;

/// <summary>
///     Model-binding configuration shared by the running API and the OpenAPI document generator.
///     Both call <see cref="Configure" />, because the generator builds its own AddControllers()
///     rather than using Startup — configuration registered in only one of the two would let the
///     published document disagree with the API it documents.
/// </summary>
public static class ModelBindingConfiguration
{
    public static void Configure(MvcOptions options) =>
        options.ModelMetadataDetailsProviders.Add(new ServerPopulatedBindingMetadataProvider());
}

/// <summary>
///     Makes a <c>[JsonIgnore]</c> property non-bindable, so a value arriving in the query string
///     cannot reach it and ApiExplorer does not publish it as a parameter.
///     <c>IsBindingAllowed = false</c> is what <c>[BindNever]</c> sets; <c>[BindNever]</c> itself is
///     unavailable to the Application-layer projects these DTOs live in, which have no reference to
///     the ASP.NET Core shared framework.
/// </summary>
public class ServerPopulatedBindingMetadataProvider : IBindingMetadataProvider
{
    public void CreateBindingMetadata(BindingMetadataProviderContext context)
    {
        if (context.Attributes.OfType<JsonIgnoreAttribute>().Any())
        {
            context.BindingMetadata.IsBindingAllowed = false;
        }
    }
}
```

## Documentation/SwaggerConfiguration.cs

One `public static void Configure(SwaggerGenOptions options)`, applied in two
places — `Startup` hands it to Util.WebApi as `Options.Swagger.ConfigureGenerator`,
and the generator calls it directly — so the published document and the running
API cannot describe the same endpoint differently. The parts that are not
obvious, and that a shorter version gets wrong:

1. `options.SwaggerDoc("v1", new OpenApiInfo { … })` with the API's title and
   description.
2. **This method owns the `"Bearer"` scheme**, in both places. `Startup` leaves
   `Options.Swagger.JwtAuthentication` false, because the library's JWT scheme is
   added after `ConfigureGenerator` runs, with `AddSecurityDefinition` — which
   throws on a duplicate key. Turning both on does not fail startup; it fails
   every request with a 500 in `Local` and `Development`, because the Swagger
   middleware resolves the generator on every request. **Assign** the scheme
   rather than adding it all the same —
   `options.SwaggerGeneratorOptions.SecuritySchemes["Bearer"] = …` — so this
   method itself never throws, whatever defined `"Bearer"` before it ran.
3. `options.IncludeXmlComments(path)` — and **throw** if the XML file is absent,
   naming `<GenerateDocumentationFile>`. A missing file silently produces a page
   with no descriptions, which is the whole reason the page is worth reading.
4. `options.CustomOperationIds(…)` producing `Controller_Action`, **set before**
   the document filter is registered — the filter matches operations back to
   their methods by that id.
5. A `SecurityDocumentFilter`, then a `LineEndingDocumentFilter` **last**.

### Why the security filter is not optional

Authorization here is `[RoleRequirement]` and `[AllowAnonymous]` from
`ArturRios.Util.WebApi`, not ASP.NET Core's `[Authorize]`, so Swashbuckle's
built-in handling sees nothing. Without the filter the generated document carries
**no security at all** — verified: the admin-only endpoint is published as open,
with no 401 and no 403. That is worse than undocumented; it is wrong.

```csharp
public sealed class SecurityDocumentFilter : IDocumentFilter
{
    private const string BearerScheme = "Bearer";

    public void Apply(OpenApiDocument document, DocumentFilterContext context)
    {
        var methods = context.ApiDescriptions
            .Where(description => description.ActionDescriptor is ControllerActionDescriptor)
            .ToDictionary(
                description =>
                {
                    var action = (ControllerActionDescriptor)description.ActionDescriptor;

                    return $"{action.ControllerName}_{action.ActionName}";
                },
                description => ((ControllerActionDescriptor)description.ActionDescriptor).MethodInfo);

        // The document-wide default: authenticated unless an operation says otherwise — the reverse
        // of ASP.NET Core's default, and how this API actually behaves.
        document.Security = [Requirement(document)];

        foreach (var operation in document.Paths.Values.SelectMany(path =>
                     path.Operations?.Values ?? Enumerable.Empty<OpenApiOperation>()))
        {
            if (operation.OperationId is null || !methods.TryGetValue(operation.OperationId, out var method))
            {
                continue;
            }

            Apply(document, operation, method);
        }
    }

    private static OpenApiSecurityRequirement Requirement(OpenApiDocument document) => new()
    {
        [new OpenApiSecuritySchemeReference(BearerScheme, document)] = []
    };

    private static void Apply(OpenApiDocument document, OpenApiOperation operation, MethodInfo method)
    {
        var attributes = method
            .GetCustomAttributes(inherit: true)
            .Concat(method.DeclaringType?.GetCustomAttributes(inherit: true) ?? [])
            .ToList();

        if (attributes.OfType<AllowAnonymousAttribute>().Any())
        {
            // An empty requirement list, not an absent one. The document carries a default that
            // applies to every operation which does not state its own, so saying nothing here would
            // document an anonymous endpoint as needing a token; an empty list is how OpenAPI spells
            // "this one overrides the default with nothing".
            operation.Security = [];
            operation.Description = Append(operation.Description, "**Anonymous** — no bearer token required.");

            return;
        }

        operation.Security = [Requirement(document)];
        operation.Responses ??= new OpenApiResponses();

        operation.Responses.TryAdd(
            "401",
            new OpenApiResponse { Description = "The token is missing, malformed, or expired." });

        var roles = attributes.OfType<RoleRequirementAttribute>().SelectMany(RoleNames).Distinct().ToList();

        if (roles.Count == 0)
        {
            operation.Description = Append(
                operation.Description,
                "**Any authenticated caller** — the handler decides who may act, so no role is required at the door.");

            return;
        }

        operation.Responses.TryAdd(
            "403",
            new OpenApiResponse { Description = "The token is valid but the caller does not hold a required role." });

        operation.Description = Append(operation.Description, $"**Requires role:** {string.Join(" or ", roles)}.");
    }

    /// <summary>
    ///     Reads the role ids off a <c>RoleRequirementAttribute</c> and names them. The attribute is
    ///     a <c>TypeFilterAttribute</c>: it carries no role property of its own, and passes the ids
    ///     to its filter through <c>Arguments</c>. An attribute that stops carrying them yields
    ///     nothing and the operation is documented without a role line — the security requirement
    ///     above, which is what actually matters, does not depend on this.
    /// </summary>
    private static IEnumerable<string> RoleNames(RoleRequirementAttribute attribute) =>
        (attribute.Arguments ?? [])
        .OfType<IEnumerable<int>>()
        .SelectMany(ids => ids)
        .Select(id => Enum.IsDefined(typeof(Roles), id)
            ? SplitPascalCase(((Roles)id).ToString())
            : $"role {id}");

    private static string SplitPascalCase(string value) =>
        string.Concat(value.Select((character, index) =>
            index > 0 && char.IsUpper(character) ? $" {character}" : $"{character}"));

    private static string Append(string? description, string line) =>
        string.IsNullOrWhiteSpace(description) ? line : $"{description}\n\n{line}";
}
```

It must be a **document** filter, not an operation filter: a security requirement
is a reference to a scheme, and a reference only serializes once bound to the
document that defines the scheme. An operation filter never sees that document,
and the requirement serializes as an empty object.

Verified output for the scaffold's two endpoints:

```
doc-level security: [{"Bearer": []}]
GET /HealthCheck           security=[]                responses=[200]
GET /HealthCheck/detailed  security=[{"Bearer": []}]  responses=[200, 401, 403]
                           description: **Requires role:** System Admin.
```

### LineEndingDocumentFilter

Runs last, rewriting every CRLF to LF across info, security schemes, paths,
operations, parameters, responses, and schemas — walking schemas with a seen-set,
since a self-referencing schema recurses forever otherwise. Swashbuckle rejoins
XML documentation lines with `Environment.NewLine`, so without this the document
generated on Windows and the one CI regenerates on Linux describe the same API
and still differ, in hunks of pure line ending — and `scripts/openapi.py --check`
compares bytes.

## Settings/appsettings.json

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

This is the only settings file the scaffold writes, and the only one committed.
The configuration loader reads `Settings/appsettings.<Environment>.json`, falling
back to `appsettings.Local.json` — never `appsettings.json` by that name, so
this file is the shape to copy rather than a baseline anything layers over. The
per-environment files are local: the copied `.gitignore` excludes
`appsettings.Local.json`, `.Development.json`, `.Staging.json` and
`.Production.json`, so a developer or a deployment writes its own and none is
scaffolded — a file written into an ignored path is one the first commit
silently leaves behind. Nothing the scaffold needs lives in them: its
configuration is the environment (below).

## Environments/.env.example

Everything the API reads from the environment when it runs from source. Copy to
`.env.local` (gitignored) and fill in.

```bash
# Search Path stays public. The entities still live in the <name> schema (AppDbContext's default
# schema); naming that schema here fails on a fresh database with 3F000 — see references/docker.md.
<NAME>_DATA_CONNECTIONSTRING=Host=localhost;Port=5432;Database=<name>;Username=;Password=;Search Path=public
<NAME>_DATA_DATABASETYPE=PostgreSql

# Required. The API refuses to start without it.
<NAME>_AUTH_TOKEN_SECRET=
# Set only during a rotation; clear it one token lifetime afterwards.
<NAME>_AUTH_TOKEN_SECRET_PREVIOUS=
<NAME>_AUTH_TOKEN_ISSUER=<name>
<NAME>_AUTH_TOKEN_AUDIENCE=<name>
<NAME>_AUTH_TOKEN_EXPIRATION_IN_SECONDS=3600

<NAME>_MASTER_USER_NAME=
<NAME>_MASTER_USER_EMAIL=
<NAME>_MASTER_USER_PASSWORD=

# Comma-separated origins allowed to call the API from a browser. Empty refuses every
# cross-origin request, which is the safe default for an API that honours credentials.
<NAME>_CORS_ALLOWED_ORIGINS=

<NAME>_LOG_DIRECTORY=logs
```

## Properties/launchSettings.json

Two profiles, `http` and `https`, both with
`"ASPNETCORE_ENVIRONMENT": "Local"` — the loader resolves
`Environments/.env.local` from it. Not `Development`, which would reach a file
the developer does not have.
