# See https://superuser.com/a/1747701
function fish_remove_path --description "Shows user added PATH entries and removes the selected one"
    echo "User added PATH entries"
    set -l PATH_ENTRIES
    echo $fish_user_paths | sed 's/ \//\n\//g' | nl
    echo "Select the number of entry to be removed, if more than one separate the values by spaces"
    read -d " " -a PATH_ENTRIES

    set erasing ""
    for entry in $PATH_ENTRIES
        if not string match -qr '^[0-9]+$' $entry
            echo "Provided argument $entry is not a number" 1>&2
            return 1
        end
        set -l FISH_ENTRIES (count $fish_user_paths)
        if test $entry -gt $FISH_ENTRIES
            echo "Index $entry out of bounds, must be between 1 and $FISH_ENTRIES" 1>&2
            return 1
        end
        set erasing $erasing $fish_user_paths[$entry]
    end
    # set --erase --universal does not work for some reason
    for element in $fish_user_paths
        if contains $element $erasing
            continue
        end
        set new_user_paths $new_user_paths $element
    end
    echo "Erasing $erasing"
    set --universal fish_user_paths $new_user_paths
end
