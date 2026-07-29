---
name: implement-use-case
description: Use when the user wants to implement, build, or start a use case identified by number or name (e.g. "implement UC-03", "start UC-11", "let's do use case 7", "begin the create scope use case"). Drives one use case from backlog to a review-ready pull request by following the project's own workflow documents — loading the specs, refining a design and plan, branching, implementing every flow, testing until green, and preparing the PR — pausing for human approval at every stage boundary. Invoke whenever a message names a use case in an implementation context, even if the word "skill" is never used. Requires the project to have workflow and use case specification documents; stops and says so if they are missing.
---

# Implement a Use Case

## Overview

Drives a single use case from backlog to a review-ready pull request, following
**the project's own workflow documents** rather than a process baked into this
skill.

**Core principle:** the documents own the steps; this skill owns the gates. Every
branch pattern, status transition, test command, and Definition of Done comes from
the project's `Development Workflow Document` and `Workflow.md`, read at invocation
time. This skill contributes what a document cannot: it gets loaded when you ask,
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

| Rationalization | Reality |
|---|---|
| "I already know this flow from the last use case" | Re-read the documents. They may have changed, and the specifics are per use case. |
| "Restating the steps here makes the skill self-contained" | It makes the skill a second source of truth that silently drifts from the docs. Read them instead. |
| "The user is clearly in a hurry" | Then they can say so and skip a gate explicitly. You do not decide that for them. |
| "This alternative flow is unrealistic, it's not worth implementing" | It is in the specification. Implement it, or raise it at Gate 1 and let the user drop it. |
| "The spec cites FR-OR-14 which doesn't exist — probably a typo for FR-OR-04" | Probably. Ask. Guessing at a requirement is how the wrong thing gets built correctly. |

## Procedure

Create a todo per step.

### 1. Identify the use case

Get the use case number or name from the user's message. If it is missing or
ambiguous, ask before doing anything else.

**One invocation handles exactly one use case.** If several are named, confirm the
order and implement the first.

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
`doc-discovery.md` §4.

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

**Stop at [Gate 1](references/gate-protocol.md).** No code before approval.

### 6. Branch and mark the work started

Once the plan is approved, create the branch from an up-to-date base branch using
the pattern extracted in step 3.

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

Stop and ask. On approval, push the branch and open a pull request into the base
branch, following the project's description convention so the merge closes the
issue.

Then hand off. **Do not review, approve, merge, or delete the branch.**

### 11. **Gate 4** — after the human merges

When the user confirms the merge and branch deletion, ask before closing out, then
move the issue to done and confirm it is closed.

### 12. Verify the Definition of Done

Walk the Definition of Done checklist **from the project's Development Workflow
Document** — not a remembered version of it — and confirm each item against
evidence. Report any item that does not hold.

## Quick Reference

| Gate | When | Blocks |
|---|---|---|
| 1 | Design and plan written | Any code being written |
| 2 | Implementation complete | Moving to the testing stage |
| 3 | Full suite green | Opening the pull request |
| 4 | Human merged and deleted the branch | Closing the issue |

**The only unattended transition** is marking the work started, right after the
branch is created.

**Always the human's:** approving, merging, deleting the branch.

| Where a thing comes from | Document |
|---|---|
| Branch pattern, status lifecycle, Definition of Done | Development Workflow Document |
| Step-by-step flow and pause points | `initial/Workflow.md` |
| Actors, flows, `AF-xx` | Use Case Specification Document |
| `FR-xx`, data model, authorization | System Requirements Document |
| Test structure, naming, coverage | Testing Specification Document |
| Libraries and versions | Technology Stack Document |

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
