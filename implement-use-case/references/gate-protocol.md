# Gate Protocol

The gates are the point of this skill. The workflow documents describe the steps;
this file defines how work is handed back for review between them.

## The rule

**Exactly one stage transition is made unattended:** the one that marks work as
started, immediately after the branch is created. Every other transition — into
testing, into review, into done — requires the user to say go, each time, after
seeing what was completed.

Approval is **per gate**. "Looks good" at the design gate authorizes
implementation, not the pull request. Never bank one approval to spend at a later
gate, and never present two gates at once to save a round trip.

## What a pause looks like

At every gate, give the user three things and then stop:

1. **What the stage produced** — concrete and verifiable. Files, behavior,
   commands run, output observed. Not "implemented the use case".
2. **What is still open** — anything deferred, assumed, or discovered along the
   way that the user should weigh before the work advances.
3. **What happens next if they approve** — named explicitly, so approval is
   informed.

Then ask, and wait. Do not begin the next stage's work "while waiting".

## What never counts as approval

- Silence.
- The user answering an unrelated question in the same message.
- Your own judgment that the stage obviously succeeded.
- An earlier approval at a different gate.
- The tests passing. Green tests are evidence for the gate, not the gate itself.

If the user's reply is ambiguous — "ok" to a message that asked two things — ask
which they meant rather than choosing the interpretation that lets work continue.

## The gates

### Gate 1 — before any code is written

After the design and the implementation plan exist, before the branch.

Show: the design for this repository, the plan sequenced test-first, how each
`AF-xx` alternative flow maps to a failure path, and every assumption the
specification did not settle.

This is the cheapest gate. A misread requirement caught here costs a paragraph; it
costs a rewrite at Gate 2.

### Gate 2 — implementation complete, before the testing stage

Show: what was built, how it maps to the plan, which alternative flows are
implemented, and anything you had to decide that the plan did not cover.

State plainly whether the main flow **and every** alternative flow are done. A
partially implemented use case that advances to testing wastes the testing stage.

### Gate 3 — suite green, before the pull request

Show: the test command actually run and its real output — the counts, not a
paraphrase. Coverage of the main flow and each applicable `AF-xx`.

Never claim green without having run the suite in this session and read the
result. If tests were skipped, filtered, or excluded, say which and why.

Opening a pull request is outward-facing and hard to retract. It waits for a yes.

Approval here also clears the README tracking update, since that change ships
inside the same pull request. Say at this gate whether the README tracks issues
and which row you will mark — including the marker you chose when the file has no
completed row to copy.

### Gate 4 — after the human merges, before closing out

The user reviews, merges, and deletes the branch. You do none of those. When they
confirm the merge, ask before moving the issue to done and closing it.

Confirm the README tracking landed with the merge. If it did not, report it and
ask — editing the README outside a pull request is a change to the base branch,
and that is the user's call.

## Actions that are always the human's

- **Approving a pull request.** Never self-approve.
- **Merging.** Never merge, even with approval to open the pull request.
- **Deleting the branch.** It goes with the merge.
- **Force-pushing** to a shared branch, or rewriting published history.

You may prepare and push a branch, and open a pull request once Gate 3 clears.
That is the boundary.

## When the user asks you to skip a gate

They may. It is their project. Confirm what they are authorizing and how far it
extends — "straight through to the pull request without stopping at testing?" —
then proceed, and still stop at the actions listed above as always-human.

A blanket "just do the whole thing" does not authorize merging, self-approving, or
deleting branches. Those are not gates in the flow; they are the human's role in
it.

## Scope

One invocation implements **one** use case. If the user names several, implement
the first and ask before starting the next — each one gets its own branch, issue,
and pull request, and each one gets its own four gates.
