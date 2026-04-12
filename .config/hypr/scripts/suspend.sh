#!/usr/bin/env bash
if pidof hyprlock > /dev/null; then
    echo "Hyprlock is already running."
else
    /usr/bin/hyprlock &    
    sleep 0.5
fi
systemctl suspend