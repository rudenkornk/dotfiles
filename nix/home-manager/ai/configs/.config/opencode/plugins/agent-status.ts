// opencode does not use the external hook model the other agents use; it runs
// plugins in-process. The shell API ($) inherits opencode's environment, so
// $TMUX_PANE is set and PATH includes tmux-agent-status (from home.packages).
//
// Lifecycle events arrive through the single generic `event` hook (the Hooks
// interface has no per-event keys for these), discriminated by `event.type`.
import type { Plugin } from "@opencode-ai/plugin";

export const AgentStatus: Plugin = async ({ $ }) => {
  type AgentState = "running" | "waiting" | "done" | "error";

  // Each state update spawns a `tmux-agent-status` process, and opencode can emit two lifecycle
  // events milliseconds apart (e.g. a final `busy` tick immediately followed by `session.idle`).
  // Concurrently spawned processes finish in arbitrary order, so the earlier "running" write could
  // land after the final "done" write and leave the tab stuck. A single-flight pump serializes the
  // writes and coalesces to the newest requested state, so the last event always wins.
  let pending: AgentState | null = null;
  let lastQueued: AgentState | null = null;
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
  const setState = (state: AgentState) => {
    if (state === lastQueued) return;
    lastQueued = state;
    pending = state;
    void pump();
  };

  // One plugin instance receives the events of a parent session and of every subagent session it
  // spawns, so a single event never describes the whole tab: a child going idle while its parent
  // still works is not "done", and a busy tick from any session must not hide a prompt raised by
  // another one. Track what each session is doing and derive one tab state from all of them.
  const activeSessions = new Set<string>();
  const failedSessions = new Set<string>();
  // Keyed by interaction kind and request id, valued by the session that owns the request, so
  // answering one prompt cannot clear the tab while another prompt is still unanswered.
  const pendingInteractions = new Map<string, string>();
  // `session.error` carries an optional session id; an error we cannot attribute to a session has
  // to be latched globally, because no particular session can ever clear it.
  let unattributedError = false;
  // Distinguishes real completion from plugin startup, so an idle tick cannot announce "done"
  // before anything has run.
  let sawActivity = false;

  const refreshState = () => {
    // A prompt outranks everything else: work continuing elsewhere must not bury a request that
    // only the user can answer.
    if (pendingInteractions.size > 0) setState("waiting");
    // `session.error` is immediately followed by a status flip to idle (see `halt()` in opencode's
    // session processor); ranking errors above activity keeps them visible through that idle.
    else if (unattributedError || failedSessions.size > 0) setState("error");
    else if (activeSessions.size > 0) setState("running");
    else if (sawActivity) setState("done");
  };

  const markIdle = (sessionID: string) => {
    activeSessions.delete(sessionID);
    // A session interrupted while it was prompting never replies, so drop what it was waiting on
    // rather than leaving the tab amber forever.
    for (const [key, owner] of pendingInteractions) {
      if (owner === sessionID) pendingInteractions.delete(key);
    }
    sawActivity = true;
  };

  // Ask events name the request through `id` and replies through `requestID`; both are the same
  // value, and the kind prefix keeps a permission and a question from colliding on it.
  const addInteraction = (
    kind: "permission" | "question",
    props: Record<string, unknown> | undefined,
  ) => {
    const info = props as { id?: string; sessionID?: string } | undefined;
    if (!info?.id || !info.sessionID) return;
    pendingInteractions.set(`${kind}:${info.id}`, info.sessionID);
    sawActivity = true;
  };
  const removeInteraction = (
    kind: "permission" | "question",
    props: Record<string, unknown> | undefined,
  ) => {
    const requestID = (props as { requestID?: string } | undefined)?.requestID;
    if (requestID) pendingInteractions.delete(`${kind}:${requestID}`);
  };

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
          const info = props as
            | { sessionID?: string; status?: { type?: string } }
            | undefined;
          if (!info?.sessionID) break;
          // A scheduled retry after a provider hiccup is still work in progress, not a pause.
          if (info.status?.type === "busy" || info.status?.type === "retry") {
            activeSessions.add(info.sessionID);
            // Fresh work supersedes this session's previous failure. Other sessions keep theirs.
            failedSessions.delete(info.sessionID);
            unattributedError = false;
            sawActivity = true;
          } else if (info.status?.type === "idle") {
            markIdle(info.sessionID);
          } else {
            break;
          }
          refreshState();
          break;
        }
        // Idle is announced twice, as a status flip and through this deprecated event; handling
        // both is harmless because the tracked sets and the status pump both deduplicate it.
        case "session.idle": {
          const sessionID = (props as { sessionID?: string } | undefined)
            ?.sessionID;
          if (!sessionID) break;
          markIdle(sessionID);
          refreshState();
          break;
        }
        // The agent is blocked on interactive input: a question prompt
        // (`question.asked`) or a tool-approval request (`permission.asked`).
        case "question.asked":
          addInteraction("question", props);
          refreshState();
          break;
        case "permission.asked":
          addInteraction("permission", props);
          refreshState();
          break;
        // A question is resolved either by an answer or by a dismissal; both end the pause.
        case "question.replied":
        case "question.rejected":
          removeInteraction("question", props);
          refreshState();
          break;
        case "permission.replied":
          removeInteraction("permission", props);
          refreshState();
          break;
        case "session.error": {
          const info = props as
            | { sessionID?: string; error?: { name?: string } }
            | undefined;
          // A user interrupt (Esc) flows through the same event as a `MessageAbortedError`;
          // that is not a failure, and the follow-up idle will render it as "done".
          if (info?.error?.name === "MessageAbortedError") break;
          if (info?.sessionID) failedSessions.add(info.sessionID);
          else unattributedError = true;
          sawActivity = true;
          refreshState();
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
