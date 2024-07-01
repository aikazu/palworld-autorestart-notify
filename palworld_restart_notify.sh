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
    if [ -n "$ROLE_ID" ]; then
        message="<@&$ROLE_ID> $message"
    fi
    
    local response
    response=$(curl -s -w "\n%{http_code}" -H "Content-Type: application/json" -X POST -d "{\"content\":\"$message\"}" "$DISCORD_WEBHOOK")
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
    while pgrep -f PalServer > /dev/null; do
        sleep 1
    done
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
    # Wait for the restart interval
    sleep $RESTART_INTERVAL &
    wait $!
    
    # Send warning notification before restart
    send_discord_notification "The Palworld server will restart in $(($RESTART_WARNING_TIME / 60)) minutes!"
    
    # Wait for the warning period
    sleep $RESTART_WARNING_TIME &
    wait $!
    
    restart_server
done
