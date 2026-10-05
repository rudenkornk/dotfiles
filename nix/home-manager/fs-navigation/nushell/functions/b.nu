def --wrapped b [...args: string] {
  $in | if ($args | is-not-empty) and ($args.0 | path type) == file and (
    ^file --brief --mime-type -- $args.0 | str starts-with 'image/'
  ) {
    ^kitten icat --fit both -- ...$args
  } else {
    ^bat ...$args
  }
}
