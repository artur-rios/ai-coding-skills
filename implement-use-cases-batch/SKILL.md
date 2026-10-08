---
name: implement-use-cases-batch
description: Use when the user asks to implement several use cases in one run — a range or list like "implement use cases from 01 to 11", "implement UC-01 through UC-05", "do all the use cases in milestone 2", "implement the whole backlog". Drives each use case through the same workflow and verifications as implement-use-case — load specs, design, branch from the integration branch (develop where the repository enforces that model), implement every flow, test until green, mark the README backlog and add an Unreleased CHANGELOG entry, open the pull request — but replaces the four human approval gates with automated verifications, then merges its own pull request, closes the issue, and starts the next use case. Authorizes the whole batch once up front, then runs unattended until it finishes or hits a stop condition. For a single use case with human review at each stage boundary, use implement-use-case instead.
---

# Implement Use Cases in Batch

## Overview

Implements a **series** of use cases end to end without stopping between them —
same workflow documents, same specification loading, same verifications as
`implement-use-case`, but the four human gates become automated checks and the
skill merges its own pull requests.

**Core principle:** autonomy replaces the *approval*, never the *verification*.
Every check `implement-use-case` performs still runs; what changes is who acts on
the result. A gate the human used to pass becomes a condition the batch must prove
before it may continue — and failing it stops the batch instead of prompting.

Two things make that safe enough to run unattended:

1. **One authorization up front.** The batch is agreed once — scope, order, what
   will be merged, what stops it — and then not re-litigated per use case. That is
   the point of the skill.
2. **Hard stop conditions.** Unattended means proceeding without asking when things
   go right. It never means pressing on when they go wrong. See
   [references/autonomy-protocol.md](references/autonomy-protocol.md).

## When to Use

**Precondition: the project has workflow and use case specification documents, and
the repository permits the agent to merge.** Both are verified in step 2 before any
authorization is requested.

- The user names a range or a set: "implement use cases from 01 to 11", "UC-03
  through UC-07", "everything in milestone 2", "the rest of the backlog".
- The user asks for the backlog to be worked through unattended.

Skip / adapt if:
- **One use case is named.** That is `implement-use-case`, which stops for review at
  each stage boundary. Do not use this skill to avoid those gates on a single unit
  of work.
- **The project has no workflow documents.** Stop and say so (step 1). An inferred
  process is a guessed process, and guessing at scale is worse than guessing once.
- **The user wants to review each pull request.** They are asking for
  `implement-use-case` run repeatedly, not for this.
- **Branch protection or a ruleset requires an approving review.** Say so and
  stop — see *Red Flags*. Self-approving to satisfy a protection the repo owner configured is
  not autonomy, it is circumvention.

## Gates Become Verifications

The four gates of `implement-use-case` are not removed. Each becomes a check whose
failure stops the batch:

| `implement-use-case` gate | Becomes | Batch stops when |
|---|---|---|
| **1** — design and plan approved | Self-check: every `AF-xx` mapped to a failure path, every cited `FR-<AREA>-xx` exists, the plan is sequenced test-first | A cited requirement does not exist, or a flow has no mapping |
| **2** — implementation complete | Checklist: main flow **and every** `AF-xx` implemented | Any flow is unimplemented or partially implemented |
| **3** — suite green | The project's full suite run in this session, unfiltered, output read | Tests still fail after the retry budget, or the run was filtered |
| **4** — human merged | Required checks green on the pull request — the Branch Policy check included — then the batch merges it into the integration branch | CI fails, the merge conflicts, or the merge is refused |

**A verification that cannot be performed counts as failed.** No test command in the
documents is a stop, not a licence to skip testing.

## Red Flags — STOP and Re-read the Procedure

- "The user said no human intervention, so I shouldn't stop for anything" → NO.
  They removed the *approval* gates, not the *failure* stops. A batch that merges
  broken work is worse than one that halts at use case 4 of 11.
- "One test is flaky, I'll rerun until it passes and move on" → NO. Re-running to
  confirm a genuine flake is fine; re-running until green is how a real failure
  gets merged. After the retry budget, stop.
- "CI is red but the failure looks unrelated" → NO. Unrelated failures are still
  failures, and you are about to merge into the branch everyone builds on.
- "Branch protection wants one approval — I'll approve my own pull request" → NO.
  Stop and report. The user configured that rule; only they may relax it.
- "`gh pr merge --admin` gets past this" → NO. Bypassing protections is never what
  "unattended" authorized.
- "This test is blocking the batch, I'll skip it for now" → NO. Disabling a test to
  make the suite green is falsifying the verification the whole batch rests on.
- "UC-07's spec is ambiguous, I'll pick the reading that lets me continue" → NO.
  Ambiguity is a stop. At scale, a wrong reading gets built eleven times.
- "I'll implement all eleven, then open one pull request" → NO. One use case, one
  branch, one issue, one pull request. That invariant is what makes the batch
  reviewable afterwards.
- "The base branch moved, I'll force-push my branch onto it" → NO. Never rewrite
  published history. Rebase or merge cleanly, or stop on the conflict.
