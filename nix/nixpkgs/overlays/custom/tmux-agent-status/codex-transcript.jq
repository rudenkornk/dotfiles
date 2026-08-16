# Extract tab-name material from an agent transcript, for `tmux-agent-name set --source codex-transcript`.
# The input is the whole transcript slurped as a parsed JSON stream (`jq -rs`).
#
# Prefer the latest summary entry, else the latest plain user message.
# The format is undocumented, so this is best-effort.
([.[] | select(.type == "summary") | .summary | strings | select(. != "")] | last)
// ([.[] | select(.type == "user") | .message.content | strings] | last)
// empty
