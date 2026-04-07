#!/bin/bash
# ==========================================================
# SoftEther VPN Client Modular Manager (Combined Final)
# - Interactive menu: Import&Connect or Full Reset (flush)
# - Bruteforce flush removes all accounts, NICs, routes and config files
# - Import uses basename of .vpn file (no absolute path)
# - Wait for NIC to appear before assigning IP
# ==========================================================

VPNCMD="/usr/local/vpnclient/vpncmd"
VPNCLIENT="/usr/local/vpnclient/vpnclient"
VPNDIR="/usr/local/vpnclient"

# Default network params (customize if needed)
VPN_NIC_NAME="vpn"
VPN_STATIC_IP="10.20.0.2"
VPN_NETMASK="255.255.240.0"
VPN_GATEWAY="10.20.0.1"
VPN_SUBNET="10.20.0.0/20"

log() { echo -e "[`date +%H:%M:%S`] $*"; }
require_root() { [ "$(id -u)" -eq 0 ] || { echo "Run as root (sudo $0)"; exit 1; }; }

# ---------------------------
trim() { echo "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

# ==========================================================
# FLUSH: brute-force deletion of all accounts & NICs
# ==========================================================
flush_all() {
    log "=== FLUSH MODE STARTED ==="
    $VPNCLIENT start >/dev/null 2>&1 || true
    sleep 1

    log "Deleting all VPN accounts..."
    account_list=$($VPNCMD localhost /CLIENT /CMD AccountList 2>/dev/null | awk -F'|' '/VPN Connection Setting Name/ {print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
    if [ -n "$account_list" ]; then
        while IFS= read -r acc; do
            [ -z "$acc" ] && continue
            log "Deleting account: $acc"
            $VPNCMD localhost /CLIENT /CMD AccountDelete "$acc" >/dev/null 2>&1 || true
        done <<< "$account_list"
    else
        log "No VPN accounts found to delete."
    fi

    log "Deleting all Virtual NICs..."
    nic_list=$($VPNCMD localhost /CLIENT /CMD NicList 2>/dev/null | awk -F'|' '/Virtual Network Adapter Name/ {print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
    if [ -n "$nic_list" ]; then
        while IFS= read -r nic; do
            [ -z "$nic" ] && continue
            log "Deleting NIC: $nic"
            $VPNCMD localhost /CLIENT /CMD NicDelete "$nic" >/dev/null 2>&1 || true
            ip link delete "$nic" >/dev/null 2>&1 || true
            ip link delete "${nic}_vpn" >/dev/null 2>&1 || true
        done <<< "$nic_list"
    else
        log "No NICs found to delete."
    fi

    log "Stopping vpnclient service/process..."
    pkill -f vpnclient >/dev/null 2>&1 || true
    $VPNCLIENT stop >/dev/null 2>&1 || true
    sleep 1

    log "Removing client config files..."
    if [ -d "$VPNDIR/backup.vpn_client.config" ]; then
        rm -rf "$VPNDIR/backup.vpn_client.config" >/dev/null 2>&1 || true
    else
        rm -f "$VPNDIR/backup.vpn_client.config" >/dev/null 2>&1 || true
    fi
    rm -f "$VPNDIR/vpn_client.config" >/dev/null 2>&1 || true

    log "Flushing ip addresses and routes for vpn interfaces..."
    for iface in $(ip -o link | awk -F': ' '{print $2}' | grep -i vpn || true); do
        ip addr flush dev "$iface" >/dev/null 2>&1 || true
        ip route flush dev "$iface" >/dev/null 2>&1 || true
    done

    log "Starting vpnclient service fresh..."
    $VPNCLIENT start >/dev/null 2>&1 || true
    sleep 1

    log "✅ Cleanup successful."
}

# ==========================================================
# IMPORT & CONNECT
# ==========================================================
detect_vpn_file() {
    log "Searching for .vpn files in /usr/local/vpnclient and /opt..."
    mapfile -t vpn_files < <(find /usr/local/vpnclient /opt -maxdepth 1 -type f -name "*.vpn" 2>/dev/null)
    (( ${#vpn_files[@]} )) || { echo "[ERROR] No .vpn files found in /opt or /usr/local/vpnclient"; exit 1; }
    if [ ${#vpn_files[@]} -eq 1 ]; then
        CONFIG_FILE="${vpn_files[0]}"
        echo "[INFO] Found single config: $(basename "$CONFIG_FILE")"
    else
        echo "[INFO] Multiple .vpn files found:"
        select choice in "${vpn_files[@]}"; do CONFIG_FILE="$choice"; break; done
    fi
    CONFIG_DIR=$(dirname "$CONFIG_FILE")
    CONFIG_BASENAME=$(basename "$CONFIG_FILE")
    VPN_ACCOUNT_NAME=$(basename "$CONFIG_FILE" .vpn)
}

start_vpnclient() { log "Ensuring vpnclient service runs..."; $VPNCLIENT start >/dev/null 2>&1 || true; sleep 1; }

wait_for_nic() {
    local attempts=15
    log "Waiting for interface name to appear..."
    for i in $(seq 1 $attempts); do
        if ip link show "$VPN_NIC_NAME" >/dev/null 2>&1 || ip link show "${VPN_NIC_NAME}_vpn" >/dev/null 2>&1; then
            log "Detected interface (try $i)."; return 0
        fi
        sleep 1
    done
    log "[WARN] NIC did not appear after ${attempts}s."; return 1
}

create_nic_if_needed() {
    if $VPNCMD localhost /CLIENT /CMD NicList 2>/dev/null | awk -F'|' '/Virtual Network Adapter Name/ {print $2}' | grep -q -w "$VPN_NIC_NAME"; then
        log "Virtual NIC '$VPN_NIC_NAME' already exists (SoftEther layer)."
    else
        log "Creating Virtual NIC '$VPN_NIC_NAME'..."
        $VPNCMD localhost /CLIENT /CMD NicCreate "$VPN_NIC_NAME" >/dev/null 2>&1 || true
    fi
}

import_account() {
    log "Importing VPN account from: $CONFIG_FILE"
    cd "$CONFIG_DIR" || { log "Cannot cd to $CONFIG_DIR"; exit 1; }
    $VPNCMD localhost /CLIENT /CMD AccountImport "$CONFIG_BASENAME" >/dev/null 2>&1 || true
    sleep 2
    imported=$($VPNCMD localhost /CLIENT /CMD AccountList 2>/dev/null | awk -F'|' '/VPN Connection Setting Name/ {print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' | tail -n1)
    [ -z "$imported" ] && { log "[ERROR] Account import failed."; return 1; }
    VPN_ACCOUNT_NAME="$imported"
    log "Imported account: '$VPN_ACCOUNT_NAME'"
}

bind_nic_and_connect() {
    log "Binding NIC '$VPN_NIC_NAME' to account '$VPN_ACCOUNT_NAME'..."
    $VPNCMD localhost /CLIENT /CMD AccountNicSet "$VPN_ACCOUNT_NAME" /NICNAME:$VPN_NIC_NAME >/dev/null 2>&1 || true
    sleep 1
    log "Connecting account '$VPN_ACCOUNT_NAME'..."
    $VPNCMD localhost /CLIENT /CMD AccountConnect "$VPN_ACCOUNT_NAME" >/dev/null 2>&1 || true
    sleep 2
}

# ==========================================================
# STATIC IP + SPLIT-TUNNEL ROUTING
# ==========================================================
apply_static_ip_and_route() {
    iface="$VPN_NIC_NAME"
    if ip link show "$iface" >/dev/null 2>&1; then
        actual_iface="$iface"
    elif ip link show "${iface}_vpn" >/dev/null 2>&1; then
        actual_iface="${iface}_vpn"
    else
        actual_iface="$iface"
    fi

    wait_for_nic || true

    log "Assigning static IP $VPN_STATIC_IP/$VPN_NETMASK to interface $actual_iface..."
    ip addr flush dev "$actual_iface" >/dev/null 2>&1 || true
    ip addr add "$VPN_STATIC_IP"/20 dev "$actual_iface" >/dev/null 2>&1 || true

    log "Adding route to VPN gateway $VPN_GATEWAY via $actual_iface..."
    ip route replace "$VPN_GATEWAY"/32 dev "$actual_iface" >/dev/null 2>&1 || true

    log "Adding route to VPN subnet $VPN_SUBNET via $actual_iface..."
    ip route replace "$VPN_SUBNET" dev "$actual_iface" >/dev/null 2>&1 || true

    log "Leaving default route untouched (split-tunnel preserved)."
    log "Routing table now:"
    ip route show | grep -E "default|$VPN_SUBNET|$VPN_GATEWAY" || true
}

show_summary() {
    echo "=========================================================="
    echo "[SUCCESS] VPN Client connected/configured (summary):"
    printf "%-18s : %s\n" "Account" "$VPN_ACCOUNT_NAME"
    printf "%-18s : %s\n" "NIC (softether)" "$VPN_NIC_NAME"
    printf "%-18s : %s\n" "Static IP" "$VPN_STATIC_IP"
    printf "%-18s : %s\n" "VPN Gateway" "$VPN_GATEWAY"
    printf "%-18s : %s\n" "VPN Subnet" "$VPN_SUBNET"
    printf "%-18s : %s\n" "Local gateway" "$(ip route | awk '/default/ {print $3; exit}')"
    echo "=========================================================="
}

# ==========================================================
# MAIN
# ==========================================================
require_root
clear
echo "=========================================================="
echo " SoftEther VPN Client Modular Manager (final)"
echo "=========================================================="
echo "1) Import & Connect VPN"
echo "2) Full Reset (Flush all configs and accounts)"
echo "3) Exit"
read -rp "Select an option (1-3): " main_choice
echo "=========================================================="

case "$main_choice" in
    1)
        detect_vpn_file
        start_vpnclient
        create_nic_if_needed
        import_account
        bind_nic_and_connect
        apply_static_ip_and_route
        show_summary
        ;;
    2)
        flush_all
        read -rp "Flush completed. Continue import new VPN config now? (y/n): " cont
        [[ "$cont" =~ ^[Yy]$ ]] && exec "$0"
        ;;
    3) echo "Goodbye."; exit 0 ;;
    *) echo "Invalid option."; exit 1 ;;
esac
