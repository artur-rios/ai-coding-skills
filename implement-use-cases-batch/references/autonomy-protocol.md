# Autonomy Protocol

`implement-use-case` hands work back at four gates. This batch does not — it proves
the same things and continues on its own. This file defines what "unattended" is
allowed to mean.

The trade is precise: **the human approval is removed, the verification is not.**
Anything that was checked before is still checked; only the consequence changes.
Where a human used to say go, the batch must produce evidence — and where the
evidence does not come, it stops.

---

## 1. Preconditions — verified before authorization is even requested

If any of these fails, the run ends in step 2 and nothing is created.

| Precondition | Check | Why it blocks |
| --- | --- | --- |
| Authenticated tooling | `gh auth status` | Merging and closing need it; discovering that at use case 1 wastes the setup |
| Merge permission | `gh repo view --json viewerPermission` | Without write access the batch cannot do the thing it was authorized to do |
| No required review | Classic branch protection **and** rulesets on the base branch: `gh api repos/{owner}/{repo}/rulesets`, `gh api repos/{owner}/{repo}/rules/branches/<base>` — the `pull_request` rule's `required_approving_review_count` must be 0 | A required approving review means a human is in the loop by policy — respect it, do not route around it |
| An allowed merge method | The `pull_request` rule's `allowed_merge_methods` (`merge`, `squash` on `develop`) and the repository's merge settings | Merging with a method the ruleset refuses fails at use case 1 |
| The right base branch | The enforced branching model — `CONTRIBUTING.md`, `.github/workflows/branch-policy.yml`, a `develop` branch (see `doc-discovery.md` §3) | Use case work merges into the integration branch; `main` takes only release pull requests, and the Branch Policy check rejects anything else |
| Clean tree | `git status --porcelain` is empty | Uncommitted work would be swept into the first branch |
| Base up to date | `git fetch && git status -sb` | Branching from a stale base produces avoidable conflicts |
| A test command | From the Testing Specification | Gate 3 cannot be verified without one, and an unverifiable gate is a failed gate |

Note whether CI runs on pull requests, and which checks the ruleset requires —
on the `develop` flow, the Branch Policy check is one of them. If CI runs, it gates
every merge. If it does not, the local suite is the *only* evidence — say so explicitly when asking for
authorization, because it materially changes what the user is agreeing to.

## 2. The authorization

One approval, for the whole batch, with the scope known. It must state plainly that
the batch **merges its own pull requests, closes the issues, and deletes the
branches**.

What does **not** count as authorization:

- Silence, or a reply that does not address the request.
- "Do whatever you think is best", given before the resolved scope was shown.
- A general "work autonomously" instruction from earlier in the session.
- Authorization for a *previous* batch. Each run is authorized on its own scope.

Authorization covers the use cases named and the actions listed. It does not extend
to a use case discovered later, a different base branch, a release — cutting
`release/*`, merging into `main`, tagging — or a repository the user did not name.

## 3. Stop conditions

Each of these ends the **batch**. Not the current use case — the batch. The
distinction matters: a failure at use case 4 usually means use cases 5 through 11
would fail the same way, and eight broken merges is a much worse outcome than one
honest halt.

| Stop | Detect | Why not just continue |
| --- | --- | --- |
| Failing suite | Still red after the retry budget | The next use case builds on this code |
| Red CI | Any required check red on the pull request | Merging red is how a broken base branch reaches everyone |
| Merge conflict | The pull request will not merge cleanly | Resolving conflicts unattended means guessing at intent |
| Dangling requirement | A use case cites an `FR-<AREA>-xx` the System Requirements Document does not define | Guessing which requirement was meant builds the wrong thing correctly |
| Missing specification | The use case has no entry in the specification | There is nothing to implement, only a name |
| Ambiguous flow | A flow admits more than one reasonable implementation | At batch scale a wrong reading is repeated, not caught |
| Branch protection | A required approving review, or a rule the merge would violate — classic protection or a ruleset | The rule exists because someone wanted a human here |
| Dirty tree between use cases | `git status --porcelain` not empty after a merge | Something was left behind; find out what before compounding it |

### The retry budget

A failing suite gets **three** fix attempts by default: fix, re-run, read. That is
enough to clear a genuine mistake and not enough to mask a real defect.

Re-running an *unchanged* suite is only legitimate to confirm a suspected flake, and
only once. If a test passes on the second identical run, say so in the report — a
flake the user does not know about is a defect you hid.

## 4. Actions that stay forbidden

Authorization to merge is not authorization for these. None of them is ever implied
by "no human intervention":

- **Force-pushing**, or rewriting any published history.
- **`gh pr merge --admin`**, or any flag whose purpose is to bypass a protection.
- **Approving your own pull request** to satisfy a required-review rule.
- **Disabling, skipping, filtering, or deleting a test** to make a suite green.
- **Merging with red or unread CI.**
- **Opening or merging a pull request into `main`**, cutting a `release/*` branch,
  or pushing a tag. Releasing is the repository owner's step.
- **Editing branch protection, repository settings, or CI configuration** to make
  the batch's path easier.
- **Reverting or force-updating already-merged work** to tidy up after a stop.
- **Continuing past a stop condition**, in any form, including "just this one".

Each of these converts a verification into a formality. The batch's whole claim to
being safe unattended is that its checks are real.

## 5. When a stop fires

1. **Stop immediately.** Do not start the next use case.
2. **Leave the evidence.** The branch stays pushed, the pull request stays open, the
   issue stays in its current status. Do not clean up.
3. **Do not touch merged work.** Use cases that merged are done. Reverting them is
   the user's decision, made on your report.
4. **Report** per SKILL.md step 6: what merged, what was in flight and how it
   failed, what never started.

A stopped batch is a successful outcome for the use cases that landed. Report it as
progress with a halt, not as a failure of the whole run.
