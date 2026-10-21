import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { Plugin } from "@opencode/plugin/tui";
import { createEffect, onCleanup } from "solid-js";

const run = promisify(execFile);
type AgentState = "running" | "waiting" | "done" | "error" | "clear";
type Update = { state?: AgentState; title?: string };

export default Plugin.define({
  id: "dotfiles.tmux-agent-status",
  setup(context) {
    if (!process.env.TMUX_PANE) return;

    let pending: Update | undefined;
    let pumping = false;
    let disposed = false;
    let lastState: AgentState | undefined;
    let lastTitle: string | undefined;

    // Serialize helper processes so an earlier write cannot overwrite a newer state.
    const pump = async () => {
      if (pumping) return;
      pumping = true;
      try {
        while (pending && !disposed) {
          const update = pending;
          pending = undefined;
          if (update.state) {
            await run("tmux-agent-status", [
              "set",
              "--state",
              update.state,
            ]).catch(() => {});
          }
          if (update.title && !disposed) {
            await run("tmux-agent-name", [
              "set",
              "--source",
              "summary",
              "--text",
              update.title,
            ]).catch(() => {});
          }
        }
      } finally {
        pumping = false;
      }
    };

    const disposeSlot = context.ui.slot({
      append: "app",
      render: () => {
        // The app slot remounts on reconnect; derive state from the client's refreshed session cache.
        createEffect(() => {
          const route = context.ui.router.current();
          const selected =
            route.type === "session" ? route.sessionID : undefined;
          const roots = new Set(
            context.ui.tabs.list().map((tab) => tab.sessionID),
          );
          if (selected) roots.add(context.data.session.root(selected));
          const family = new Set(
            [...roots].flatMap((id) => [
              id,
              ...context.data.session.family(id),
            ]),
          );

          let waiting = false;
          let running = false;
          let failed = false;
          let finished = false;
          for (const id of family) {
            const session = context.data.session.get(id);
            const active = context.data.session.status(id) === "running";
            waiting ||=
              (context.data.session.permission.list(id)?.length ?? 0) > 0;
            waiting ||=
              (context.data.session.form.list(id, session?.location)?.length ??
                0) > 0;
            running ||= active;
            failed ||= !active && session?.outcome === "failed";
            finished ||= session?.outcome !== undefined;
          }
          const state: AgentState = waiting
            ? "waiting"
            : failed
              ? "error"
              : running
                ? "running"
                : finished
                  ? "done"
                  : "clear";
          const title = selected
            ? context.data.session.get(context.data.session.root(selected))
                ?.title
            : undefined;
          const update: Update = {};
          if (state && state !== lastState) {
            update.state = state;
            lastState = state;
          }
          if (title && title !== lastTitle) {
            update.title = title;
            lastTitle = title;
          }
          if (!update.state && !update.title) return;
          pending = { ...pending, ...update };
          void pump();
        });
        onCleanup(() => {
          pending = undefined;
          lastState = undefined;
          lastTitle = undefined;
        });
        return null;
      },
    });

    return () => {
      disposed = true;
      pending = undefined;
      disposeSlot();
    };
  },
});
