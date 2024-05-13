function c --wraps __zoxide_z
  if test "$argv" = "-"
     or test "$argv" = ""
    popd && eza --classify --icons
  else
    pushd .
    __zoxide_z $argv && eza --classify --icons
  end
end
