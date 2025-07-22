#!/usr/bin/env bash

# Kill all running Waybar instances
killall waybar

# Small delay to ensure process is fully stopped
sleep 1

# Restart Waybar
waybar &
