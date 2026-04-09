# "Warm up" `sudo` before running it under `nohup`, to avoid failure.
sudo echo ""

# Redirect both stdout and stderr to a log file.
# Otherwise, `nohup` will create unnecessary `nohup.out` in cwd.
nohup sudo \
    DISPLAY=$DISPLAY \
    WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
    XAUTHORITY=$XAUTHORITY \
    XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR \
    @throne@/bin/Throne $args &>/tmp/Throne_$USER.log &

disown
