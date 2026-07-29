<!--
GUIDANCE — delete this comment block in the generated file.

Source: all four initial/ documents, plus the Phase 2 System Requirements
questions from references/gap-questions.md.

This is the longest document in the folder and the one every use case traces
into. Rules:
  - One testable assertion per requirement row. Split compound statements.
  - "The system shall …" phrasing throughout.
  - Requirement IDs are FR-<AREA>-xx, restarting at 01 per §3 subsection.
  - Name no library versions — link to the Technology Stack Document instead.
  - §3 subsections mirror the domain areas; one area code each.
-->

# System Requirements Document — {{Project Name}}

## 1. Introduction

### 1.1 Purpose

<!-- What this document specifies. State plainly that the concrete technology
     stack lives in the Technology Stack Document and is not restated here. -->

This document specifies the functional and non-functional requirements for
**{{Project Name}}**.

The concrete technology stack — platform and language versions, libraries,
database, and tooling — is defined in the
[Technology Stack Document](Technology%20Stack%20Document.md). This document
states requirements and refers to that one for specific technologies and versions
rather than restating them.

### 1.2 Scope

<!-- One paragraph enumerating the capability areas the system covers. -->

### 1.3 Definitions

| Term | Definition |
| --- | --- |
| {{Term}} | {{Definition}} |

---

## 2. System Overview

```mermaid
graph LR
    subgraph Clients
        C1[{{Client}}]
    end

    subgraph {{Project Name}}
        M1[{{Module}}]
    end

    subgraph Infrastructure
        DB[({{Datastore}})]
        EXT[{{External Service}}]
    end

    C1 --> M1
    M1 --> DB
    M1 --> EXT
```

---

## 3. Functional Requirements

<!-- One H3 per domain area. Each area owns one two-letter code. -->

### 3.1 {{Domain Area}}

| ID | Requirement |
| --- | --- |
| FR-{{XX}}-01 | The system shall {{testable assertion}} |

<!-- Repeat 3.2, 3.3 … for every area. -->

---

## 4. Data Model

### 4.0 Identifier Strategy

<!-- How entities are addressed internally versus externally. If the project uses a
     single identifier, say so explicitly in one paragraph and keep the heading —
     downstream documents reference this section. -->

### 4.1 Entity Relationship Diagram

```mermaid
erDiagram
    {{ENTITY_A}} ||--o{ {{ENTITY_B}} : {{relationship}}
```

### 4.2 {{Entity}} Fields

| Field | Type | Constraints | Description |
| --- | --- | --- | --- |
| {{Field}} | {{type}} | {{required / unique / range}} | {{meaning}} |

<!-- One H3 per entity, numbered sequentially. -->

---

## 5. {{Interface}} Overview

<!-- For an HTTP API: "API Endpoints Overview", one H3 per resource.
     For a CLI: "Command Surface". For a library: "Public API Surface".
     For a worker: "Triggers and Messages". Title the section accordingly. -->

### 5.1 {{Resource}} Endpoints

| Method | Path | Description | Requirement |
| --- | --- | --- | --- |
| {{VERB}} | {{/path}} | {{what it does}} | FR-{{XX}}-01 |

---

## 6. Non-Functional Requirements

| ID | Category | Requirement |
| --- | --- | --- |
| NFR-01 | {{Performance / Security / Availability / Maintainability}} | The system shall {{testable assertion}} |

<!-- If the user has defined no targets, do not invent numbers. State the
     categories that apply and record explicitly that thresholds are to be set
     before the first release — that is a decision, not a placeholder. -->

---

## 7. Authorization Matrix

| Operation | {{Role A}} | {{Role B}} | {{Role C}} |
| --- | --- | --- | --- |
| {{Operation}} | ✅ | ⚠️ {{condition}} | ❌ |

<!-- Legend: ✅ allowed · ⚠️ allowed under a stated condition · ❌ denied.
     Include the legend below the table. Omit the section only for single-actor
     systems with no access control at all. -->

---

## 8. {{Lifecycle}} Strategy

<!-- Deletion, archival, state transitions — whatever lifecycle rules the Business
     Rules document established. Use a flowchart when branching behavior differs
     by entity, and follow it with the cascade notes. -->

```mermaid
flowchart TD
    A[{{Request}}] --> B{ {{Decision}} }
    B -->|{{branch}}| C[{{Outcome}}]
```

---

## 9. Traceability

| Feature | Requirements |
| --- | --- |
| {{F-01 feature name}} | FR-{{XX}}-01 through FR-{{XX}}-{{nn}} |

| Business Rule | Realized by |
| --- | --- |
| BR-01 | FR-{{XX}}-01, FR-{{XX}}-04 |

<!-- Every F-xx from the Vision Document and every BR-xx from the Business Rules
     document appears in exactly one row. -->
