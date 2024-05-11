function c --wraps __zoxide_z
  if test "$argv" = "-"
     or test "$argv" = ""
    popd && exa --classify --icons
  else
    pushd .
    __zoxide_z $argv && exa --classify --icons
  end
end
