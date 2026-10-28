#!/usr/bin/env bash

case "$1" in
    shutdown)
        (setsid bash -c 'systemctl poweroff' &>/dev/null &);;
    reboot)
        (setsid bash -c 'systemctl reboot' &>/dev/null &);;
    logout)
        # End the compositor so the session closes normally and the display
        # manager shows its greeter again. terminate-user kills the display
        # manager's session helper along with everything else, and SDDM is
        # left on a black screen.
        if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] && hyprctl dispatch exit &>/dev/null; then
            :
        else
            (setsid bash -c 'loginctl terminate-session "${XDG_SESSION_ID:-}"' &>/dev/null &)
        fi;;
    *)
        exit 1
        ;;
esac