#!/bin/bash

# Default configuration (can be overridden with environment variables)
START_CMD="${PALWORLD_START_CMD:-./PalServer.sh -publiclobby -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS}"
DISCORD_WEBHOOK="${DISCORD_WEBHOOK:-}"
ROLE_ID="${DISCORD_ROLE_ID:-}"
RESTART_INTERVAL="${RESTART_INTERVAL:-20700}"  # 5 hours and 45 minutes in seconds
RESTART_WARNING_TIME="${RESTART_WARNING_TIME:-900}"  # 15 minutes in seconds

# Function to start the server
start_server() {
    echo "Starting $SERVER_NAME at $(date)"
    $START_CMD &
    send_discord_notification "$SERVER_NAME has started!"
}

# Function to stop the server
stop_server() {
    echo "Stopping $SERVER_NAME at $(date)..."
    send_discord_notification "$SERVER_NAME is stopping for a restart. It will be back soon!"
    pkill -f PalServer
    while pgrep -f PalServer > /dev/null; do
        sleep 1
    done
    echo "$SERVER_NAME stopped."
}

# Function to send Discord notification
send_discord_notification() {
    if [ -z "$DISCORD_WEBHOOK" ]; then
        echo "Discord notifications are disabled (DISCORD_WEBHOOK is not set)"
        return
    fi
    
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

# Trap for graceful shutdown
trap 'stop_server; exit 0' SIGTERM SIGINT

# Main loop
while true; do
    start_server
    
    # Run for the specified interval
    sleep $RESTART_INTERVAL &
    wait $!
    
    # Send warning notification before restart
    send_discord_notification "$SERVER_NAME will restart in $(($RESTART_WARNING_TIME / 60)) minutes!"
    
    # Wait for the warning period
    sleep $RESTART_WARNING_TIME &
    wait $!
    
    stop_server
    
    # Wait 30 seconds before restarting
    sleep 30
done
