#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

source_file="$1"
target_file="$2"
begin=${3:-"# --- dotfiles begin --- #"}
end=${4:-"# --- dotfiles end --- #"}
# If inserting the first time, then insert before line with this number:
insert_before=${5:-"0"} # First line is "1". "0" is special case meaning insert in the end

touch "$target_file"
if ! grep --quiet "$begin" "$target_file"; then
    tmp_insert_file=tmp_insert
    total_lines=$(wc --lines "$target_file" | cut --delimiter " " --fields 1)
    n_before=$(( (insert_before + total_lines) % (total_lines + 1) ))
    n_after=$(( total_lines - n_before ))

    head -n $n_before $target_file > $tmp_insert_file
    echo "$begin" >> $tmp_insert_file
    cat "$source_file" >> $tmp_insert_file
    echo "$end" >> $tmp_insert_file
    tail -n $n_after $target_file >> $tmp_insert_file
    mv $tmp_insert_file "$target_file"
else
    sed -i -ne "/$begin/ {p; r $source_file" -e ":a; n; /$end/ {p; b}; ba}; p" "$target_file"
fi

