# Frameworks: detecting the test stack, and writing tests that fit it

`SKILL.md` step 1 detects how the project already tests. This file is the per-stack lookup: where the test
framework shows up, where tests live, how a Given-When-Then name is written in that language, how the project
separates unit from functional tests, which mocking and data-driven tools it uses, and the command that runs the
unit suite. **What the repository already does wins over every default here** — the existing tests, the test
configuration and `CONTRIBUTING.md` are read first.

## Detect the framework

| Stack | Manifest | Framework signals |
|---|---|---|
| .NET | `*.csproj` | `xunit` / `xunit.v3`, `NUnit`, `MSTest` package references in a test project (it also references `Microsoft.NET.Test.Sdk`) |
| JS / TS | `package.json` | `vitest`, `jest`, `mocha`, `@angular/build:unit-test` / Karma in `angular.json`, `node:test` imports; the `test` script |
| Python | `pyproject.toml`, `setup.cfg`, `pytest.ini`, `tox.ini` | `pytest` (+ `[tool.pytest.ini_options]`), else `unittest` |
| JVM | `build.gradle*`, `pom.xml` | `junit-jupiter` (JUnit 5), `junit:junit` (4), `kotest`, `testng`; Spring's `spring-boot-starter-test` brings JUnit 5, AssertJ and Mockito |
| Rust | `Cargo.toml` | built-in `#[test]`; `rstest`, `proptest`, `mockall` in `[dev-dependencies]` |
| Go | `go.mod` | built-in `testing`; `testify`, `gomock` / `mockery` in `go.mod` |
| Dart / Flutter | `pubspec.yaml` | `test` (Dart), `flutter_test` (Flutter); `mocktail` / `mockito` |
| Swift | `Package.swift` | Swift Testing (`import Testing`, `@Test`) or XCTest |
| Ruby / PHP / other | `Gemfile`, `composer.json` | RSpec / Minitest, PHPUnit / Pest — read the existing tests and follow them |

No framework at all: add the stack's default (the first one named in each row), as a dev / test dependency only,
and say so in the report.

## Where the tests go

Put new tests where the project's existing tests are, mirroring the source path of the unit under test. With no tests
yet, follow the layout the build is configured for — a repository from **scaffold-project** keeps every test under
`tests/`, with the tool reconfigured to find them there:

| Stack | Convention | In a scaffold-project repository |
|---|---|---|
| .NET | a test project per project under test, `<Project>.Tests` | `tests/<Layer>/<Project>.Tests/` (or `tests/<Project>.Tests/`), added to the solution |
| JS / TS | `*.test.ts` / `*.spec.ts` beside the code, or a `tests/` folder — whatever the runner's `include` matches | `tests/`, mirroring `src/` (Angular: `tests/app/…`, included as `../tests/**/*.spec.ts`); `.test.tsx` for a component, `.test.ts` for a module |
| Python | `tests/test_<module>.py`, flat — or `tests/<subpackage>/test_<module>.py` when the project mirrors subpackages (then give each folder an `__init__.py`, or keep every basename unique) | the same, under `tests/` |
| JVM | `src/test/java` (or `kotlin`) | `tests/java` (or `tests/kotlin`), the Gradle / Maven test source set |
| Rust | **unit tests inline**, in a `#[cfg(test)] mod tests` at the bottom of the module (they can reach private items); `tests/` holds integration tests that see only the public API | the same — `tests/` stays for integration tests |
| Go | `<file>_test.go` **beside the code**, same package (white-box) or `<pkg>_test` (black-box) — the toolchain requires it | the same; `tests/` holds only cross-package or end-to-end tests |
| Dart / Flutter | `test/` in the package | `tests/` — a test package depending on the app by path (`tests/unit/`, `tests/widget/`) |

## Writing the Given-When-Then name

Same three parts everywhere; the spelling follows the language's own identifier or description rules:

