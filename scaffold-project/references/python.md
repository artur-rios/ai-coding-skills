# Python

Read after the user picked Python (step 1 of `SKILL.md`). The project is managed with
[uv](https://docs.astral.sh/uv/) and uses the `src/` layout, which already matches the shared shape.

If `uv --version` fails, stop and ask the user to install uv (or name the tool they use instead)
before the interview — do not fall back to a hand-written `setup.py`.

## Kind — ask only if the request didn't say

*"Is it an application (a CLI, a service, a script) or a library others will install from PyPI?"*

| Kind | `uv init` flag | Branch policy |
|---|---|---|
| Application | `--package` (installable, with a console-script entry point) | application |
| Library | `--lib` | library |

## Interview

Asked in the same round as the shared questions. The shared name question asks for the
**distribution name** in kebab-case (`order-tools`); the import package is the same in snake_case
(`order_tools`).

| Question | Default |
|---|---|
| "Minimum Python version?" | the newest stable minor uv knows (`uv python list --only-downloads` shows them), as `>=3.x` |
| *Library:* "PyPI keywords? (space-separated)" | none |

## Generate

```bash
uv init --package --name <distribution-name> --description "<description>" --vcs none --python <version> .
# library: --lib instead of --package
uv add --dev pytest ruff
```

`uv init` works in a non-empty directory and writes `pyproject.toml`, `src/<import_name>/`,
`.python-version` and a `README.md` — the root README replaces the last one in step 6.

## Shape

- Code is in `src/<import_name>/`; tests go in `tests/` (`.gitkeep` until the first test). Add to
  `pyproject.toml`:

  ```toml
  [tool.pytest.ini_options]
  testpaths = ["tests"]
  markers = [
      "unit: isolated tests against test doubles",
      "functional: end-to-end tests",
  ]
  addopts = "--strict-markers"

  [tool.ruff]
  line-length = 120
  ```

- Fill the `[project]` metadata the generator left blank: `license` (an SPDX expression —
  `"MIT"`, `"AGPL-3.0-only"` — or, for the default and Custom Commercial licenses,
  `license-files = ["LICENSE"]`), `authors` from `git config user.name` / `user.email`, the starting
  `version = "0.1.0"`, and `[project.urls]` `Repository` and `Changelog` (absolute GitHub URLs). A
  library adds `keywords` and `readme = "README.md"`.
- Keep the generator's `main()` / `hello()` stub only as the minimal entry point the console script
  needs; strip any sample text beyond it.
- Root `.gitignore`: uv writes none with `--vcs none`. Use the standard Python ignores (`__pycache__/`,
  `*.py[cod]`, `.venv/`, `dist/`, `build/`, `*.egg-info/`, `.pytest_cache/`, `.ruff_cache/`,
  `.coverage`, `htmlcov/`) before appending the shared block.

## README fill-ins

- **Requirements:** `- Python <version> or later`.
- **Usage:** an application → `uvx --from git+https://github.com/<owner>/<repo> <distribution-name>`
  or `uv run <distribution-name>` from a clone; a library → `pip install <distribution-name>`
  (`uv add <distribution-name>`). A library's README is rendered on PyPI, so `{{LinkBase}}` is the
  absolute GitHub URL.

## CONTRIBUTING fill-ins

- **Prerequisites:** `- [uv](https://docs.astral.sh/uv/getting-started/installation/) — it installs
  the Python version in .python-version itself`
- **Build:**

  ````markdown
  ```bash
  uv sync
  uv run ruff check
  uv build
  ```
  ````

- **Testing:**

  ````markdown
  Tests live under `tests/`, mirroring the package under `src/`, and are written with pytest. Every test is named with
  the Given / When / Then pattern (`test_given_some_condition_when_some_action_then_some_output`) and marked
  `@pytest.mark.unit` or `@pytest.mark.functional`, so the two kinds can be run separately:

  ```bash
  uv run pytest -m unit
  uv run pytest -m functional
  ```
  ````

- **VersionFile** (library): ``the `version` in `pyproject.toml` ``

## Branch policy (library variant)

- `__VERSION_FILE__` → `pyproject.toml`
- `__VERSION_PATTERN__` → `^version\s*=\s*"\K[^"]+`

## Verify

```bash
uv sync
uv run ruff check
uv run ruff format --check
uv build
uv run pytest
```

`pytest` exits **5** ("no tests collected") while `tests/` holds only a `.gitkeep` — that exit code,
and only that one, is acceptable here; say so in the report. An application also runs its entry point
once: `uv run <distribution-name>` must exit 0.
