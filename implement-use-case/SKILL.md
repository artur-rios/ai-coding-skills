---
name: implement-use-case
description: Use when the user wants to implement, build, or start a use case identified by number or name (e.g. "implement UC-03", "start UC-11", "let's do use case 7", "begin the create scope use case"). Drives one use case from backlog to a review-ready pull request by following the project's own workflow documents — loading the specs, refining a design and plan, branching, implementing every flow, testing until green, marking the use case done in the README backlog when the README tracks one, recording it under Unreleased in CHANGELOG.md, and preparing the PR into the integration branch (develop where the repository enforces that model) — pausing for human approval at every stage boundary. Invoke whenever a message names a use case in an implementation context, even if the word "skill" is never used. Requires the project to have workflow and use case specification documents; stops and says so if they are missing.
---

# Implement a Use Case

## Overview

Drives a single use case from backlog to a review-ready pull request, following
**the project's own workflow documents** rather than a process baked into this
skill.

**Core principle:** the documents own the steps; this skill owns the gates. Every
branch pattern, status transition, test command, and Definition of Done comes from
the project's `Development Workflow Document` and `Workflow.md`, read at invocation
time — with one override: where the repository *enforces* a branching model
(`CONTRIBUTING.md`, a Branch Policy check, a `develop` branch, rulesets), that model
sets the base branch, because a pull request the check rejects cannot merge. This
skill contributes what a document cannot: it gets loaded when you ask,
it stops the work at every review boundary, and it refuses to advance on its own
judgment.

That is also why it never restates a step the documents define. If it did, the two
would drift and you would have no way to tell which one the agent followed.

## When to Use

- A message names a use case in an implementation context: "implement UC-03",
  "start use case 7", "let's build the create-order use case".
- The user wants the full delivery flow — spec to pull request — not just a code
  change.

Skip / adapt if:
- The project has **no workflow documents**. Stop and say so (step 2). Do not
  invent a process.
- The user names **several** use cases, a range, or a milestone — that is
  `implement-use-cases-batch`, which runs this same workflow unattended across a
  series and merges its own pull requests.
- The user wants a quick edit, a bugfix, or an experiment. This skill is the
  production line for a specified unit of work; it is heavy for anything else.
- The user is asking a question about a use case rather than asking for it to be
  built.

## Red Flags — STOP and Re-read the Procedure

- "The workflow doc is basically the standard flow, I'll just proceed" → NO. Read
  it. The branch pattern and gates are project-specific.
- "I'll implement the main flow now and add the alternative flows after review"
  → NO. A use case is its main flow **and every** `AF-xx`.
- "Tests pass, so I'll open the PR" → NO. Green tests are evidence for Gate 3,
  not permission to pass it.
- "They approved the plan, so they'd obviously approve this too" → NO. Approval
  is per gate, never banked.
- "I'll batch the testing and PR gates into one message to save time" → NO. One
  gate per message.
- "I'll just merge it since it's approved" → NO. Merging, approving, and deleting
  the branch are always the human's.
- "No workflow doc, but the repo clearly uses `feature/*` branches" → NO. Inferred
  process is guessed process. Stop and ask.
- "The workflow doc says branch from `main`, so I'll target `main`" → NO, not when
  the repository enforces a `develop` flow. `main` takes only `release/*` pull
  requests; branch from `develop`, target `develop`, and report the stale document
  at Gate 1.
- "I'll fix the stale workflow document while I'm here" → NO. Report it. A
  document fix is its own pull request, not part of this use case's.
- "The CHANGELOG is the owner's job at release time" → NO. The owner *finalizes*
  `## [Unreleased]` at release time; each change records itself there, in its own
  pull request.
- "There's no CHANGELOG, I'll start one" → NO. Say so at Gate 3. Starting a
  changelog is a project decision.
- "The README has no backlog, I'll add one while I'm here" → NO. Update tracking
  that exists; do not introduce it.
- "The README row is done, I'll also tidy the other stale rows" → NO. One use
  case, one row. The rest is someone else's pull request.

| Rationalization | Reality |
|---|---|
| "I already know this flow from the last use case" | Re-read the documents. They may have changed, and the specifics are per use case. |
| "Restating the steps here makes the skill self-contained" | It makes the skill a second source of truth that silently drifts from the docs. Read them instead. |
| "The user is clearly in a hurry" | Then they can say so and skip a gate explicitly. You do not decide that for them. |
| "This alternative flow is unrealistic, it's not worth implementing" | It is in the specification. Implement it, or raise it at Gate 1 and let the user drop it. |
| "The spec cites FR-OR-14 which doesn't exist — probably a typo for FR-OR-04" | Probably. Ask. Guessing at a requirement is how the wrong thing gets built correctly. |
| "The document is the source of truth, so its base branch wins" | The documents own the process; the Branch Policy check owns what can merge. A pull request it rejects is not a deliverable. |
| "The changelog entry can describe the handlers I added" | The changelog is read by API clients, operators, and users. Say what they can now do. |

