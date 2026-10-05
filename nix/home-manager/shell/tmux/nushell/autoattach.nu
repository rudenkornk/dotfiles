if $nu.is-interactive and ('TMUX' not-in $env) {
  let sessions = (^tmux list-sessions -F '#{session_id} #{session_attached}' | complete)
  if $sessions.exit_code != 0 {
    exec tmux -2 -u
  }
  let detached = ($sessions.stdout | lines | parse '{session} {attached}'
    | where attached == '0' | get --optional 0.session)
  if $detached != null {
    exec tmux -2 -u attach-session -t $detached
  }
}
