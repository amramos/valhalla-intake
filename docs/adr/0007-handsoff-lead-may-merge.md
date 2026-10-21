# ADR-0007: Under team-lead-handsoff, the lead may merge reviewed PRs to main

**Status:** Accepted
**Date:** 2026-10-21

## Context

`AGENTS.md` says agents never commit to `main`: every change lands through a pull request that the
owner merges. The owner chose to build the vertical slice with `team-lead-handsoff`
(`docs/plans/vertical-slice-ledger.md`, D17), so reviewed work reaches `main` without the owner in
the loop.

GitHub can't enforce CI on `main` here. Branch protection isn't available for a private repository
on the owner's current plan (D19). There is also no separate reviewer account, and the owner's own
account can't approve its own PRs (D20).

## Decision

Agents still never commit to `main` directly. The one exception is the lead running
`team-lead-handsoff`, which may **merge** a pull request into `main`, and only when every line of
its merge checklist is true and written into the PR as a comment:

- CI is green on the PR's latest commit. The lead checks this before every merge, because branch
  protection can't (D19).
- The reviewer's verdict, from Codex as another vendor's model, is posted on the PR as a comment and
  reads **approve**, with no unresolved blocking finding (D20).
- The exported build passes its smoke test on that branch.
- `main` is tagged `pre-merge/<feature-slug>-<yyyymmdd>` and pushed before the merge.

The merge is a merge commit (`gh pr merge <n> --merge --delete-branch`), so each feature can be
reverted as one unit. After each merge, the lead runs the full suite on `main`. If it's red, the
lead reverts through a PR and stops the stack.

## Alternatives considered

- **Keep the rule and use `team-lead`:** PRs wait for the owner. The owner declined this for the
  slice.
- **Make the repository public to get branch protection:** declined; the repository stays private.
- **A reviewer bot account (`REVIEWER_GH_TOKEN`):** declined for now. The review is a PR comment.

## Consequences

- Work reaches `main` without the owner. Every merge is tagged and revertable, and the checklist on
  each PR records why it was merged.
- Nothing in GitHub stops a merge that skips the checklist: the gate is the lead's discipline. The
  merge checklist is the only gate.
- `Closes` lines in merged PRs move issues to `Done`, as the owner delegated. Epics stay
  `In Review` until the owner plays the result.

**Revisit when:** branch protection becomes available (a paid plan, or a public repository), a
reviewer identity exists, or any hands-off merge needs a revert. Any of these means re-checking
whether this exception should stand.
