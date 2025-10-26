#!/bin/bash
set -euo pipefail
trap 'echo "[ERROR] Script exited unexpectedly on line $LINENO."' ERR

# === Safety Check: Must run from /opt ===
if [[ "$(pwd)" != "/opt" ]]; then
    echo "[ERROR] This script must be executed from /opt directory."
    echo "Current directory: $(pwd)"
    echo "Please move the script to /opt and re-run it."
    exit 1
fi

echo "[OK] Directory check passed — running from /opt"
echo

# === Ensure configs folder exists ===
if [ ! -d "./configs" ]; then
    mkdir -p ./configs
    echo "[INFO] Folder ./configs has been created."
fi

# === Ask user whether to auto-download configs ===
read -rp "Do you want to download default configs from GitHub? [y/N]: " dl_confirm
if [[ "$dl_confirm" =~ ^[Yy]$ ]]; then
    base_url="https://raw.githubusercontent.com/setiyadi-ben/Linux-Engineer-Applied-Practice/refs/heads/main/Automations/automation/configs"
    echo "[DOWNLOAD] Fetching default configs from $base_url ..."
    curl -fsSL "$base_url/jail.local" -o ./configs/jail.local || echo "[WARN] jail.local not found on remote repo."
    curl -fsSL "$base_url/sshd_config" -o ./configs/sshd_config || echo "[WARN] sshd_config not found on remote repo."
    echo "[OK] Default config files downloaded to ./configs/"
else
    echo "[INFO] You chose to prepare configs manually."
    echo "[INFO] Please ensure required files exist in ./configs before continuing."
fi
echo

# === Verify required config files ===
missing_files=()
for f in jail.local sshd_config; do
    if [ ! -f "./configs/$f" ]; then
        missing_files+=("$f")
    fi
done
if ! ls ./configs/*.pub >/dev/null 2>&1; then
    missing_files+=("at least one *.pub key")
fi

if [ ${#missing_files[@]} -gt 0 ]; then
    echo "[ERROR] The following config file(s) are missing in ./configs/:"
    printf '  - %s\n' "${missing_files[@]}"
    echo
    echo "[ACTION REQUIRED] Please add missing files, or re-run this script and choose to download defaults."
    echo "Hint: place your SSH public key (*.pub) in ./configs before re-running."
    exit 1
fi

echo "[OK] All required config files and SSH key(s) found in ./configs/"
echo "[READY] Proceeding with restoration steps..."
echo


echo "This script will do the followings:"
echo "1. Install utility apps:
        htop, fastfetch, ..(soon)"
echo "2. Restore: 
        a. fail2ban config (3 max fails, 10 years ban),
        b. sshd_config (publickey access + add staff users & etc),
        c. casaos (gui version for docker deployment)
        d. (optional for advanced sysadmin) softether vpn server"
echo

# Step 1 (planned, skipped)
echo "[INSTALL] Install basic utility apps."
echo
sudo apt-get update && sudo apt-get install -y htop fastfetch
echo "[OK] Utility apps installed."

# Step 2a — Restore fail2ban (with flexible ignore IP prompt)
sudo apt update && apt install -y fail2ban
if [ -f ./configs/jail.local ]; then
    echo "[RESTORE] jail.local → /etc/fail2ban/jail.local"
    sudo mkdir -p /etc/fail2ban
    sudo cp -f ./configs/jail.local /etc/fail2ban/jail.local
    sudo chmod 644 /etc/fail2ban/jail.local

    echo
    read -rp "Do you want to add IP(s) to ignore list for Fail2Ban? [y/N]: " add_ignore
    if [[ "$add_ignore" =~ ^[Yy]$ ]]; then
        read -rp "Enter IP(s) to ignore (separate multiple with ';'): " ip_list
        if [ -n "$ip_list" ]; then
            formatted_ips=$(echo "$ip_list" | sed 's/[[:space:]]*;[[:space:]]*/ /g' | xargs)
            sudo sed -i "s|^ignoreip *=.*|& $formatted_ips|" /etc/fail2ban/jail.local
            echo "[OK] Added IP(s) to ignore list: $formatted_ips"
        else
            echo "[SKIP] No IP entered — ignore list unchanged."
        fi
    else
        echo "[SKIP] No additional IPs added to Fail2Ban ignore list."
    fi

    sudo systemctl enable --now fail2ban >/dev/null 2>&1 || true
else
    echo "[SKIP] Missing ./configs/jail.local"
fi
echo

# Step 2b — Restore SSH keys dynamically based on sshd_config
read -rp "Have you placed your public key(s) in ./configs/ ? [y/N]: " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    key_targets=$(awk '/^AuthorizedKeysFile/ {for (i=2; i<=NF; i++) print $i}' /etc/ssh/sshd_config)
    if [ -z "$key_targets" ]; then
        echo "[WARN] No AuthorizedKeysFile entries found in sshd_config."
        key_targets=".ssh/authorized_keys"
    fi

    mkdir -p ~/.ssh
    chmod 700 ~/.ssh

    for target in $key_targets; do
        full_path=~/${target#\~\/}
        dir_path=$(dirname "$full_path")
        mkdir -p "$dir_path"
        : > "$full_path"
        for pubfile in ./configs/*.pub; do
            [ -f "$pubfile" ] || continue
            cat "$pubfile" >> "$full_path"
        done
        chmod 600 "$full_path"
        echo "[OK] Restored keys into $full_path"
    done

    echo "[OK] SSH public keys restored based on sshd_config."
else
    echo "[SKIP] SSH public keys not restored."
fi
echo

# Step 2c — Install CasaOS
echo "[INSTALL] CasaOS — GUI for Docker deployment"
if curl -fsSL https://get.casaos.io | sudo bash; then
    echo "[OK] CasaOS installed successfully."
else
    echo "[ERROR] CasaOS installation failed."
fi
echo

echo "[DONE] All restoration steps completed."

# Step 2d — Optional: SoftEther VPN Server auto-install
echo
read -rp "For advanced sysadmins: do you want to install SoftEther VPN Server now? [y/N]: " softether_confirm
if [[ "$softether_confirm" =~ ^[Yy]$ ]]; then
    if [ ! -f ./configs/autoinstall_softether-server.sh ]; then
        echo "[INFO] SoftEther installer not found locally."
        read -rp "Download it from GitHub now? [y/N]: " dl_softether
        if [[ "$dl_softether" =~ ^[Yy]$ ]]; then
            curl -fsSL "https://raw.githubusercontent.com/setiyadi-ben/Linux-Engineer-Applied-Practice/refs/heads/main/Automations/automation/configs/autoinstall_softether-server.sh" \
                -o ./configs/autoinstall_softether-server.sh && chmod +x ./configs/autoinstall_softether-server.sh
            echo "[OK] SoftEther installer downloaded successfully."
        else
            echo "[SKIP] Installer not downloaded. You can run it manually later from ./configs."
            exit 0
        fi
    fi

    echo "[RUNNING] Executing SoftEther VPN Server installer..."
    sudo bash ./configs/autoinstall_softether-server.sh
else
    echo "[SKIP] SoftEther VPN Server installation skipped."
fi

