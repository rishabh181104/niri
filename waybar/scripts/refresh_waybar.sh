#!/usr/bin/env bash

# Kill all running Waybar instances
killall waybar

# Small delay to ensure process is fully stopped
sleep 1

# Restart Waybar
waybar --config $HOME/.config/niri/waybar/config.jsonc --style $HOME/.config/niri/waybar/style.css &
