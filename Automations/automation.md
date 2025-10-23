# Automations | Restore Previous Config
## [**back to Linux-Engineer-Applied-Practice**](../README.md)

### Set-up right custom environment might be a burden when we as system enginner has hundreds or maybe thousand of servers available. So when we implementing this kind of scripts, we can relax and test after all the restoring progress were done.

```
/automation
│
├── restore.sh
└── configs/
    ├── fail2ban.local
    ├── daemon.json (planned)
    ├── root-crontab (planned)
    ├── sshd_config
    ├── (put your public ssh keys here ".pub"")
```

<p align="Justify">This is the script code below, periodically will be updated whenever I succesfully implement in my environment infrastructure. If you wanna install it use this curl below: </p>

```sh
# Restore Previous Config
curl -fSSL https://raw.githubusercontent.com/setiyadi-ben/Linux-Engineer-Applied-Practice/refs/heads/main/Automations/automation/restore.sh | sudo bash
```

<!-- ```sh
#!/bin/bash
set -euo pipefail
trap 'echo "[ERROR] Script exited unexpectedly on line $LINENO."' ERR

echo "This script will do the followings:"
echo "1. (Planned) Purging bloatware app if exists from systemd.
        ie: samba, etc."
echo "2. Restore: 
        a. fail2ban config (3 max fails, 10 years ban),
        b. sshd_config (publickey access + add staff users & etc),
        c. casaos (gui version for docker deployment)" 
echo

# Step 1 (planned, skipped)
echo "[SKIP] Purging bloatware apps — not executed (planned only)."
echo

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
            # Bersihkan format: hapus spasi berlebih, ubah ';' jadi spasi
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
    # Extract all key file paths from sshd_config
    key_targets=$(awk '/^AuthorizedKeysFile/ {for (i=2; i<=NF; i++) print $i}' /etc/ssh/sshd_config)

    if [ -z "$key_targets" ]; then
        echo "[WARN] No AuthorizedKeysFile entries found in sshd_config."
        key_targets=".ssh/authorized_keys"
    fi

    mkdir -p ~/.ssh
    chmod 700 ~/.ssh

    for target in $key_targets; do
        full_path=~/${target#\~\/}  # expand tilde if present
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
curl -fsSL https://get.casaos.io | sudo bash
echo

if curl -fsSL https://get.casaos.io | sudo bash; then
    echo "[OK] CasaOS installed successfully."
else
    echo "[ERROR] CasaOS installation failed."
fi

echo "[DONE] All restoration steps completed."

``` -->