| Form | Stacks | Example |
|---|---|---|
| PascalCase method | C# (.NET) | `GivenEmptyCart_WhenCheckoutIsCalled_ThenThrowsInvalidOperation` |
| camelCase method | Java, Kotlin, Swift, Dart (method form) | `givenEmptyCart_whenCheckoutIsCalled_thenThrowsIllegalState` |
| `Test` + PascalCase | Go (a test function must start with `Test` and an upper-case letter) | `TestGivenEmptyCart_WhenCheckoutIsCalled_ThenReturnsErrEmptyCart` |
| snake_case function | Python (`test_` prefix for discovery), Rust | `test_given_empty_cart_when_checkout_is_called_then_raises_value_error` / `given_empty_cart_when_checkout_is_called_then_returns_err` |
| description string | Jest, Vitest, Mocha, Jasmine/Karma, Dart `test()` / `testWidgets()`, RSpec, Kotest, JUnit `@DisplayName`, Swift `@Test("…")` | `it("given an empty cart, when checkout is called, then throws EmptyCartError")` |

With description strings, nest instead of repeating: a `describe("CartService")` per unit, an inner
`describe("checkout")` per action when it helps, and the `it`/`test` text carries the full given / when / then.

## Separating unit from functional tests

If the project marks its suites, every new test carries the unit marker — a test without it is run by no CI job.
Look at the existing tests, the test configuration and `.github/workflows/` (the filters the CI jobs pass):

| Stack | Marker | CI filter |
|---|---|---|
| .NET | xUnit `[Trait("Category", "Unit")]` (or a helper such as `[UnitFact]`), NUnit `[Category("Unit")]`, MSTest `[TestCategory("Unit")]` — on the class | `dotnet test --filter "Category=Unit"` (MSTest: `TestCategory=Unit`) |
| Python | `@pytest.mark.unit` on each test or class, or `pytestmark = pytest.mark.unit` once per module; registered under `markers` (required with `--strict-markers`) | `pytest -m unit` |
| JVM | JUnit 5 `@Tag("unit")` on the class | Gradle `useJUnitPlatform { includeTags(…) }`, Maven `-Dgroups=unit` |
| JS / TS | a folder (`tests/unit/`), a file suffix (`*.unit.test.ts`), or a Vitest / Jest `projects` entry | the path or project name passed to the runner |
| Rust | location: inline unit tests vs `tests/`; slow tests `#[ignore]` | `cargo test --lib --bins` (unit only), `cargo test --test <name>` |
| Go | location or a build tag on the *other* suite (`//go:build integration`), or `testing.Short()` | `go test ./...` vs `go test -tags integration ./...` / `-short` |
| Dart / Flutter | a folder (`unit/`, `widget/`), or `@Tags(['unit'])` with the tags declared in `dart_test.yaml` | `flutter test unit` / `--tags unit` |

## Mocks and data-driven tests

Use what the project already uses. Defaults when it uses nothing yet:

| Stack | Test doubles | Data-driven cases |
|---|---|---|
| .NET | Moq or NSubstitute (whichever the solution references); hand-written fakes for simple interfaces | xUnit `[Theory]` + `[InlineData]` / `[MemberData]`; NUnit `[TestCase]`; MSTest `[DataRow]` |
| JS / TS | `vi.fn()` / `vi.mock()` (Vitest), `jest.fn()` / `jest.mock()`; Angular `TestBed` providers with fakes | `it.each` / `test.each` |
| Python | `unittest.mock` (`Mock`, `patch`), `pytest-mock`'s `mocker`; `monkeypatch` | `@pytest.mark.parametrize` with `ids=` |
| JVM | Mockito (`@Mock`, `@ExtendWith(MockitoExtension.class)`), MockK for Kotlin | `@ParameterizedTest` + `@ValueSource` / `@CsvSource` / `@MethodSource` |
| Rust | traits + hand-written fakes; `mockall` when the project has it | `rstest` `#[case]` when present; otherwise one `#[test]` per case |
| Go | interfaces + small fakes; `gomock` / `testify/mock` when present | table-driven tests: a slice of literal cases and `t.Run(tc.name, …)` per case |
| Dart / Flutter | `mocktail` (`class MockX extends Mock implements X`) or `mockito` | a loop over a literal list of cases, each its own `test()` |

Give each data-driven case its own given / when / then title: `it.each` takes `$field` / `%s` in the name,
`parametrize` takes `ids=`, `@ParameterizedTest(name = "…")`, Go's `t.Run(tc.name, …)`.

### JS / TS specifics

- **Testing Library cleans up between tests only when the runner exposes `afterEach` globally** (Jest; Vitest with
  `globals: true`). Under Vitest without globals, renders pile up across tests — add `afterEach(cleanup)` to the setup
  file (`import { cleanup } from "@testing-library/react"`) and say so in the report.
