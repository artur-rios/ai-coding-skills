# .NET — NuGet library

Read together with `references/dotnet.md` when the .NET kind is **NuGet library**. Everything in
`dotnet.md` applies — template `classlib`, basic layout (no DDD question), `<Version>` in the csproj,
the library branch-policy variant — and this file adds the package metadata nuget.org needs, the
csproj properties that carry it, and the pack check.

The csproj is the single source of the metadata: **create-nuget-publish-workflow** packs it as is and
**generate-project-docs** reads the `<PackageId>` from it, so nothing here goes in a `.nuspec`.

## Interview

Asked in the same round as the shared and .NET questions. Offer every default; an answer of "default"
or a blank takes it.

| Question | Default | Becomes |
|---|---|---|
| "Package id?" | `<Prefix.>ProjectName` | `<PackageId>` — keep it equal to the project name, so `src/<PackageId>/<PackageId>.csproj` holds (the multi-package publish workflow relies on that layout) |
| "Starting version?" | `0.1.0` | `<Version>` |
| "Authors? (comma-separated)" | `git config user.name` | `<Authors>` |
| "Company or owner shown on nuget.org? (blank for none)" | none | `<Company>` — omitted when blank |
| "Tags for search on nuget.org? (space-separated, e.g. `orders validation`)" | none — ask once more if blank; a package without tags is hard to find | `<PackageTags>`, `;`-separated |
| "Target framework(s)?" | `net<SDK major>.0` from `dotnet --version` | one → `<TargetFramework>`; several (`net8.0;net10.0`) → `<TargetFrameworks>` |
| "Project URL — the repository, or a docs site?" | `https://github.com/<owner>/<repo>` | `<PackageProjectUrl>` |
| "Package icon — path to a square PNG, at least 128×128, inside the repository? (blank for none)" | none | `<PackageIcon>` + a packed `<None>` item; omitted when blank |
| "After the scaffold builds, also generate the NuGet publish workflow (create-nuget-publish-workflow)?" | yes | step 8 of `SKILL.md` |
| "And the README + Hugo docs site (generate-project-docs)?" | yes | step 8 of `SKILL.md` — that skill then rewrites the README this skill writes |

The description is the shared one-sentence answer (`<Description>`). The license is the shared license
answer, mapped below. The repository URL comes from the remote or the owner/repo answer.

### License → package metadata

| License | csproj |
|---|---|
| Artur Rios Attribution License | `<PackageLicenseFile>LICENSE</PackageLicenseFile>` + the LICENSE packed — it is not an SPDX license |
| MIT | `<PackageLicenseExpression>MIT</PackageLicenseExpression>` |
| AGPL | `<PackageLicenseExpression>AGPL-3.0-only</PackageLicenseExpression>` — or `AGPL-3.0-or-later` if the user says "or later" |
| Custom Commercial | `<PackageLicenseFile>LICENSE</PackageLicenseFile>` + the LICENSE packed, and `<PackageRequireLicenseAcceptance>true</PackageRequireLicenseAcceptance>` when the grant is restrictive |

`<Copyright>`: `Copyright (c) <year> Artur Rios` for the default license (fixed, like the LICENSE
text); `Copyright (c) <year> <Authors>` otherwise.

## The csproj

Write the answers into the `<PropertyGroup>` of `src/<PackageId>/<PackageId>.csproj`, keeping what
`dotnet new classlib` generated (`TargetFramework`, `ImplicitUsings`, `Nullable`):

