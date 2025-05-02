#!/bin/bash
set -euo pipefail

# Configuration - Keep these at the top
GPG_NAME="Real Name"
GPG_EMAIL="your.email@email.com"

# Absolute paths for reliability
RM="/usr/bin/rm"
GPG="/usr/bin/gpg"
AWK="/usr/bin/awk"
SUDO="/usr/bin/sudo"
SYSTEMCTL="/usr/bin/systemctl"

# Enhanced error handling
handle_error() {
    echo "Error occurred on line $1 - Last exit code: $?"
    exit 1
}
trap 'handle_error $LINENO' ERR

# 1. Clean existing credentials
echo "=== Removing existing credentials ==="
"${RM}" -rf "${HOME}/.password-store" "${HOME}/.gnupg"

echo "Removing GPG keys..."
"${GPG}" --list-secret-keys --with-colons | \
"${AWK}" -F: '/^fpr:/ {print $10}' | \
while read -r fpr; do
    echo "Deleting key: ${fpr}"
    "${GPG}" --batch --yes --delete-secret-keys "${fpr}" 2>/dev/null || true
    "${GPG}" --batch --yes --delete-keys "${fpr}" 2>/dev/null || true
done

# 2. Install dependencies
echo -e "\n=== Installing required packages ==="
"${SUDO}" apt-get update
"${SUDO}" apt-get install -y \
    pass \
    gnupg2 \
    pinentry-gnome3 \
    dbus-x11 \
    libsecret-1-0

# 3. Generate new GPG key
echo -e "\n=== Generating new GPG key ==="
cat >"${HOME}/gpg-keygen" <<EOF
%echo Generating GPG key for ${GPG_NAME}
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: ${GPG_NAME}
Name-Email: ${GPG_EMAIL}
Expire-Date: 0
%commit
%echo Key generation complete
EOF

"${GPG}" --batch --generate-key "${HOME}/gpg-keygen"
"${RM}" -f "${HOME}/gpg-keygen"

# 4. Initialize pass
echo -e "\n=== Initializing password store ==="
KEY_ID=$("${GPG}" --list-secret-keys --with-colons | \
         "${AWK}" -F: '/^fpr:/ {print $10; exit}')

[ -z "${KEY_ID}" ] && { echo "ERROR: No GPG fingerprint found!"; exit 1; }

echo "Initializing pass with fingerprint: ${KEY_ID}"
pass init "${KEY_ID}"

# 5. Configure Docker Desktop integration
echo -e "\n=== Configuring Docker Desktop ==="
echo "Initializing credential store..."
mkdir -p "${HOME}/.password-store/docker-credential-helpers"
echo "test" | pass insert -e docker-credential-helpers/docker-pass-initialized-check

echo -e "\n=== Finalizing setup ==="
"${SYSTEMCTL}" --user restart docker-desktop
"${SYSTEMCTL}" --user enable docker-desktop

echo -e "\nSUCCESS! You can now log in to Docker Desktop."
echo "Note: First login might take 10-15 seconds to initialize."