- **Interactions through `@testing-library/user-event`**, not `fireEvent`: `const user = userEvent.setup()` before
  `render`, `await` every action, `user.tab()` to blur.
- **Fake timers:** `vi.useFakeTimers()` (or Jest's), `userEvent.setup({ advanceTimers: vi.advanceTimersByTime })`,
  `await vi.advanceTimersByTimeAsync(ms)`, and `vi.useRealTimers()` in `afterEach`.
- **jsdom / happy-dom is a unit environment.** A real-browser runner (Vitest browser mode, Playwright, Cypress, Karma
  in Chrome) is functional.
- **Test invalid values the types can't stop** — `NaN`, `Infinity`, text parsed at run time, `undefined` optionals,
  data from `JSON.parse` or the network — not values the compiler already rejects.

**Loops over literal cases are data-driven tests, not "logic in tests"** — Go's table-driven tests and Dart's case
lists are the idiomatic form. What stays forbidden is computing the *expected* value in the test.

## Running the unit suite

| Stack | Command |
|---|---|
| .NET | `dotnet test <sln or test project> --filter "Category=Unit"` (without the filter when the project doesn't categorize) |
| JS / TS | the project's script — `npm test`, `npx vitest run <path>`, `npx jest <path>`, `npm test -- --watch=false` (Angular) |
| Python | `uv run pytest -m unit` when the project uses uv (`uv.lock`); otherwise `python -m pytest -m unit` from the project's virtual environment |
| JVM | `./gradlew test` (`--tests '<Class>'` for one class) / `./mvnw test -Dtest=<Class>` |
| Rust | `cargo test --lib --bins` (unit tests only — inline modules); add `-- <name filter>` to narrow it |
| Go | `go test ./<pkg>/... -run <TestName>` |
| Dart / Flutter | `flutter test <path>` / `dart test <path>` |

Run it in watch-free mode, read the summary, and report the real counts.

## Shape per framework

Every example tests the same scenario — checkout on an empty cart fails — so the parts map one to one.

```ts
// Vitest / Jest
describe("CartService", () => {
  it("given an empty cart, when checkout is called, then throws EmptyCartError", () => {
    const sut = new CartService(new Cart(), { charge: vi.fn() });   // Arrange

    const act = () => sut.checkout();                                // Act

    expect(act).toThrow(EmptyCartError);                             // Assert
  });
});
```

```python
# pytest
@pytest.mark.unit
def test_given_empty_cart_when_checkout_is_called_then_raises_empty_cart_error():
    sut = CartService(Cart(), Mock(spec=PaymentGateway))

    with pytest.raises(EmptyCartError):
        sut.checkout()
```

```java
// JUnit 5 + Mockito + AssertJ
@Tag("unit")
@ExtendWith(MockitoExtension.class)
class CartServiceTests {
    @Mock PaymentGateway gateway;

    @Test
    void givenEmptyCart_whenCheckoutIsCalled_thenThrowsIllegalState() {
        var sut = new CartService(new Cart(), gateway);

        assertThatThrownBy(sut::checkout).isInstanceOf(IllegalStateException.class);
    }
}
```

```rust
// Rust, inline in the module under test
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn given_empty_cart_when_checkout_is_called_then_returns_empty_cart_error() {
        let sut = CartService::new(Cart::default(), FakeGateway::default());

        let result = sut.checkout();

        assert_eq!(result, Err(CheckoutError::EmptyCart));
    }
}
```

```go
// Go, cart_service_test.go beside cart_service.go
func TestGivenEmptyCart_WhenCheckoutIsCalled_ThenReturnsErrEmptyCart(t *testing.T) {
	sut := NewCartService(&Cart{}, &fakeGateway{})

	_, err := sut.Checkout()

	if !errors.Is(err, ErrEmptyCart) {
		t.Fatalf("got %v, want ErrEmptyCart", err)
	}
}
```

```dart
// Dart / Flutter
void main() {
  test('given an empty cart, when checkout is called, then throws EmptyCartException', () {
    final sut = CartService(Cart(), MockPaymentGateway());

    expect(() => sut.checkout(), throwsA(isA<EmptyCartException>()));
  });
}
```

The C# / xUnit version, with the full scenario list, is `references/example-xunit.md`.
