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

**Given-When-Then is the default, not an override.** If your repository documents
its own convention — a `Testing Specification Document`, a `CONTRIBUTING.md`
section, or a pattern the existing tests already follow — the skill follows that
instead, surfaces the difference, and tells you which it used. A repo with two
naming schemes is worse off than one using the scheme you'd not have picked. This
is also what keeps it consistent when
[implement-use-case](implement-use-case.md) delegates the unit layer to it.

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

1. **Identify** the target, detect the test framework (.NET/xUnit-NUnit-MSTest,
   Jest/Vitest, pytest, JUnit, …), and check for a project testing standard that
   overrides the default naming.
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

## What it refuses to do

The skill carries a red-flag list for the ways a test suite quietly becomes
worthless:

| Temptation | What the skill does instead |
|---|---|
| Ship the happy path and add edge cases "later" | Treats the edge cases as the deliverable |
| Discover scenarios while writing tests | Enumerates them first, so coverage is reviewable before forty tests exist |
| Edit a failing assertion until it passes | Investigates, and reports a real defect rather than hiding it |
| Loop over inputs to compute expected values | Data-driven cases with literal expectations — a computed expectation can agree with a wrong implementation |
| Mock the class under test | Mocks collaborators only |
| Report a suite as green from inference | Runs it and quotes the real numbers |

## Files in this skill

| Path | Purpose |
|---|---|
| `SKILL.md` | The skill instructions. |
| `references/edge-cases.md` | The edge-case taxonomy that turns "cover everything" into a concrete scenario list. |
| `references/example-xunit.md` | A complete worked example (C#/xUnit) mapping each test to its scenario category. |

## What you get back

After it runs, you receive an overview covering:

- **Target** — what was tested, the framework used, and the naming convention
  followed if it wasn't Given-When-Then.
- **Scenario list** — behaviors and edge cases covered, grouped by unit.
- **Result** — the actual pass/fail numbers from the test run.
- **Gaps & findings** — anything left uncovered and why, plus real defects or
  ambiguities the tests surfaced in the code under test.
