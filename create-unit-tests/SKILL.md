---
name: create-unit-tests
description: Use when the user wants to generate unit tests for a target project, class, module, component, or function, in any stack (.NET, JavaScript / TypeScript, Python, Java / Kotlin, Rust, Go, Dart / Flutter, …) and any kind of project (library, API, web front end, CLI, mobile app) — tests are named with the Given-When-Then pattern (GivenSomeCondition_WhenSomeAction_ThenSomeOutput, spelled the language's way) unless the project documents its own convention, which wins, and coverage includes happy paths plus edge cases. Triggers on "write unit tests", "add tests for", "create tests", "cover this with tests", "unit test this".
---

# Create Unit Tests

## Overview

Generates a thorough unit-test suite for a target project (or a single class /
module / component / function within it), in whatever stack and framework the
project uses. Two non-negotiable rules define the output:

1. **Every test name follows Given-When-Then:**
   `GivenSomeCondition_WhenSomeAction_ThenSomeOutput` — spelled the way the
   language writes test names (`references/frameworks.md`).
2. **Coverage is exhaustive** — every public behavior *and* its edge cases, not
   just the happy path.

**Core principle:** enumerate behaviors and edge cases *before* writing any test,
so the suite is driven by a scenario list, not by whatever came to mind first.

## When to Use

- The user asks to "write/add/generate unit tests", "cover X with tests", or
  "test this class/module/component/function" — in any language.
- A new or existing unit has no tests, or has tests that miss edge cases.

Skip / adapt if the user wants integration, end-to-end, or performance tests — the
Given-When-Then naming still helps, but the scenario taxonomy below is aimed at
unit-level behavior.

### When the project already has a testing standard

Given-When-Then is this skill's default, **not an override of the project's own
convention.** If the repository documents one — a `Testing Specification Document`,
a `CONTRIBUTING.md` section, or an established pattern visible in the existing
tests — follow it, and say which you followed and why.

Raise the conflict rather than resolving it silently:

> "The Testing Specification names tests `Method_Scenario_Expected`; this skill
> defaults to Given-When-Then. I'll follow the project's convention unless you'd
> rather switch."

A repository whose tests use two naming schemes is worse off than one using the
scheme you disagree with. This matters most when `implement-use-case` delegates the
unit layer here — there, the project's Testing Specification governs, always.

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
- Exactly three segments, each in the language's form — PascalCase identifiers joined
  by underscores in C#, or lowercase comma-separated clauses in a description string.
- `Then` states one observable outcome (return value, thrown exception, state
  change, or interaction) — if a scenario needs two unrelated assertions, it's two
  tests.
- Keep it readable over short: `GivenNullInput` beats `GivenN`.

The segments are spelled the language's way — PascalCase in C#, camelCase methods in Java / Kotlin,
`Test` + PascalCase in Go, snake_case with a `test_` prefix in Python, snake_case in Rust — and where test names
are description strings (Jest, Vitest, Mocha, Karma, Dart, RSpec, Kotest) the same three parts become the text:
`it("given an empty cart, when checkout is called, then throws EmptyCartError")`. The full table is in
`references/frameworks.md`, *Writing the Given-When-Then name*.

## Red Flags — STOP and Re-read the Procedure

- "I'll write the happy-path tests now and add edge cases after review" → NO. The
  edge cases *are* the deliverable; a happy-path suite proves almost nothing.
- "I'll list the scenarios as I write them" → NO. Enumerate first (step 3), or
  coverage becomes whatever you happened to think of.
- "This method is obviously a getter, I don't need to read it" → NO. A test written
  from an assumed API passes against the wrong behavior.
- "The test fails, so my assertion must be wrong" → Maybe the code is. Investigate,
  and report a real defect instead of editing the assertion until it agrees.
- "One test can assert both outcomes" → NO. One observable outcome per test, or the
  failure message stops telling you what broke.
- "I'll mock the class under test so I can isolate this method" → NO. Mock
  collaborators only; mocking the unit tests the mock.
- "The project uses MSTest / Jest / unittest but xUnit / Vitest / pytest is better" → NO.
  Match the project.
- "I'll render the whole app / start the server / hit the real database to test this" →
  NO. That is a functional test. Fake the collaborators; the unit runs alone.
- "The tool wants tests beside the code, so I'll put them there" → only if that is where
  the project keeps them. Follow the layout the build is configured for — a repository
  from scaffold-project keeps them under `tests/` (except Rust unit tests and Go
  `_test.go` files, which the toolchains require beside the code).
- "The suite should pass now" → Run it. Report real numbers, never expected ones.

| Rationalization | Reality |
|---|---|
| "Enumerating scenarios first is bureaucracy" | It is what makes coverage reviewable *before* forty tests exist along the wrong axis. |
| "A loop over inputs is DRYer than twelve cases" | A loop that computes the expected value can agree with a wrong implementation. Use data-driven cases with literal expectations. |
| "Given-When-Then names are too long" | The name is the failure message. `GivenN_WhenX_ThenY` tells you nothing when the build breaks at 3am. |
| "The user asked for tests, not a bug report" | A test suite that hides a defect to stay green is worse than no suite. Report what you found. |
| "This edge case can't happen in practice" | Then it costs one cheap test to prove it. "Can't happen" is how nulls reach production. |

## Procedure

Create a todo per step.

### 1. Identify the target, the test framework, and the naming convention

- Confirm what to test: a whole project, or a specific class/module/function.
- Check for a project testing standard (`Testing Specification Document`,
  `CONTRIBUTING.md`, or the naming already used by existing tests). It wins over
  this skill's Given-When-Then default — see *When the project already has a
  testing standard* above.
- Detect the stack and its test framework, assertion library and mocking tool from the
  manifests and the existing tests (`references/frameworks.md`, *Detect the framework*).
  New tests use the same ones; never introduce a second framework. If there is none, add
  the stack's default as a dev / test dependency and say so. If one is configured but not
  declared as a dependency (a `[tool.pytest.ini_options]` without pytest in any
  dependency group), declare it where the stack keeps test dependencies
  (`[dependency-groups] dev`, `devDependencies`, `[dev-dependencies]`, the test project)
  and say so.
- Find **where the tests go** — beside the existing ones, mirroring the source path; with
  no tests yet, the layout the build is configured for (`references/frameworks.md`,
  *Where the tests go*). Create the test project or folder only when none exists.
- **Find how the suites are separated.** Many repositories mark every test with its kind
  — a .NET `[Trait("Category", "Unit")]` (or a helper such as `[UnitFact]`), a pytest
  `@pytest.mark.unit`, a JUnit `@Tag("unit")`, a `tests/unit/` folder, a Dart tag — and
  CI runs each kind as its own filtered job. Check the existing tests, the test
  configuration, `CONTRIBUTING.md` and `.github/workflows/` (`references/frameworks.md`,
  *Separating unit from functional tests*). If the project separates them, the new tests
  carry the same marker or location; a test without it is never run by any CI job. If no
  workflow runs the tests at all, use the commands in `CONTRIBUTING.md` and say in the
  report that CI does not run them.
- Read the runner's include pattern (`include` / `testMatch` / `testpaths` / the source
  set) and name the files so it picks them up — `*.test.ts` for a module, `*.test.tsx`
  for a component, `test_*.py`, `*Tests.cs`.

