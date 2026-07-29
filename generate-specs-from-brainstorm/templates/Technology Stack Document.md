<!--
GUIDANCE — delete this comment block in the generated file.

Source: initial/Technology Stack.md, plus the Phase 2 version questions.

This document is the SINGLE SOURCE OF TRUTH for every technology and version. No
other document in the folder restates a version — they link here. Keep the
closing Version Summary table complete: every technology named anywhere above
appears in it exactly once.

Never invent a version number. When the user does not know, write
"latest stable at implementation time" in the version cell — that is a recorded
policy, not a placeholder.

Section headings adapt to the project: a library has no "Relational Database"
section; a worker has no "API documentation" row. Drop sections that do not
apply rather than filling them with "N/A".
-->

# Technology Stack Document — {{Project Name}}

## 1. Purpose

This document is the **single source of truth for the technologies used to build
{{Project Name}}** — the runtime platform, language, libraries, data storage,
cross-cutting concerns, and testing tools, together with the version each is
pinned to and the role it plays.

Every other document in this folder **references this document** for technical
choices instead of restating them, so that:

- The domain documents ([Vision](Vision%20Document.md),
  [System Requirements](System%20Requirements%20Document.md),
  [Use Case Specification](Use%20Case%20Specification%20Document.md)) stay focused
  on *what* the system does.
- The [Operations & Infrastructure Document](Operations%20%26%20Infrastructure%20Document.md)
  stays focused on the platform's structure and operations.
- The [Testing Specification Document](Testing%20Specification%20Document.md)
  stays focused on *how* to test.
- Technology versions and roles are maintained in exactly **one** place.

> **Rule:** when a technology choice changes, it changes here first. Other
> documents link to this one rather than duplicating the detail.

---

## 2. Platform & Language

| Concern | Choice | Notes |
| --- | --- | --- |
| Runtime / framework | **{{platform}}** | {{how it is targeted}} |
| Language | **{{language + version}}** | {{whether the version is pinned or tracks the platform default}} |
| Language features | {{compiler settings applied project-wide}} | {{where they apply}} |

---

## 3. Libraries

| Package | Version | Used by | Role |
| --- | --- | --- | --- |
| **{{package}}** | `{{version}}` | {{component}} | {{what it provides}} |

<!-- Split into subsections (first-party, third-party) only when the project has
     a meaningful first-party library family. -->

---

## 4. Data Storage

| Concern | Choice |
| --- | --- |
| {{Datastore}} | **{{engine}}** — {{why it is the choice}} |
| Connection configuration | {{how the connection is supplied}} |

<!-- State whether the same engine is used in every environment including tests,
     or where it differs and why. Omit this section entirely for stateless
     systems. -->

---

## 5. Data Access

| Concern | Choice | Version |
| --- | --- | --- |
| {{ORM / driver}} | **{{choice}}** | `{{version}}` |
| Migrations | {{tooling}} | `{{version}}` |
| Naming convention | {{convention}} | — |

<!-- Close with a paragraph on the access pattern (repository, direct context,
     query objects) and what that buys — it is usually what makes the code
     testable, which the Testing Specification depends on. -->

---

## 6. Cross-Cutting Technologies

| Concern | Technology | Version | How it is used |
| --- | --- | --- | --- |
| Input validation | {{choice}} | `{{version}}` | {{how}} |
| Logging | {{choice}} | `{{version}}` | {{how}} |
| Authentication / authorization | {{choice}} | `{{version}}` | {{how}} |
| Error / result model | {{choice}} | `{{version}}` | {{how}} |
| API documentation | {{choice}} | `{{version}}` | {{how}} |
| Configuration | {{choice}} | — | {{how}} |

<!-- Drop rows that do not apply. Do not leave a row with "N/A". -->

---

## 7. Testing Technologies

These are the technologies mandated for tests. **How** they are applied (naming,
structure, coverage, the per-unit workflow) is defined in the
[Testing Specification Document](Testing%20Specification%20Document.md); this
section is the canonical list of the tools and versions.

| Concern | Technology | Version | How it is used |
| --- | --- | --- | --- |
| Test framework | {{choice}} | `{{version}}` | {{how}} |
| Test runner / SDK | {{choice}} | `{{version}}` | {{how}} |
| Coverage | {{choice}} | `{{version}}` | {{how}} |
| Mocking / test doubles | {{choice}} | `{{version}}` | {{how}} |
| Test data generation | {{choice}} | `{{version}}` | {{how}} |
| Integration dependencies | {{choice}} | `{{version}}` | {{how}} |

---

## 8. Version Summary

| Category | Package / Tool | Version |
| --- | --- | --- |
| Platform | {{platform}} | `{{version}}` |
| Language | {{language}} | `{{version}}` |
| {{Category}} | {{package}} | `{{version}}` |

<!-- Every technology named anywhere in this document appears here exactly once.
     This table is what a reader checks when upgrading. -->
