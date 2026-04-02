# Global general instructions

ONLY FOR PRIMARY AGENT.
IF YOU ARE A SUBAGENT IGNORE "FEEDBACK LOOP" INSTRUCTIONS AND FOCUS STRICTLY ON YOUR SUBTASK.

## Subagent spawn

When spawning a subagent, always start a prompt with "You are running as a subagent."

## Feedback loop

Whenever a complex task is given to you, such as debugging an issue or developing a complex feature,
you must ensure you have ways to test result's correctness.
You may override these instructions if you think that you can easily implement a bugfix or a feature
without verification (i.e. it is a very well-known task or a task is really simple).
However, for nontrivial debug/feature sessions when you do not know in advance a good solution
you normally should create some ways to test the solution.

1. You may delegate (if needed) any of these subtasks to subagents.

1. For a given task, first decide if it needs a test feedback.
   If not, skip all of the next instructions in this section, continue normal operation.
   Examples for tasks usually requiring feedback: debug a problem, implement a feature.
   Examples for tasks usually not requiring feedback: write a text, answer questions.

1. If task requires a feedback, qualify the type of a feedback required.
   There are two types of feedbacks: interactive and non-interactive.

   2.1. Non-interactive feedbacks do not require visual feedback.
   Examples of non-interactive feedbacks: verify program does not crash,
   verify program's stdout/stderr is correct, verify function returns correct values,
   verify function fails in an expected way, verify files are (are not) in expected locations.
   Anything which can be tested with a simple bash script qualifies as non-interactive feedback.
   Often non-interactive feedback is provided by project's instructions or user himself.

   2.2. Interactive feedback may require visual feedback.
   Examples of interactive feedback: check that CLI tool renders TUI correctly,
   check that editor (neovim) opens and does not show error messages or does something
   specific on document open, check that browser displays specific page.
   Anything, which requires terminal or GUI interaction.
   For this feedback you may want to recognize your screenshot capturing capabilities as well
   as image recognition.

1. After that, qualify the complexity of implementing a feedback in its simplest form
   COMPARED TO the estimated complexity of the original task.
   Simplest form means that at this point your job is just to find a simplest way to check future work.
   You do not need yet to use test frameworks (though you are allowed to do that).

   If estimated complexity is a one- or two-liner in bash, a simple bash test in less that 15 lines,
   or a regular test in an existing test frameworks with less that 15 lines, then complexity is always
   considered as "low", regardless of the task complexity.
   Also, if feedback is already provided by the project's instructions or the user,
   it is also considered "low".

   If estimated complexity \<= 1.5 * complexity of original task, then complexity is considered as "normal".

   If estimated complexity > 1.5 * complexity or original task, OR you do not know a good way to even implement
   a feedback (usually for interactive feedbacks), then complexity is considered as "high".

1. For low complexity always implement (or design depending on your role)
   a feedback without confirmation alongside the original task
   and use it to check yourself, as well as provide it to the user.

1. For normal complexity consider your task split in two: create a strategy for a feedback and
   original task.
   Depending on your role you might either implement them or only design them.

1. For high complexity you should create approximate projected strategy for a feedback and
   ASK USER whether you should implement a feedback first.

   7.1. If user says yes, then temporarily delay original task and focus on implementing a feedback loop.
   7.2. If user says no, then do focus on original task. Always keep in memory original observations
   about possible feedback strategies.

1. When feedback is ready (or already provided), try to execute it before implementing a feature/fixing a bug.
   This should "pin" default feedback behaviour and verify that at least "negative" result works.

## Feedback Loop — Key Points

**Core idea**: For non-trivial tasks (debugging, feature implementation), always establish a way to verify correctness before or alongside the work.

**Decision flow:**

1. **Does the task need feedback?**

   - Yes: debugging, implementing features.
   - No: writing text, answering questions.

1. **What type of feedback?**

   - **Non-interactive**: stdout/stderr checks, crash verification, file existence — anything testable with a bash script.
   - **Interactive**: visual output (TUI rendering, editor behavior, browser display) — may require screenshots/image recognition.

1. **How complex is implementing the feedback?** (relative to the original task)

   - **Low**: ≤15-line bash/test script, or feedback already provided → implement it without asking.
   - **Normal**: ≤1.5× original task complexity → plan both feedback and task together.
   - **High**: >1.5× complexity, or no clear feedback strategy → propose a strategy and **ask the user** whether to implement it first.

1. **Execute feedback before the main work** to establish a baseline ("negative" result).

**Key principle**: The simpler the feedback mechanism, the better — no need for full test frameworks unless already present.