### 2. Read the code under test — do not guess its behavior

Read every public member you will test — or, for a UI component, its inputs / props,
the states it renders and the events it emits. For each, note: parameters and their
valid/invalid ranges, return type, thrown exceptions or returned errors, external
dependencies (to fake), and any state it reads or mutates. Note what **kind of unit**
it is — component, handler, service, CLI command, data access, validator, pure
function — since each kind adds its own scenarios (`references/edge-cases.md` §10). **Never invent behavior** — if the code
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
- **Async & time** — resolution and rejection, cancellation, timeouts, injected clocks.
- **Kind-specific** — render states and user events for a component, status mapping for a
  handler, exit codes and output streams for a CLI, and so on (§10 of the taxonomy).

Write this list out (as the todos or a comment block) so coverage is visible and
reviewable before implementation.

### 4. Write the tests

- One behavior per test; **Arrange-Act-Assert** body under a Given-When-Then name.
- Group tests per unit (one test class / `describe` / module per unit under test).
- Carry the project's unit marker on every new test (step 1) — the trait, marker, tag
  or folder its CI filters by.
- Use data-driven tests for families of similar inputs (`[Theory]`, `it.each`,
  `@pytest.mark.parametrize`, `@ParameterizedTest`, a Go case table), but keep the
  Given-When-Then name meaningful.
- Fake only external collaborators; never mock the unit under test.
- No logic computing the expected value (no conditionals, no arithmetic deciding what
  to expect) — the expected value is a literal so a wrong implementation can't match a
  wrong test. Iterating over a table of literal cases is fine; that is what Go's and
  Dart's data-driven tests look like.
- Await every asynchronous act before asserting, and assert a rejection on the awaited
  promise (`await expect(p).rejects…`, `pytest.raises` around `await`, `Assert.ThrowsAsync`);
  an un-awaited assertion passes without checking anything.

### 5. Run the tests and confirm they pass

