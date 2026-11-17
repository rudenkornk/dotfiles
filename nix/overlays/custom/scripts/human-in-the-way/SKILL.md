---
name: human-in-the-way
description: >-
  Run architecture, step-design, implementation, and final-documentation reviews with explicit user approval gates.
  Use only when the user explicitly invokes human-in-the-way; never activate implicitly for ordinary implementation tasks.
disable-model-invocation: true
---

# Human in the Way

Apply this workflow only to the root agent, not subagents.
Keep it active for the current task until completion or explicit cancellation.
The root agent owns every user-facing review gate; do not ask subagents to run this workflow themselves.
Respect the host agent's permissions and repository rules, except for the partial-commit exception below.

The optional [workflow diagram](references/workflow.md) illustrates the review cycle for the user.
The instructions here are sufficient; reading the diagram is not required.

## Approval Gates

Approval must be explicit and apply to the presented version and current gate.
Approval of architecture does not approve a step plan; approval of a step plan does not approve its implementation.
Silence, a question, requested revisions, or a general instruction to continue is not approval.
Do not require a particular literal approval word when the user's intent is unambiguous.

At every review gate, end the turn after presenting the material.
**STOP HERE. Do not proceed until the user has explicitly APPROVED the presented version.**
If the user requests revisions, revise the material and stop for review again.
Never treat requested changes as approval of the revised result.

## 1. High-Level Design

Perform a /deep-research of the existing implementation and think through the whole implementation and architecture.
Resolve relevant requirements, compatibility, failure handling, dependencies, and validation decisions with the user.
Determine a best-effort logical commit sequence, separating structural refactoring, supporting functionality,
feature implementation, and integration where those stages have useful work.
The sequence may be amended as understanding improves.

Present the architecture, responsibilities, interactions, API boundaries, and intended commit sequence for review.
Proactively use diagrams, type-hinted Python API sketches, and implementation pseudocode outlines.
Python is for readability; it need not match the project's implementation language.
Pseudocode outlines should sketch major operations, control flow, and boundaries, not complete implementations.
Start with ASCII diagrams; use Mermaid or Typst only when greater complexity warrants them.
Architectural prose may be substantial where useful, but favor diagrams, API boundaries, and implementation outlines.

**STOP HERE. Do not proceed until the user has explicitly APPROVED the presented design.**
Repeat the design review until approved.

Record the approved version in the project in a separate, movable documentation commit before implementing steps.
Keep this commit isolated from production changes so it can be amended or relocated later.
If repository writes are not permitted, wait until they are permitted before recording it or implementing steps.

## 2. Step-Design Review

Begin with a small `Step X/N` header.
N may be approximate; briefly explain changes to the estimate between steps.
Design the next cohesive, independently reviewable change within the approved architecture.
A step may cover part of a commit, one commit, or several commits, such as independent mechanical refactors.
State the intended commit boundaries and relevant validation checks.

Limit each step to 500 lines of meaningful production-code changes across the whole step, not per commit.
Exclude lines belonging to tests, documentation, data, lockfiles, configuration, and other support files from this count.
Those files and activities remain part of the step and must be planned, implemented, and reviewed where relevant.
Also 500LOC rule do not apply to **separated** steps only containing unchanged moved code and formatting-only changes.
Do not use net line growth to hide a large change or classify production logic as support material to bypass the limit.
If implementation would exceed the budget, stop and obtain approval for a revised split before continuing.

Keep the plan focused: aim for no more than 2 A4 pages.
Lead with diagrams, Python-style API sketches, and implementation pseudocode outlines; keep text notes minimal.
Do not present full implementations, even as pseudocode.

**STOP HERE. Do not proceed until the user has explicitly APPROVED the presented step plan.**
Repeat the step-design review until approved.

## 3. Implementation Review

Implement only the approved step and run its agreed validation checks.
Embed concise documentation only for critical context that cannot be inferred from the code,
including interaction diagrams where useful.
Do not copy step plans into obvious comments or docstrings.

Commit at the planned boundaries and keep each commit focused and usable.
When a step covers only part of a planned commit, leave it uncommitted for review of the working diff.
This is an explicit exception to standing instructions to commit completed work immediately.
Preserve unrelated user changes and make the step's review scope clear.
Incorporate corrections into the relevant task commits rather than accumulating fixup commits.

Present the implementation changes, validation results, and commits or uncommitted review diff.
**STOP HERE. Do not proceed until the user has explicitly APPROVED the presented implementation.**
Apply requested corrections, rerun affected checks, and present the revised implementation for approval again.
Do not begin the next step until this implementation is approved.

If the approved architecture must change, pause implementation and reopen architecture review.
Present the focused architecture change and its effect on the step and commit sequence.
**STOP HERE. Do not proceed until the user has explicitly APPROVED the architecture change.**
Update the isolated design-document commit after approval and obtain approval for any revised step plan before implementing it.

After implementation approval, return to step-design review if more steps remain.
Otherwise, proceed to final documentation review.

## 4. Final Documentation Review

When all steps are finished, prepare the final version of the initial design document to reflect the implemented result.
Present that version and propose its destination: a separate file, an addition to an existing file, or another suitable layout.
Propose which temporary review material should be removed and how documentation commits should be consolidated.
Ask whether to amend the initial documentation commit in place or relocate it to the history tip.

**STOP HERE. Do not integrate the documentation until the user has explicitly APPROVED its content and placement.**
Repeat the documentation review until approved and resolve the documentation-commit placement before rewriting history.

Integrate the approved documentation and refactor documentation commits as requested.
Preserve unrelated work and obey repository history-rewrite restrictions.
Review the final diff and commit sequence, rerun affected validation, and report the result.
