# React + shadcn/ui

Read after the user picked React (step 1 of `SKILL.md`). A Vite + React + TypeScript single-page app
with Tailwind CSS and shadcn/ui, tested with Vitest and Testing Library. An application: the branch
policy is the application variant.

## Interview

Asked in the same round as the shared questions. The shared name question asks for the **package
name** in kebab-case (`order-portal`).

| Question | Default |
|---|---|
| "npm or pnpm?" | npm |
| "shadcn/ui components to add now? (e.g. `button card dialog`; blank for none)" | none |

shadcn's base colour, style and CSS-variable choices are taken from `shadcn init`'s defaults (`-d`);
the user changes them later in `components.json`.

## Generate

Vite accepts a directory that holds only `.git`. If step 0 left other files the user kept, generate
into a temporary directory and move its contents in.

```bash
npm create vite@latest . -- --template react-ts --no-interactive
npm install
npm install tailwindcss @tailwindcss/vite
```

The template already brings `@types/node`; install it with `--save-dev` only if `package.json` lacks
it. Its `lint` script runs **Oxlint** (`.oxlintrc.json`), not ESLint — keep it.

Check `npm create vite@latest -- --help` first: if this version has no `--no-interactive`, drop it
and answer "No" to "install and start now?".

Then the shadcn steps, from <https://ui.shadcn.com/docs/installation/vite>:

1. `src/index.css` → replace its whole content with `@import "tailwindcss";`.
2. `tsconfig.json` and `tsconfig.app.json` → add to `compilerOptions`:
   `"paths": { "@/*": ["./src/*"] }` — **without** the `"baseUrl": "."` older guides pair with it:
   TypeScript 7 removed `baseUrl` (`TS5102`), and `paths` resolves relative to the tsconfig on its own.
3. `vite.config.ts`:

   ```ts
   import path from "node:path";
   import tailwindcss from "@tailwindcss/vite";
   import react from "@vitejs/plugin-react";
   import { defineConfig } from "vite";

   export default defineConfig({
     plugins: [react(), tailwindcss()],
     resolve: { alias: { "@": path.resolve(import.meta.dirname, "./src") } },
   });
   ```

4. `npx shadcn@latest init -d` (check `npx shadcn@latest init --help` for the current flag names —
   the CLI changes often; answer its prompts with the defaults if a flag is missing). `-d` takes the
   default preset (base-nova at the time of writing) and detects Vite; it may add `button` itself.
5. If the user named components: `npx shadcn@latest add <components>` — they land in
   `src/components/ui/`; one `init` already added is skipped.

## Shape

- **Strip the Vite demo:** delete `src/App.css`, `src/assets/`, the demo icons in `public/` (whatever
  the template ships there — `favicon.svg`, `icons.svg`, `vite.svg`) and the counter / logos in
  `src/App.tsx`, leaving an `App` that renders the project's display name (title-cased:
  `order-portal` → "Order Portal") in a heading. Set `index.html`'s `<title>` to the same name and
  drop its favicon link.
- **Tests in `tests/`:**

  ```bash
  npm install --save-dev vitest jsdom @testing-library/react @testing-library/jest-dom @testing-library/user-event
  ```

  Add the test configuration to `vite.config.ts` — import `defineConfig` from `vitest/config` instead
  of `vite` so the `test` key type-checks:

  ```ts
  test: {
    environment: "jsdom",
    include: ["tests/**/*.test.{ts,tsx}"],
    setupFiles: ["./tests/setup.ts"],
  },
  ```

  `tests/setup.ts`: `import "@testing-library/jest-dom/vitest";`

  Add `"tests"` to `include` in `tsconfig.app.json` so the editor and `tsc -b` type-check the tests
  with the same `@/` alias.

- **One smoke test,** `tests/App.test.tsx`, rendering `<App />` and asserting the heading is there.
  Vitest globals are off, so it imports `describe`, `it` and `expect` from `vitest`.
  It is not a sample: it is the proof that `tests/`, jsdom, the `@/` alias and Tailwind's import all
  resolve, and the first real test replaces it.
- `package.json`: set `"name": "<package name>"` (create-vite uses the directory's name) and
  `"version": "0.1.0"`, and add `"test": "vitest run"`.
- Root `.gitignore`: Vite's own, then the shared block.

## README fill-ins

- **Requirements:** `- Node.js <major> or later` (the version `node --version` reports, if LTS).
- **Usage:** `npm ci && npm run dev`, then <http://localhost:5173>; `npm run build` writes the static
  site to `dist/`.

## CONTRIBUTING fill-ins

- **Prerequisites:** `- [Node.js](https://nodejs.org/) <major> or later`
- **Build:** `npm ci`, `npm run lint`, `npm run build`.
- **Testing:**

  ````markdown
  Tests live under `tests/`, mirroring `src/`, as `*.test.tsx` files run by Vitest with Testing Library in jsdom.
  Every test is named with the Given / When / Then pattern (`given some condition, when some action, then some
  output`).

  ```bash
  npm test
  ```

  UI components are added with `npx shadcn@latest add <component>`; they land in `src/components/ui/`.
  ````

## Verify

```bash
npm run lint
npm run build
npm test
```

`npm test` must report **1 passed** — the smoke test. Zero tests found means the `include` pattern is
not reading `tests/`.
