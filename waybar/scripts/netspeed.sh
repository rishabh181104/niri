#!/usr/bin/env bash

# Function to format speed in human-readable units
format_speed() {
  local speed=$1
  if command -v bc >/dev/null 2>&1; then
    # Use bc for precise floating-point calculations if available
    if [ "$speed" -ge 1048576 ]; then
      printf "%.2f MB/s" "$(echo "scale=2; $speed / 1048576" | bc -l)"
    elif [ "$speed" -ge 1024 ]; then
      printf "%.2f KB/s" "$(echo "scale=2; $speed / 1024" | bc -l)"
    else
      printf "%d B/s" "$speed"
    fi
  else
    # Fallback to integer-only formatting without bc
    if [ "$speed" -ge 1048576 ]; then
      printf "%d MB/s" "$((speed / 1048576))"
    elif [ "$speed" -ge 1024 ]; then
      printf "%d KB/s" "$((speed / 1024))"
    else
      printf "%d B/s" "$speed"
    fi
  fi
}

# Function to detect active interface with Ethernet priority
get_active_interface() {
  local eth_interface=""
  local wifi_interface=""

  # Iterate through network interfaces efficiently
  for iface in /sys/class/net/*; do
    iface_name=$(basename "$iface")
    [ "$iface_name" = "lo" ] && continue # Skip loopback
    if [ -f "$iface/operstate" ] && [ "$(cat "$iface/operstate" 2>/dev/null)" = "up" ]; then
      if [ -d "$iface/wireless" ]; then
        wifi_interface="$iface_name"
      elif [[ "$iface_name" =~ ^(en|eth|eno|ens|enp) ]]; then
        eth_interface="$iface_name"
      fi
    fi
  done

  # Prioritize Ethernet
  if [ -n "$eth_interface" ]; then
    echo "$eth_interface|"
  elif [ -n "$wifi_interface" ]; then
    echo "$wifi_interface|"
  else
    echo "none|"
  fi
}

# Main loop for continuous Waybar updates
while true; do
  # Get active interface and icon
  IFS='|' read -r INTERFACE ICON <<<"$(get_active_interface)"

  # Handle disconnected state
  if [ "$INTERFACE" = "none" ]; then
    echo "{\"text\": \" Disconnected\", \"tooltip\": \"No active network\"}"
  else
    # Cache file paths
    RX_FILE="/sys/class/net/$INTERFACE/statistics/rx_bytes"
    TX_FILE="/sys/class/net/$INTERFACE/statistics/tx_bytes"

    # Check file readability
    if [ ! -r "$RX_FILE" ] || [ ! -r "$TX_FILE" ]; then
      echo "{\"text\": \" Error\", \"tooltip\": \"Cannot read $INTERFACE stats\"}"
    else
      # Read initial bytes
      RX1=$(cat "$RX_FILE")
      TX1=$(cat "$TX_FILE")

      # Precise 1-second interval
      sleep 1

      # Read final bytes
      RX2=$(cat "$RX_FILE")
      TX2=$(cat "$TX_FILE")

      # Calculate speeds
      RX_SPEED=$((RX2 - RX1))
      TX_SPEED=$((TX2 - TX1))

      # Ensure non-negative speeds
      [ "$RX_SPEED" -lt 0 ] && RX_SPEED=0
      [ "$TX_SPEED" -lt 0 ] && TX_SPEED=0

      # Output JSON
      echo "{\"text\": \"↓ $(format_speed $RX_SPEED) ↑ $(format_speed $TX_SPEED) $ICON\", \"tooltip\": \"$INTERFACE: ↓ $(format_speed $RX_SPEED) ↑ $(format_speed $TX_SPEED)\"}"
    fi
  fi
done
