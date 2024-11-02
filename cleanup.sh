#!/bin/bash
set -e  # Exit on error
set -x

echo "$TAILSCALE_API_KEY";
echo "$TAILSCALE_HOSTNAME";
output=$(curl "https://api.tailscale.com/api/v2/tailnet/-/devices" \
  -u "$TAILSCALE_API_KEY:")
echo $output
# Get device ID if it exists
DEVICE_ID=$(curl "https://api.tailscale.com/api/v2/tailnet/-/devices" \
  -u "$TAILSCALE_API_KEY:" \
  | jq -r ".devices[] | select(.hostname == \"$TAILSCALE_HOSTNAME\") | .nodeId")


# Delete device if found
if [ ! -z "$DEVICE_ID" ]; then
  echo "Found existing device, deleting..."
  curl -X DELETE "https://api.tailscale.com/api/v2/device/$DEVICE_ID" \
    -H "Authorization: Bearer $TAILSCALE_API_KEY"
fi
