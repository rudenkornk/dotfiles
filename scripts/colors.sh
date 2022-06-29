#! /usr/bin/env bash

# Credits https://askubuntu.com/a/803316
colors=256
for (( n=0; n < $colors; n++ )) do
    printf " [%d] $(tput setaf $n)%s$(tput sgr0)" $n "■■■■■■■■■■
"
done