## Procedure

Create a todo per step.

### 1. Identify the use case

Get the use case number or name from the user's message. If it is missing or
ambiguous, ask before doing anything else.

**One invocation handles exactly one use case.** If several are named — a range, a
list, a milestone — the user is asking for `implement-use-cases-batch`, which runs
the same workflow unattended across a series. Say so and confirm which they want
before starting; if they want this skill's per-stage gates, implement the first and
ask before the next.

### 2. Locate and validate the workflow documents

Follow [references/doc-discovery.md](references/doc-discovery.md) to find the
project's workflow and specification documents.

**If there is no workflow document, stop here.** Report what is missing and offer
the two ways forward — run `generate-specs-from-brainstorm` to produce the
requirements set, or have the user state the process. Do not infer a workflow from
git history or branch names.

If both workflow documents exist and contradict each other, surface the
contradiction and ask which is right.

### 3. Extract the project's parameters and report them

Pull the branch pattern, base branch, status lifecycle, unattended transition,
issue tracker, test commands, and Definition of Done from the documents, per
`doc-discovery.md` §4. Then check whether the repository **enforces** a branching
model (`doc-discovery.md` §3) — a branching section in `CONTRIBUTING.md`,
`.github/workflows/branch-policy.yml`, a `develop` branch on the remote, rulesets.
Where it does, it sets the base branch (usually `develop`) and the accepted
prefixes (`feature/`, or `fix/` for a fix); a document that still says `main` is
stale — note it for Gate 1.

Check too whether the repository's `README.md` tracks issues — a roadmap or
backlog table — and note the exact row for this use case and the marker the file
uses for done work; and whether a `CHANGELOG.md` with a `## [Unreleased]` section
exists (`changelog-entry.md` §1).

Report what you found and where. A misread parameter is cheapest to fix now.

Ask about anything the documents leave undefined.

### 4. Load the specifications for this use case

Read the use case's own specification and everything it traces to, per
`doc-discovery.md` §5 — actors, pre/postconditions, main flow, every `AF-xx`, the
cited `FR-<AREA>-xx` requirements, the data model, the authorization rules, the
testing standard, and the technology stack.

Then locate the tracking issue for this use case, using the tracker the documents
named.

Cross-check: a use case citing a requirement that does not exist is a stop-and-ask,
not a guess.

### 5. Refine the design and plan — then **Gate 1**

The specification is the *what*. Produce the *how* for this repository: the
components, interfaces, validation, domain behavior, and entry points needed, and
how each alternative flow maps to a failure path. Ground it in the patterns the
repository already uses (`doc-discovery.md` §6).

Capture it as a written, step-by-step plan, sequenced test-first per the project's
Testing Specification.

If design and planning skills are available in this session (for example
`superpowers:brainstorming` and `superpowers:writing-plans`), use them. Otherwise
produce the design and plan directly.

**Stop at [Gate 1](references/gate-protocol.md).** No code before approval. Raise
any stale workflow document found in step 3 here, with the base branch you will
use instead.

### 6. Branch and mark the work started

Once the plan is approved, create the branch from an up-to-date base branch using
the pattern extracted in step 3 — in a repository with the `develop` flow:

```bash
git switch develop && git pull
git switch -c feature/uc-##-use-case-name
```

Then make the **one** status change permitted without asking: move the issue to
whichever status the documents define as "work has begun".

### 7. Implement

Execute the approved plan, following the repository's established patterns.
Implement the main flow **and every alternative flow**. Grow the implementation and
its tests together. Commit on the branch as you go.

Deviating from the approved plan is fine when the code demands it — note the
deviation and raise it at Gate 2 rather than silently redesigning.

### 8. **Gate 2** — implementation complete

Stop. Summarize what was built and which flows are covered. Only after approval,
move the issue to the project's testing status.

### 9. Test until green

Write the tests per the project's Testing Specification — main flow and each
applicable `AF-xx`. If a unit-test skill is available (`create-unit-tests`), use it
for the unit layer; the Testing Specification still governs naming and structure.

Run the suite with the commands extracted in step 3. Fix failures, re-run, and
repeat **until everything passes**.

Report the real command output. Never describe a suite as green without having run
it in this session and read the result.

