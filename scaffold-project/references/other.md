# Any other stack

Read when the user picked a technology without a reference of its own (Go, Elixir, Ruby, PHP, C++,
Swift, …). The shared shape and the shared files still apply in full; only the stack-specific parts are
worked out with the user instead of read from a file.

## Interview

Asked in the same round as the shared questions:

| Question | Default |
|---|---|
| "What kind of project — an application or a library others install?" | — |
| "Which generator or init command should set it up? (e.g. `go mod init`, `mix new`, `bundle gem`)" | the ecosystem's standard one; say which |
| "Which build and test commands?" | the ecosystem's standard ones; say which |

## Generate and shape

1. Run the generator (step 5 of `SKILL.md`), into a temporary directory if it insists on creating its
   own.
2. Put production code in `src/` and tests in `tests/`. Where the toolchain expects otherwise,
   configure it (a source-set setting, a test-path option, a separate test package that depends on the
   code by path) — and when a language **requires** tests beside the code (Go's `_test.go` files for
   package-internal tests), keep those beside the code and put black-box and integration tests in
   `tests/`. Write down which applies in CONTRIBUTING.
3. Strip generator demos; keep the minimal entry point.
4. `.gitignore`: the ecosystem's standard ignores, then the shared block.

## Fill-ins

Write README *Requirements* / *Usage* and CONTRIBUTING *Prerequisites* / *Build* / *Testing* the way
the other references do: the toolchain and its minimum version, the shortest working command, tests in
`tests/` named with the Given / When / Then pattern and split into unit and functional. For a library,
find the file and a `grep -P` pattern for the version, for the library branch policy.

## Verify

Build, lint if the ecosystem has a standard linter, and run the tests — with the exit code read. State
in the report which commands were used and that this stack has no dedicated reference, so the user can
check the choices.
