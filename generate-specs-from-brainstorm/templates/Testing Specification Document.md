<!--
GUIDANCE — delete this comment block in the generated file.

Source: initial/Technology Stack.md (test tooling), initial/Workflow.md (when
tests happen), plus the Phase 2 testing questions.

This document defines HOW tests are written. It does not define WHEN they happen
in the delivery flow — that is the Development Workflow Document — and it does
not pin tool versions — that is the Technology Stack Document.

Adapt the test categories to the project. A library has unit tests and maybe
integration tests but no end-to-end HTTP tests; a service has both. Drop a
category section entirely rather than writing "not applicable".
-->

# Testing Specification Document — {{Project Name}}

## 1. Purpose

This document defines **how a {{unit of work}} is tested once it has been
implemented**. It is a standard to be followed by any human or agent that builds
tests for this project, so that every {{unit of work}} in the
[Use Case Specification Document](Use%20Case%20Specification%20Document.md)
receives the same shape of testing, with the same tools, naming, and structure.

The rule is simple:

> **After a {{unit of work}} is developed, tests are built for it in the same
> change — before it is considered done.** A {{unit of work}} without its tests is
> incomplete.

The tools and versions used are defined in the
[Technology Stack Document](Technology%20Stack%20Document.md); when the tests run
in the delivery flow is defined in the
[Development Workflow Document](Development%20Workflow%20Document.md).

## 2. Testing philosophy

<!-- Numbered principles. Cover at least: what tests describe (behavior, not
     implementation), which layer each kind of logic is tested at, how isolated
     unit tests are, how realistic integration/end-to-end tests are, and that the
     same pattern is applied every time. -->

1. **Behavior-driven.** Tests describe *behavior*, not implementation.
2. **Test at the right layer.** {{which logic is unit-tested, which is tested end to end}}
3. **Isolation in unit tests.** {{how dependencies are replaced}}
4. **Realism in {{integration/functional}} tests.** {{what is real rather than faked}}
5. **Same pattern every time.** The workflow in §8 is applied identically to every
   {{unit of work}}.

## 3. What to test for each {{unit of work}}

| Artifact produced | Test kind | Test location |
| --- | --- | --- |
| {{artifact}} | {{Unit / Integration / Functional}} | {{project or folder}} |

<!-- Follow with notes on what deliberately gets NO tests and why — for example
     plain data holders with no behavior. Being explicit about the exclusions is
     what stops the suite filling with empty tests. -->

## 4. Test project layout

<!-- How the test tree mirrors the source tree, and the naming rule that maps a
     production unit to its test unit. -->

```
{{tree showing src/ and its mirrored tests/}}
```

## 5. Naming & structure

Every test is named with the **{{naming convention}}** pattern:

```
{{example test name}}
```

Every test body follows the {{Arrange/Act/Assert or Given/When/Then}} shape:

```{{language}}
{{short annotated example}}
```

## 6. {{Unit}} testing standard

### 6.1 Scope of a {{unit}} test

<!-- Exactly what one test exercises, and what it must not reach into. -->

### 6.2 Test doubles

<!-- Which double is used for which kind of collaborator, and the rule against
     introducing a second mocking library. -->

### 6.3 Coverage per unit

<!-- The checklist a test author walks for each production unit: happy path,
     each validation failure, each not-found, each authorization denial, each
     boundary. -->

## 7. {{Integration / Functional}} testing standard

### 7.1 Scope

<!-- What one test exercises end to end, and through which entry point. -->

### 7.2 External dependencies

<!-- How the datastore and any external service are provided during these tests —
     container, sandbox, or fake — and why. -->

### 7.3 Coverage per entry point

<!-- Main flow plus every AF-xx, including authorization flows. State that both
     the response and the resulting persisted state are asserted. -->

## 8. Per-{{unit of work}} workflow

Apply this every time:

1. {{step}}
2. {{step}}

## 9. Running the suites

```bash
{{test command}}
```

| Suite | Command |
| --- | --- |
| {{category}} | `{{command}}` |

<!-- Include how the categories are separated (tags, traits, filters, separate
     projects) so one kind can be run without the other. -->
