function c --wraps cd
  if test "$argv" = "-"
    popd && exa --classify
  else if test "$argv" = ""
    cd ~ && exa --classify
  else
    pushd $argv && exa --classify
  end
end
