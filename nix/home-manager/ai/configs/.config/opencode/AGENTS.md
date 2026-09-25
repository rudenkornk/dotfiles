# Scope

These are global rules.
Follow them for all code, unless specific rules were overridden with project-local rules.

# Math Formatting

In responses intended for the OpenCode terminal UI, write equations in readable Unicode or plain text rather than LaTeX math
delimiters (`$...$`, `$$...$$`, `\\(...\\)`, or `\\[...\\]`). Use ASCII when a Unicode expression would be unclear.
When the user requests LaTeX source, or when editing a LaTeX file, preserve the requested syntax.

# Implementation Scope and Complexity

Prefer the most straightforward implementation for the current task.
Small behavioral compromises are acceptable when avoiding them requires substantially more complexity.
Optimize for readable code and fewer responsibilities to maintain.

## Start with the simplest viable approach

- For existing code, first consider changing configuration, adding a parameter, or using an existing extension point.
- For new code, start with a direct implementation for the current inputs and callers.

## Weigh behavior against implementation cost

A small compromise affects convenience or optional coverage while preserving the main workflow.
Examples include retaining an existing upstream limitation or supporting explicitly named variants
instead of every possible configuration.

Prefer such compromises when the alternative requires substantial special-case code, adapters, or state management.
If unsure whether a compromise is acceptable, present explained choices.

## Let simple utilities fail naturally

For internal utilities and configuration glue, exceptions or panics are acceptable when an operation cannot succeed.
Use the caller's established preconditions and the underlying API's error behavior.

# Implementation Planning and Commit History

Clear, straightforward Git history is a primary deliverable, alongside clear code.
Apply this workflow proactively, without waiting for the user to request decomposition or commits.
The simplicity rules above apply to every stage.

## Plan the commit sequence first

Before presenting a nontrivial implementation plan or editing code, inspect the existing implementation
and consider the following stages in order.
The initial plan must identify the applicable stages and intended commit boundaries.

1. Structural refactoring.

   Move, rename, or reorganize existing code without changing functionality or behavior.
   Put necessary formatting and indentation changes here.
   Keep this mechanical and easy to verify for equivalence.

   Commit this separately before introducing supporting functionality or the feature.
   Purely mechanical changes are not limited by size.

1. Supporting functionality.

   Add or adapt the small helpers, parameters, or extension points needed by the feature.
   Adopt them in existing code where appropriate before introducing the feature itself.
   Add tests, logging, or other supporting work only where independently justified.

   Keep this separate from structural cleanup and actual feature behavior.
   This stage may contain several commits, each coherent and independently verifiable.

1. Feature implementation.

   Implement the requested behavior on top of the prepared structure.
   Prefer a small, focused commit with mostly additions.
   Roughly 250 added lines is a useful signal to consider further decomposition, not a hard limit.

   For larger features, implement a straightforward base first.
   Add further capabilities in separate commits.

1. Integration.

   Apply or enable the feature in existing callers and configurations.
   Keep this separate from implementing the feature when there is a meaningful integration step.

Each applicable stage must form a separate commit or coherent sequence of commits.
Skip stages that have no useful work.
Do not invent abstractions, introduce unnecessary helpers, or split a trivial change merely to fill these stages.

## Apply the decomposition recursively

Whenever a stage itself mixes preparation, implementation, and integration, apply the same sequence within it.
Supporting functionality at one level may be a feature requiring its own preparation at the next level.

Revisit the decomposition when implementation reveals a missed dependency or an incorrect earlier decision.
Do not wait until the end of the task or until the user asks to organize the history.

## Commit completed work

This is a standing explicit request to create commits for completed implementation work,
unless the user requests otherwise or the active mode forbids modifications.

Create commits at the planned boundaries.
Keep intermediate commits usable and each patch focused on one responsibility.
Stage only changes belonging to the task and follow the commit-message rules below.

Run checks appropriate to each stage.
Complete repository-specific validation before finishing the series.

## Maintain a coherent history

This is standing explicit authorization to rewrite commits created during the current session
for the current task whenever doing so produces a clearer, more coherent history.

Before each history-rewriting operation, create a uniquely named backup branch
pointing to the branch tip before the rewrite.
Report its name and preserve it until the user requests its removal.
Preserve any uncommitted work as well.

When implementation reveals a missed change or an incorrect earlier decision,
incorporate the correction into the appropriate commit and replay subsequent eligible commits.
Amend, reorder, split, or squash eligible commits as needed.
Prefer correcting the relevant commit over appending cleanup or fixup commits.

Do not rewrite commits that predate the current session or belong to another task.
Review the resulting commit sequence and final diff, and rerun affected checks after rewriting.

Pushing, including force-pushing rewritten history, requires an explicit user request.

# Comment & Markdown Style Guidelines

These rules apply to comments in all source files (Python, Lua, Nix, shell, etc.) as well as to prose text in
Markdown files.

## Rule 1: Comment only what the code cannot say

Preferably do not comment new code at all.
Add a comment only in the exceptional case where it is not obvious from the code why something is built the way it is.
Never document external tools: whoever wonders what a tool does will look it up
and get a better answer than any paraphrase kept in this repo.

Prefer comments that are short, inlined and precise.
Multiline comments placed above the code are acceptable,
but only when they describe actual specifics of this project and its unobvious quirks.

**Bad** — explains `nix-direnv` itself, which is what its own documentation is for:

