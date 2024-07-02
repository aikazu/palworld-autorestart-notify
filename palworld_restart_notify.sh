#!/bin/bash

# Default configuration (can be overridden with environment variables)
DISCORD_WEBHOOK="${DISCORD_WEBHOOK:-}"
ROLE_ID="${DISCORD_ROLE_ID:-}"
RESTART_INTERVAL="${RESTART_INTERVAL:-20700}"  # 5 hours and 45 minutes in seconds
RESTART_WARNING_TIME="${RESTART_WARNING_TIME:-900}"  # 15 minutes in seconds
START_CMD="${PALWORLD_START_CMD:-./PalServer.sh -publiclobby -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS}"

# Function to send Discord notification
send_discord_notification() {
    if [ -z "$DISCORD_WEBHOOK" ]; then
        echo "Discord notifications are disabled (DISCORD_WEBHOOK is not set)"
        return
    }
    
    local message="$1"
    [ -n "$ROLE_ID" ] && message="<@&$ROLE_ID> $message"
    
    local response
    response=$(curl -s -w "\n%{http_code}" -H "Content-Type: application/json" -X POST -d "{\"content\":\"${message//\"/\\\"}\"}" "$DISCORD_WEBHOOK")
    local body=$(echo "$response" | sed '$d')
    local status_code=$(echo "$response" | tail -n1)
    
    if [ "$status_code" -ne 204 ]; then
        echo "Failed to send Discord notification. Status code: $status_code, Response: $body" >&2
    else
        echo "Discord notification sent successfully."
    fi
}

# Function to stop the server
stop_server() {
    echo "Stopping Palworld server at $(date)..."
    pkill -f PalServer
    timeout 60 bash -c 'while pgrep -f PalServer > /dev/null; do sleep 1; done'
    if pgrep -f PalServer > /dev/null; then
        echo "Force stopping Palworld server..."
        pkill -9 -f PalServer
    fi
    echo "Palworld server stopped."
}

# Function to start the server
start_server() {
    echo "Starting Palworld server at $(date)"
    $START_CMD &
    send_discord_notification "The Palworld server has been started and is now online!"
}

# Function to restart the server
restart_server() {
    send_discord_notification "The Palworld server is restarting. It will be back soon!"
    stop_server
    start_server
}

# Trap for graceful exit
trap 'echo "Script terminated."; exit 0' SIGTERM SIGINT

# Main loop
while true; do
    next_restart=$(date -d "+ $RESTART_INTERVAL seconds" +"%Y-%m-%d %H:%M:%S")
    echo "Next restart scheduled at: $next_restart"
    
    sleep $((RESTART_INTERVAL - RESTART_WARNING_TIME))
    
    # Send warning notification before restart
    warning_minutes=$((RESTART_WARNING_TIME / 60))
    send_discord_notification "The Palworld server will restart in $warning_minutes minutes!"
    
    sleep $RESTART_WARNING_TIME
    
    restart_server
done