if test (count $argv) -gt 0
    and test -f "$argv[1]"
    and string match --quiet 'image/*' (file --brief --mime-type -- "$argv[1]")
    kitten icat --fit both -- $argv
else
    bat $argv
end
