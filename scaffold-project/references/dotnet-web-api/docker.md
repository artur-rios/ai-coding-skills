# Docker

**Only `docker/*.env.example` files are written.** The real ones are gitignored
and the user fills them in. A committed secret is not recoverable.

## Dockerfile

Two stages. The build stage also produces an EF Core migrations bundle — a plain
executable — so the runtime image never needs the SDK or the `dotnet-ef` tool to
apply migrations.

```dockerfile
# syntax=docker/dockerfile:1

# Build stage: publishes the Web API and, alongside it, an EF Core migrations bundle. The bundle is
# built here because applying migrations needs the SDK and the dotnet-ef tool, neither of which the
# runtime image carries -- the bundle is a plain executable the entrypoint runs before the API
# starts, so the deployed container never needs the SDK.
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /source

# Restored first and on their own so the tool and package layers survive a source-only change.
COPY .config/dotnet-tools.json .config/
RUN dotnet tool restore

# Central package management: the project files name their packages and this file alone gives the
# versions, so restore fails outright without it. It belongs in this layer rather than with the
# sources below for the same reason the csproj files do -- a source-only change must not invalidate
# the restore cache, and a version change should.
COPY Directory.Packages.props ./

COPY src/Presentation/<Prefix>.<Name>.WebApi/<Prefix>.<Name>.WebApi.csproj src/Presentation/<Prefix>.<Name>.WebApi/
COPY src/Application/<Prefix>.<Name>.Command/<Prefix>.<Name>.Command.csproj src/Application/<Prefix>.<Name>.Command/
COPY src/Application/<Prefix>.<Name>.Query/<Prefix>.<Name>.Query.csproj src/Application/<Prefix>.<Name>.Query/
COPY src/Application/<Prefix>.<Name>.Shared/<Prefix>.<Name>.Shared.csproj src/Application/<Prefix>.<Name>.Shared/
COPY src/Domain/<Prefix>.<Name>.Domain/<Prefix>.<Name>.Domain.csproj src/Domain/<Prefix>.<Name>.Domain/
COPY src/Infrastructure/<Prefix>.<Name>.Data/<Prefix>.<Name>.Data.csproj src/Infrastructure/<Prefix>.<Name>.Data/
RUN dotnet restore src/Presentation/<Prefix>.<Name>.WebApi/<Prefix>.<Name>.WebApi.csproj

COPY src/ src/

RUN dotnet publish src/Presentation/<Prefix>.<Name>.WebApi/<Prefix>.<Name>.WebApi.csproj \
        --configuration Release --no-restore --output /app

# Framework-dependent on purpose: the runtime image already ships the .NET runtime the bundle needs.
# The placeholder connection string is what DesignTimeDbContextFactory needs to hand `dotnet ef` a
# DbContext while the bundle is built; nothing connects here, and the bundle uses the --connection
# the entrypoint passes it instead.
RUN <NAME>_DATA_CONNECTIONSTRING="Host=localhost;Port=5432;Database=<name>;Username=postgres;Password=postgres" \
    dotnet ef migrations bundle \
        --project src/Infrastructure/<Prefix>.<Name>.Data \
        --startup-project src/Infrastructure/<Prefix>.<Name>.Data \
        --configuration Release \
        --output /app/<name>-migrate \
        --force

# Runtime stage.
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app

# curl is installed for the container health check alone: the runtime image ships neither curl nor
# wget, and without one Compose has no way to tell a started container from a ready one -- which is
# what "depends_on: service_healthy" needs to be meaningful for anything placed in front of the API.
RUN apt-get update \
    && apt-get install --yes --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /app .
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /app/<name>-migrate

# Serilog writes under this directory and the seeder needs nothing writable, so the container can
# drop to the image's non-root user once the directory belongs to it.
ENV <NAME>_LOG_DIRECTORY=/app/logs
RUN mkdir -p /app/logs && chown -R $APP_UID:$APP_UID /app/logs
USER $APP_UID

# Matches the aspnet image's own default; named here so the Compose port mapping has an explicit
# counterpart to point at.
ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["dotnet", "<Prefix>.<Name>.WebApi.dll"]
```

