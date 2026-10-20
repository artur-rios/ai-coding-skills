<!--
GUIDANCE — delete this comment block in the generated file.

The contributor guide, written at the repository root in Phase 3 alongside the
README and CHANGELOG.md. It holds everything a person changing the project needs
and a person using it does not: prerequisites for building, the build and test
commands, the branching model, the commit and changelog rules, the versioning
policy and the release process. None of this is repeated in the README, which
links here.

The project has no code yet, so the commands are the **intended** ones. Take
them from the documents — never write a command you cannot point to a document
for, and ask when the documents do not determine one:
  {{build prerequisite}}  SDKs, runtimes and services a contributor needs —
                          Technology Stack Document
  {{build command}}       Technology Stack Document
  {{test command}}        Testing Specification Document §Running the suites
  {{category test command}} one line per test category, if the Testing
                          Specification separates them (filters, tags, projects)
  {{test categories}}     what each category exercises — Testing Specification
  {{test naming}}         the naming convention — Testing Specification

For a .NET project with the default testing standard: xUnit, every test named
Given / When / Then, and every test class carrying a `Category` trait (`Unit` or
`Functional`) so the categories run — and are reported — separately:
  dotnet test src/<Solution>.sln --filter "Category=Unit"
  dotnet test src/<Solution>.sln --filter "Category=Functional"
CI runs each category as its own job.

Other substitutions:
  {{unit of work}}        as in the Development Workflow Document
  {{branch example}}      a filled-in branch, e.g. feature/uc-01-create-order
  {{commit example}}      two lowercase Conventional Commits subjects that fit the
                          project, e.g. `feat: let a customer place an order`
  {{audience}}            who reads the changelog: "a user", "an API client or an
                          operator", "a package consumer"
  {{versioning meaning}}  what major / minor / patch mean for THIS kind of project
                          (see below)
  {{version location}}    where the version number lives and how it is set

Versioning — SemVer is the policy; say what a major, minor and patch release
mean for this kind of project:
  - API service: major = a breaking change to the HTTP contract, a configuration
    change operators must act on, or a data migration that cannot be rolled back
    transparently; minor = new endpoints, fields, options or behaviour that
    existing clients and deployments do not notice; patch = fixes.
  - Application: major = a change in user-visible behaviour users must relearn,
    data that cannot be read by the previous version, required configuration
    changes, or dropped client/platform compatibility; minor = new features;
    patch = fixes.
  - Library: major = a breaking change to the public API or its documented
    behaviour; minor = new API or non-breaking behaviour; patch = fixes.
The version lives where the Technology Stack Document puts it (a csproj
`<Version>`, `pubspec.yaml`, `Cargo.toml`, `package.json`) — or, when the source
carries none, in the release branch name and tag. While the version is 0.x, add
the SemVer note: anything may change between 0.x releases, and state how this
project applies SemVer before 1.0 (e.g. a minor bump marks a breaking change).

The Releasing section assumes the default delivery: a tag on `main` marks the
release. If the Operations & Infrastructure Document defines a deployment
pipeline that merges or tags (a CD job, a release workflow), describe what it
does in step 3 instead of the manual tag. Keep the sentence about tag-triggered
workflows only if the documents define one (a publish or release workflow); such
a workflow must start by failing unless the tagged commit is on `main`.
-->

# Contributing

One {{unit of work}} = one branch = one issue = one pull request. The full process — branch naming, the
issue status lifecycle, the approval gates, the testing gate, and the Definition of Done — is in the
[Development Workflow Document](requirements/Development%20Workflow%20Document.md), with its
step-by-step operational form in [`initial/Workflow.md`](initial/Workflow.md).

## Prerequisites

{{build prerequisite}} — see the
[Technology Stack Document](requirements/Technology%20Stack%20Document.md).

## Building

```bash
{{build command}}
```

## Testing

The following command runs the complete suite described in the
[Testing Specification Document](requirements/Testing%20Specification%20Document.md):

```bash
{{test command}}
```

The suite covers {{test categories}}. Tests are named {{test naming}}. Run one category at a time:

```bash
{{category test command}}
```

Every {{unit of work}} ships with its tests before its pull request is opened.

## Branching model

```
feature/<name> ─┐
fix/<name> ─────┴─▶ develop ──▶ release/x.y.z ──▶ main  (tag vx.y.z)
```

| Branch | Cut from | Merges into | How |
|---|---|---|---|
| `feature/<name>`, `fix/<name>` | `develop` | `develop` | Pull request, squash or merge. The branch is deleted on merge. |
| `release/x.y.z` | `develop` | `main` | Pull request, merged with a merge commit. |
| `develop`, `main` | — | — | Protected: no direct pushes, no force pushes, no deletion. |

`develop` is the integration branch and the base for all new work, e.g. `{{branch example}}`; `main` only
holds released code. Names are lowercase: letters, digits, `.`, `_` and `-`. A `release/` branch is a
snapshot of `develop` and carries no commits of its own: a fix for a release lands on `develop` through a
`fix/` branch and a new release branch is cut.

The **Branch Policy** workflow checks all of this on every pull request and is a required check on
`develop` and `main`. The rulesets *Develop: PRs only* and *Main: release PRs only* protect the two
branches, and *Version tags* reserves release tags for the repository owner.

## Commits and the changelog

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/) with a lowercase
subject, e.g. {{commit example}}.

Record every change {{audience}} would notice under `## [Unreleased]` in [CHANGELOG.md](./CHANGELOG.md),
in the same pull request that makes it.

## Versioning

Releases follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html). {{versioning meaning}}

{{version location}}

## Releasing

1. Because a release branch carries no commits of its own, finalize the changelog on `develop` first: in
   a `feature/` or `fix/` branch, rename `## [Unreleased]` in [CHANGELOG.md](./CHANGELOG.md) to
   `## [x.y.z] - <yyyy-mm-dd>` above a fresh, empty `## [Unreleased]`, update the compare links at the
   bottom — and set the version where it lives, if the source carries one — then merge it into
   `develop`.
2. Cut the release branch from `develop` and open a pull request into `main`:

   ```bash
   git switch develop && git pull && git switch -c release/x.y.z && git push -u origin release/x.y.z
   ```

3. Once every check passes, merge it with a merge commit, then tag the merge commit on `main`:

   ```bash
   git switch main && git pull
   git tag vx.y.z && git push origin vx.y.z
   ```

The release workflow triggered by the tag verifies that the tagged commit is on `main` and refuses to
run otherwise. The repository owner can bypass these rules; that is for emergencies, not for routine work.
