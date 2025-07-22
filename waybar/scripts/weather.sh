#!/usr/bin/env bash

# Weather script for Waybar
# Fetches weather data from wttr.in and formats it for display

CITY="Saharanpur"
CACHE_FILE="/tmp/waybar_weather_cache"
CACHE_DURATION=900  # 15 minutes in seconds

# Function to get weather icon based on condition
get_weather_icon() {
    local condition="$1"
    condition=$(echo "$condition" | tr '[:upper:]' '[:lower:]')

    case "$condition" in
        *sunny*|*clear*) echo "󰖙" ;;
        *partly*cloudy*|*partly*cloud*) echo "󰖕" ;;
        *cloudy*|*overcast*|*cloud*) echo "󰖐" ;;
        *rain*|*shower*|*drizzle*) echo "󰖗" ;;
        *thunder*|*storm*) echo "󰖓" ;;
        *snow*|*blizzard*) echo "󰖘" ;;
        *fog*|*mist*|*haze*) echo "󰖑" ;;
        *wind*) echo "󰖝" ;;
        *hot*) echo "󰖙" ;;
        *cold*) echo "󰖘" ;;
        *night*|*dark*) echo "󰖔" ;;
        *) echo "󰖕" ;;  # default weather icon
    esac
}

# Function to get weather data
get_weather() {
    local weather_data

    # Try to fetch weather data with timeout
    weather_data=$(curl -s --max-time 10 "https://wttr.in/${CITY}?format=%t+%C" 2>/dev/null)
    local curl_exit_code=$?

    if [ $curl_exit_code -eq 0 ] && [ -n "$weather_data" ] && [[ "$weather_data" != *"Unknown location"* ]]; then
        # Clean up the data - remove extra spaces and format
        weather_data=$(echo "$weather_data" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -s ' ')
        echo "$weather_data"
        # Cache the result
        echo "$weather_data" > "$CACHE_FILE"
        echo "$(date +%s)" >> "$CACHE_FILE"
        return 0
    else
        return 1
    fi
}

# Function to check if cache is valid
is_cache_valid() {
  if [ ! -f "$CACHE_FILE" ]; then
    return 1
  fi

  local cache_time
  cache_time=$(tail -n 1 "$CACHE_FILE" 2>/dev/null)
  local current_time=$(date +%s)

  if [ -n "$cache_time" ] && [ $((current_time - cache_time)) -lt $CACHE_DURATION ]; then
    return 0
  else
    return 1
  fi
}

# Function to get cached weather
get_cached_weather() {
  if [ -f "$CACHE_FILE" ]; then
    head -n 1 "$CACHE_FILE" 2>/dev/null
  fi
}

# Main logic
if is_cache_valid; then
    # Use cached data
    weather_text=$(get_cached_weather)
    if [ -n "$weather_text" ]; then
        # Extract condition for icon
        condition=$(echo "$weather_text" | cut -d' ' -f2-)
        weather_icon=$(get_weather_icon "$condition")
        echo "{\"text\": \"$weather_icon $weather_text\", \"tooltip\": \"Weather in $CITY\\nClick to view detailed forecast\"}"
        exit 0
    fi
fi

# Fetch new weather data
weather_text=$(get_weather)
if [ $? -eq 0 ] && [ -n "$weather_text" ]; then
    # Extract condition for icon
    condition=$(echo "$weather_text" | cut -d' ' -f2-)
    weather_icon=$(get_weather_icon "$condition")
    echo "{\"text\": \"$weather_icon $weather_text\", \"tooltip\": \"Weather in $CITY\\nClick to view detailed forecast\"}"
else
    # Fallback to cached data or error message
    cached_weather=$(get_cached_weather)
    if [ -n "$cached_weather" ]; then
        # Extract condition for icon
        condition=$(echo "$cached_weather" | cut -d' ' -f2-)
        weather_icon=$(get_weather_icon "$condition")
        echo "{\"text\": \"$weather_icon $cached_weather\", \"tooltip\": \"Weather in $CITY (cached)\\nClick to view detailed forecast\"}"
    else
        echo "{\"text\": \"󰖕 No data\", \"tooltip\": \"Unable to fetch weather data\"}"
    fi
fi