```diff
+    # Caches `nix develop` environments in `.direnv` and keeps them alive with GC roots,
+    # so entering a project directory does not re-evaluate the flake.
+    nix-direnv.enable = true;
```

**Good:**

```diff
+    nix-direnv.enable = true;
```

**Bad** — an obscure change with no comment at all, which leaves room for an accidental revert
and for re-discovering the problem it fixes:

```diff
-        Linter(["statix", "check", repo_path]),
+        Linter(["statix", "check"]),
```

**Bad** — better, but too wordy, and it breaks up the structure of the surrounding code:

```diff
-        Linter(["statix", "check", repo_path]),
+        # `statix` drops its `.gitignore` filtering when given an absolute path,
+        # so it is left with its default target, the current directory.
+        Linter(["statix", "check"]),
```

**Good:**

```diff
-        Linter(["statix", "check", repo_path]),
+        Linter(["statix", "check"]),  # NOTE: `statix` respects `.gitignore` only with no or relative path.
```

## Rule 2: Comments are prose

Comments and Markdown prose should be treated as continuous text formatted as paragraphs, with proper punctuation
and capitalization. Even a single-sentence comment must start with a capital letter and end with punctuation
(`.`, `!`, or `?`).

**Exceptions:**

- If the comment starts with a backtick-quoted code reference, the capitalization follows the identifier's own casing.
- If the last word of a comment is a URL, do not append a trailing dot — URL pickers may misparse it.
  Start a new line for the next sentence instead.

**Good:**

```lua
-- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
-- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
lazy = true,
version = false, -- Always use the latest git commit.
```

```lua
enabled = true,
-- `bullet = true` and `right_pad = 2` makes line same width rendered and unrendered.
bullet = true,
right_pad = 2,
```

```lua
clangd = {
  -- See https://www.lazyvim.org/extras/lang/clangd
  cmd = {
```

**Bad:**

```lua
-- Do not add "v" mode: it might conflict with other keymaps   ← missing dot
mode = { "i", "n", "t" },
```

```lua
{ "folke/tokyonight.nvim", opts = { style = "night" } }, -- moon, storm, night, day   ← not a sentence
```

## Rule 3: Line length ≤ 120 characters

No comment line may exceed 120 characters. When a sentence does not fit, split it at a meaningful boundary —
after a comma, or before a conjunction such as "and", "or", "which". A sentence that fits within 120 chars
may still be split across lines.

**Good:**

```lua
-- `LazyVim` defaults for `<leader><space>` find files and `<leader>/` live grep open in a "root" directory.
```

```lua
-- `LazyVim` defaults for `<leader><space>` find files and
-- `<leader>/` live grep open in a "root" directory.
```

```lua
-- For example, in cases with nested projects inside one repo,
-- `lsp` detector correctly recognizes root of each sub-project, whereas I need a root of entire project.
```

**Bad:**

```lua
-- For example, in cases with nested projects inside one repo, `lsp` detector correctly recognizes root of each sub-project, whereas I need a root of entire project.
```

```lua
-- For example, in cases with nested projects inside one repo, `lsp` detector correctly recognizes root of each
-- sub-project, whereas I need a root of entire project.   ← split at a bad boundary
```

## Rule 4: One sentence per line (generally)

Different sentences should generally each start on their own line. Two short sentences may share a line if together
they fit within 120 characters. A sentence must never be split across a line boundary with another sentence mixed in.

**Good:**

```lua
-- `LazyVim` defaults for `<leader><space>` find files and `<leader>/` live grep open in a "root" directory.
-- This `root` directory has a rather complicated algorithm,
-- which defaults to `{ "lsp", { ".git", "lua" }, "cwd" }` and does not work for me well.
-- For example, in cases with nested projects inside one repo,
-- `lsp` detector correctly recognizes root of each sub-project, whereas I need a root of entire project.
```

```lua
-- Setup is very cumbersome. At the end the problem was in a very slow performance.
```

**Bad:**

```lua
-- `LazyVim` defaults for `<leader><space>` find files and
-- `<leader>/` live grep open in a "root" directory. This `root` directory has a rather complicated algorithm,
-- which defaults to `{ "lsp", { ".git", "lua" }, "cwd" }` and does not work for me well. For example,
-- in cases with nested projects inside one repo, `lsp` detector correctly recognizes root of each sub-project,
-- whereas I need a root of entire project.
```

# Commit Message Style

No line in a commit message, including the title and body, may exceed 120 characters.

All Comment & Markdown Style Guidelines above also apply to commit message bodies,
including prose, capitalization, punctuation, and sentence wrapping.
Those style rules do not apply to titles, which follow the `type(scope): summary` format.

Commit messages must be short.
In ~95% of cases the message is only the title (`type(scope): summary`, as in the existing history) — no body at all.

A small body is allowed only for notes about git ordering and implementation plans rather than about the code itself —
e.g. "Preparation for the upcoming change...", or how this commit relates to neighboring patches in a series.
All information related to the code itself MUST live in the code (comments, docs), not in the commit message.

## Exception: commits that delete code

When a commit removes code — especially a workaround that is no longer needed — the rule above inverts.
Deleted code has nowhere to live, so leaving behind a ghost comment describing what used to be there
and why it went away just trades one piece of dead weight for another.
Delete the code cleanly and put the explanation in the commit body instead, where `git log` and `git blame` will surface it
for whoever wonders why the workaround disappeared.