### 10. **Gate 3** — before the pull request

Stop and ask.

### 11. Record the use case — README backlog and CHANGELOG

On Gate 3 approval, and **before** opening the pull request, record the use case in
the two places the repository keeps for it, so the merge carries them with the
implementation:

- **README backlog** — only if the README tracks issues: mark this use case's row
  done, per [references/readme-tracking.md](references/readme-tracking.md). If the
  README has no issue tracking, skip this silently. Do not add tracking to a README
  that does not have it — that is a different piece of work, and not one you were
  asked to do.
- **CHANGELOG** — only if `CHANGELOG.md` exists: add an entry under
  `## [Unreleased]`, per [references/changelog-entry.md](references/changelog-entry.md).
  If there is no `CHANGELOG.md`, you said so at Gate 3; do not create one.

Commit both on the same branch. They land on the base branch only when the pull
request merges, which is the same moment the issue actually closes.

### 12. Open the pull request

Push the branch and open a pull request into the base branch — `develop` where the
repository enforces that model, never `main` — following the project's description
convention so the merge closes the issue.

Then hand off. **Do not review, approve, merge, or delete the branch.**

### 13. **Gate 4** — after the human merges

When the user confirms the merge and branch deletion, ask before closing out, then
move the issue to done and confirm it is closed.

Confirm the README tracking and the CHANGELOG entry landed with the merge. If they
did not — the step was skipped, or the file was edited on the base branch
meanwhile — say so and ask before changing either outside a pull request.

### 14. Verify the Definition of Done

Walk the Definition of Done checklist **from the project's Development Workflow
Document** — not a remembered version of it — and confirm each item against
evidence. Report any item that does not hold.

## Quick Reference

| Gate | When | Blocks |
|---|---|---|
| 1 | Design and plan written | Any code being written |
| 2 | Implementation complete | Moving to the testing stage |
| 3 | Full suite green | The README tracking update, the CHANGELOG entry, and the pull request |
| 4 | Human merged and deleted the branch | Closing the issue |

**The only unattended transition** is marking the work started, right after the
branch is created.

**Always the human's:** approving, merging, deleting the branch.

| Where a thing comes from | Document |
|---|---|
| Branch pattern, status lifecycle, Definition of Done | Development Workflow Document |
| Base branch and accepted prefixes, when enforced | `CONTRIBUTING.md`, `.github/workflows/branch-policy.yml`, rulesets — they override a stale document |
| Step-by-step flow and pause points | `initial/Workflow.md` |
| Actors, flows, `AF-xx` | Use Case Specification Document |
| `FR-xx`, data model, authorization | System Requirements Document |
| Test structure, naming, coverage | Testing Specification Document |
| Libraries and versions | Technology Stack Document |
| Whether the backlog is mirrored in the README, and how done is marked | The repository's `README.md` |
| Whether changes are recorded, and for which reader | The repository's `CHANGELOG.md` and `CONTRIBUTING.md` |

## Common Mistakes

- **Inventing a process when no workflow document exists.** Stop and offer to
  generate one instead.
- **Restating the workflow steps in the conversation as if they were this skill's.**
  Read them from the project's documents each time.
- **Implementing only the main flow.** Every `AF-xx` is part of the use case.
- **Banking an approval.** Gate 1's yes does not clear Gate 3.
- **Batching gates** into a single message to save a round trip.
- **Claiming green tests without running them** in this session.
- **Merging, self-approving, or deleting the branch.** Always the human's.
- **Working from memory of a previous use case** in the same session instead of
  re-reading this one's specification.
- **Guessing at a dangling requirement reference** instead of asking.
- **Handling several use cases in one invocation.** One use case, one branch, one
  issue, one pull request.
- **Leaving the README backlog stale** when the project keeps one. The tracker and
  the README disagreeing is how a backlog stops being trusted.
- **Adding backlog tracking to a README that has none**, or restructuring the
  tables of one that does.
- **Committing the README update or the CHANGELOG entry straight to the base
  branch.** Both belong on the use case's branch, inside the pull request.
- **Targeting `main`** in a repository with a `develop` flow. `main` only takes
  `release/*` pull requests; the Branch Policy check rejects anything else.
- **Following a stale workflow document's base branch** over the enforced model —
  or silently fixing that document in the use case's pull request. Report it at
  Gate 1.
- **Writing the changelog entry for the reviewer** — handler and test names —
  instead of for the API client, operator, or user who reads the changelog.
- **Editing a released CHANGELOG section** or the compare links. Only
  `## [Unreleased]` belongs to the use case.
