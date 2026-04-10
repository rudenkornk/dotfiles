argparse 'c/config=' -- $argv
or return 1

# 2. Set the default path
set -l target_config "@default_config@"
if set -q _flag_config
    set target_config $_flag_config
end

if not test -f "$target_config"
    echo "Error: Config file '$target_config' not found."
    return 1
end

set -l cmd "@sing-box@/bin/sing-box run --config <(@sops@/bin/sops --decrypt '$target_config') --directory /tmp/sing-box-$USER $argv"

echo "Command: $cmd"

sudo @bash@/bin/bash -c "$cmd"
