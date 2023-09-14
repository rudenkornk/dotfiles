function c --wraps cd
  if test "$argv" = "-"
     or test "$argv" = ""
    popd && exa --classify
  else
    pushd $argv && exa --classify
  end
end
