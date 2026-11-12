Maintain dependency-update PRs across my public GitHub projects.

## Inventory and initial review

- Identify my authenticated GitHub account.
- Find owned repositories, excluding private, archived, and forked repositories.
  Paginate API requests.
- Find all open Dependabot PRs.
- Inspect CI results and failed-job logs.
  Distinguish build failures, test failures, infrastructure problems, and cancelled jobs.
- Present an initial review table with:
  repository, PR link, update, CI status, failure reason if applicable, and merge blockers.
  Distinguish passing, failed, pending, cancelled, missing, and neutral checks.
- Wait for my approval before merging any PR.
  Do not assume all passing PRs are approved.

## Approved passing PRs

- Merge only PRs I explicitly approve, using rebase merge only.
- Immediately before merging, verify the PR is still open and its current head has passing required checks.
  Missing, pending, or cancelled required checks are not success.
- Match the expected head commit when merging.
  Never bypass branch protection or use administrator overrides.
- Recheck remaining PRs after merges.
  Earlier passing results do not guarantee compatibility with newly merged updates.

## Investigate remaining PRs

- Work in `~/projects/<repository>`.
  If absent, clone using SSH.
- Read repository instructions and inspect Git status before switching branches.
  Preserve existing changes, untracked files, and local-only commits.
  If switching would endanger existing work, pause and ask.
- Check out the Dependabot branch for each PR requiring investigation.
- Investigate actual failure causes before proposing changes.
  Inspect dependency changes, tool versions, upstream source, and macro expansions where relevant.
- Search upstream issues and fixes.
  Distinguish merged fixes from fixes actually available in the pinned dependencies.
- Propose the smallest reasonable compatibility fix that preserves intended behavior.
  Follow decision-review requirements before resolving behavioral or design choices.
- Do not blindly apply linter suggestions, weaken checks, or introduce workarounds solely to make CI green.
  For upstream regressions, offer skipping the update when appropriate.

## Fix history and validation

- Put compatibility fixes before the dependency update:
  `existing base → compatibility fix → dependency update`.
- Validate the fix with the original dependencies, then replay the update and validate again.
  Each commit should represent a correct, usable state.
- Preserve the dependency-update patch unless an approved change requires otherwise.
- Run repository-required checks and focused checks for the changed behavior.
  Continue beyond the first repaired diagnostic to uncover further failures.
- Fold corrections into the relevant fix commit and replay the update.
  Do not leave temporary fixup commits.
- Record HEAD before the first rewrite in each repository.
  Preserve unrelated work throughout history changes.

## Review repaired PRs

- Present another review table after investigation and local fixes.
  Include repository, PR link, original failure, fix or recommendation,
  validation results, remaining blockers, and push status.
- Wait for my review and explicit merge approval.
  Do not interpret approval of a fix as approval to merge.
- Keep rewritten branches local until pushing is explicitly approved.
  If approval to merge requires publishing local fixes, confirm push authorization when unclear.
- Once approved, push using an explicit `--force-with-lease` against the verified remote head.
  If the lease fails, investigate and ask rather than overwriting remote changes.
- Wait for CI on the pushed head before merging.
  GitHub may take time to register checks after a push; missing checks are not success.
- Rebase-merge approved PRs only after all required checks pass.
  Return new failures or materially changed fixes for review.
- Repeat investigation and review until every PR has an agreed disposition.
- Skipping means leaving the PR open and unmerged.
  Do not close it or configure Dependabot ignores without explicit approval.

## Final report

- After processing all approved merges, present a final table covering every discovered PR.
  Include repository, PR link, update, final outcome, and any fix or reason for skipping.
- Clearly distinguish merged, skipped, blocked, and awaiting-approval PRs.
- Report remaining local commits, unpushed branches, and incomplete validation.
- Link relevant upstream issues for skipped updates.
- If history was rewritten, include each repository's original HEAD,
  labelled “HEAD before the first rewrite”.