- "The workflow doc says `main`, so the batch merges into `main`" → NO, not when
  the repository enforces a `develop` flow. `main` takes only `release/*` pull
  requests. Merge into `develop`, and name the stale document in the authorization
  request.
- "The batch is done, I'll cut the release too" → NO. Releasing — `release/*`,
  the pull request into `main`, the tag — is the owner's step per `CONTRIBUTING.md`.
  Authorization to merge use cases is not authorization to release.
- "There's no classic branch protection, so no review is required" → Check the
  rulesets too. A ruleset's `pull_request` rule can require a review that branch
  protection does not show.

| Rationalization | Reality |
|---|---|
| "Stopping mid-batch wastes the run" | The merged use cases stay merged. A batch that stops at 4 of 11 delivered 4; one that pushes through delivered a mess to unpick. |
| "The user isn't watching, so a small shortcut is invisible" | It is visible in the merge commit, forever, and they authorized the batch on the assumption you took none. |
| "Re-reading the specs for every use case is wasteful" | It is the reason use case 9 does not inherit use case 2's misreading. Load them fresh, every time. |
| "I already know this project's workflow from use case 1" | The parameters are read once per batch, in step 2. Working from memory of *another project's* workflow is the failure this prevents. |
| "Verification between use cases is redundant, nothing changed" | The base branch changed — you just merged into it. Confirm it is clean and green before branching again. |
| "The CHANGELOG entries can be written once, at the end" | Each pull request records its own change. An entry written later is one a stopped batch never writes. |

## Procedure

Create a todo per step, and a todo per use case in the batch.

### 1. Resolve the batch and validate the documents

Parse what the user asked for into a concrete, ordered list of use case
identifiers, per [references/batch-control.md](references/batch-control.md) §1.
A range is inclusive: "from 01 to 11" means `UC-01` … `UC-11`.

Then locate the project's workflow and specification documents exactly as
`implement-use-case` does — follow
[references/doc-discovery.md](references/doc-discovery.md).

**Stop here if:** there is no workflow document, no use case specification, or the
two workflow documents contradict each other. Report it; do not infer a process.

Resolve every requested identifier against the Use Case Specification. Identifiers
that do not exist are reported **now**, before authorization — not discovered at
use case 8.

### 2. Extract the parameters and verify the batch can run unattended

Pull the branch pattern, base branch, status lifecycle, issue tracker, test
commands, and Definition of Done per `doc-discovery.md` §4. Check whether the
repository enforces a branching model (`doc-discovery.md` §3) — where it does, it
sets the base branch (usually `develop`) and the accepted prefixes, and a document
that still says `main` is stale: note it for the authorization request. Note whether
the README tracks issues and whether `CHANGELOG.md` has a `## [Unreleased]`
section. These are read **once** for the batch.

Then verify the automation preconditions, per `autonomy-protocol.md` §1:

- `gh auth status` — authenticated, with permission to merge and close.
- The working tree is clean and the base branch is up to date.
- The repository's merge settings, classic branch protection, **and rulesets** on
  the base branch allow a merge without a human approval
  (`gh api repos/{owner}/{repo}/rules/branches/develop`). **If an approving review
  is required, stop and report it.** Note the merge methods the ruleset allows and
  its required checks.
- A test command exists in the documents.
- CI: note whether the repository runs checks on pull requests. If it does, the
  batch waits for them; if it does not, the local suite is the only evidence — say
  so in the authorization request.

**Any precondition that fails ends the run here**, before anything is created.

### 3. Authorize the batch — the one and only stop for approval

Present, and wait for an explicit yes:

- The resolved use cases, in execution order, and any requested id that does not exist.
- The branch, issue, and pull request that each will produce.
- **That the batch will merge its own pull requests, close the issues, and delete
  the branches**, and into which base branch — `develop` on the `develop` flow,
  never `main`.
- That each pull request carries its own README backlog update and `## [Unreleased]`
  CHANGELOG entry — or that the repository keeps neither.
- Any workflow document found stale against the enforced branching model.
- Whether CI will gate the merges, or only the local suite.
- The stop conditions, and what happens to already-merged work when one fires.

> "11 use cases, UC-01 through UC-11, in specification order. Each gets its own
> branch, issue and pull request, cut from `develop`; I'll merge each into
> `develop` and close its issue before starting the next. Each pull request marks
> its row in the README backlog and adds its entry under `## [Unreleased]` in
> CHANGELOG.md. CI runs on pull requests — the tests and the Branch Policy check —
> and must be green to merge. Releasing to `main` stays yours.
> I stop the batch on a failing suite after 3 fix attempts, red CI, a merge
> conflict, an ambiguous spec, or a dangling requirement — already-merged use cases
> stay merged. Go ahead?"

**Silence, "sure whatever", or an unrelated reply is not authorization.** Neither
is a general instruction to work autonomously given before the scope was known.

### 4. Run the loop — one use case at a time

For each identifier in order, execute the full per-use-case cycle in
[references/batch-control.md](references/batch-control.md) §2:

1. **Load** this use case's specifications fresh from disk — never from memory of
   the previous one.
2. **Design and plan**, grounded in the repository's patterns. Run the Gate 1
   verification.
