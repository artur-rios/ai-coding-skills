# Angular + spartan/ui

Read after the user picked Angular (step 1 of `SKILL.md`). An Angular CLI workspace with Tailwind CSS
and spartan/ui (brain primitives + helm styles, the shadcn approach for Angular). An application: the
branch policy is the application variant.

## Interview

Asked in the same round as the shared questions. The shared name question asks for the **project
name** in kebab-case (`order-portal`).

| Question | Default |
|---|---|
| "npm or pnpm?" | npm |
| "Server-side rendering?" | no |
| "spartan/ui theme? (neutral, stone, zinc, gray, slate)" | neutral |
| "spartan/ui components to add now? (e.g. `button card dialog`, or `all`; blank for none)" | none |

## Generate

Use the CLI's latest release through `npx`, never a global `ng` that may be majors behind:

```bash
npx @angular/cli@latest new <name> --directory . --style css --ssr false --skip-git --defaults
```

Run `npx @angular/cli@latest new --help` first and add any option this version would otherwise prompt
for; the interview has already answered everything, so the generator must not ask. (With Angular CLI
22 the command above is enough.)

Then Tailwind CSS v4: `npx ng add tailwindcss` — it writes `.postcssrc.json` and `@import 'tailwindcss'`
— or, on a CLI without it, the manual steps from
<https://tailwindcss.com/docs/installation/framework-guides/angular>.

Then spartan/ui, from <https://www.spartan.ng/documentation/installation>. `init` also runs the theme
generator — do **not** run `ui-theme` after it, which writes the theme a second time:

```bash
npm install --save-dev @spartan-ng/cli
npx ng g @spartan-ng/cli:init --theme <theme>
```

Check that `src/styles.css` now starts with these lines, in this order (add any `init` left out):

```css
@layer theme, base, components, utilities;
@import "tailwindcss/theme.css" layer(theme);
@import "tailwindcss/preflight.css" layer(base);
@import "tailwindcss/utilities.css";
@import "@spartan-ng/brain/hlm-tailwind-preset.css";
```

followed by the theme's `:root` / `.dark` variables.

If the user named components, first write `components.json` at the root — without it the `ui`
generator prompts for the path, alias and style, and **without a terminal it exits 0 having done
nothing**:

```json
{ "componentsPath": "src/app/ui", "importAlias": "@spartan-ng/helm", "style": "vega" }
```

(check `npx ng g @spartan-ng/cli:ui --help` for the current style names), then run
`npx ng g @spartan-ng/cli:ui <component>` once per component — it takes one name, or `all`. Confirm
the files appeared under `src/app/ui/`.

## Shape

- **Helm components live under `src/`** — `components.json`'s `componentsPath` is `src/app/ui`, never a
  root `libs/` folder, which breaks the shared shape. Keep the `@spartan-ng/helm/*` path aliases the CLI
  writes into `tsconfig.json` pointing there. If `utils` generated `provideSpartanHlm()`, add it to
  the `providers` in `src/app/app.config.ts`.
- **Strip the CLI demo:** reduce `src/app/app.html` to a heading with the project's display name
  (`order-portal` → "Order Portal") and the `<router-outlet />`; delete the placeholder content and its
  styles.
- **Specs in `tests/`:** move the generated root spec — `src/app/app.spec.ts` — to
  `tests/app/app.spec.ts`, fix its import (`../../src/app/app`), update its assertions to the new
  heading, and rename its tests to the Given / When / Then pattern (`given the app, when it is
  created, then it renders the project name`). Then point the test target at `tests/`:
  - `angular.json` → create `projects.<name>.architect.test.options` (the generator writes none) with
    `"include": ["../tests/**/*.spec.ts"]` — the `@angular/build:unit-test` builder resolves it from
    `sourceRoot` (`src/`), so `tests/**/*.spec.ts` finds nothing;
  - `tsconfig.spec.json` → `include: ["tests/**/*.ts", "src/**/*.d.ts"]`.

  That spec is the scaffold's one test file: it proves the component, the router and `tests/` all
  resolve, and the first real spec replaces it.
- Keep what the CLI generated outside `src/`: `public/` (static assets, served at the root),
  `.vscode/`, `.prettierrc`. Merge the CLI's `.editorconfig` into the template one (step 6 of
  `SKILL.md`) so its `[*.ts] quote_type = single` survives.
- Set `"version": "0.1.0"` in `package.json`.
- Root `.gitignore`: the CLI's own, plus `/.nx` (the spartan CLI caches workspace data there), then the
  shared block.

## README fill-ins

- **Requirements:** `- Node.js <the range the Angular CLI version requires>`.
- **Usage:** `npm ci && npm start`, then <http://localhost:4200>; `npm run build` writes the site to
  `dist/<name>/browser`.

## CONTRIBUTING fill-ins

- **Prerequisites:** `- [Node.js](https://nodejs.org/) <range>` — the Angular CLI runs through `npx` /
  the project's own `node_modules`, so no global install.
- **Build:** `npm ci`, `npm run build`.
- **Testing:**

  ````markdown
  Specs live under `tests/`, mirroring `src/app/`, as `*.spec.ts` files run by the Angular CLI's test builder. Every
  spec is named with the Given / When / Then pattern (`given some condition, when some action, then some output`).

  ```bash
  npm test -- --watch=false
  ```

  UI components are added with `npx ng g @spartan-ng/cli:ui`; they land in `src/app/ui/`.
  ````

## Verify

```bash
npm run build
npm test -- --watch=false
```

The `@angular/build:unit-test` builder runs Vitest in jsdom — no browser needed (a Karma-based builder
needs `--browsers=ChromeHeadless`). The run must report **1 test file passed, 0 failed** — "No tests
found" means the `include` is not reading `tests/`; a spec failing to compile means the moved spec's
import or `tsconfig.spec.json` is wrong.
