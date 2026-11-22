#!/bin/bash
# ==========================================================
# SoftEther VPN Client Modular Manager (Combined Final)
# - Interactive menu: Import&Connect or Full Reset (flush)
# - Bruteforce flush removes all accounts, NICs, routes and config files
# - Import uses basename of .vpn file (no absolute path)
# - Wait for NIC to appear before assigning IP
#
# CHANGES:
# [FIX] import_account: pre-check existing account by exact name
#       to prevent duplicate "(2)" entries on re-import
# [NEW] bind_nic_and_connect: AccountStartupSet added after NicSet
#       so vpnclient daemon auto-connects this account on service start
# [FIX] install_route_service: replaced ip monitor (race condition at boot)
#       with existence-check loop modeled after VPN server tap bind script.
#       Loop polls ip link show until interface exists, then checks idempotency
#       before applying IP and routes. No timing assumption, no missed events.
# [FIX] vpn-route-apply.sh: ACTUAL_IFACE now resolved inside loop, not before.
#       Previously resolved at script start before interface existed, causing
#       loop to poll wrong interface name (vpn instead of vpn_vpn) indefinitely.
# [FIX] flush_all: also disables and removes route persistence service
#       and saved route file on full reset
# [FIX] vpn-route-apply.service: changed from Type=simple + Restart=always
#       to Type=oneshot + RemainAfterExit=yes. IP and route persist on the
#       interface even after VPN disconnect (Linux assigns to NIC, not tunnel),
#       so one-shot apply at boot is sufficient. No restart loop needed.
# [FIX] import_account: AccountImport names the resulting account from the
#       "VPN Connection Setting Name" embedded inside the .vpn file, not from
#       the filename. Now unconditionally clears whatever account(s) exist
#       first, then reads back the single account that resulted from
#       AccountImport — no filename-based guessing.
# [NEW] stop_and_delete_account: AccountDelete silently no-ops on an account
#       that is Connecting/Online (e.g. one left auto-starting via a prior
#       AccountStartupSet). Now runs AccountStartupRemove + AccountDisconnect
#       before every AccountDelete, with up to 3 retries and a hard
#       verification that the account list is actually empty before importing.
# [FIX] main(): import_account's failure/error return is now checked, so a
#       failed import aborts with [FATAL] instead of connecting a stale
#       account.
# [NEW] apply_static_ip_and_route: prompts for "IP/prefix" (validated IPv4,
#       prefix 8-30, not the network/broadcast address); netmask, subnet and
#       gateway (first host of the subnet) are DERIVED from what was typed.
# [FIX] vpn-route-apply.sh: idempotency check matches "IP/prefix" (not just
#       the IP), so re-running with a different prefix is re-applied.
# [FIX] ip addr add (+ vpn-route-apply.sh): added "brd +" so the broadcast
#       address is set; the idempotency check also requires "brd".
# [CHANGE] Section 0 (default network params) removed: there are NO default
#       IP / prefix / netmask / gateway / subnet anymore. The user MUST type
#       "IP/prefix" manually (example: 10.20.0.100/24). Blank input or input
#       without "/prefix" is rejected and asked again — no silent fallback.
# [CHANGE] VPN_NIC_NAME is now "softether". SoftEther names the Linux tap
#       device "vpn_<NICNAME>" (-> vpn_softether), so every interface lookup
#       now uses vpn_${VPN_NIC_NAME} instead of the old ${VPN_NIC_NAME}_vpn
#       pattern (which only worked by coincidence when the NIC was "vpn").
# [NEW] detect_vpn_file: .vpn files are now also detected in /home/<user>
#       (one level deep, e.g. /home/benny/xxx.vpn), besides /usr/local/vpnclient and /opt.
# [REMOVE] Proxmox option removed (configure_proxmox_interfaces,
#       resolve_actual_iface, show_summary_proxmox). Menu renumbered:
#       1) Import & Connect VPN, 2) Full Reset, 3) Exit.
# ==========================================================

VPNCMD="/usr/local/vpnclient/vpncmd"
VPNCLIENT="/usr/local/vpnclient/vpnclient"
VPNDIR="/usr/local/vpnclient"

