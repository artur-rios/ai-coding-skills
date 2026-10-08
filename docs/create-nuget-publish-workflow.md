# create-nuget-publish-workflow

Generates a tag-triggered GitHub Actions workflow that packs a .NET project and
publishes its NuGet package(s) to **nuget.org** and **GitHub Packages**.

## What it does

It writes `.github/workflows/publish-package.yml` into the target repository and
picks one of two strategies based on how many packable projects the solution has:

| Strategy | When | Tag format | Extras |
|---|---|---|---|
| **Single-package** | Exactly one packable project | any version tag — `1.2.3` or `v1.2.3` | none |
| **Multi-package** | More than one packable project | `<PackageId>@<version>` | copies `scripts/release.py` helper |

A project counts as **packable** when it opts in — an explicit `<PackageId>`,
`<IsPackable>true</IsPackable>`, or `<GeneratePackageOnBuild>true</GeneratePackageOnBuild>`
— and isn't excluded as an `<IsPackable>false</IsPackable>` project, a test project,
or an executable without a package id. So a repo with one library plus several test
projects is still *single-package*. The same rule lives verbatim in
[generate-nuget-lib-docs](generate-nuget-lib-docs.md), so the two skills never
disagree about what a repository ships.

The **multi-package** strategy additionally needs an explicit `<PackageId>` per
project, because its tags are `<PackageId>@<version>`. A project that packs under
the default id is packable but not addressable — the skill says so and asks you to
set the id rather than guessing one.

## When to use it

Ask for it when you want to:

- "publish to NuGet" / "add a release or publish workflow"
- "set up the GitHub Action to publish the package(s)"

**It requires a repository that actually ships a package.** If nothing is packable,
it stops and says so rather than generating a workflow with nothing to publish —
making a project packable is your decision, not its.

Skip it if the repo publishes somewhere other than NuGet / GitHub Packages.

## How it works

1. **Analyze the repo.** Detects packable projects from the repository root — not
   just `src/`, since not every repo has one — and reads each for `<PackageId>`,
   `<Version>`, `<RepositoryUrl>`, and `<TargetFramework>` (to choose the SDK
   version glob). Stops here if nothing is packable.
2. **Count them** to pick single- vs. multi-package.
3. **Write the workflow** from the matching template in `templates/`, filling the
   `__UPPER_CASE__` placeholders.
4. For multi-package, also copy `templates/release.py` to `scripts/release.py`.
5. **Align `CONTRIBUTING.md`'s Releasing section**, when the repo has one, with
   what the workflow now enforces.
6. **Report the follow-ups** you must do yourself (see below).

Both jobs otherwise behave identically: checkout the tag → **verify the tagged
commit is on `main`** → set up .NET → validate the tag version against the csproj
`<Version>` → restore → pack (Release) → `dotnet nuget push` to nuget.org then
GitHub Packages, each with `--skip-duplicate`. Only released code — what reached
`main` through a `release/*` pull request — can be published.

## What it refuses to do

| Temptation | What the skill does instead |
|---|---|
| Add `<PackageId>` so there's something to publish | Stops and asks — making a project packable is a release decision |
| Count test projects toward the strategy | Excludes them; one library plus three test projects is *single-package* |
| Use multi-package "for flexibility" | Lets the count decide; one package gets the simpler tag flow |
| Hardcode the SDK version | Derives it from `<TargetFramework>` |
| Infer the package id from the folder name | Reads `<PackageId>` — a guessed id produces tags nothing responds to |
| Skip `release.py` as mere ergonomics | Copies it; it is what makes per-package tagging usable, and it pushes tags one at a time on purpose |
| Drop the tag-on-main check because only the owner tags | Keeps it, before the build; a tag on any other branch publishes unreleased code |

## Files in this skill

| Path | Purpose |
|---|---|
| `SKILL.md` | The skill instructions. |
| `templates/single-package.yml` | Workflow for a one-package repo. |
| `templates/multi-package.yml` | Workflow for a multi-package repo. |
| `templates/release.py` | Interactive bump/tag/push helper for multi-package repos: bumps on the release branch (refuses `main`), tags and pushes only commits on `origin/main`. |

## After it runs — your responsibilities

- Add the `NUGET_API_KEY` secret in the repo settings (`GITHUB_TOKEN` is
  automatic; the workflow already requests `packages: write`).
- **Release, single-package:** set `<Version>` and finalize `CHANGELOG.md` on a
  `release/<version>` branch, merge its pull request into `main`, then tag the merge
  commit: `git switch main && git pull && git tag 1.2.3 && git push origin 1.2.3`
  (the tag must equal the csproj `<Version>`).
- **Release, multi-package:** on the release branch,
  `python scripts/release.py bump <project> patch`; after the merge, on `main`,
  `python scripts/release.py` (interactive) or `tag <project>` and `push <project>`.
- Restrict who can create version tags (the author's libraries use a "Version tags"
  ruleset), since a tag is a publish.

> The release helper pushes tags one at a time on purpose — GitHub drops the push
> event past three tags in a single push, so batch-pushing would publish nothing.