```xml
<PropertyGroup>
  <TargetFramework>net10.0</TargetFramework>
  <ImplicitUsings>enable</ImplicitUsings>
  <Nullable>enable</Nullable>

  <!-- Package identity -->
  <PackageId>Acme.Orders</PackageId>
  <Version>0.1.0</Version>
  <Authors>Jane Doe</Authors>
  <Company>Acme</Company>
  <Description>Order validation and totals for Acme services.</Description>
  <Copyright>Copyright (c) 2026 Jane Doe</Copyright>
  <PackageTags>orders;validation</PackageTags>
  <PackageProjectUrl>https://github.com/acme/orders</PackageProjectUrl>
  <PackageReleaseNotes>https://github.com/acme/orders/blob/main/CHANGELOG.md</PackageReleaseNotes>
  <PackageLicenseExpression>MIT</PackageLicenseExpression>
  <PackageReadmeFile>README.md</PackageReadmeFile>
  <IsPackable>true</IsPackable>

  <!-- Source link and symbols: a consumer can step into the exact source of the version they
       installed. The .NET 8+ SDK carries Source Link for GitHub itself; these switch it on. -->
  <RepositoryUrl>https://github.com/acme/orders</RepositoryUrl>
  <RepositoryType>git</RepositoryType>
  <PublishRepositoryUrl>true</PublishRepositoryUrl>
  <EmbedUntrackedSources>true</EmbedUntrackedSources>
  <IncludeSymbols>true</IncludeSymbols>
  <SymbolPackageFormat>snupkg</SymbolPackageFormat>
  <Deterministic>true</Deterministic>

  <!-- IntelliSense for consumers. -->
  <GenerateDocumentationFile>true</GenerateDocumentationFile>
</PropertyGroup>

<!-- Normalizes paths in the PDB on CI only, so local debugging keeps working. -->
<PropertyGroup Condition="'$(GITHUB_ACTIONS)' == 'true'">
  <ContinuousIntegrationBuild>true</ContinuousIntegrationBuild>
</PropertyGroup>

<ItemGroup>
  <None Include="..\..\README.md" Pack="true" PackagePath="\" />
  <!-- Only with PackageLicenseFile: -->
  <None Include="..\..\LICENSE" Pack="true" PackagePath="\" />
  <!-- Only with an icon: the path relative to this csproj, and PackageIcon set to its file name. -->
  <None Include="..\..\docs\images\icon.png" Pack="true" PackagePath="\" />
</ItemGroup>
```

Drop the elements the answers left out (`<Company>`, the icon item, the LICENSE item when the license is
an expression) — never leave an empty element or a placeholder value.

`GenerateDocumentationFile` turns every undocumented public member into warning CS1591. That is the
point for a library — the consumer's IntelliSense is the documentation — so leave it on and do not add
`CS1591` to `<NoWarn>`. The scaffold has no public members yet, so the first build is clean.

## README fill-ins

The README is packed into the package and rendered on nuget.org, so:

- `{{LinkBase}}` is `https://github.com/<owner>/<repo>/blob/main`, not `.` — relative links break on
  nuget.org.
- **Usage:** `dotnet add package <PackageId>`, then one sentence saying the API is documented as it
  lands.
- Add a NuGet badge under the title:
  `[![NuGet](https://img.shields.io/nuget/v/<PackageId>.svg)](https://www.nuget.org/packages/<PackageId>)`

If the user accepted generate-project-docs, that skill replaces this README in step 8; write it
anyway so the pack check below has a README to pack.

## Verify

After `dotnet build`, pack into a directory outside the repository and look inside:

```bash
pack_dir=$(mktemp -d)
dotnet pack src/<PackageId>/<PackageId>.csproj -c Release -o "$pack_dir"
unzip -l "$pack_dir/<PackageId>.<Version>.nupkg"
```

(PowerShell: a fresh directory under `$env:TEMP` and `Expand-Archive` / `[IO.Compression.ZipFile]` to list it.)

The `.nupkg` and a `.snupkg` must both exist, the nupkg must contain `README.md` (and `LICENSE` /
the icon when configured), and the pack output must have **no NU5xxx warnings** — NU5039 (readme not
found), NU5046 (icon not found) and NU5125 (license URL deprecated) all mean a property points at the
wrong place. Delete the check directory afterwards.

## Report

- The package id, version, target framework(s) and license metadata written.
- That the package is not published: publishing is the tag-triggered workflow from
  **create-nuget-publish-workflow** (if accepted) after the first release, and it needs the
  `NUGET_API_KEY` repository secret.