Run the suite with the project's own command (`references/frameworks.md`, *Running
the unit suite* — `dotnet test`, `npm test`, `pytest`, `./gradlew test`, `cargo test`,
`go test`, `flutter test`, …), without watch mode. Then format the new test code with the
project's formatter, and run the checks that cover test code — the ones `CONTRIBUTING.md`
or CI runs: the type-check and lint (`tsc -b` or the build script and `npm run lint` —
Vitest and Jest strip types without checking them), `cargo fmt --check` and
`cargo clippy --all-targets -- -D warnings`, `ruff check` / `ruff format --check`,
`dotnet format --verify-no-changes`, `go vet`, `flutter analyze`. Fix genuine test bugs. Behaviour the code has but nothing specifies (an unusual
rounding mode, a lenient parser) is an **ambiguity**: test what it does, with a comment
saying the test pins current behaviour, and list it in the report. A **confirmed defect**
— the code contradicts its own documentation, its types, an invariant it states, or
plain correctness (a wrapped integer, a crash on valid input) — is different:
**report it — do not silently change the assertion to match buggy output.** Keep the
test, asserting the *correct* behaviour, and mark it as an expected failure that turns red once the bug is fixed — `it.fails`
(Vitest), `test.failing` (Jest), `@pytest.mark.xfail(strict=True)`. Where the framework
has no expected-failure form, skip the test with the reason (`[Fact(Skip = "…")]`,
`@Disabled("…")`, `#[ignore = "…"]`, `t.Skip("…")`, `skip:` in Dart). Either way add a
comment naming the bug, and list it under *Gaps & findings*. A test that pins the buggy
behaviour as if it were correct (`#[should_panic]` on a panic that shouldn't happen) is
the silent assertion change this rule forbids.

### 6. Report to the user (required)

Tell the user:

- **Target** — what was tested (project / class / module), the framework used, and
  the naming convention followed if it was not Given-When-Then.
- **Scenario list** — the behaviors and edge cases covered, grouped by unit.
- **Result** — the pass/fail output of the test run (actual numbers, from the run
  you performed in this session).
- **Gaps & findings** — anything not covered and why, plus any real defects or
  ambiguities the tests surfaced in the code under test.

## Quick Reference

| Decision | Rule |
|---|---|
| Test naming | Given-When-Then, unless the project documents its own convention — that wins. |
| Framework | The project's existing one. Never introduce a second. |
| Name spelling | The language's form of Given-When-Then (`references/frameworks.md`). |
| Location | Beside the existing tests; else the layout the build is configured for. |
| Unit marker | The project's own (`[Trait("Category", "Unit")]`, `@pytest.mark.unit`, `@Tag("unit")`, a `unit/` folder, …) on every new test, when the project separates its suites. |
| Unit vs functional | A unit runs alone with faked collaborators. A real server, database, browser or device makes it functional. |
| Scenario list | Written before the first test, not discovered while writing. |
| Assertions per test | One observable outcome. Two means two tests. |
| Mocks | External collaborators only, never the unit under test. |
| A failing test | Investigate before editing. A real defect gets reported, not hidden. |
| Claiming green | Only after running the suite in this session and reading the output. |

### Edge-case checklist

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

### Example

The same scenario in Vitest / Jest, pytest, JUnit, Rust, Go and Dart is at the end of
[references/frameworks.md](references/frameworks.md) — use the one for the project's
stack. A complete, runnable C# / xUnit suite with its scenario list is in
[references/example-xunit.md](references/example-xunit.md). Its shape:

```csharp
[Trait("Category", "Unit")]                                 // when the project filters by category
public class CartServiceTests
{
    [Fact]
    public void GivenEmptyCart_WhenCheckoutIsCalled_ThenThrowsInvalidOperation()
    {
        var cart = new Cart();                              // Arrange
        var sut  = new CartService(cart, Mock.Of<IPaymentGateway>());

        var act = () => sut.Checkout();                     // Act

        Assert.Throws<InvalidOperationException>(act);      // Assert
    }

    [Theory]                                                // edge cases, one name family
    [InlineData(-1)]
    [InlineData(0)]
    public void GivenNonPositiveQuantity_WhenAddItem_ThenThrowsArgumentOutOfRange(int qty)
    {
        var sut = new CartService(new Cart(), Mock.Of<IPaymentGateway>());

        var act = () => sut.AddItem("sku-1", qty);

        Assert.Throws<ArgumentOutOfRangeException>(act);
    }
}
```

## Common Mistakes

- **Only testing the happy path.** The requirement is exhaustive — work the
  edge-case checklist for every unit.
- **Breaking the naming rule.** Not three segments, missing `Given`/`When`/`Then`,
  or two behaviors crammed into one `Then`.
- **Imposing Given-When-Then on a project that documents another convention.**
  Follow the project's; say which you followed.
- **Guessing behavior.** A test written from an assumed API is worse than no test —
  read the real code first.
- **Assertion-free or logic-heavy tests.** Every test asserts one literal outcome;
  no loops/conditionals computing the expected value.
- **Changing an assertion to hide a real bug.** If the code is wrong, report it;
  don't make the test agree with buggy output.
- **Mocking the unit under test** or introducing a new test framework instead of
  matching the project's existing one.
- **Leaving out the unit marker** in a repository whose CI filters by it
  (`--filter "Category=Unit"`, `pytest -m unit`, `includeTags("unit")`, a `tests/unit`
  path). The tests pass locally with the plain command and are silently skipped by
  every CI job.
- **Writing a functional test and calling it a unit test** — rendering the whole app,
  starting the server, opening a real database. It belongs to the functional suite.
- **Putting tests where the tool defaults instead of where the project keeps them.**
  Check the configured test path first.
