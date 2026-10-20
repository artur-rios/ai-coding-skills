# Edge-case taxonomy

Use this to turn "cover everything possible" into a concrete scenario list. For
each public member under test, walk every category that applies and turn each
applicable row into one Given-When-Then test.

## 1. Happy path

The reason the code exists. Typical valid inputs → expected output.

- Normal value in the middle of the valid range.
- The most common real-world usage.

## 2. Boundaries (the richest source of bugs)

Off-by-one and limit errors cluster here.

| Input shape | Cases to test |
|---|---|
| Numbers | `0`, `1`, `-1`, min, max, `min-1`, `max+1`, overflow/underflow; width and sign conversions (`as` casts, `(int)` truncation, `usize` → `i64`); rounding ties (`x.xx5`) and the rounding mode used |
| Collections | empty, single element, exactly-full, one past capacity |
| Strings | `""`, single char, max length, one over max length |
| Ranges | just inside, exactly on, just outside each bound |
| Dates/time | epoch, DST boundary, leap day, min/max representable |

## 3. Invalid / malformed input

- `null` / `None` / `nil` / `undefined` / an absent `Option` for each argument whose type allows it (and inside a
  collection) — skip what the type system already forbids.
- Wrong type / unparseable string / `NaN`, `+Infinity`, `-Infinity`.
- Out-of-range enum value; negative where only non-negative is valid.
- Malformed structured input (bad JSON, missing required field).

## 4. Empty & missing

- Empty string vs. whitespace-only string vs. `null`.
- Empty collection / empty dictionary / empty stream.
- Absent optional value (`None`, `Optional.empty`, `null`, `undefined`).
- Default-constructed object with unset fields.

## 5. Duplicates, ordering & size

- Repeated / duplicate elements.
- Already-sorted, reverse-sorted, and unsorted inputs.
- Large input (does it still behave; any O(n²) blowup assumptions).
- Unicode, surrogate pairs, combining characters, mixed casing.

## 6. Errors & exceptions

- Every failure path is exercised and asserted — a thrown exception (type, ideally message or code), a returned
  error (`Err(…)`, an `error` value, a result object with errors), a panic that is part of the contract
  (`#[should_panic(expected = …)]`).
- A dependency throws — does the unit propagate, wrap, or swallow it as designed?
- A dependency returns `null` / an error result / times out.
- Resource cleanup still happens on the failure path (no leak).

## 7. State & side effects

- **Idempotency:** calling twice equals calling once (when it should).
- **Ordering:** does calling A before B differ from B before A?
- **Mutation:** does the method mutate its arguments or shared state unexpectedly?
- **Isolation:** one test's state must not leak into another (fresh fixture).
- **Concurrency** (only if the unit claims thread-safety): parallel calls don't
  corrupt state.

## 8. Interactions (for units with collaborators)

- The dependency is called with the exact expected arguments.
- It's called the expected number of times (including zero — "does NOT call X
  when …").
- Return values from the dependency are used / transformed correctly.

## 9. Async, time & randomness

- The awaited / returned future, promise or task resolves **and** rejects — both paths asserted (an un-awaited
  assertion passes vacuously).
- Cancellation and timeouts: a cancelled token / aborted signal / context stops the work and reports it.
- Time is injected (a clock, `TimeProvider`, fake timers, `freezegun`) — never `now()` read inside the assertion; test
  just before / at / after expiry boundaries.
- Randomness and generated ids come from an injected source, so the expected value stays a literal.

## 10. By kind of unit

The axes above apply everywhere; these add what each kind of unit typically gets wrong. A **unit** test exercises the
unit alone, with its collaborators faked — a test that starts the real server, database, browser or device is a
functional test, and belongs to the project's functional suite, not this one.

| Kind of unit | Also cover |
|---|---|
| **UI component** (React, Angular, Vue, Flutter widget) | Each render state — loading, empty, error, populated; each input / prop at its boundaries; each user interaction (click, type, submit, blur) and the event, callback or navigation it triggers; disabled and validation states; a prop changed by the parent after the first render; content found by role, label or text the way a user finds it (Testing Library queries, `find.text` / `find.byType`), not by CSS class. Render real child components; fake only what does I/O, routing or global context. Snapshot-only tests don't count as coverage. |
| **HTTP handler / controller / route** | Each status the handler can return, mapped from the service result; input binding and validation failures; authorization outcomes when the handler checks them; the service called with the bound input — the service faked, no real HTTP stack. |
| **Service / use case / command handler** | Every business rule as its own scenario; each collaborator failure; the outcome reported the project's way (returned error, result object, thrown exception — whichever it uses). |
| **CLI command** | Argument parsing — missing, unknown, conflicting and malformed arguments; the exit code; what goes to stdout vs stderr; help and version output. Run the command's function with fake I/O rather than spawning a process. |
| **Data access / I/O wrapper** | Unit-test the mapping and query-building logic with fakes; not-found, duplicate and conflict results; files through a temp directory or an in-memory filesystem. Real-database round trips are functional tests. |
| **Validator / parser / mapper** | Every rule's pass and fail side; every field mapped (a missing field in the mapping is the classic bug); round-trips where both directions exist. |
| **Pure function / domain model** | Invariants enforced at construction; equality and hashing; every state transition and the illegal ones. |

## Turning the list into tests

For each applicable row, name a test:
`Given<thisCondition>_When<theActionUnderTest>_Then<theExpectedOutcome>` — spelled the way the language writes it
(`references/frameworks.md`, *Writing the Given-When-Then name*).

Prefer a data-driven test (`[Theory]`, `it.each`, `@pytest.mark.parametrize`, `@ParameterizedTest`, a Go case table)
when
several rows share the same When/Then and differ only by input — but keep the test
name describing the *category* (e.g. `GivenOutOfRangeQuantity_...`).
