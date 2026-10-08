<!--
GUIDANCE — delete this comment block in the generated file.

This is the agent-facing delivery workflow: how one unit of work travels from
backlog to a review-ready pull request, and where the agent must stop and ask.

Substitutions:
  {{Project Name}}      e.g. Acme Ordering API
  {{unit of work}}      "use case", "ticket", "story" — whatever the project uses
  {{UNIT}}              its identifier prefix, e.g. UC
  {{branch pattern}}    e.g. feature/uc-##-use-case-name
  {{branch pattern example}}  a filled-in instance, e.g. feature/uc-01-create-order
  {{test command}}      the project's test invocation

Branches are cut from `develop`, the integration branch, and pull requests target
`develop`; `main` only receives release branches (see CONTRIBUTING.md). Change a
rule ONLY where the source material specifies something different. Keep
the pause gates unless the user explicitly said the agent may advance unattended.
-->

# Workflow — {{Project Name}}

How a single {{unit of work}} is delivered, from picking it up to closing it out.
The formal, normative version of this process lives in the
[Development Workflow Document](../requirements/Development%20Workflow%20Document.md);
this document is the operational form an implementer follows step by step.

> **One {{unit of work}} = one branch = one issue = one pull request.**

## Invocation

Work starts when a {{unit of work}} is named by its identifier, e.g. `{{UNIT}}-03`.
If the identifier is missing or ambiguous, ask which one before doing anything
else. One pass handles exactly **one** {{unit of work}}.

## The golden rule: pause at every stage boundary

The work is reviewed before it advances. Therefore:

- **The only status change made unattended is `Todo → In Progress`**, right after
  the branch is created. It signals that work has begun.
- **Every other stage transition requires explicit approval first.** Before moving
  to **Testing**, before opening a **pull request**, and before moving to
  **Done**, stop, show what was done, and ask. Do not batch these.
- **Never merge the pull request, never self-approve, never delete the branch.**
  Review, merge, and branch deletion are human actions. An agent may *prepare and
  push* the pull request.

When pausing, summarize what the stage completed, state what comes next, and wait
for a clear go-ahead.

## Workflow overview

```
Load specs → Refine (design → plan) → [approval] → Branch + issue→In Progress
  → Implement → [approval] → issue→Testing → Test until green → [approval]
  → CHANGELOG entry + README backlog → Open PR into develop
  → [human review + merge + delete branch] → [approval] → issue→Done
```

Steps 1–2 and every `[approval]` gate are where the implementer stops.

---

## Step 1 — Load the specifications

Read the relevant requirements documents before designing anything. Pull the
specifics for this {{unit of work}}; do not work from memory:

- [Use Case Specification Document](../requirements/Use%20Case%20Specification%20Document.md)
  — the target {{unit of work}}: actors, pre/postconditions, main flow, and every
  `AF-xx` alternative flow.
- [System Requirements Document](../requirements/System%20Requirements%20Document.md)
  — the `FR-xx` requirements traced to it, plus the data model, interface
  surface, and authorization matrix.
- [Development Workflow Document](../requirements/Development%20Workflow%20Document.md)
  — the normative delivery process.
- [Testing Specification Document](../requirements/Testing%20Specification%20Document.md)
  — how the tests will be written.
- [Technology Stack Document](../requirements/Technology%20Stack%20Document.md)
  — the libraries, versions, and patterns to build with.

Then locate the tracking issue for this {{unit of work}}.

## Step 2 — Refine the design and plan

The specification is the *what*; a repository-specific *how* is still needed
before coding.

1. **Design** — turn the specification and its traced requirements into a
   concrete design for this codebase: which components, interfaces, validation,
   domain behavior, and entry points are needed, and how each alternative flow
   maps to an error or failure response. Ground it in the patterns already
   present in the repository.
2. **Plan** — capture the result as a written, step-by-step implementation plan,
   sequenced test-first per the Testing Specification.

**Present the refined design and plan, and wait for approval before writing any
code.** This is the first review gate.

## Step 3 — Branch and move the issue to In Progress

Once the plan is approved, create the branch from an up-to-date `develop` using
the naming pattern `{{branch pattern}}`:

```bash
git switch develop && git pull
git switch -c {{branch pattern example}}
```

Then — the **one** status change made without asking — move the issue to
**In Progress**.

## Step 4 — Implement

Execute the approved plan, following the repository's established patterns.
Implement the main flow **and every alternative flow** from the specification.
Grow the implementation and its tests together. Commit on the branch as you go.

## Step 5 — Pause for review before Testing

When the implementation is code-complete, **stop and ask** before advancing.
Summarize what was built. Only after approval, move the issue to **Testing**.

## Step 6 — Test until green

Following the [Testing Specification Document](../requirements/Testing%20Specification%20Document.md),
write the tests for this {{unit of work}} (main flow + each applicable `AF-xx`),
run the suite, fix failures, and **re-run until everything passes**:

```bash
{{test command}}
```

Report the passing results. **Do not open a pull request yet — stop and ask.**

## Step 7 — Open the pull request (after approval)

Once approved, record the change on the same branch, so it merges with the
implementation:

- Add an entry under `## [Unreleased]` in [CHANGELOG.md](../CHANGELOG.md),
  describing what a user or operator would notice.
- If the root README tracks the backlog, mark this {{unit of work}}'s row done.

Then push the branch and open a pull request into `develop`, referencing the
issue so the merge closes it. Then **hand off to a human** for
review and merge. Do **not** merge or delete the branch.

## Step 8 — Close out (after the human merges)

After the pull request is merged and the branch deleted, **ask** before finishing,
then move the issue to **Done** and confirm it is closed.

---

## Definition of Done

- [ ] Implemented on a `{{branch pattern}}` branch created from `develop`.
- [ ] Main flow and every alternative flow implemented.
- [ ] Tests cover the {{unit of work}} per the Testing Specification.
- [ ] The full suite passes.
- [ ] The change is recorded under `## [Unreleased]` in `CHANGELOG.md`, and the
      README backlog row (if any) is marked done, in the same pull request.
- [ ] The pull request into `develop` was reviewed by a human and merged.
- [ ] The branch was deleted.
- [ ] The issue is in **Done** and closed.
