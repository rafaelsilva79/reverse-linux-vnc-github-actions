#!/bin/bash

# Usage: ./tunnel.sh <service: pinggy|serveo> <type: http|tcp> <port>
# Example: ./tunnel.sh pinggy tcp 3000
#          ./tunnel.sh serveo http 8080

SERVICE=$1
TYPE=$2
PORT=$3

# Github actions
if [[ "$GITHUB_ACTIONS" == "true" && -z "$SSH_TUNNEL" ]]; then
  echo "Warning: SSH_TUNNEL is missing or has no value"
  exit 1
fi

# Validate input
if [[ -z "$SERVICE" || -z "$TYPE" || -z "$PORT" ]]; then
  echo "Usage: $0 <service: pinggy|serveo> <type: http|tcp> <port>"
  exit 1
fi

if [[ "$SERVICE" != "pinggy" && "$SERVICE" != "serveo" ]]; then
  echo "Error: Service must be 'pinggy' or 'serveo'"
  exit 1
fi

if [[ "$TYPE" != "http" && "$TYPE" != "tcp" ]]; then
  echo "Error: Type must be 'http' or 'tcp'"
  exit 1
fi

if [[ "$SERVICE" == "serveo" && "$TYPE" == "tcp" ]]; then
  echo "Error: TCP mode is not supported with Serveo"
  exit 1
fi

# Create temp log file
LOGFILE=$(mktemp)

# Configure SSH destination and remote forwarding
case "$SERVICE:$TYPE" in
  pinggy:http)
    SSH_PORT=443
    DEST="free.pinggy.io"
    REMOTE="-R0:localhost:$PORT"
    ;;
  pinggy:tcp)
    SSH_PORT=443
    DEST="tcp@free.pinggy.io"
    REMOTE="-R0:localhost:$PORT"
    ;;
  serveo:http)
    SSH_PORT=22
    DEST="serveo.net"
    REMOTE="-R 80:localhost:$PORT"
    ;;
esac

# Establishes the connection
ssh -T -p $SSH_PORT \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  $REMOTE $DEST > "$LOGFILE" 2>&1 &

# Wait briefly for output
sleep 3

# Extract and display URL
if [[ "$SERVICE" == "pinggy" ]]; then
  URL=$(grep -oE '(https|tcp)://[a-zA-Z0-9.-]+\.pinggy\.link(:[0-9]+)?' "$LOGFILE" | head -n 1)
else
  URL=$(grep -oE 'https://[a-zA-Z0-9.-]+\.serveo\.net' "$LOGFILE" | head -n 1)
fi

if [[ -z "$URL" ]]; then
  echo "Error: Failed to retrieve tunnel URL."
else
  echo "Tunnel URL: $URL"
fi

# Delete the log file
rm "$LOGFILE"
