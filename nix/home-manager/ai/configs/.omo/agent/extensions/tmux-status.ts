import { execFile } from "node:child_process";
import { promisify } from "node:util";
import type { ExtensionAPI, ExtensionContext } from "@code-yeongyu/senpi";

const run = promisify(execFile);
type State = "running" | "waiting" | "done" | "error";

export default function (pi: ExtensionAPI) {
  if (!process.env.TMUX_PANE) return;

  let running = false;
  let failed = false;
  let started = false;
  let prompts = 0;
  let lastState: State | undefined;
  let lastTitle: string | undefined;
  let writes = Promise.resolve();

  // Children and the shared RPC host must not update the terminal client's pane.
  const ownsPane = (ctx: ExtensionContext) => ctx.mode === "tui";
  const enqueue = (command: string, args: string[]) => {
    writes = writes.then(async () => {
      await run(command, args).catch(() => {});
    });
    return writes;
  };
  const title = (value: string | undefined) => {
    if (!value || value === lastTitle) return;
    lastTitle = value;
    void enqueue("tmux-agent-name", [
      "set",
      "--source",
      "summary",
      "--text",
      value,
    ]);
  };
  const refresh = () => {
    const state: State | undefined =
      prompts > 0
        ? "waiting"
        : running
          ? "running"
          : failed
            ? "error"
            : started
              ? "done"
              : undefined;
    if (!state || state === lastState) return;
    lastState = state;
    void enqueue("tmux-agent-status", ["set", "--state", state]);
  };

  pi.on("session_start", (_event, ctx) => {
    if (!ownsPane(ctx)) return;
    running = false;
    failed = false;
    started = false;
    prompts = 0;
    lastState = undefined;
    lastTitle = undefined;
    void enqueue("tmux-agent-status", ["set", "--state", "clear"]);
    title(pi.getSessionName());
  });
  pi.on("session_info_changed", (event, ctx) => {
    if (ownsPane(ctx)) title(event.name);
  });
  pi.on("agent_start", (_event, ctx) => {
    if (!ownsPane(ctx)) return;
    running = true;
    failed = false;
    started = true;
    refresh();
  });
  pi.on("ui_prompt_start", (_event, ctx) => {
    if (!ownsPane(ctx)) return;
    prompts += 1;
    refresh();
  });
  pi.on("ui_prompt_end", (_event, ctx) => {
    if (!ownsPane(ctx)) return;
    prompts = Math.max(0, prompts - 1);
    refresh();
  });
  pi.on("agent_before_settle", (event, ctx) => {
    if (ownsPane(ctx)) failed = event.outcome === "error";
  });
  // agent_end can still be followed by retries, compaction or queued work.
  pi.on("agent_settled", (_event, ctx) => {
    if (!ownsPane(ctx)) return;
    running = false;
    prompts = 0;
    refresh();
    title(pi.getSessionName());
  });
  pi.on("session_abort", (_event, ctx) => {
    if (!ownsPane(ctx)) return;
    running = false;
    failed = false;
    prompts = 0;
    refresh();
  });
  pi.on("session_shutdown", async (_event, ctx) => {
    if (!ownsPane(ctx)) return;
    running = false;
    prompts = 0;
    refresh();
    await writes;
  });
}
