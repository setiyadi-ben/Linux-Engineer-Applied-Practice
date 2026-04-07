#!/bin/bash
# =============================================================================
# setup-squid-ssh-proxy.sh
# Set up Squid as an HTTP CONNECT proxy for SSH tunneling
# Compatible: Debian, Ubuntu, and derivatives
# =============================================================================

set -e

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC}   $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERR]${NC}  $1"; exit 1; }
header()  { echo -e "\n${BOLD}==> $1${NC}"; }

# =============================================================================
# MODULE 1: Prerequisites
# =============================================================================
check_root() {
    header "Checking privileges"
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root. Use: sudo $0"
    fi
    success "Running as root"
}

check_os() {
    header "Checking OS"
    if [[ ! -f /etc/debian_version ]]; then
        warn "Not a Debian/Ubuntu system. Proceeding at your own risk."
    else
        OS_VER=$(cat /etc/debian_version)
        success "Debian/Ubuntu detected (version: $OS_VER)"
    fi
}

# =============================================================================
# MODULE 2: Interactive input
# =============================================================================
ask_port() {
    header "Squid listen port"
    echo "Default Squid port is 3128."
    echo "Choose a port that does not conflict with other services on this VPS."
    echo ""
    while true; do
        read -rp "Enter port [default: 3128]: " INPUT_PORT
        INPUT_PORT="${INPUT_PORT:-3128}"

        if ! [[ "$INPUT_PORT" =~ ^[0-9]+$ ]]; then
            warn "Not a number. Try again."
            continue
        fi

        if [[ "$INPUT_PORT" -lt 1 || "$INPUT_PORT" -gt 65535 ]]; then
            warn "Port must be between 1-65535. Try again."
            continue
        fi

        if ss -tlnp | grep -q ":${INPUT_PORT} "; then
            warn "Port $INPUT_PORT is already in use by another process."
            read -rp "Use it anyway? [y/N]: " FORCE
            [[ "${FORCE,,}" == "y" ]] && break || continue
        fi

        SQUID_PORT="$INPUT_PORT"
        success "Squid will listen on port: $SQUID_PORT"
        break
    done
}

ask_access_mode() {
    header "Access mode"
    echo "Select the access policy for this proxy:"
    echo ""
    echo "  1) Restricted  - CONNECT to port 22 only (SSH)"
    echo "                   Safest option, recommended for SSH tunneling only."
    echo ""
    echo "  2) Moderate    - CONNECT to common ports (22, 80, 443, 8080, 8443)"
    echo "                   More flexible tunnel usage."
    echo ""
    echo "  3) Custom      - Define allowed ports manually"
    echo ""
    echo "  4) Open        - CONNECT to all ports"
    echo "                   NOT recommended on a public VPS."
    echo ""

    while true; do
        read -rp "Choose [1/2/3/4, default: 1]: " ACCESS_CHOICE
        ACCESS_CHOICE="${ACCESS_CHOICE:-1}"
        case "$ACCESS_CHOICE" in
            1)
                ALLOWED_PORTS="22"
                ACCESS_LABEL="Restricted (port 22 only)"
                break
                ;;
            2)
                ALLOWED_PORTS="22 80 443 8080 8443"
                ACCESS_LABEL="Moderate (common ports)"
                break
                ;;
            3)
                read -rp "Enter allowed ports (space-separated, e.g.: 22 2222 443): " CUSTOM_PORTS
                if [[ -z "$CUSTOM_PORTS" ]]; then
                    warn "No ports entered. Try again."
                    continue
                fi
                ALLOWED_PORTS="$CUSTOM_PORTS"
                ACCESS_LABEL="Custom ($CUSTOM_PORTS)"
                break
                ;;
            4)
                warn "Open mode selected. Proxy may be abused by third parties."
                read -rp "Are you sure? [y/N]: " CONFIRM_OPEN
                if [[ "${CONFIRM_OPEN,,}" == "y" ]]; then
                    ALLOWED_PORTS="ALL"
                    ACCESS_LABEL="Open (all ports)"
                    break
                fi
                ;;
            *)
                warn "Invalid choice. Enter 1, 2, 3, or 4."
                ;;
        esac
    done

    success "Access mode: $ACCESS_LABEL"
}

