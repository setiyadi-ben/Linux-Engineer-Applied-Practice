#!/bin/bash

# Configuration
TAP_IF="tap_softether"
IP_ADDR="10.20.0.2"
GATEWAY="10.20.0.1"
BROADCAST="10.20.15.255"
MASK="255.255.240.0"

# Check if the adapter exists
if ip link show $TAP_IF &>/dev/null; then
    # Check if IP is already configured
    if ! ip addr show $TAP_IF | grep -q "$IP_ADDR"; then
        # If IP is not configured, bind the IP, set the broadcast, and bring the interface up
        ip addr add $IP_ADDR/$MASK brd $BROADCAST dev $TAP_IF
        ip link set $TAP_IF up
        echo "IP $IP_ADDR bound to $TAP_IF, interface is now up."
    else
        echo "IP $IP_ADDR is already configured on $TAP_IF."
    fi

    # Check if the default route is already set
    if ! ip route | grep -q "default via $GATEWAY"; then
        # If the route is not set, add the default route
        ip route add default via $GATEWAY
        echo "Default route added via $GATEWAY."
    else
        echo "Default route already exists via $GATEWAY."
    fi
else
    echo "$TAP_IF not found, please create the adapter via SoftEther."
fi
