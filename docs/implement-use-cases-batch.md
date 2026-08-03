# implement-use-cases-batch

Implements a **series** of use cases end to end, unattended — the same workflow and
the same verifications as [implement-use-case](implement-use-case.md), but the four
human approval gates become automated checks and the skill merges its own pull
requests before starting the next use case.

## What it does

- Resolves what you asked for ("use cases from 01 to 11") into a concrete, ordered
  list, checked against the specification **before** anything starts.
- Reads the project's workflow documents once, exactly as `implement-use-case` does.
- Verifies it can actually run unattended: authenticated tooling, merge permission,
  a clean tree, a test command, and no branch-protection rule requiring a human
  approval.
- **Asks once**, for the whole batch, then runs without further approval.
- Per use case: loads the specs fresh, designs, branches, implements every flow,
  tests until green, updates the README backlog, opens the pull request, waits for
  CI, merges, deletes the branch, closes the issue, checks the Definition of Done,
  syncs, and moves on.
- Logs one line per completed use case, and stops the whole batch the moment a
  verification fails.

## When to use it

It triggers on a range or a set: "implement use cases from 01 to 11", "UC-03
through UC-07", "do everything in milestone 2", "implement the rest of the
backlog".

For a **single** use case, use [implement-use-case](implement-use-case.md) — it
stops for your review at each stage boundary. Don't reach for the batch skill to
avoid those gates on one unit of work; that's not what it's for.

## The trade it makes

> Autonomy replaces the approval, never the verification.

Every check `implement-use-case` runs still runs here. What changes is who acts on
the result: instead of handing work back, the batch must prove the condition and
continues only if it holds.

| `implement-use-case` gate | Becomes | The batch stops when |
|---|---|---|
| **1** — design and plan approved | Every `AF-xx` mapped to a failure path, every cited `FR-xx` exists, plan sequenced test-first | A cited requirement doesn't exist, or a flow has no mapping |
| **2** — implementation complete | Main flow **and every** `AF-xx` implemented | Any flow is stubbed or deferred |
| **3** — suite green | The full suite, run in this session, unfiltered, output read | Tests still fail after the retry budget, or the run was filtered |
| **4** — you merged | CI green, then the batch merges | CI fails, the merge conflicts, or is refused |

A verification that **cannot** be performed counts as failed. No test command in
the documents is a stop, not permission to skip testing.

## The one approval

The batch is authorized once, up front, with the resolved scope on the table — and
the request says plainly that it will **merge its own pull requests, close the
issues, and delete the branches**:

> "11 use cases, UC-01 through UC-11, in specification order. Each gets its own
> branch, issue and pull request; I'll merge each into `main` and close its issue
> before starting the next. CI runs on pull requests and must be green to merge.
> I stop the batch on a failing suite after 3 fix attempts, red CI, a merge
> conflict, an ambiguous spec, or a dangling requirement — already-merged use cases
> stay merged. Go ahead?"

Silence isn't authorization. Neither is "do whatever you think is best" given
before the scope was known, nor an approval for a previous batch — each run is
authorized on its own scope.

## Stop conditions

| Stop | Fires when |
|---|---|
| Failing suite | Still red after the retry budget (3 fix attempts by default) |
| Red CI | Any required check fails on the pull request |
| Merge conflict | The branch won't merge cleanly into the base |
| Dangling reference | A use case cites an `FR-<AREA>-xx` that doesn't exist |
| Missing specification | The use case has no entry to implement |
| Ambiguous flow | A flow admits more than one reasonable implementation |
| Branch protection | A required approving review, or a rule the merge would violate |
| Dirty tree | The working tree isn't clean between use cases |

A stop ends the **batch**, not just the current use case — a failure at use case 4
usually means 5 through 11 fail the same way, and eight broken merges are far worse
than one honest halt.

When a stop fires: merged use cases stay merged, the failing branch stays pushed,
the pull request stays open, and you get a report of what landed, what failed and
how, and what never started. It never reverts merged work to tidy up — that's your
call, made on the evidence.

## What stays forbidden

Authorization to merge is not authorization for any of these, and "no human
intervention" never implies them:

- Force-pushing or rewriting published history
- `gh pr merge --admin`, or any flag whose purpose is bypassing a protection
- Approving its own pull request to satisfy a required-review rule
- Disabling, skipping, filtering, or deleting a test to make a suite green
- Merging on red or unread CI
- Editing branch protection, repo settings, or CI config to smooth its own path
- Reverting merged work, or continuing past a stop condition

Each of those turns a verification into a formality — and the batch's whole claim
to being safe unattended is that its checks are real.

## How it works

1. **Resolve** the range into identifiers; validate the workflow documents.
2. **Extract** the project's parameters once, and verify the automation
   preconditions.
3. **Authorize** — the one and only approval.
4. **Loop**, one use case at a time, through the full cycle.
5. **Log** one line per completed use case.
6. **Report** the batch, finished or stopped.

## Requirements

The same workflow documents [implement-use-case](implement-use-case.md) needs —
typically the set [generate-specs-from-brainstorm](generate-specs-from-brainstorm.md)
produces — plus a repository where the agent may merge.

Document discovery is **shared verbatim** with `implement-use-case`, so the two
skills can never read the same project differently.

## Files in this skill

| Path | Purpose |
|---|---|
| `SKILL.md` | The procedure, the red flags, and the gates-to-verifications mapping. |
| `references/autonomy-protocol.md` | Preconditions, what counts as authorization, the stop conditions, and the forbidden actions. |
| `references/batch-control.md` | Resolving a range into identifiers, the per-use-case cycle, progress logging, and resuming a stopped batch. |
| `references/doc-discovery.md` | Finding the workflow documents and extracting parameters — shared verbatim with `implement-use-case`. |

## What you get back

A series of merged use cases, each on its own branch with its own issue and pull
request, each with a green suite and green CI behind it — or an honest halt partway
with everything that landed still landed, the failing branch preserved for
inspection, and a report of exactly where it stopped and why.
