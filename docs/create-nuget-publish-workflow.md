# create-nuget-publish-workflow

Generates a tag-triggered GitHub Actions workflow that packs a .NET project and
publishes its NuGet package(s) to **nuget.org** and **GitHub Packages**.

## What it does

It writes `.github/workflows/publish-package.yml` into the target repository and
picks one of two strategies based on how many packable projects the solution has:

| Strategy | When | Tag format | Extras |
|---|---|---|---|
| **Single-package** | Exactly one publishable project | any version tag — `1.2.3` or `v1.2.3` | none |
| **Multi-package** | More than one publishable project | `<PackageId>@<version>` | copies `scripts/release.py` helper |

A project counts as **publishable** when its `.csproj` contains a `<PackageId>`
element. Test projects, samples, and internal libraries that omit `<PackageId>`
are excluded — so a repo with one library plus several test projects is still
*single-package*.

## When to use it

Ask for it when you want to:

- "publish to NuGet" / "add a release or publish workflow"
- "set up the GitHub Action to publish the package(s)"

Skip it if the repo is not .NET, does not use the `src/<Project>/…csproj` layout,
or publishes somewhere other than NuGet / GitHub Packages.

## How it works

1. **Analyze the repo.** Detects publishable projects (`grep -rl "<PackageId>"
   --include=*.csproj src`) and reads each one for `<PackageId>`, `<Version>`,
   `<RepositoryUrl>`, and `<TargetFramework>` (to choose the SDK version glob).
2. **Count them** to pick single- vs. multi-package.
3. **Write the workflow** from the matching template in `templates/`, filling the
   `__UPPER_CASE__` placeholders.
4. For multi-package, also copy `templates/release.py` to `scripts/release.py`.
5. **Report the follow-ups** you must do yourself (see below).

Both jobs otherwise behave identically: checkout the tag → set up .NET → validate
the tag version against the csproj `<Version>` → restore → pack (Release) →
`dotnet nuget push` to nuget.org then GitHub Packages, each with
`--skip-duplicate`.

## Files in this skill

| Path | Purpose |
|---|---|
| `SKILL.md` | The skill instructions. |
| `templates/single-package.yml` | Workflow for a one-package repo. |
| `templates/multi-package.yml` | Workflow for a multi-package repo. |
| `templates/release.py` | Interactive bump/tag/push helper for multi-package repos. |

## After it runs — your responsibilities

- Add the `NUGET_API_KEY` secret in the repo settings (`GITHUB_TOKEN` is
  automatic; the workflow already requests `packages: write`).
- **Release, single-package:** `git tag 1.2.3 && git push origin 1.2.3`
  (the tag must equal the csproj `<Version>`).
- **Release, multi-package:** `python scripts/release.py` (interactive) or
  `python scripts/release.py release <project> patch`.

> The release helper pushes tags one at a time on purpose — GitHub drops the push
> event past three tags in a single push, so batch-pushing would publish nothing.
