<!--
GUIDANCE — delete this comment block in the generated file.

Source: System Requirements Document §3 (every FR must be exercised by at least
one use case), initial/Business Rules.md, and the Phase 2 use case questions.

Rules:
  - One UC per user-visible operation. Number them UC-01 upward, grouped by domain
    area in the order the areas appear in System Requirements §3.
  - Every UC gets the full field table, a numbered main flow, and its alternative
    flows. AF numbering restarts at AF-01 inside each use case.
  - Every UC cites the FR-<AREA>-xx requirements it implements.
  - Cover at minimum: not-found, unauthorized, and invalid-input alternative flows
    wherever they can occur.
-->

# Use Case Specification Document — {{Project Name}}

## 1. Introduction

### 1.1 Purpose

This document specifies the use cases for **{{Project Name}}**. Each use case
describes actor interactions, preconditions, postconditions, main flows, and
alternative/exception flows.

<!-- If the System Requirements Document defines an identifier strategy where the
     externally-visible id differs from the internal one, add a note here that
     every {id} in these flows is the external identifier. -->

### 1.2 Actors

| Actor | Description |
| --- | --- |
| **{{Actor}}** | {{what they are and what access they have}} |

<!-- Include external systems as actors when the system calls out to them. -->

### 1.3 Use Case Overview

```mermaid
graph LR
    subgraph Actors
        A1(("{{Actor}}"))
    end

    subgraph "{{Domain Area}}"
        UC01[UC-01: {{Name}}]
    end

    A1 --> UC01
```

---

## 2. Use Case Specifications

---

### UC-01: {{Name}}

| Field | Value |
| --- | --- |
| **ID** | UC-01 |
| **Name** | {{Name}} |
| **Actors** | {{Actor}}{{, Actor}} |
| **Description** | {{what the use case allows and why}} |
| **Preconditions** | {{what must be true before the flow starts}} |
| **Postconditions** | {{what is true after the main flow succeeds}} |
| **Requirements** | FR-{{XX}}-01, FR-{{XX}}-02 |

**Main Flow**

1. {{Actor does something}}
2. {{System validates …}}
3. {{System performs …}}
4. {{System returns …}}

**Alternative Flows**

| ID | Condition | Outcome |
| --- | --- | --- |
| AF-01 | {{invalid input}} | {{system rejects with …}} |
| AF-02 | {{target not found}} | {{system responds …}} |
| AF-03 | {{actor not authorized}} | {{system denies with …}} |

---

<!-- Repeat the block above for UC-02, UC-03 … in area order. -->

---

## 3. Use Case — Requirements Traceability

| Use Case | Requirements |
| --- | --- |
| UC-01: {{Name}} | FR-{{XX}}-01, FR-{{XX}}-02 |

<!-- Every FR from System Requirements §3 must appear at least once in this table.
     An FR exercised by no use case is either dead or a missing use case — resolve
     it, do not ship it. -->

---

## 4. State Diagrams

### 4.1 {{Entity}} Lifecycle

```mermaid
stateDiagram-v2
    [*] --> {{Initial}}
    {{Initial}} --> {{Next}} : {{transition}}
    {{Next}} --> [*] : {{terminal transition}}
```

<!-- One H3 per entity that has a meaningful lifecycle. Omit the whole section if
     no entity has states beyond "exists". -->
