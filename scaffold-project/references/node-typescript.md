# Node.js / TypeScript

Read after the user picked Node.js or TypeScript for something that is **not** a React or Angular
front end (those have their own references). TypeScript, ES modules, Vitest for tests.

## Kind — ask only if the request didn't say

*"Is it an application (a CLI, a server, a worker) or a library published to npm?"* — application →
application branch policy; library → library branch policy.

## Interview

Asked in the same round as the shared questions. The shared name question asks for the **package
name** in kebab-case, optionally scoped (`order-tools`, `@acme/order-tools`).

| Question | Default |
|---|---|
| "npm or pnpm?" | npm |
| "Minimum Node.js version?" | the current Active LTS major (`node --version` if it is an LTS line) |

Commands below use npm; with pnpm, `pnpm add -D` / `pnpm exec` / `pnpm run`.

## Generate

```bash
npm init -y
npm install --save-dev typescript @types/node vitest
npm install --save-dev tsx        # application only: runs src/ directly in development
```

Then write `package.json` fields over the generated ones — `name`, `version: "0.1.0"`,
`description`, `license` (SPDX id, or `"SEE LICENSE IN LICENSE"` for the default and Custom
Commercial licenses), `author` (from git), `repository`, `type: "module"`,
`engines: { "node": ">=<major>" }`, and the scripts:

| Script | Application | Library |
|---|---|---|
| `build` | `tsc -p tsconfig.build.json` | same |
| `typecheck` | `tsc --noEmit` | same |
| `test` | `vitest run` | same |
| `dev` | `tsx watch src/index.ts` | — |
| `start` | `node dist/index.js` | — |

A library also gets `"main": "./dist/index.js"`, `"types": "./dist/index.d.ts"`,
`"exports": { ".": { "types": "./dist/index.d.ts", "default": "./dist/index.js" } }` and
`"files": ["dist"]`; an application gets `"private": true`.

## Shape

- `tsconfig.json` — editor and type-check config, covering code **and** tests:

  ```json
  {
    "compilerOptions": {
      "target": "ES2023",
      "module": "NodeNext",
      "moduleResolution": "NodeNext",
      "strict": true,
      "esModuleInterop": true,
      "skipLibCheck": true,
      "forceConsistentCasingInFileNames": true,
      "noEmit": true
    },
    "include": ["src", "tests"]
  }
  ```

- `tsconfig.build.json` — what ships, `src/` only:

  ```json
  {
    "extends": "./tsconfig.json",
    "compilerOptions": { "noEmit": false, "rootDir": "src", "outDir": "dist", "declaration": true },
    "include": ["src"]
  }
  ```

  (`declaration` matters only for a library; harmless for an application.)

- `vitest.config.ts`:

  ```ts
  import { defineConfig } from "vitest/config";

  export default defineConfig({
    test: { include: ["tests/**/*.test.ts"] },
  });
  ```

- `src/index.ts` — the entry point and nothing else: an application's `main` with an empty body, a
  library's `export {}`. No sample function.
- `tests/` — `.gitkeep` until the first test.
- Root `.gitignore`: `node_modules/`, `dist/`, `coverage/`, `*.tsbuildinfo`, `npm-debug.log*`, then
  the shared block.

## README fill-ins

- **Requirements:** `- Node.js <major> or later`.
- **Usage:** a library → `npm install <package>`, and `{{LinkBase}}` is the absolute GitHub URL
  (npm renders the README); an application → `npx <package>` if it is published, otherwise
  `npm ci && npm run build && npm start` from a clone.

## CONTRIBUTING fill-ins

- **Prerequisites:** `- [Node.js](https://nodejs.org/) <major> or later` (and pnpm, when chosen).
- **Build:** `npm ci`, `npm run typecheck`, `npm run build`.
- **Testing:**

  ````markdown
  Tests live under `tests/`, mirroring `src/`, as `*.test.ts` files run by Vitest. Every test is named with the
  Given / When / Then pattern (`given some condition, when some action, then some output`), and unit and functional
  tests sit in `tests/unit/` and `tests/functional/`, so the two kinds can be run separately:

  ```bash
  npm test -- tests/unit
  npm test -- tests/functional
  ```
  ````

- **VersionFile** (library): ``the `version` in `package.json` ``

## Branch policy (library variant)

- `__VERSION_FILE__` → `package.json`
- `__VERSION_PATTERN__` → `"version"\s*:\s*"\K[^"]+`

## Verify

```bash
npm run typecheck
npm run build
npx vitest run --passWithNoTests
```

`--passWithNoTests` is acceptable only while `tests/` is empty; say so in the report. An application
also runs `npm start` once and must exit 0.