# Only the NIC name is fixed (SoftEther names the Linux tap device "vpn_<NICNAME>"). IP, prefix, netmask, gateway and subnet have NO
# default: they are filled in by parse_vpn_cidr from what the user types.
VPN_NIC_NAME="softether"   # Linux iface becomes vpn_<name> -> vpn_softether (13 chars, limit 15)
VPN_STATIC_IP=""
VPN_PREFIX=""
VPN_NETMASK=""
VPN_GATEWAY=""
VPN_SUBNET=""

log() { echo -e "[`date +%H:%M:%S`] $*"; }
require_root() { [ "$(id -u)" -eq 0 ] || { echo "Run as root (sudo $0)"; exit 1; }; }

trim() { echo "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

# ==========================================================
# CIDR HELPERS (pure bash, no extra packages)
# ==========================================================
valid_ipv4() {
    local ip="$1" o
    [[ "$ip" =~ ^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$ ]] || return 1
    for o in "${BASH_REMATCH[@]:1}"; do
        (( 10#$o <= 255 )) || return 1
    done
    return 0
}

ip_to_int() {
    local a b c d
    IFS=. read -r a b c d <<< "$1"
    echo $(( (10#$a << 24) | (10#$b << 16) | (10#$c << 8) | 10#$d ))
}

int_to_ip() {
    local n="$1"
    echo "$(( (n >> 24) & 255 )).$(( (n >> 16) & 255 )).$(( (n >> 8) & 255 )).$(( n & 255 ))"
}

# Validate "A.B.C.D/N" and, only if valid, set the globals:
#   VPN_STATIC_IP, VPN_PREFIX, VPN_NETMASK, VPN_SUBNET, VPN_GATEWAY
# On failure returns 1 and puts the reason in CIDR_ERR (globals untouched).
# Gateway = first host of the subnet (10.20.0.100/24 -> 10.20.0.1).
parse_vpn_cidr() {
    local cidr="$1" ip prefix ip_int mask_int net_int bcast_int
    ip="${cidr%/*}"
    prefix="${cidr#*/}"

    valid_ipv4 "$ip" || { CIDR_ERR="format IP tidak valid: '$ip'"; return 1; }
    if ! [[ "$prefix" =~ ^[0-9]{1,2}$ ]] || (( 10#$prefix < 8 || 10#$prefix > 30 )); then
        CIDR_ERR="prefix harus angka 8-30 (contoh /24 atau /20), dapat: '/$prefix'"
        return 1
    fi
    prefix=$((10#$prefix))

    ip_int=$(ip_to_int "$ip")
    mask_int=$(( (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF ))
    net_int=$(( ip_int & mask_int ))
    bcast_int=$(( net_int | (~mask_int & 0xFFFFFFFF) ))

    if [ "$ip_int" -eq "$net_int" ] || [ "$ip_int" -eq "$bcast_int" ]; then
        CIDR_ERR="$ip adalah alamat network/broadcast dari $(int_to_ip "$net_int")/$prefix, pilih IP host"
        return 1
    fi

    VPN_STATIC_IP=$(int_to_ip "$ip_int")   # normalised (strips leading zeros like 015)
    VPN_PREFIX="$prefix"
    VPN_NETMASK=$(int_to_ip "$mask_int")
    VPN_SUBNET="$(int_to_ip "$net_int")/$prefix"
    VPN_GATEWAY=$(int_to_ip $(( net_int + 1 )))
    return 0
}

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
            ip link delete "vpn_${nic}" >/dev/null 2>&1 || true
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

    log "Removing route persistence service if exists..."
    systemctl disable vpn-route-apply.service >/dev/null 2>&1 || true
    systemctl stop vpn-route-apply.service >/dev/null 2>&1 || true
    rm -f /etc/systemd/system/vpn-route-apply.service
    rm -f "$VPNDIR/vpn-route-apply.sh"
    systemctl daemon-reload >/dev/null 2>&1 || true

    log "Starting vpnclient service fresh..."
    $VPNCLIENT start >/dev/null 2>&1 || true
    sleep 1

    log "✅ Cleanup successful."
}

# ==========================================================
# IMPORT & CONNECT
# ==========================================================
detect_vpn_file() {
    log "Searching for .vpn files in /usr/local/vpnclient, /opt and /home/<user>..."
    mapfile -t vpn_files < <(
        {
            find /usr/local/vpnclient /opt -maxdepth 1 -type f -name "*.vpn"
            find /home -mindepth 2 -maxdepth 2 -type f -name "*.vpn"
        } 2>/dev/null
    )
    (( ${#vpn_files[@]} )) || { echo "[ERROR] No .vpn files found in /usr/local/vpnclient, /opt or /home/<user>"; exit 1; }
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
        if ip link show "$VPN_NIC_NAME" >/dev/null 2>&1 || ip link show "vpn_${VPN_NIC_NAME}" >/dev/null 2>&1; then
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

stop_and_delete_account() {
    local acc="$1"
    log "Stopping and removing existing account: $acc"
    # An account previously marked as Startup (AccountStartupSet, done by
    # bind_nic_and_connect) gets auto-reconnected by the vpnclient daemon the
    # instant the service (re)starts — often *before* this function even runs.
    # AccountDelete silently no-ops on an account that is Connecting/Online,
    # so it must be un-flagged and disconnected first, or the delete below
    # does nothing and the stale account survives to shadow the next import.
    $VPNCMD localhost /CLIENT /CMD AccountStartupRemove "$acc" >/dev/null 2>&1 || true
    $VPNCMD localhost /CLIENT /CMD AccountDisconnect "$acc" >/dev/null 2>&1 || true
    sleep 1
    $VPNCMD localhost /CLIENT /CMD AccountDelete "$acc" >/dev/null 2>&1 || true
}

import_account() {
    # NOTE: AccountImport names the resulting account from the "VPN Connection
    # Setting Name" embedded inside the .vpn file at export time — NOT from the
    # .vpn filename. So VPN_ACCOUNT_NAME (derived from the filename here) can
    # never be trusted to match what SoftEther will actually call the account,
    # and checking existence against it is a no-op that lets a stale account
    # with the *real* embedded name silently block/shadow a fresh import.
    # Fix: always clear whatever account(s) currently exist before importing,
    # so there is nothing left to collide with, then read back whichever single
    # account resulted — that is unambiguously the one we just imported.
    log "Clearing existing VPN account(s) before import (avoids stale/duplicate re-import)..."

    for attempt in 1 2 3; do
        existing=$($VPNCMD localhost /CLIENT /CMD AccountList 2>/dev/null \
            | awk -F'|' '/VPN Connection Setting Name/ {print $2}' \
            | sed 's/^[ \t]*//;s/[ \t]*$//')
        [ -z "$existing" ] && break

        while IFS= read -r acc; do
            [ -z "$acc" ] && continue
            stop_and_delete_account "$acc"
        done <<< "$existing"
        sleep 1
    done

    remaining=$($VPNCMD localhost /CLIENT /CMD AccountList 2>/dev/null \
        | awk -F'|' '/VPN Connection Setting Name/ {print $2}' \
        | sed 's/^[ \t]*//;s/[ \t]*$//')
    if [ -n "$remaining" ]; then
        log "[ERROR] Could not remove existing account(s) after 3 attempts, still present: $remaining"
        log "[ERROR] They may still be reconnecting via auto-startup. Manually run:"
        log "[ERROR]   $VPNCMD localhost /CLIENT /CMD AccountStartupRemove <name>"
        log "[ERROR]   $VPNCMD localhost /CLIENT /CMD AccountDisconnect <name>"
        log "[ERROR]   $VPNCMD localhost /CLIENT /CMD AccountDelete <name>"
        return 1
    fi

    log "Importing VPN account from: $CONFIG_FILE"
    cd "$CONFIG_DIR" || { log "Cannot cd to $CONFIG_DIR"; exit 1; }
    $VPNCMD localhost /CLIENT /CMD AccountImport "$CONFIG_BASENAME" >/dev/null 2>&1 || true
    sleep 2

    imported_list=$($VPNCMD localhost /CLIENT /CMD AccountList 2>/dev/null \
        | awk -F'|' '/VPN Connection Setting Name/ {print $2}' \
        | sed 's/^[ \t]*//;s/[ \t]*$//')
    imported_count=$(echo "$imported_list" | grep -c .)

    if [ "$imported_count" -ne 1 ]; then
        log "[ERROR] Expected exactly 1 account after import, found $imported_count: $imported_list"
        return 1
    fi

    VPN_ACCOUNT_NAME="$imported_list"
    log "Imported account: '$VPN_ACCOUNT_NAME'"
}

bind_nic_and_connect() {
    log "Binding NIC '$VPN_NIC_NAME' to account '$VPN_ACCOUNT_NAME'..."
    $VPNCMD localhost /CLIENT /CMD AccountNicSet "$VPN_ACCOUNT_NAME" /NICNAME:$VPN_NIC_NAME >/dev/null 2>&1 || true
    sleep 1

    log "Setting account '$VPN_ACCOUNT_NAME' as startup (auto-connect on service start)..."
    $VPNCMD localhost /CLIENT /CMD AccountStartupSet "$VPN_ACCOUNT_NAME" >/dev/null 2>&1 || true

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
    elif ip link show "vpn_${iface}" >/dev/null 2>&1; then
        actual_iface="vpn_${iface}"
    else
        actual_iface="$iface"
    fi

    wait_for_nic || true

    # No default: the user must type IP/prefix by hand. Blank input and input
    # without "/prefix" are rejected and asked again.
    local input_cidr
    while true; do
        read -rp "Masukkan IP static + prefix untuk VPN client (wajib diisi manual, contoh: 10.20.0.100/24): " input_cidr \
            || { log "[FATAL] Input dibatalkan."; exit 1; }
        input_cidr=$(trim "$input_cidr")
        if [ -z "$input_cidr" ]; then
            log "[ERROR] Input tidak boleh kosong. Tulis manual dengan format IP/prefix, contoh: 10.20.0.100/24"
            continue
        elif [[ "$input_cidr" != */* ]]; then
            log "[ERROR] Prefix wajib ditulis (format IP/prefix), contoh: 10.20.0.100/24"
            continue
        fi
        if parse_vpn_cidr "$input_cidr"; then
            break
        fi
        log "[ERROR] $CIDR_ERR — coba lagi."
    done
    log "Network diturunkan dari input: subnet $VPN_SUBNET, netmask $VPN_NETMASK, gateway $VPN_GATEWAY"

    log "Assigning static IP $VPN_STATIC_IP/$VPN_PREFIX ($VPN_NETMASK) to interface $actual_iface..."
    ip addr flush dev "$actual_iface" >/dev/null 2>&1 || true
    ip addr add "$VPN_STATIC_IP/$VPN_PREFIX" brd + dev "$actual_iface" >/dev/null 2>&1 || true

    log "Adding route to VPN gateway $VPN_GATEWAY via $actual_iface..."
    ip route replace "$VPN_GATEWAY"/32 dev "$actual_iface" >/dev/null 2>&1 || true

    log "Adding route to VPN subnet $VPN_SUBNET via $actual_iface..."
    ip route replace "$VPN_SUBNET" dev "$actual_iface" >/dev/null 2>&1 || true

    log "Leaving default route untouched (split-tunnel preserved)."
    log "Routing table now:"
    ip route show | grep -E "default|$VPN_SUBNET|$VPN_GATEWAY" || true
}

# ==========================================================
# ROUTE PERSISTENCE SERVICE
# [FIX] Type=oneshot + RemainAfterExit=yes, tanpa Restart=always.
#       IP dan route tetap nempel di interface meskipun VPN disconnect
#       (Linux assign ke NIC, bukan ke tunnel). One-shot apply saat boot
#       sudah cukup — tidak perlu restart loop setiap 5 detik.
# ==========================================================
install_route_service() {
    local service_file="/etc/systemd/system/vpn-route-apply.service"
    local script_copy="$VPNDIR/vpn-route-apply.sh"

    log "Installing VPN route persistence service..."

    cat > "$script_copy" << EOF
#!/bin/bash
VPN_NIC_NAME="$VPN_NIC_NAME"
VPN_STATIC_IP="$VPN_STATIC_IP"
VPN_PREFIX="$VPN_PREFIX"
VPN_GATEWAY="$VPN_GATEWAY"
VPN_SUBNET="$VPN_SUBNET"

# Resolve actual iface name inside loop, not before.
# At script start, neither vpn nor vpn_vpn may exist yet.
# Loop checks both candidate names each iteration;
# exits as soon as either appears.
ACTUAL_IFACE=""
until [ -n "\$ACTUAL_IFACE" ]; do
    if ip link show "vpn_\${VPN_NIC_NAME}" >/dev/null 2>&1; then
        ACTUAL_IFACE="vpn_\${VPN_NIC_NAME}"
    elif ip link show "\${VPN_NIC_NAME}" >/dev/null 2>&1; then
        ACTUAL_IFACE="\${VPN_NIC_NAME}"
    fi
    [ -z "\$ACTUAL_IFACE" ] && sleep 1
done

# Idempotency: skip IP assign only if the exact IP/prefix is already configured
# (matching the prefix too, so a /24 -> /16 change is not skipped as "present").
if ! ip addr show "\$ACTUAL_IFACE" | grep -q "inet \${VPN_STATIC_IP}/\${VPN_PREFIX} brd "; then
    ip addr flush dev "\$ACTUAL_IFACE" 2>/dev/null
    ip addr add "\${VPN_STATIC_IP}/\${VPN_PREFIX}" brd + dev "\$ACTUAL_IFACE" 2>/dev/null
    echo "[vpn-route] IP \${VPN_STATIC_IP}/\${VPN_PREFIX} assigned to \$ACTUAL_IFACE"
else
    echo "[vpn-route] IP \${VPN_STATIC_IP}/\${VPN_PREFIX} already present on \$ACTUAL_IFACE, skipping"
fi

# Idempotency: skip gateway route if already present
if ! ip route | grep -q "\$VPN_GATEWAY"; then
    ip route replace "\${VPN_GATEWAY}/32" dev "\$ACTUAL_IFACE" 2>/dev/null
    echo "[vpn-route] Gateway route \$VPN_GATEWAY added"
fi

# Idempotency: skip subnet route if already present
if ! ip route | grep -q "\$VPN_SUBNET"; then
    ip route replace "\$VPN_SUBNET" dev "\$ACTUAL_IFACE" 2>/dev/null
    echo "[vpn-route] Subnet route \$VPN_SUBNET added"
fi

echo "[vpn-route] Done on \$ACTUAL_IFACE"
EOF

    chmod +x "$script_copy"

    cat > "$service_file" << EOF
[Unit]
Description=Restore VPN static IP and routes after SoftEther auto-connect
# No After= network dependency — waits for interface internally via loop.
# vpnclient daemon (AccountStartupSet) brings up interface when ready.

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=$script_copy

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable vpn-route-apply.service >/dev/null 2>&1
    systemctl restart vpn-route-apply.service >/dev/null 2>&1
    log "✅ vpn-route-apply.service installed, enabled, and started."
}

show_summary() {
    echo "=========================================================="
    echo "[SUCCESS] VPN Client connected/configured (summary):"
    printf "%-18s : %s\n" "Account" "$VPN_ACCOUNT_NAME"
    printf "%-18s : %s\n" "NIC (softether)" "$VPN_NIC_NAME"
    printf "%-18s : %s\n" "Static IP" "$VPN_STATIC_IP/$VPN_PREFIX"
    printf "%-18s : %s\n" "Netmask" "$VPN_NETMASK"
    printf "%-18s : %s\n" "VPN Gateway" "$VPN_GATEWAY"
    printf "%-18s : %s\n" "VPN Subnet" "$VPN_SUBNET"
    printf "%-18s : %s\n" "Local gateway" "$(ip route | awk '/default/ {print $3; exit}')"
    printf "%-18s : %s\n" "Route service" "$(systemctl is-active vpn-route-apply.service 2>/dev/null || echo 'not installed')"
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
        import_account || { log "[FATAL] Import failed — aborting instead of connecting with a stale/wrong account."; exit 1; }
        bind_nic_and_connect
        apply_static_ip_and_route
        install_route_service
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