# Presentation — Program, Startup, and configuration

## Program.cs

The entry point does one thing. Everything else is `Startup`.

```csharp
namespace <Prefix>.<Name>.WebApi;

public class Program
{
    public static void Main(string[] args)
    {
        var startup = new Startup(args);

        startup.BuildAndRun();
    }
}
```

`Program` must be a **named, non-top-level class**: the functional tests boot the
API with `WebApiTest<Program>`, which needs the type.

## Startup.cs

`WebApiStartup` from `ArturRios.Util.WebApi` provides `Builder`, `App`,
`LoadConfiguration`, `BuildApp`, `AddMiddlewares`, `UseSwaggerGen`,
`UseSwagger`, `AddCustomInvalidModelStateResponse`, and the overridable hooks
below.

Two `using`s are easy to miss and both fail at compile time:
`Microsoft.AspNetCore.DataProtection` (that is the namespace
`PersistKeysToDbContext` lives in, even though it ships in the
`…DataProtection.EntityFrameworkCore` package) and `ArturRios.Jwt` for
`JwtConfiguration` / `JwtHandler` / `JwtKey`.

```csharp
public class Startup(string[] args) : WebApiStartup(args)
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

    /// <summary>
    ///     Rate-limiting policy name applied with <c>[EnableRateLimiting(AnonymousEndpointRateLimitPolicy)]</c>
    ///     to anonymous, credential-checking endpoints. Public so the controllers and this
    ///     configuration stay in sync without duplicating the literal.
    /// </summary>
    public const string AnonymousEndpointRateLimitPolicy = "Anonymous";
```

### Build — the order is the contract

```csharp
    public override void Build()
    {
        ConfigureLogging();                    // see references/observability.md
        Builder.Host.UseSerilog();

        Log.Information("Building web api on {Environment} environment", Builder.Environment.EnvironmentName);

        LoadConfiguration();
        ConfigureWebApi();
        AddDependencies();
        ConfigureSecurity();

        AddCustomInvalidModelStateResponse();
        UseSwaggerGen(jwtAuthentication: true);

        // Layered over the SwaggerGen the call above registers, so Swagger UI shows the controllers'
        // own summaries and marks which endpoints need a token. The same method produces
        // docs/openapi/<name>.json, which is what keeps the published page and this one identical.
        Builder.Services.ConfigureSwaggerGen(SwaggerConfiguration.Configure);

        BuildApp();
        ConfigureApp();

        // ExceptionMiddleware is the codebase's only exception handler: nothing in the request path
        // catches, so a bug or a broken dependency reaches here, gets logged with its stack trace,
        // and is written as the same JSON envelope every other failure uses. Business outcomes never
        // arrive as exceptions -- those are errors on a returned ProcessOutput / DataOutput<T> /
        // PaginatedOutput<T>, which ResponseResolver maps to a status.
        //
        // The two middlewares are registered around UseSwagger rather than before it, and the order
        // is the whole point.
        //
        // ExceptionMiddleware stays first, so a failure inside Swagger still answers the same JSON
        // envelope as every other error rather than a bare 500. AuthenticationMiddleware goes after,
        // because it does not exempt the Swagger routes: registered ahead of them it answers 401 to
        // every request for /swagger, index.html included, which no browser can satisfy — it has no
        // way to send a bearer token for a document request, so the UI is unreachable.
        //
        // This does not expose the document in production: Util.WebApi registers Swagger only in the
        // environments it allows, and in Production it registers nothing at all — the generator is
        // what publishes the document for readers who are not running the API.
        AddMiddlewares([typeof(ExceptionMiddleware)]);
        UseSwagger();
        AddMiddlewares([typeof(AuthenticationMiddleware)]);

        StartServices();

        Log.Information("Ready to run!");
    }
```

### ConfigureWebApi

```csharp
    public override void ConfigureWebApi()
    {
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
    public override void AddDependencies()
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

### ConfigureApp

```csharp
    public override void ConfigureApp()
    {
        ConfigureCors();

        // Local is included alongside Development because it is what a developer machine runs: the
        // configuration loader resolves Environments/.env.<environment>, so the launch profiles name
        // Local to reach .env.local. Testing IsDevelopment() alone would silently cost the developer
        // exception page in the one environment that exists to have it.
        if (Builder.Environment.IsDevelopment() || Builder.Environment.IsEnvironment("Local"))
        {
            App.UseDeveloperExceptionPage();
        }

        App.UseHttpsRedirection();
        App.UseRouting();
        App.UseRateLimiter();
        App.UseAuthentication();
        App.UseAuthorization();
        App.MapControllers();
    }
```

### ConfigureCors

Refusing by default is deliberate. A missing entry costs a browser front end its
access until an operator adds one — visible and quickly fixed. Defaulting to
"any origin" leaves a deployment wide open with nothing to indicate it.

```csharp
    public override void ConfigureCors()
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

        // Credentials are allowed because a front end sends the bearer token the API issued. That is
        // also why the origin list has to be explicit: AllowAnyOrigin and AllowCredentials are
        // mutually exclusive by specification, precisely to stop this combination from existing.
        App.UseCors(policy => policy
            .WithOrigins(origins)
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials());
    }
```

### ConfigureSecurity

```csharp
    public override void ConfigureSecurity()
    {
        Builder.Services.AddAuthentication("Jwt").AddJwtBearer("Jwt");
        Builder.Services.AddAuthorization();

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

### StartServices

```csharp
    /// <summary>
    ///     Runs the database seeder before the host starts serving. Migrations are not applied
    ///     here — the seeder throws if any are pending.
    /// </summary>
    public override void StartServices()
    {
        using var scope = App.Services.CreateScope();

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
places — `Startup` and the generator — so the published document and the running
API cannot describe the same endpoint differently. The parts that are not
obvious, and that a shorter version gets wrong:

1. `options.SwaggerDoc("v1", new OpenApiInfo { … })` with the API's title and
   description.
2. **Assign** the Bearer scheme rather than `AddSecurityDefinition`, which throws
   on a duplicate key: `UseSwaggerGen(jwtAuthentication: true)` has already
   defined `"Bearer"` when this runs inside the API, and has not when the
   generator runs it. `options.SwaggerGeneratorOptions.SecuritySchemes["Bearer"] = …`
   is the one call that works in both places.
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

`appsettings.Local.json`, `appsettings.Development.json`, and
`appsettings.Production.json` are written alongside it with the same shape;
`.gitignore` excludes the first two so a developer's overrides stay local.

## Environments/.env.example

Everything the API reads from the environment when it runs from source. Copy to
`.env.local` (gitignored) and fill in.

```bash
<NAME>_DATA_CONNECTIONSTRING=Host=localhost;Port=5432;Database=<name>;Username=;Password=;Search Path=<name>
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
