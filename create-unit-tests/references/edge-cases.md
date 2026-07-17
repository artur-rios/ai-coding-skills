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
| Numbers | `0`, `1`, `-1`, min, max, `min-1`, `max+1`, overflow/underflow |
| Collections | empty, single element, exactly-full, one past capacity |
| Strings | `""`, single char, max length, one over max length |
| Ranges | just inside, exactly on, just outside each bound |
| Dates/time | epoch, DST boundary, leap day, min/max representable |

## 3. Invalid / malformed input

- `null` for each reference argument (and null inside a collection).
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

- Every documented `throw` path is exercised and asserted (type + ideally message
  or error code).
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

## Turning the list into tests

For each applicable row, name a test:
`Given<thisCondition>_When<theActionUnderTest>_Then<theExpectedOutcome>`.

Prefer a data-driven test (`[Theory]`, `it.each`, `@pytest.mark.parametrize`) when
several rows share the same When/Then and differ only by input — but keep the test
name describing the *category* (e.g. `GivenOutOfRangeQuantity_...`).
