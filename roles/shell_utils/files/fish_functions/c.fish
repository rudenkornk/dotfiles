function c --wraps cd
  if test "$argv" = "-"
     or test "$argv" = ""
    popd && exa --classify --icons
  else
    pushd $argv && exa --classify --icons
  end
end
