# create-unit-tests

Generates a thorough unit-test suite for a target project (or a single class,
module, or function), with two hard rules: **Given-When-Then test names** and
**exhaustive coverage** including edge cases.

## What it does

- Names every test `GivenSomeCondition_WhenSomeAction_ThenSomeOutput`.
- Covers the happy path **and** the edge cases — boundaries, nulls, empty inputs,
  exceptions, state/side effects, and collaborator interactions.
- Detects and matches the project's existing test framework and assertion/mocking
  libraries rather than introducing new ones.
- Runs the suite and reports the result, plus any real defects the tests surfaced.

## When to use it

Ask for it with phrases like "write unit tests", "add tests for this class",
"cover this module with tests", or "unit test this function".

It's aimed at unit-level tests. For integration or end-to-end tests the naming
convention still helps, but the edge-case taxonomy is unit-focused.

## The naming rule

Each test name has exactly three PascalCase segments joined by underscores:

```
Given<PreconditionOrState>_When<ActionUnderTest>_Then<ExpectedOutcome>
```

Example: `GivenEmptyCart_WhenCheckoutIsCalled_ThenThrowsInvalidOperation`.

`Then` states one observable outcome (return value, thrown exception, state
change, or interaction). Two unrelated assertions mean two tests. For languages
where test names are strings (JS, Python, Ruby) the same three parts go into the
description text.

## How it works

1. **Identify** the target and detect the test framework (.NET/xUnit-NUnit-MSTest,
   Jest/Vitest, pytest, JUnit, …).
2. **Read the code under test** — parameters, return types, throws, dependencies,
   state. It never invents behavior.
3. **Enumerate scenarios first** across a fixed taxonomy (happy path, boundaries,
   invalid input, empty/missing, errors, state/side effects, interactions) so
   coverage is visible before any test is written.
4. **Write the tests** — one behavior per test, Arrange-Act-Assert body under a
   Given-When-Then name, data-driven tests for input families, mocks only for
   external collaborators.
5. **Run the suite** and fix genuine test bugs; real code defects are reported, not
   hidden by adjusting assertions.
6. **Report** an overview: target, scenario list, pass/fail numbers, and any gaps
   or defects found.

## Files in this skill

| Path | Purpose |
|---|---|
| `SKILL.md` | The skill instructions. |
| `references/edge-cases.md` | The edge-case taxonomy that turns "cover everything" into a concrete scenario list. |
| `references/example-xunit.md` | A complete worked example (C#/xUnit) mapping each test to its scenario category. |

## What you get back

After it runs, you receive an overview covering:

- **Target** — what was tested and the framework used.
- **Scenario list** — behaviors and edge cases covered, grouped by unit.
- **Result** — the actual pass/fail numbers from the test run.
- **Gaps & findings** — anything left uncovered and why, plus real defects or
  ambiguities the tests surfaced in the code under test.