ask_ip_restriction() {
    header "IP restriction (optional)"
    echo "You can restrict proxy access to specific IPs or subnets."
    echo "Useful if your client IP is stable or to prevent misuse."
    echo ""
    read -rp "Restrict access by IP? [y/N]: " RESTRICT_IP

    if [[ "${RESTRICT_IP,,}" == "y" ]]; then
        read -rp "Enter allowed IP or subnet (e.g.: 1.2.3.4 or 1.2.3.0/24): " ALLOWED_IP
        if [[ -z "$ALLOWED_IP" ]]; then
            warn "No IP entered. Skipping IP restriction."
            ALLOWED_IP=""
        else
            success "Access restricted to: $ALLOWED_IP"
        fi
    else
        ALLOWED_IP=""
        info "No IP restriction applied."
    fi
}

# =============================================================================
# MODULE 3: Install Squid
# =============================================================================
install_squid() {
    header "Installing Squid"
    if command -v squid &>/dev/null; then
        SQUID_VER=$(squid -v 2>&1 | head -1 | awk '{print $4}')
        success "Squid already installed (${SQUID_VER}), skipping."
    else
        info "Installing Squid..."
        apt-get update -qq
        apt-get install -y squid
        success "Squid installed successfully."
    fi
}

# =============================================================================
# MODULE 4: Generate Squid config
# =============================================================================
generate_squid_config() {
    header "Writing Squid configuration"

    SQUID_CONF="/etc/squid/squid.conf"
    SQUID_CONF_BAK="/etc/squid/squid.conf.bak.$(date +%Y%m%d%H%M%S)"

    if [[ -f "$SQUID_CONF" ]]; then
        cp "$SQUID_CONF" "$SQUID_CONF_BAK"
        info "Old config backed up: $SQUID_CONF_BAK"
    fi

    # Build port ACL lines
    PORT_ACL_LINES=""
    if [[ "$ALLOWED_PORTS" == "ALL" ]]; then
        PORT_ACL_LINES="acl allowed_ports port 1-65535"
    else
        for PORT in $ALLOWED_PORTS; do
            PORT_ACL_LINES+="acl allowed_ports port $PORT\n"
        done
    fi

    # Build IP ACL (if set)
    IP_ACL_LINE=""
    IP_ACCESS_LINE=""
    if [[ -n "$ALLOWED_IP" ]]; then
        IP_ACL_LINE="acl allowed_clients src $ALLOWED_IP"
        IP_ACCESS_LINE="http_access allow CONNECT allowed_ports allowed_clients"
    else
        IP_ACCESS_LINE="http_access allow CONNECT allowed_ports"
    fi

    cat > "$SQUID_CONF" <<EOF
# =============================================================
# Squid SSH Proxy - generated by setup-squid-ssh-proxy.sh
# Generated: $(date)
# =============================================================

# Squid listen port
http_port ${SQUID_PORT}

# CONNECT method ACL
acl CONNECT method CONNECT

# Allowed destination ports
$(echo -e "$PORT_ACL_LINES")

# Allowed client IPs (if restricted)
${IP_ACL_LINE}

# Allow CONNECT per policy
${IP_ACCESS_LINE}

# Deny everything else
http_access deny all

# Disable cache (not needed for a tunnel proxy)
cache deny all

# Hide Squid version and client IP
httpd_suppress_version_string on
forwarded_for delete

# Minimal logging
access_log /var/log/squid/access.log combined
cache_log /dev/null
EOF

    success "Config written to $SQUID_CONF"
}