3. **Branch** from an up-to-date base branch (`develop` on the `develop` flow);
   move the issue to the "work started" status.
4. **Implement** the main flow and every alternative flow.
5. **Verify** Gate 2: every flow implemented.
6. **Test** until green, within the retry budget, running the project's full suite.
7. **Verify** Gate 3: real output, unfiltered, read in this session.
8. **Record the use case** — mark the README backlog row if the README carries a
   backlog ([readme-tracking.md](references/readme-tracking.md)), and add the
   `## [Unreleased]` CHANGELOG entry if `CHANGELOG.md` exists
   ([changelog-entry.md](references/changelog-entry.md)) — then open the pull
   request into the base branch.
9. **Wait for CI**, then merge with a method the base branch allows, delete the
   branch, and close the issue.
10. **Verify** the Definition of Done from the project's own document. Its
    human-review and human-merge items are met by the batch authorization and the
    green, merged pull request — report them that way, never as a review that
    happened; every other item must hold ([batch-control.md](references/batch-control.md) §2j).
11. **Sync** the base branch and confirm the tree is clean before the next use case.

A stop condition at any sub-step ends the **batch**, not just the use case. Go to
step 6.

### 5. Report progress as you go

After each use case, emit one line: the identifier, the pull request number, the
merge result, and the test counts. The user is not approving anything — they are
watching a log. Make it a log worth reading.

### 6. Report the batch

Whether it finished or stopped:

- Use cases **merged**, with pull request numbers and issue numbers.
- Use case **in flight** when a stop fired, what failed, and where the branch was
  left. Do not delete it — it is the evidence.
- Use cases **not started**.
- The Definition of Done result for every merged use case, with the human-review
  items marked as merged under the batch authorization.
- Any workflow document found stale against the enforced branching model, and
  whether the repository lacked a `CHANGELOG.md`.
- Everything deferred, assumed, or discovered that the user should know.

**Never roll back merged work to "clean up" a stopped batch.** Reverting merges is
a decision for the user, on the evidence you just gave them.

## Quick Reference

| Decision | Rule |
|---|---|
| Scope | A range or list of use cases. One use case → `implement-use-case`. |
| Approvals | Exactly one, in step 3, for the whole batch. |
| Order | The specification's own order, unless the documents state dependencies. |
| Unit of work | One use case = one branch = one issue = one pull request. Always. |
| Merging | The batch merges into the integration branch (`develop` on the `develop` flow), after green CI, with a method the ruleset allows. Never with `--admin`, never past a required review, never into `main`. |
| Recording | Each pull request carries its README backlog row and its `## [Unreleased]` CHANGELOG entry. |
| Releasing | Not the batch's. `release/*`, the pull request into `main`, and the tag are the owner's. |
| A failure | Stops the batch. Merged work stays merged; the failing branch stays pushed. |
| Specs | Re-read per use case, from disk. |
| Parameters | Read once per batch, in step 2. |

| Stop condition | Fires when |
|---|---|
| Failing suite | Tests still red after the retry budget (default 3 fix attempts) |
| Red CI | Any required check fails on the pull request |
| Merge conflict | The branch will not merge cleanly into the base |
| Dangling reference | A use case cites an `FR-<AREA>-xx` that does not exist |
| Ambiguous spec | A flow admits more than one reasonable implementation |
| Protection | Branch protection or a ruleset requires an approving review |
| Dirty tree | The working tree is not clean between use cases |

**Never:** force-push, `gh pr merge --admin`, self-approve, disable or filter a
failing test, merge on red CI, rewrite published history, open or merge a pull
request into `main`, or continue past a stop.

## Common Mistakes

- **Treating "no human intervention" as "no stopping".** The approvals are gone;
  the failure stops are the reason removing them is safe.
- **Merging on red or unread CI.** Waiting for checks is not optional just because
  nobody is watching.
- **Self-approving to satisfy branch protection**, or reaching for `--admin`. Both
  defeat a rule the user set deliberately.
- **Retrying a failing suite indefinitely.** Confirm a flake, then stop. Green after
  eleven reruns is not green.
- **Skipping, filtering, or disabling a test to unblock the batch.** That falsifies
  the verification everything else rests on.
- **Batching several use cases into one branch or pull request** to save round
  trips. The invariant is what makes the run auditable afterwards.
- **Carrying one use case's specification into the next.** Load them fresh; that is
  how a misreading stays contained.
- **Rolling back merged use cases because a later one failed.** Report and let the
  user decide.
- **Asking for approval per use case anyway.** That is `implement-use-case`. If the
  user wanted those gates they would have named one use case.
- **Merging into `main`** because a stale workflow document said so. In a
  repository on the `develop` flow, `main` takes only release pull requests.
- **Checking only classic branch protection.** Rulesets carry their own review and
  status-check rules; read them before claiming the batch can merge unattended.
- **Skipping the CHANGELOG entry** because nobody is reviewing. The changelog is
  how the owner writes the release; a batch that skips it leaves eleven gaps.
- **Starting the batch before resolving the identifiers.** A range that includes a
  use case which does not exist should be caught in step 1, not at use case 8.
