function grl --wraps gr
  gr git --no-pager log --decorate --graph --oneline -n 1 $argv
end
