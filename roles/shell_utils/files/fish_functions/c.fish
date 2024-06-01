function c --wraps z
  if test "$argv" = "-"
     or test "$argv" = ""
    popd && eza --classify --icons
  else
    pushd .
    z $argv && eza --classify --icons
  end
end
