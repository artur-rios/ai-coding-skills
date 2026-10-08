# CHANGELOG Entry

*(Shared verbatim between `implement-use-case` and `implement-use-cases-batch`.
Change it in both or neither.)*

Projects that keep a `CHANGELOG.md` record every change a reader of it would notice
under `## [Unreleased]`, **in the same pull request that makes the change** — that is
what their `CONTRIBUTING.md` asks of every contributor, and a use case is the
largest such change there is. When the repository has no `CHANGELOG.md`, this file
does not apply.

## 1. Does this repository keep a changelog?

Look for `CHANGELOG.md` at the repository root with a `## [Unreleased]` heading —
the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) layout. Read
`CONTRIBUTING.md` too: it usually says who the changelog is written for ("every
change an API client or operator would notice", "every change a user would
notice").

| Found | Do |
| --- | --- |
| `CHANGELOG.md` with `## [Unreleased]` | Add the entry (§2) |
| `CHANGELOG.md` without `## [Unreleased]` | Add `## [Unreleased]` directly above the newest release heading, then the entry; say so at the gate |
| No `CHANGELOG.md` | Do **not** create one — starting a changelog is a project decision, not part of a use case. Say so at the gate (or in the batch report) |

## 2. What to write

One entry for the use case, under the subsection of `## [Unreleased]` that fits:

| The use case | Subsection |
| --- | --- |
| Adds a capability (the usual case) | `### Added` |
| Changes existing behaviour a reader relies on | `### Changed` |
| Corrects behaviour (a `fix/` branch) | `### Fixed` |
| Removes or deprecates something | `### Removed` / `### Deprecated` |
| Closes a vulnerability | `### Security` |

Reuse the subsection if it already exists under `## [Unreleased]`; otherwise add it,
in Keep a Changelog order (Added, Changed, Deprecated, Removed, Fixed, Security).

**Write for the changelog's reader, not for the reviewer.** Say what the API client,
operator, or user can now do or will now see — not which handlers, classes, or
tests were added. Match the file's own phrasing: its sentence shape, its tense, its
line width, whether entries name the use case. Read the existing entries first.

```markdown
## [Unreleased]

### Added

- A person can recover their password by email: a single-use, expiring reset link,
  and a confirmation once the password changes.
```

## 3. What not to touch

- **Released sections.** Everything below `## [Unreleased]` is history.
- **The compare links at the bottom**, and the `## [Unreleased]` heading's name.
  Those change when the owner finalizes a release, not in a use case.
- **Other entries.** Do not reword, reorder, or merge entries this use case did
  not write.

## 4. When it happens

The entry is committed **on the use case's branch**, together with the README
backlog update when there is one, right before the pull request is opened. It
reaches `develop` (or whatever base branch applies) only when the pull request
merges — the same moment the work does. If the pull request is abandoned, the
entry goes with it, which is the correct outcome.
