function c --wraps cd
  if test "$argv" = "-"
    popd && exa --classify
  else
    pushd $argv && exa --classify
  end
end
