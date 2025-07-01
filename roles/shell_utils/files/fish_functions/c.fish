function c --wraps z
  if test "$argv" = "-"
     or test "$argv" = ""
    popd && eza --classify --icons --all
  else
    pushd .
    z $argv && eza --classify --icons --all
  end
  if test -f .venv/bin/activate.fish
    source .venv/bin/activate.fish
  end
end
