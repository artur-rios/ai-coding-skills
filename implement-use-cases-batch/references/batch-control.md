# Batch Control

Resolving what the user asked for into an ordered list, and the cycle each use case
goes through.

---

## 1. Resolving the batch

### Parsing the request

| The user says | Resolves to |
| --- | --- |
| "use cases from 01 to 11" | `UC-01` … `UC-11`, **inclusive** at both ends |
| "UC-03 through UC-07" | `UC-03` … `UC-07`, inclusive |
| "UC-02, UC-05 and UC-09" | Exactly those three, in that order |
| "everything in milestone 2" | Every use case the milestone's issues reference |
| "the rest of the backlog" | Every use case whose issue is still open |
| "all the use cases" | Every `UC-xx` in the specification |

Zero-padding follows the specification's own convention. "1 to 11" and "01 to 11"
mean the same thing.

### Resolving against reality

Check every identifier against the Use Case Specification **before** asking for
authorization:

- **Does not exist** → report it in step 1 and exclude it. A range that overshoots
  the specification is a typo, not an instruction to invent use cases.
- **Already implemented** (its issue is closed, or the code plainly exists) → report
  it and exclude it. Do not re-implement; do not silently skip either.
- **No issue in the tracker** → report it. Ask whether to create the issue or
  exclude the use case; this is part of the authorization request, not a mid-batch
  interruption.

### Ordering

Use the **specification's own order** — `UC-01`, `UC-02`, … — unless the documents
state dependencies, in which case a dependency is implemented before its dependent.

Do not reorder on your own judgment of what seems foundational. If the ordering
looks wrong, say so in the authorization request and let the user decide; they may
know something the documents do not say.

## 2. The per-use-case cycle

Every use case runs this cycle from the top. No step is skipped because the
previous use case did something similar.

### a. Load the specifications — fresh

Read this use case's specification and everything it traces to, from disk. Never
work from memory of the previous use case; that is how a misreading spreads across
a batch.

**Stop** if the specification is missing, or cites a requirement that does not exist.

### b. Design and plan → Gate 1 verification

Produce the repository-specific design and a test-first plan. Then verify, and stop
if any of it fails:

- [ ] Every `AF-xx` in the specification maps to a concrete failure path.
- [ ] Every cited `FR-<AREA>-xx` exists in the System Requirements Document.
- [ ] The plan sequences tests before implementation, per the Testing Specification.
- [ ] No flow admits more than one reasonable implementation.

### c. Branch and mark started

Create the branch from an **up-to-date** base branch, using the project's pattern.
Move the issue to the project's "work started" status.

### d. Implement

Main flow and **every** alternative flow, following the repository's existing
patterns. Commit as you go.

### e. Gate 2 verification

- [ ] The main flow is implemented.
- [ ] Every `AF-xx` is implemented — not stubbed, not deferred.
- [ ] Any deviation from the plan is noted for the report.

### f. Test until green

Write the tests per the project's Testing Specification, run the **full** suite,
fix, re-run — within the retry budget in `autonomy-protocol.md` §3.

### g. Gate 3 verification

- [ ] The suite was run in this session and its output read.
- [ ] The run was the full suite — not filtered, not a subset.
- [ ] Every test passes. Zero skipped tests that this use case should have covered.

### h. README tracking, then the pull request

If the repository's README carries a backlog, mark this use case's row done **on
this branch**, so the status change merges with the implementation. Then push and
open the pull request, referencing the issue so the merge closes it.

### i. Merge

1. Wait for CI. Poll until the required checks conclude — do not merge on pending.
2. **Green** → merge using the repository's configured method, then delete the
   branch.
3. **Red, or the merge conflicts** → stop the batch.

Never `--admin`, never force, never self-approve.

### j. Definition of Done

Walk the checklist from the project's Development Workflow Document and confirm each
item against evidence. A failed item stops the batch — the use case is not done, and
the next one would build on it.

### k. Sync and continue

Return to the base branch, pull, and confirm the working tree is clean. Then start
the next use case.

## 3. Progress reporting

One line per completed use case, as it completes:

```
UC-03 — Create order · PR #14 merged · issue #7 closed · 42 tests passed
```

The user is not approving anything; they are reading a log. Keep it scannable and
factual — no summaries of what you are about to do, no reassurance.

## 4. Resuming a stopped batch

A stopped batch is resumed by invoking the skill again with the remaining use
cases. It is **not** resumed by continuing from memory:

- The already-merged use cases are done and are not revisited.
- The use case that failed starts over from step a, on a fresh branch, unless the
  user says to continue the existing branch.
- Preconditions and authorization are checked again. The base branch has moved and
  the previous authorization covered a different scope.
