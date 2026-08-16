# Extract tab-name material from a Codex session rollout, for `tmux-agent-name set --source codex-transcript`.
# The rollout is JSONL slurped raw (`jq -Rrs`); `fromjson?` tolerates a final line that is still being appended.
# The material is the agent's own description of the current turn: prefer its first commentary,
# authored right after it understands the task, else its final answer, which covers turns without tool calls.
# The rollout format is undocumented, so all of this is best-effort.
[split("\n")[] | fromjson?] as $events

| def is_user_message:
    .type == "event_msg" and .payload.type == "user_message";

  # Assistant text appears both as a UI event and as a model-facing response item;
  # match both, since it is unknown which of the two a given rollout flavor contains.
  def assistant_message:
    if .type == "event_msg"
      and .payload.type == "agent_message"
      and (.payload.message | type) == "string"
    then { phase: (.payload.phase // ""), text: .payload.message }
    elif .type == "response_item"
      and .payload.type == "message"
      and .payload.role == "assistant"
    then {
      phase: (.payload.phase // ""),
      text: ([.payload.content[]? | .text? | select(type == "string")] | join("\n"))
    }
    else null
    end;

  # Guardian and other subagents write machine output (JSON verdicts) into rollouts of their own;
  # a tab named after those would show noise like "risk_level-low".
  if any($events[]; .type == "session_meta" and .payload.thread_source == "subagent")
  then empty
  else
    # Keep only the assistant messages of the turn opened by the latest user message.
    (reduce $events[] as $event
      ({ seen_user: false, messages: [] };
       if ($event | is_user_message)
       then { seen_user: true, messages: [] }
       else ($event | assistant_message) as $message
         | if .seen_user and $message != null and $message.text != ""
           then .messages += [$message]
           else .
           end
       end)) as $turn

    | ([ $turn.messages[] | select(.phase == "commentary") | .text ] | first)
      // ([ $turn.messages[] | select(.phase == "final_answer") | .text ] | last)
      // empty
  end
