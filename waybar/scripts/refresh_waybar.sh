#!/usr/bin/env bash

# Kill all running Waybar instances
killall waybar

# Small delay to ensure process is fully stopped
sleep 1

# Restart Waybar
waybar -c $HOME/.config/niri/waybar/config.jsonc -s $HOME/.config/niri/waybar/style.css &
