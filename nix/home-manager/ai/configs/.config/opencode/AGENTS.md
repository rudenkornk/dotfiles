# Scope

These are global rules.
Follow them for all code, unless specific rules were overridden with project-local rules.

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

## When new code/infrastructure is required or recommended

If decided to go with a complex solution, then **design a plan** and split it into these major steps:

1. Refactoring existing **code structure** (if needed).\
   This step never changes functionality or behavior. Usually includes code motion, formatting, renaming.
   This is something which is very easy to prove equivalence with a previous version.

   This steps typically deserve its one single separate commit and is not limited by size.

1. Refactoring existing **code functionality**. Adding new glue/infrastructure code.\
   Not yet a meaningful part of an actual feature. Examples include:

   - Add new glue/infrastructure/helpers.
   - Use new glue/infrastructure/helpers in existing code replacing old inline implementation.
   - Support new simple cases in existing code.
   - Make existing code more defensive.
   - Add the tests for an untested area vulnerable to dev mistakes.
   - Add more logging / instrumentation where it was needed.

   This step NEVER includes changes related to changed code indent, changed formatting, style, etc.
   All of that should have happened on the previous step.

   This steps may consist of any number of commits. Each of those should be readable and easy to verify on its own.

1. Implementing an actual feature.\
   This bullet typically deserve only one single commit with mostly `+` diff, less that 250 lines of code.

   If implementing a big feature with different functionality, decompose it:

   - For new files: a simple and straightforward base layer. Commit.
   - Next several complications, each should have its own commit.
     (This relate both when adding to new file, or changing existing one.)

1. Apply feature to the code.\
   Typically a single refactoring commit which replaces old approach with a new one over the codebase.

As said, this should be applied recursively.
Refactoring existing functionality on upper level may become a feature if decomposed further.
A good sign that a stage decomposition is needed (except for structural refactoring)
is net addition of more than 250 lines of code (do not treat this too literally, though).

**Each step on its own is affected by main rules of simplicity from previous topics.**

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
