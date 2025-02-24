#!/bin/bash
set -e

# Validate required environment variables
[ -z "$NETWORK_IDS" ] && { echo "ERROR: NETWORK_IDS not set"; exit 1; }
[ -z "$ZTAUTHTOKEN" ] && { echo "ERROR: ZTAUTHTOKEN not set"; exit 1; }

# Start zerotier in background
zerotier-one -d

# Wait for ZeroTier daemon to initialize
sleep 5

for NETWORK_ID in $(echo "$NETWORK_IDS" | tr ',' '\n'); do
  # Retry joining network with timeout
  MAX_RETRIES=5
  RETRY_COUNT=0
  until zerotier-cli join "$NETWORK_ID" || [ $RETRY_COUNT -eq $MAX_RETRIES ]; do
    echo "Join attempt $((RETRY_COUNT+1))/$MAX_RETRIES failed, retrying..."
    RETRY_COUNT=$((RETRY_COUNT+1))
    sleep 5
  done

  if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "Failed to join network $NETWORK_ID after $MAX_RETRIES attempts"
    exit 1
  fi

  # Auto-accept logic
  if [ "$AUTOJOIN" == "true" ]; then
    HOST_ID="$(zerotier-cli info | awk '{print $3}')"
    curl -s -XPOST \
      -H "Authorization: Bearer $ZTAUTHTOKEN" \
      -d "{\"hidden\":false,\"config\":{\"authorized\":true},\"name\":\"${ZTHOSTNAME:-}\"}" \
      "https://my.zerotier.com/api/network/$NETWORK_ID/member/$HOST_ID"
  fi

  # Wait for IP assignment (check both interface and IP)
  IP_FOUND=0
  while [ $IP_FOUND -lt 1 ]; do
    ZTDEV=$(ip -o link show | awk -F': ' '/zt/{print $2}' | head -1)
    if [ -n "$ZTDEV" ]; then
      IP_FOUND=$(ip addr show dev $ZTDEV | grep -c 'inet')
    fi
    sleep 5
    echo "Waiting for ZeroTier IP assignment on $ZTDEV..."
  done
done

# Networking setup
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

exec tail -f /dev/null