The bundle step works from the first scaffold: step 4 creates the initial
migration for the Data Protection key ring, so there is always at least one to
bundle. (It would in fact succeed with none — `dotnet ef migrations bundle`
produces an empty bundle rather than failing — but an empty one applied to an
empty database would leave `AddDataProtection` writing to a table that does not
exist.)

## docker/entrypoint.sh

```bash
#!/bin/sh
set -e

# Applies pending EF Core migrations, then hands off to the API. Migrations are never applied by the
# application itself -- the seeder refuses to run against a schema that is behind, which is what
# turns "the database is stale" into a message rather than an unrelated error on the first query.
if [ "${<NAME>_RUN_MIGRATIONS:-true}" = "true" ]; then
    echo "Applying database migrations..."
    /app/<name>-migrate --connection "${<NAME>_DATA_CONNECTIONSTRING}"
fi

exec "$@"
```

Committed with the executable bit set; `.gitattributes` keeps its line endings
LF, without which it fails on a Linux container with `no such file or directory`.

## docker-compose.yml

One file for every environment: what differs between them is configuration, not
topology, so each supplies its own env file rather than its own Compose file.

```yaml
services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
    image: ${API_IMAGE:-<name>-api}:${API_IMAGE_TAG:-latest}
    restart: unless-stopped

    # host.docker.internal is defined by Docker Desktop already, but not by the plain Docker engine.
    # There it is only what this line makes it: the gateway address of the container's bridge
    # network, which is the host itself. It is inert when DB_HOST names a real host instead.
    extra_hosts:
      - "host.docker.internal:host-gateway"

    environment:
      ASPNETCORE_ENVIRONMENT: ${ASPNETCORE_ENVIRONMENT:-Development}

      # The connection string is assembled from parts so an environment only has to state what
      # actually differs. DB_CONNECTION_EXTRA appends anything Npgsql accepts and this file should
      # not assume, e.g. "SSL Mode=Require;Trust Server Certificate=true".
      #
      # Search Path is pinned, and it is not cosmetic. EF names the migrations history table
      # unqualified, so Postgres resolves it through the search path, whose default is "$user",
      # public. The entities live in their own schema; the moment the login shares that schema's
      # name -- the obvious name for this service's role -- "$user" starts resolving to it. The first
      # run then records its history in public and every run after it reads an empty history table,
      # concludes nothing was applied, and dies on `relation "..." already exists`.
      #
      # Pin it to a schema that already exists -- public, the default below. Setting it to the
      # application's own schema fails on a fresh database: EF creates __EFMigrationsHistory before
      # running any migration, so it resolves the unqualified name through a search path naming a
      # schema the first migration has not created yet, and the container dies on
      # `3F000: no schema has been selected to create in`.
      <NAME>_DATA_CONNECTIONSTRING: "Host=${DB_HOST:-host.docker.internal};Port=${DB_PORT:-5432};Database=${DB_NAME:-<name>};Username=${DB_USER:?set DB_USER in the env file};Password=${DB_PASSWORD:?set DB_PASSWORD in the env file};Search Path=${DB_SEARCH_PATH:-public};${DB_CONNECTION_EXTRA:-}"
      <NAME>_DATA_DATABASETYPE: PostgreSql

      <NAME>_AUTH_TOKEN_SECRET: ${<NAME>_AUTH_TOKEN_SECRET:?set <NAME>_AUTH_TOKEN_SECRET in the env file}
      # Set during a rotation so tokens signed with the retired key keep working.
      <NAME>_AUTH_TOKEN_SECRET_PREVIOUS: ${<NAME>_AUTH_TOKEN_SECRET_PREVIOUS:-}
      <NAME>_AUTH_TOKEN_ISSUER: ${<NAME>_AUTH_TOKEN_ISSUER:-<name>}
      <NAME>_AUTH_TOKEN_AUDIENCE: ${<NAME>_AUTH_TOKEN_AUDIENCE:-<name>}
      <NAME>_AUTH_TOKEN_EXPIRATION_IN_SECONDS: ${<NAME>_AUTH_TOKEN_EXPIRATION_IN_SECONDS:-3600}

      # Seeded on first start, and only while the database holds no system administrator.
      <NAME>_MASTER_USER_NAME: ${<NAME>_MASTER_USER_NAME:?set <NAME>_MASTER_USER_NAME in the env file}
      <NAME>_MASTER_USER_EMAIL: ${<NAME>_MASTER_USER_EMAIL:?set <NAME>_MASTER_USER_EMAIL in the env file}
      <NAME>_MASTER_USER_PASSWORD: ${<NAME>_MASTER_USER_PASSWORD:?set <NAME>_MASTER_USER_PASSWORD in the env file}

      # Empty by default, which refuses every cross-origin request. A browser front end will not
      # reach the API until its origin is listed here.
      <NAME>_CORS_ALLOWED_ORIGINS: ${<NAME>_CORS_ALLOWED_ORIGINS:-}

      # The entrypoint applies pending EF Core migrations before starting the API. false when they
      # are applied out of band -- scripts/migrations.py, or a deploy step of its own.
      <NAME>_RUN_MIGRATIONS: ${<NAME>_RUN_MIGRATIONS:-true}

    volumes:
      - logs:/app/logs

    # Host side of the mapping, so an environment can pick the interface as well as the port:
    # "8080" publishes on every interface, "127.0.0.1:8080" only to the host -- which is what a
    # server with a reverse proxy in front of the API wants.
    ports:
      - "${API_PORT:-8080}:8080"

    healthcheck:
      test: ["CMD", "curl", "--fail", "--silent", "http://localhost:8080/healthcheck"]
      interval: 15s
      timeout: 5s
      retries: 5
      start_period: 30s

# A named volume rather than a bind mount, so the same file works unchanged on Windows and Linux --
# a host path would need a different form on each.
volumes:
  logs:
```

