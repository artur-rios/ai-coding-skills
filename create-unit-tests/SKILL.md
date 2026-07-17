---
name: create-unit-tests
description: Use when the user wants to generate unit tests for a target project, class, module, or function — every test is named with the Given-When-Then pattern (GivenSomeCondition_WhenSomeAction_ThenSomeOutput) and coverage includes happy paths plus edge cases. Triggers on "write unit tests", "add tests for", "create tests", "cover this with tests", "unit test this".
---

# Create Unit Tests

## Overview

Generates a thorough unit-test suite for a target project (or a single class /
module / function within it). Two non-negotiable rules define the output:

1. **Every test name follows Given-When-Then:**
   `GivenSomeCondition_WhenSomeAction_ThenSomeOutput`.
2. **Coverage is exhaustive** — every public behavior *and* its edge cases, not
   just the happy path.

**Core principle:** enumerate behaviors and edge cases *before* writing any test,
so the suite is driven by a scenario list, not by whatever came to mind first.

## When to Use

- The user asks to "write/add/generate unit tests", "cover X with tests", or
  "test this class/module/function".
- A new or existing unit has no tests, or has tests that miss edge cases.

Skip / adapt if the user wants integration, end-to-end, or performance tests — the
Given-When-Then naming still helps, but the scenario taxonomy below is aimed at
unit-level behavior.

## The Given-When-Then Naming Rule

Each test name has exactly three parts joined by underscores:

```
Given<PreconditionOrState>_When<ActionUnderTest>_Then<ExpectedOutcome>
```

| Part | Answers | Example fragment |
|---|---|---|
| `Given…` | What is the starting state / input? | `GivenEmptyCart` |
| `When…` | What method/behavior is exercised? | `WhenCheckoutIsCalled` |
| `Then…` | What is the observable result? | `ThenThrowsInvalidOperation` |

Full example: `GivenEmptyCart_WhenCheckoutIsCalled_ThenThrowsInvalidOperation`.

**Rules:**
- Exactly three segments; each in PascalCase; underscore only between segments.
- `Then` states one observable outcome (return value, thrown exception, state
  change, or interaction) — if a scenario needs two unrelated assertions, it's two
  tests.
- Keep it readable over short: `GivenNullInput` beats `GivenN`.

For languages where test names are strings rather than method identifiers (JS,
Python, Ruby), use the same three parts as the description text, e.g.
`it("Given empty cart, when checkout is called, then throws")` or
`def test_given_empty_cart_when_checkout_called_then_raises():`.

## Procedure

Create a todo per step.

### 1. Identify the target and the test framework

- Confirm what to test: a whole project, or a specific class/module/function.
- Detect the existing test stack so the new tests fit in:
  - **.NET** — look for `*.Tests.csproj`, and xUnit / NUnit / MSTest package refs.
  - **JS/TS** — `jest`, `vitest`, `mocha` in `package.json`.
  - **Python** — `pytest` / `unittest`; **Java/Kotlin** — JUnit.
- If no test project/dir exists, create one following the ecosystem's convention
  (e.g. `<Project>.Tests` beside `src/`). Match the project's assertion library and
  mocking tool rather than introducing new ones.

### 2. Read the code under test — do not guess its behavior

Read every public member you will test. For each, note: parameters and their
valid/invalid ranges, return type, thrown exceptions, external dependencies (to
mock), and any state it reads or mutates. **Never invent behavior** — if the code
is ambiguous, test what it actually does and flag the ambiguity to the user.

### 3. Enumerate scenarios BEFORE writing tests

For each unit, list scenarios across these axes (full taxonomy with examples in
[references/edge-cases.md](references/edge-cases.md)):

- **Happy path** — typical valid inputs produce expected outputs.
- **Boundaries** — min, max, zero, off-by-one (empty, single element, full).
- **Invalid input** — null, wrong type, out-of-range, malformed.
- **Empty / missing** — empty collections/strings, absent optional values.
- **Errors & exceptions** — every documented throw, and failure of a dependency.
- **State & side effects** — idempotency, ordering, mutation, concurrency if relevant.
- **Interactions** — dependencies called with the right arguments the right number of times.

Write this list out (as the todos or a comment block) so coverage is visible and
reviewable before implementation.

### 4. Write the tests

- One behavior per test; **Arrange-Act-Assert** body under a Given-When-Then name.
- Group tests per unit (one test class/`describe` per class/module under test).
- Use data-driven tests (`[Theory]`/`it.each`/`@pytest.mark.parametrize`) for
  families of similar inputs, but keep the Given-When-Then name meaningful.
- Mock only external collaborators; never mock the unit under test.
- No logic in tests (no loops/conditionals deciding the expected value) — the
  expected value is a literal so a wrong implementation can't match a wrong test.

### 5. Run the tests and confirm they pass

Run the suite (`dotnet test`, `npm test`, `pytest`, …). Fix genuine test bugs. If a
test fails because the code has a real defect, **report it — do not silently change
the assertion to match buggy output.**

### 6. Report to the user (required)

Give an overview of what was done (see **Overview to Deliver** below).

## Edge-Case Checklist

Quick trigger list — expand with [references/edge-cases.md](references/edge-cases.md):

| Category | Ask yourself |
|---|---|
| Nulls | What if this argument / dependency / return is null? |
| Empty | Empty string, empty collection, whitespace-only? |
| Boundaries | 0, 1, max, max+1, negative, overflow? |
| Types | Wrong type, unparseable string, NaN/Infinity? |
| Duplicates & order | Repeated items, reversed / unsorted input? |
| Exceptions | Is every `throw` path exercised? |
| Dependencies | What if a mock throws, returns null, or times out? |
| State | Called twice — idempotent? Mutation leaking out? |

## Example (C# / xUnit)

A complete, runnable example is in
[references/example-xunit.md](references/example-xunit.md). Shape:

```csharp
public class CartServiceTests
{
    [Fact]
    public void GivenEmptyCart_WhenCheckoutIsCalled_ThenThrowsInvalidOperation()
    {
        var cart = new Cart();                              // Arrange
        var sut  = new CartService(cart);

        var act = () => sut.Checkout();                     // Act

        Assert.Throws<InvalidOperationException>(act);      // Assert
    }

    [Theory]                                                // edge cases, one name family
    [InlineData(-1)]
    [InlineData(0)]
    public void GivenNonPositiveQuantity_WhenAddItem_ThenThrowsArgumentOutOfRange(int qty)
    {
        var sut = new CartService(new Cart());

        var act = () => sut.AddItem("sku-1", qty);

        Assert.Throws<ArgumentOutOfRangeException>(act);
    }
}
```

## Overview to Deliver

After implementing, tell the user:

- **Target** — what was tested (project / class / module) and the framework used.
- **Scenario list** — the behaviors and edge cases covered, grouped by unit.
- **Result** — the pass/fail output of the test run (actual numbers).
- **Gaps & findings** — anything not covered and why, plus any real defects or
  ambiguities the tests surfaced in the code under test.

## Common Mistakes

- **Only testing the happy path.** The requirement is exhaustive — work the
  edge-case checklist for every unit.
- **Breaking the naming rule.** Not three segments, missing `Given`/`When`/`Then`,
  or two behaviors crammed into one `Then`.
- **Guessing behavior.** A test written from an assumed API is worse than no test —
  read the real code first.
- **Assertion-free or logic-heavy tests.** Every test asserts one literal outcome;
  no loops/conditionals computing the expected value.
- **Changing an assertion to hide a real bug.** If the code is wrong, report it;
  don't make the test agree with buggy output.
- **Mocking the unit under test** or introducing a new test framework instead of
  matching the project's existing one.
