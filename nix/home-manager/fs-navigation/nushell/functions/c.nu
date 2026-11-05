use std/dirs

def --env --wrapped c [...args: string] {
  if ($args | is-empty) or $args == ['-'] {
    let old_pwd = $env.PWD
    dirs drop
    $env.__C_FORWARD = (($env.__C_FORWARD? | default []) | append $old_pwd)
  } else if $args == ['+'] {
    let forward = $env.__C_FORWARD? | default []
    if ($forward | is-empty) {
      error make {msg: 'c: forward directory history is empty'}
    }
    let old_list = $env.DIRS_LIST
    let old_position = $env.DIRS_POSITION
    try {
      dirs add ($forward | last)
    } catch {|err|
      $env.DIRS_LIST = $old_list
      $env.DIRS_POSITION = $old_position
      error make $err
    }
    $env.__C_FORWARD = ($forward | drop)
  } else {
    let target = if ($args | length) == 1 and ($args.0 | path type) == dir {
      $args.0
    } else {
      ^zoxide query -- ...$args | str trim
    }
    dirs add $target
    $env.__C_FORWARD = []
  }
  eza --classify=always --icons --all --group-directories-first
}