Postgres is deliberately **not** a service here: the scaffold assumes an existing
instance the API reaches over `DB_HOST`. If the user says they want a database
container too, add one with a named volume and `depends_on: service_healthy` —
but ask, do not assume.

## docker/*.env.example

Three files — `local`, `development`, `production` — differing only in
`COMPOSE_PROJECT_NAME`, `ASPNETCORE_ENVIRONMENT`, `DB_NAME`, and their comments.
Every secret is left **empty**, with a comment saying what it is for.

```bash
COMPOSE_PROJECT_NAME=<name>-local
ASPNETCORE_ENVIRONMENT=Local
API_PORT=8080

DB_HOST=host.docker.internal
DB_PORT=5432
DB_NAME=<name>_local
DB_USER=
DB_PASSWORD=
DB_CONNECTION_EXTRA=

# Comma-separated origins allowed to call the API from a browser (scheme + host + port, exactly as
# the browser sends them). With no entry, the same-origin policy refuses every cross-origin request,
# which is the safe default for an API that hands out and honours credentials.
<NAME>_CORS_ALLOWED_ORIGINS=

# Its own secret -- a shared environment must not be able to mint tokens the others accept.
<NAME>_AUTH_TOKEN_SECRET=

# The key a rotation has moved off but not yet withdrawn. Tokens signed with it stay valid while it
# is set, so replacing the secret above does not sign everybody out. Clear it one token lifetime
# after the rotation. Leave empty when not rotating.
<NAME>_AUTH_TOKEN_SECRET_PREVIOUS=
<NAME>_AUTH_TOKEN_ISSUER=<name>
<NAME>_AUTH_TOKEN_AUDIENCE=<name>
<NAME>_AUTH_TOKEN_EXPIRATION_IN_SECONDS=3600

<NAME>_MASTER_USER_NAME=
<NAME>_MASTER_USER_EMAIL=
<NAME>_MASTER_USER_PASSWORD=

<NAME>_RUN_MIGRATIONS=true
```
