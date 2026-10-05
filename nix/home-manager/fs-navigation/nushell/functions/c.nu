use std/dirs

def --env --wrapped c [...args: string] {
  if ($args | is-empty) or $args == ['-'] {
    dirs drop
  } else {
    let target = if ($args | length) == 1 and ($args.0 | path type) == dir {
      $args.0
    } else {
      ^zoxide query -- ...$args | str trim
    }
    dirs add $target
  }
  eza --classify=always --icons --all --group-directories-first
}
