# Document Conventions

The rules every generated document follows. Read this once before writing the
first document of a phase, then apply it to every file in that phase.

## 1. File naming and location

`initial/` and `requirements/` are **siblings at the project root**, never nested
inside one another. `Brainstorm.md` lives **inside `initial/`** alongside the
documents it produced, and `README.md`, `CHANGELOG.md` and `CONTRIBUTING.md` sit
at the root, written together in Phase 3:

```
<project-root>/
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── initial/
│   ├── Brainstorm.md
│   ├── Project Overview.md
│   ├── Technology Stack.md
│   ├── Workflow.md
│   └── Business Rules.md
└── requirements/
    ├── Vision Document.md
    ├── System Requirements Document.md
    ├── Use Case Specification Document.md
    ├── Development Workflow Document.md
    ├── Operations & Infrastructure Document.md
    ├── Technology Stack Document.md
    └── Testing Specification Document.md
```

The project root is the folder the brainstorm was found in — unless it was found
in a folder already named `initial/`, in which case the root is that folder's
parent.

File names are **exact** — Title Case, spaces preserved, `.md` extension. Do not
kebab-case them, do not add numeric prefixes, do not pluralize.

## 2. Document title

Every document's `H1` is its file name (without extension) followed by an em dash
and the project name:

```markdown
# Vision Document — Acme Ordering API
```

The same project name string is used in all eleven specification documents. The
three root files are the exception: the `README.md` `H1` is the project name
alone, and `CHANGELOG.md` and `CONTRIBUTING.md` use the conventional `# Changelog`
and `# Contributing`.

## 3. Identifier schemes

| Prefix | Applies to | Format | Lives in |
| --- | --- | --- | --- |
| `F-xx` | Feature | `F-01`, `F-02` … zero-padded, sequential | Vision Document §Core Features |
| `BR-xx` | Business rule | `BR-01` … zero-padded, sequential | `initial/Business Rules.md` |
| `FR-<AREA>-xx` | Functional requirement | `FR-PE-01` — area code + zero-padded number restarting per area | System Requirements Document §3 |
| `NFR-xx` | Non-functional requirement | `NFR-01` … zero-padded, sequential across the whole document | System Requirements Document §6 |
| `UC-xx` | Use case | `UC-01` … zero-padded, sequential across the whole document | Use Case Specification Document §2 |
| `AF-xx` | Alternative / exception flow | `AF-01` … numbered **within** its own use case, restarting at `01` for each | Use Case Specification Document, inside each use case |
| `TC-<AREA>-xx` | Test case grouping | Optional; only when the Testing Specification enumerates named suites | Testing Specification Document |
| `M-xx` | Milestone | `M-01` … zero-padded, sequential in dependency order | GitHub milestone titles and the README roadmap |

Identifiers are **never renumbered** once written. If a requirement is dropped
later, the document keeps the number and marks it withdrawn rather than shifting
everything below it.

### Area codes

Area codes are two uppercase letters derived from the project's own domain areas,
one per functional grouping in System Requirements §3. Derive them from the
entities and capability groups named in the approved `initial/` documents — do
not reuse codes from an unrelated project. Examples of the *shape*:

| Domain area | Code | Requirement IDs |
| --- | --- | --- |
| Order management | `OR` | `FR-OR-01` … |
| Catalog | `CA` | `FR-CA-01` … |
| Billing | `BI` | `FR-BI-01` … |

Keep one code per `H3` section of System Requirements §3, and list the mapping in
that document's traceability table.

## 4. Traceability rules

Traceability is the spine of the requirements folder. Three links are mandatory:

1. **Business rule → functional requirement.** Every `BR-xx` in
   `initial/Business Rules.md` is realized by at least one `FR-<AREA>-xx`. The
   System Requirements Document records this in its traceability section.
2. **Use case → functional requirement.** Every `UC-xx` cites the `FR-<AREA>-xx`
   requirements it implements, in its own table row *and* in the Use Case
   Specification's traceability section.
3. **Feature → requirement range.** Every `F-xx` from the Vision Document maps to
   a contiguous requirement range (`FR-OR-01 through FR-OR-09`) in the System
   Requirements traceability table.

Every referenced identifier must exist. A `UC` citing `FR-OR-14` when the
document defines requirements only up to `FR-OR-11` is a defect — the
verification pass catches it.

## 5. Cross-document links

Documents link to each other with **relative, URL-encoded** markdown links.
Spaces become `%20` and `&` becomes `%26`:

| Target | Link |
| --- | --- |
| Vision Document | `[Vision Document](Vision%20Document.md)` |
| System Requirements Document | `[System Requirements Document](System%20Requirements%20Document.md)` |
| Use Case Specification Document | `[Use Case Specification Document](Use%20Case%20Specification%20Document.md)` |
| Development Workflow Document | `[Development Workflow Document](Development%20Workflow%20Document.md)` |
| Operations & Infrastructure Document | `[Operations & Infrastructure Document](Operations%20%26%20Infrastructure%20Document.md)` |
| Technology Stack Document | `[Technology Stack Document](Technology%20Stack%20Document.md)` |
| Testing Specification Document | `[Testing Specification Document](Testing%20Specification%20Document.md)` |

From `requirements/` back to an `initial/` document, prefix with `../initial/`.
From the root `README.md`, prefix with the folder name — `requirements/` or
`initial/` — and encode the same way.

**Single source of truth rule:** the Technology Stack Document owns every
framework, library, and version. Other documents *link* to it and never restate a
version number. When a technology changes, it changes there first.

## 6. Diagrams

Use mermaid fenced blocks. Each document has an expected diagram set:

| Document | Diagram | Mermaid type |
| --- | --- | --- |
| Vision | System context | `C4Context` |
| Vision | Domain model overview | `erDiagram` |
| Vision | Role / actor hierarchy | `graph TD` |
| System Requirements | Module overview | `graph LR` |
| System Requirements | Entity relationships | `erDiagram` |
| System Requirements | Deletion / lifecycle strategy | `flowchart TD` |
| Use Case Specification | Actor-to-use-case overview | `graph LR` with `subgraph` per area |
| Use Case Specification | Entity state diagrams | `stateDiagram-v2` |
| Development Workflow | Delivery flow | `flowchart TD` |
| Operations & Infrastructure | Solution / deployment architecture | `graph TD` |

Omit a diagram only when the project genuinely has no such dimension (e.g. no
external actors at all). Never emit an empty or placeholder diagram.

## 7. Prose and table style

- Tables for anything enumerable: definitions, requirements, actors, versions,
  endpoints, permissions. Prose only for rationale that a table cannot carry.
- Requirement statements use **"The system shall …"** phrasing, one testable
  assertion per row. Split compound requirements.
- Bold the term being defined in a definitions table's left column.
- Separate top-level sections with `---` where the reference documents do.
- Number top-level sections (`## 1. Introduction`, `## 2. …`) in every
  `requirements/` document. The `initial/` documents may use unnumbered headings.
- Keep lines readable; wrap prose around 100 characters.

## 8. No placeholders in output

Generated documents must contain no `TBD`, no `TODO`, no `{{token}}`, no
`<!-- GUIDANCE -->` comment, and no bracketed instruction left over from a
template. Anything the source material does not answer is asked as a question
**before** writing, per `gap-questions.md` — it is never shipped as a gap marker.
