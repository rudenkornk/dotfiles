Setup keyboard:
1. Copy rnk to /usr/share/X11/xkb/symbols
2. Insert contents of evdev.xml into /usr/share/X11/xkb/rules/evdev.xml into appropriate place
3. Copy rnk-russian-qwerty.vim to /usr/share/vim/vim*/keymap/
4. Use .vimrc file


Setup mouse:
1. Install logiops: https://github.com/PixlOne/logiops
2. Run logid and copy name of mouse.
   For example:
   $ sudo logid
   [INFO] Device found: Wireless Mouse MX Master 3 on /dev/hidraw1:1
   Means name is "Wireless Mouse MX Master 3"
3. Put this name into logid.cfg
4. Copy logid.cfg to /etc/logid.cfg
5. sudo systemctl enable --now logid

