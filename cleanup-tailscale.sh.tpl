#!/bin/bash
set -e  # Exit on error

# Get device ID if it exists
DEVICE_ID=$(curl "https://api.tailscale.com/api/v2/tailnet/-/devices" \
  -u "${tailscale_api_key}:" \
  | jq -r ".devices[] | select(.hostname == \"${tailscale_hostname}\") | .nodeId")

# Delete device if found
if [ ! -z "$DEVICE_ID" ]; then
  echo "Found existing device, deleting..."
  curl -X DELETE "https://api.tailscale.com/api/v2/device/$DEVICE_ID" \
    -H "Authorization: Bearer ${tailscale_api_key}"
fi
