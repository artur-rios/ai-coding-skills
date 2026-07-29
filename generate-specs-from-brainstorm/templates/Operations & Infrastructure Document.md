<!--
GUIDANCE — delete this comment block in the generated file.

Source: initial/Technology Stack.md, initial/Project Overview.md, plus the
Phase 2 operations questions from references/gap-questions.md.

This document owns the cross-cutting PLATFORM concerns that fall outside the
business domain — scaffolding, solution layout, configuration, logging, health,
environments, deployment. It is where operational capabilities that are real work
but not domain use cases get tracked formally.

Rules:
  - Name no versions — link to the Technology Stack Document.
  - Platform requirements get their own ID space, IR-xx, so they never collide
    with the domain's FR-<AREA>-xx.
  - If the project defines an operational use case (a health endpoint, a
    maintenance job), specify it here in full use case form and continue the UC
    numbering from the Use Case Specification Document rather than restarting.
-->

# Operations & Infrastructure Document — {{Project Name}}

## 1. Introduction

### 1.1 Purpose

This document captures **cross-cutting platform concerns** for **{{Project Name}}**
that fall outside the business domain modeled in the
[Vision Document](Vision%20Document.md),
[System Requirements Document](System%20Requirements%20Document.md), and
[Use Case Specification Document](Use%20Case%20Specification%20Document.md).

These are functional capabilities of the *platform* rather than the domain, so
they are documented here to keep the domain documents focused while still
tracking the work formally. The specific technologies and versions this platform
is built on are defined once in the
[Technology Stack Document](Technology%20Stack%20Document.md) and referenced from
here rather than duplicated.

### 1.2 Scope

<!-- Bulleted list of the areas this document covers: technical foundation,
     configuration, logging & monitoring, health, environments, delivery. -->

---

## 2. Technical Foundation

### 2.1 Overview

<!-- One paragraph: what the solution is structurally, and what the foundational
     scaffolding establishes that the domain features are built on top of. -->

### 2.2 Solution Architecture

```mermaid
graph TD
    subgraph {{Layer}}
        {{Component}}[{{Project or module}}<br/>{{role}}]
    end

    {{Component}} --> {{Dependency}}
```

### 2.3 Repository Layout

```
{{tree of the intended folder structure}}
```

### 2.4 Platform Requirements

| ID | Requirement |
| --- | --- |
| IR-01 | The solution shall {{structural or operational assertion}} |

---

## 3. Configuration

| Concern | Mechanism | Notes |
| --- | --- | --- |
| {{Setting group}} | {{env var / config file / secret store}} | {{how it is supplied}} |

<!-- List the configuration keys the system reads, their purpose, and which are
     secrets. Never write an actual secret value into this document. -->

---

## 4. Logging & Monitoring

<!-- What is logged, at what level, in what format, and where it goes. What is
     deliberately never logged (credentials, personal data, tokens). -->

| Concern | Approach |
| --- | --- |
| {{Log format}} | {{structured / plain}} |
| {{Destination}} | {{console / file / aggregator}} |
| {{Never logged}} | {{sensitive fields}} |

---

## 5. Health & Monitoring Endpoints

<!-- Omit this whole section for systems with no runtime surface to probe (e.g. a
     library). Otherwise specify the endpoints and their response contracts. -->

### 5.1 Endpoints

| Endpoint | Purpose | Authorization |
| --- | --- | --- |
| {{path}} | {{liveness / readiness / detailed}} | {{public / authenticated}} |

### 5.2 Response Contract

```json
{
  "{{field}}": "{{type}}"
}
```

### 5.3 Use Case — {{UC-nn}}: {{Name}}

<!-- Use the same use case field table as the Use Case Specification Document.
     Continue that document's UC numbering; do not restart at 01. -->

---

## 6. Environments

| Environment | Purpose | Differences |
| --- | --- | --- |
| {{Local}} | {{development}} | {{what differs}} |

---

## 7. Build & Delivery

<!-- How the system is built, packaged, and deployed. Include the pipeline stages
     if a CI/CD system is used. If deployment is undecided, state that explicitly
     as a decision deferred, and say what it depends on. -->

---

## 8. Traceability

| Platform capability | Requirements |
| --- | --- |
| {{Capability}} | IR-01 through IR-{{nn}} |
