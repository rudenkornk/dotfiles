// opencode does not use the external hook model the other agents use; it runs
// plugins in-process. The shell API ($) inherits opencode's environment, so
// $TMUX_PANE is set and PATH includes tmux-agent-status (from home.packages).
//
// Lifecycle events arrive through the single generic `event` hook (the Hooks
// interface has no per-event keys for these), discriminated by `event.type`.
import type { Plugin } from "@opencode-ai/plugin";

export const AgentStatus: Plugin = async ({ $ }) => {
  // Each state update spawns a `tmux-agent-status` process, and opencode can emit two lifecycle
  // events milliseconds apart (e.g. a final `busy` tick immediately followed by `session.idle`).
  // Concurrently spawned processes finish in arbitrary order, so the earlier "running" write could
  // land after the final "done" write and leave the tab stuck. A single-flight pump serializes the
  // writes and coalesces to the newest requested state, so the last event always wins.
  let pending: string | null = null;
  let lastQueued: string | null = null;
  let pumping = false;
  const pump = async () => {
    if (pumping) return;
    pumping = true;
    while (pending !== null) {
      const state = pending;
      pending = null;
      try {
        await $`tmux-agent-status set --state ${state}`;
      } catch {
        // tmux may be gone (detached pane, closed window); never break the event stream over it.
      }
    }
    pumping = false;
  };
  const setState = (state: string) => {
    if (state === lastQueued) return;
    lastQueued = state;
    pending = state;
    void pump();
  };

  // `session.error` is immediately followed by a status flip to idle (see `halt()` in
  // opencode's session processor), which would overwrite the error state with "done".
  // Remember the error and let it survive that one idle; any new activity clears it.
  let errored = false;

  // opencode AI-generates a session title (shown in its session list) and re-emits
  // `session.updated` on every session change; forward the title as naming material
  // only when it actually changed, so we do not spawn a process per event.
  let lastTitle = "";

  return {
    event: async ({ event }) => {
      // `question.*` events are runtime-only and absent from the SDK's typed
      // Event union, so read the discriminant and payload through widened
      // aliases instead of switching on the narrowed `event.type`.
      const type = event.type as string;
      const props = (event as { properties?: Record<string, unknown> })
        .properties;

      switch (type) {
        case "session.status": {
          const status = (props as { status?: { type?: string } } | undefined)
            ?.status;
          // While the agent is blocked on interactive input it stays quiet, so
          // a busy tick only ever means real work — no waiting state to guard.
          if (status?.type === "busy") {
            errored = false;
            setState("running");
          }
          break;
        }
        // The agent is blocked on interactive input: a question prompt
        // (`question.asked`) or a tool-approval request (`permission.updated`).
        case "question.asked":
        case "permission.updated":
          setState("waiting");
          break;
        case "question.replied":
        case "permission.replied":
          errored = false;
          setState("running");
          break;
        case "session.idle":
          // After a failure the session also goes idle; keep the error state visible.
          if (!errored) setState("done");
          break;
        case "session.error": {
          const name = (props as { error?: { name?: string } } | undefined)
            ?.error?.name;
          // A user interrupt (Esc) flows through the same event as a `MessageAbortedError`;
          // that is not a failure, and the follow-up idle will render it as "done".
          if (name === "MessageAbortedError") break;
          errored = true;
          setState("error");
          break;
        }
        case "session.updated": {
          const title = (props as { info?: { title?: string } } | undefined)
            ?.info?.title;
          if (title && title !== lastTitle) {
            lastTitle = title;
            await $`tmux-agent-name set --source summary --text ${title}`;
          }
          break;
        }
      }
    },
  };
};