# =============================================================================
# MODULE 5: Validate and restart Squid
# =============================================================================
restart_squid() {
    header "Validating and restarting Squid"

    info "Validating config..."
    if squid -k parse 2>&1 | grep -i "error\|fatal"; then
        error "Invalid Squid config. Check $SQUID_CONF"
    fi
    success "Config is valid."

    info "Restarting Squid..."
    systemctl restart squid
    sleep 2

    if systemctl is-active --quiet squid; then
        success "Squid is running."
    else
        error "Squid failed to start. Check: journalctl -xe -u squid"
    fi

    systemctl enable squid --quiet
    success "Squid enabled at boot."
}

# =============================================================================
# MODULE 6: Summary and client instructions
# =============================================================================
show_summary() {
    VPS_IP=$(hostname -I | awk '{print $1}')

    echo ""
    echo -e "${BOLD}=============================================${NC}"
    echo -e "${GREEN}  Squid SSH Proxy setup complete!${NC}"
    echo -e "${BOLD}=============================================${NC}"
    echo ""
    echo -e "  Squid port   : ${BOLD}$SQUID_PORT${NC}"
    echo -e "  Access mode  : ${BOLD}$ACCESS_LABEL${NC}"
    if [[ -n "$ALLOWED_IP" ]]; then
    echo -e "  Allowed IPs  : ${BOLD}$ALLOWED_IP${NC}"
    else
    echo -e "  Allowed IPs  : ${BOLD}all${NC}"
    fi
    echo ""

    echo -e "${YELLOW}--- Note ---${NC}"
    echo ""
    echo -e "  This script does ${BOLD}not configure any firewall${NC} (ufw/iptables)."
    echo -e "  It assumes the VPS runs without an active firewall, or that"
    echo -e "  you manage firewall rules separately (e.g. via your VPS provider panel)."
    echo -e "  Make sure port ${BOLD}$SQUID_PORT${NC} is reachable from outside."
    echo ""

    echo -e "${BOLD}--- Connect: Linux / macOS ---${NC}"
    echo ""
    echo -e "  One-liner:"
    echo -e "  ${CYAN}ssh -o ProxyCommand=\"nc -X connect -x ${VPS_IP}:${SQUID_PORT} %h %p\" user@${VPS_IP}${NC}"
    echo ""
    echo -e "  Or add to ~/.ssh/config:"
    echo -e "  ${CYAN}Host vps${NC}"
    echo -e "  ${CYAN}  HostName ${VPS_IP}${NC}"
    echo -e "  ${CYAN}  User user${NC}"
    echo -e "  ${CYAN}  ProxyCommand nc -X connect -x ${VPS_IP}:${SQUID_PORT} %h %p${NC}"
    echo ""

    echo -e "${BOLD}--- Connect: Bitvise SSH Client (Windows) ---${NC}"
    echo ""
    echo -e "  1. Open Bitvise > Login tab > fill in Host, Port, credentials as usual."
    echo -e "     Then click ${BOLD}Proxy settings${NC} > enable ${BOLD}Connect through SOCKS/HTTP proxy${NC}."
    echo ""
    echo -e "  2. Set Proxy type: ${BOLD}HTTP CONNECT${NC}"
    echo -e "     Proxy host: ${BOLD}${VPS_IP}${NC} | Proxy port: ${BOLD}${SQUID_PORT}${NC}"
    echo -e "     Leave proxy username/password blank, then click ${BOLD}Login${NC}."
    echo ""

    echo -e "${BOLD}--- Check Squid status ---${NC}"
    echo -e "  ${CYAN}systemctl status squid${NC}"
    echo -e "  ${CYAN}tail -f /var/log/squid/access.log${NC}"
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    echo -e "${BOLD}"
    echo "============================================="
    echo "  Squid SSH Proxy Setup"
    echo "============================================="
    echo -e "${NC}"

    check_root
    check_os
    ask_port
    ask_access_mode
    ask_ip_restriction
    install_squid
    generate_squid_config
    restart_squid
    show_summary
}

main