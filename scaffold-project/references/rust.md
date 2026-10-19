# Rust

Read after the user picked Rust (step 1 of `SKILL.md`). Cargo's own layout already matches the shared
shape: code in `src/`, integration tests in `tests/`.

## Kind — ask only if the request didn't say

*"A binary (a CLI, a service) or a library crate?"* — binary → `--bin`, application branch policy;
library → `--lib`, library branch policy.

## Interview

Asked in the same round as the shared questions. The shared name question asks for the **crate
name** in kebab-case (`order-tools`).

| Question | Default |
|---|---|
| "Edition?" | the newest edition the installed `cargo` supports (`cargo new --help` lists them) |
| *Library:* "crates.io keywords (up to 5) and categories?" | none |

## Generate

```bash
cargo init --name <crate-name> --bin --vcs none --edition <edition>     # library: --lib
```

## Shape

- Unit tests stay inline in `src/` (`#[cfg(test)] mod tests`) — that is how Rust tests private code;
  **integration tests** go in `tests/`, which Cargo compiles as separate crates on its own.
  `tests/` gets a `.gitkeep` until the first one.
- Strip the generator's sample: a binary's `main` keeps an empty body instead of
  `println!("Hello, world!")`; a library's `add` function and its test are deleted, leaving an empty
  `lib.rs` with a crate doc comment (`//! <description>`).
- `Cargo.toml` `[package]`: `version = "0.1.0"`, `description`, `license` (SPDX — `"MIT"`,
  `"AGPL-3.0-only"`) or, for the default and Custom Commercial licenses, `license-file = "LICENSE"`,
  `repository`, `readme = "README.md"`, and for a library `keywords` / `categories`. Add
  `rust-version` with the toolchain's major.minor (`rustc --version` 1.97.1 → `"1.97"`) as the
  minimum supported Rust version.
- Root `.gitignore`: `/target` (and `Cargo.lock` is **committed** for both kinds, as current Cargo
  guidance says), then the shared block.

## README fill-ins

- **Requirements:** `- Rust <rust-version> or later`.
- **Usage:** a binary → `cargo install --git https://github.com/<owner>/<repo>` (or `cargo install
  <crate>` once published); a library → `cargo add <crate>` once published, `cargo add --git
  https://github.com/<owner>/<repo>` until then, and `{{LinkBase}}` is the absolute
  GitHub URL because crates.io renders the README.

## CONTRIBUTING fill-ins

- **Prerequisites:** `- [Rust](https://rustup.rs/) <rust-version> or later, with clippy and rustfmt`
- **Build:** `cargo build`, `cargo clippy --all-targets -- -D warnings`, `cargo fmt --check`.
- **Testing:**

  ````markdown
  Unit tests sit next to the code they test, in a `#[cfg(test)] mod tests` at the bottom of each module; integration
  tests live under `tests/` and use only the public API. Every test is named with the Given / When / Then pattern
  (`given_some_condition_when_some_action_then_some_output`).

  ```bash
  cargo test --lib --bins      # unit
  cargo test --tests           # unit + integration
  ```
  ````

- **VersionFile** (library): ``the `version` in `Cargo.toml` ``

## Branch policy (library variant)

- `__VERSION_FILE__` → `Cargo.toml`
- `__VERSION_PATTERN__` → `^version\s*=\s*"\K[^"]+`

## Verify

```bash
cargo build
cargo clippy --all-targets -- -D warnings
cargo fmt --check
cargo test
```

`cargo test` passing with 0 tests is expected while there are none; say so. A library also runs
`cargo package --list --allow-dirty` to confirm `README.md` and `LICENSE` are in the crate.
