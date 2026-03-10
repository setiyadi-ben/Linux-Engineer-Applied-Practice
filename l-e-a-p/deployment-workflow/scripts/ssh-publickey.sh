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

CONFIGS_DIR="./configs"
SSH_ROOT_DIR="/root/.ssh"
SSHD_CONFIG="/etc/ssh/sshd_config"
SSHD_CONF_DIR="/etc/ssh/sshd_config.d"

# ============================================================
# Helper: set a directive in sshd_config (uncomment + set)
# Usage: set_sshd_directive <key> <value> <file>
# ============================================================
set_sshd_directive() {
    local key="$1"
    local value="$2"
    local file="$3"
    if grep -qE "^${key}" "$file"; then
        sed -i "s|^${key}.*|${key} ${value}|" "$file"
    elif grep -qE "^#\s*${key}" "$file"; then
        sed -i "s|^#\s*${key}.*|${key} ${value}|" "$file"
    else
        echo "${key} ${value}" >> "$file"
    fi
}

# ============================================================
# Helper: scan ALL files in sshd_config.d/* for a directive
# and override with the desired value if conflicting
# Usage: enforce_conf_dir <key> <desired_value>
# ============================================================
enforce_conf_dir() {
    local key="$1"
    local desired="$2"
    local fixed=0

    shopt -s nullglob
    local conf_files=("$SSHD_CONF_DIR"/*)
    shopt -u nullglob

    for conf_file in "${conf_files[@]}"; do
        [[ -f "$conf_file" ]] || continue
        if grep -qE "^${key}" "$conf_file"; then
            current_val=$(grep -E "^${key}" "$conf_file" | awk '{print $2}' | tail -1)
            if [[ "$current_val" != "$desired" ]]; then
                sed -i "s|^${key}.*|${key} ${desired}|" "$conf_file"
                echo "[CONFLICT FIXED] $(basename "$conf_file"): ${key} ${current_val} → ${desired}"
                ((fixed++)) || true
            else
                echo "[OK] $(basename "$conf_file"): ${key} already set to ${desired}."
            fi
        fi
    done

    if [[ $fixed -eq 0 && ${#conf_files[@]} -gt 0 ]]; then
        echo "[OK] No conflicting ${key} overrides found in $SSHD_CONF_DIR/*"
    fi
}

# === Step 1: Ensure ./configs/ exists ===
if [[ ! -d "$CONFIGS_DIR" ]]; then
    mkdir -p "$CONFIGS_DIR"
    echo "[OK] Created $CONFIGS_DIR directory."
else
    echo "[OK] Directory $CONFIGS_DIR already exists."
fi
echo

# === Step 2: Wait for user to upload .pub files via SFTP ===
echo "Please upload your public key file(s) (.pub) into: $(realpath $CONFIGS_DIR)"
echo "You can use SFTP or any file transfer method to place them there."
echo
read -rp "Press [Enter] when you are ready to continue..."
echo

# === Step 3: Validate .pub files exist in ./configs/ ===
shopt -s nullglob
pubfiles=("$CONFIGS_DIR"/*.pub)
shopt -u nullglob

if [[ ${#pubfiles[@]} -eq 0 ]]; then
    echo "[ERROR] No .pub files found in $CONFIGS_DIR. Aborting."
    exit 1
fi

echo "[OK] Found ${#pubfiles[@]} public key file(s):"
for f in "${pubfiles[@]}"; do
    echo "     - $(basename "$f")"
done
echo

# === Step 4: Move .pub files to /root/.ssh/ — skip if already exists ===
mkdir -p "$SSH_ROOT_DIR"
chmod 700 "$SSH_ROOT_DIR"

moved=0
skipped=0
key_names=()

for pubfile in "${pubfiles[@]}"; do
    filename=$(basename "$pubfile")
    dest="$SSH_ROOT_DIR/$filename"

    if [[ -f "$dest" ]]; then
        echo "[SKIP] $filename already exists in $SSH_ROOT_DIR — skipping."
        ((skipped++)) || true
    else
        mv "$pubfile" "$dest"
        chmod 600 "$dest"
        echo "[OK] Moved $filename → $dest"
        ((moved++)) || true
    fi

    key_names+=(".ssh/$filename")
done

echo
echo "[SUMMARY] $moved file(s) moved, $skipped file(s) skipped."
echo

# === Step 5: Update AuthorizedKeysFile in sshd_config ===
new_value="${key_names[*]}"
new_line="AuthorizedKeysFile $new_value"

if grep -qE "^#?\s*AuthorizedKeysFile" "$SSHD_CONFIG"; then
    sed -i "s|^#\?\s*AuthorizedKeysFile.*|$new_line|" "$SSHD_CONFIG"
    echo "[OK] Updated AuthorizedKeysFile in $SSHD_CONFIG:"
    echo "     $new_line"
else
    echo "$new_line" >> "$SSHD_CONFIG"
    echo "[OK] Added AuthorizedKeysFile to $SSHD_CONFIG:"
    echo "     $new_line"
fi
echo

# === Step 6: Ensure PubkeyAuthentication yes ===
echo "------------------------------------------------------------"
echo " Verifying PubkeyAuthentication..."
echo "------------------------------------------------------------"
set_sshd_directive "PubkeyAuthentication" "yes" "$SSHD_CONFIG"
echo "[OK] PubkeyAuthentication set to yes in $SSHD_CONFIG."
echo

# ============================================================
# === Step 7: Password Authentication Management ===
# ============================================================

current_auth=$(grep -E "^PasswordAuthentication" "$SSHD_CONFIG" | awk '{print $2}' | tail -1 || echo "unknown")

echo "------------------------------------------------------------"
echo " Password Authentication Settings"
echo "------------------------------------------------------------"
echo " Current status in sshd_config: PasswordAuthentication = $current_auth"
echo
echo " Options:"
echo "   [1] Disable password authentication (key-only login)"
echo "       — also enforces 'no' across ALL files in sshd_config.d/*"
echo "   [2] Enable password authentication"
echo "   [3] Enable password authentication + set root password"
echo "   [4] Revert to SSH default (comment out the line)"
echo "   [5] Skip — no changes"
echo
read -rp "Choose an option [1-5]: " auth_choice
echo

case "$auth_choice" in
    1)
        # Set in main sshd_config
        set_sshd_directive "PasswordAuthentication" "no" "$SSHD_CONFIG"
        echo "[OK] PasswordAuthentication set to: no in $SSHD_CONFIG"

        # Enforce across ALL files in sshd_config.d/*
        echo
        echo " Scanning $SSHD_CONF_DIR/* for conflicting overrides..."
        enforce_conf_dir "PasswordAuthentication" "no"
        echo
        echo "[OK] Key-only login enforced across all SSH config files."
        ;;
    2)
        set_sshd_directive "PasswordAuthentication" "yes" "$SSHD_CONFIG"
        echo "[OK] PasswordAuthentication set to: yes"
        echo "[WARN] Password login is now enabled. Ensure strong passwords are set."
        ;;
    3)
        set_sshd_directive "PasswordAuthentication" "yes" "$SSHD_CONFIG"
        echo "[OK] PasswordAuthentication set to: yes"
        echo
        echo "Set a new password for root:"
        if passwd root; then
            echo "[OK] Root password updated successfully."
        else
            echo "[WARN] passwd command failed or was cancelled."
        fi
        ;;
    4)
        if grep -qE "^PasswordAuthentication" "$SSHD_CONFIG"; then
            sed -i "s|^PasswordAuthentication.*|#PasswordAuthentication yes|" "$SSHD_CONFIG"
            echo "[OK] PasswordAuthentication reverted to SSH default (commented out)."
        else
            echo "[SKIP] PasswordAuthentication line not found — nothing to revert."
        fi
        ;;
    5)
        echo "[SKIP] No changes made to PasswordAuthentication."
        ;;
    *)
        echo "[WARN] Invalid choice '$auth_choice' — skipping password auth changes."
        ;;
esac

echo
echo "[OK] All done. Reloading SSH daemon..."
systemctl reload sshd && echo "[OK] sshd reloaded successfully." || echo "[WARN] Failed to reload sshd — please run: sudo systemctl reload sshd"
echo