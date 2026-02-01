# "Warm up" `sudo` before running it under `nohup`, to avoid failure.
sudo echo ""

# Redirect both stdout and stderr to a log file.
# Otherwise, `nohup` will create unnecessary `nohup.out` in cwd.
nohup sudo @throne@/bin/Throne $args &>/tmp/Throne_$USER.log &

disown
