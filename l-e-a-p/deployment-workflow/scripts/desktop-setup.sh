#!/usr/bin/env bash
# =============================================================================
# desktop-setup.sh
# Desktop Environment Manager — Headless Linux VPS + xRDP
# Repo: https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice
#
# Tested on  : Debian (Bullseye/Bookworm/Trixie), Ubuntu 22.04/24.04
# Should work: Any Debian/Ubuntu-based distro with apt + systemd
#
# Two install modes:
#
#   Mode A — Minimal (apt, no bloat):
#     Installs only DE core packages + xorg + xrdp dependencies.
#     Key workaround: writes ~/.xsession for the xRDP user so xRDP can
#     reliably detect and launch the correct DE regardless of how it was
#     installed. Without ~/.xsession, xRDP falls back to a black screen
#     or wrong DE for all DEs except Xfce/MATE (which Griffon's installer
#     handles explicitly). Audio may or may not work depending on DE.
#
#   Mode B — Bundle (tasksel, includes bloat):
#     Uses tasksel to install the full official Debian DE bundle. Includes
#     office suite, extra apps, and all recommends. Audio is more likely
#     to work out of the box. Larger disk footprint.
#
# Workflow for both modes:
#   1. Purge all existing DE + xRDP packages (clean slate)
#   2. Remove existing /home/* user(s)
#   3. Create new xRDP user (password-based, added to sudo)
#   4. Install chosen DE via selected mode
#   5. Run Griffon's xrdp-installer as the new user
#   6. Write ~/.xsession for the new user
#   7. Reboot
#
# Bundled xRDP installer written by Griffon (c-nergy.be)
#   Script  : xrdp-installer-1.5.5.sh
#   Author  : Griffon — http://www.c-nergy.be/blog
#   License : AS IS — credits must be kept intact and unchanged
# =============================================================================

# ── ANSI colors ───────────────────────────────────────────────────────────────
RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
CYN='\033[0;36m'
BLD='\033[1m'
DIM='\033[2m'
STK='\033[9m'
RST='\033[0m'

# ── Detect distro at startup ──────────────────────────────────────────────────
DISTRO_NAME="Linux"
if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    DISTRO_NAME="${PRETTY_NAME:-$NAME}"
fi

# ── Helpers ───────────────────────────────────────────────────────────────────
separator() {
    echo -e "${DIM}────────────────────────────────────────────────────────────────────${RST}"
}

header() {
    clear
    echo
    echo -e "${CYN}${BLD}"
    echo   "  Desktop Environment Manager — VPS Edition"
    echo   "  ${DISTRO_NAME} + xRDP"
    echo -e "${RST}"
}

pause() {
    echo
    read -rp "  Press [Enter] to return to menu..."
}

require_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}  [!] Please run this script with sudo or as root.${RST}"
        exit 1
    fi
}

# ── DE definitions for Mode A (minimal apt install) ───────────────────────────
#
# All 8 Debian tasksel DEs are listed.
# Key additions vs vanilla apt install:
#   xorg xserver-xorg xserver-xorg-core — required by xrdp-installer to detect
#     the X11 stack; not pulled in by any DE via --no-install-recommends
#   pipewire-module-xrdp — bridges PipeWire audio into the xRDP session
#   dbus-x11 — required by all DEs for proper xRDP session brokering
#   kwin-x11 — forces KDE Plasma 6 into X11 mode (default is Wayland)
#
# Display managers excluded — xRDP manages its own session.
#
# DE_XSESSION: the exact command written to ~/.xsession for xRDP session launch.
# This is the workaround that makes all DEs work reliably with xRDP regardless
# of how xRDP was installed. Without it, xRDP cannot detect the DE from an SSH
# context and falls back to a black screen or wrong environment.
# The correct command per DE can be verified from /usr/share/xsessions/<de>.desktop
# Exec= field after install.

DE_COUNT=8

DE_NAME[1]="LXDE"
DE_RAM[1]="~150 MB"
DE_X11[1]="✓ X11"
DE_X11_COLOR[1]="$GRN"
DE_PACKAGES[1]="xorg xserver-xorg xserver-xorg-core xserver-xorg-legacy
                lxde-core lxterminal pcmanfm openbox
                dbus-x11 pipewire-module-xrdp"
DE_XSESSION[1]="startlxde"

DE_NAME[2]="Xfce  ★"
DE_RAM[2]="~200 MB"
DE_X11[2]="✓ X11"
DE_X11_COLOR[2]="$GRN"
DE_PACKAGES[2]="xorg xserver-xorg xserver-xorg-core xserver-xorg-legacy
                xfce4 xfce4-terminal xfce4-panel xfce4-session
                xfce4-settings xfwm4 xfdesktop4 thunar
                dbus-x11 pipewire-module-xrdp"
DE_XSESSION[2]="startxfce4"

DE_NAME[3]="MATE"
DE_RAM[3]="~250 MB"
DE_X11[3]="✓ X11"
DE_X11_COLOR[3]="$GRN"
DE_PACKAGES[3]="xorg xserver-xorg xserver-xorg-core xserver-xorg-legacy
                mate-desktop-environment-core mate-terminal caja
                dbus-x11 pipewire-module-xrdp"
DE_XSESSION[3]="mate-session"

DE_NAME[4]="LXQt"
DE_RAM[4]="~300 MB"
DE_X11[4]="✓ X11"
DE_X11_COLOR[4]="$GRN"
DE_PACKAGES[4]="xorg xserver-xorg xserver-xorg-core
                lxqt lxqt-panel qterminal pcmanfm-qt
                dbus-x11 pipewire-module-xrdp"
DE_XSESSION[4]="startlxqt"

DE_NAME[5]="GNOME Flashback"
DE_RAM[5]="~400 MB"
DE_X11[5]="✓ X11"
DE_X11_COLOR[5]="$GRN"
DE_PACKAGES[5]="xorg xserver-xorg xserver-xorg-core
                gnome-session-flashback gnome-flashback metacity
                gnome-terminal nautilus
                dbus-x11 pipewire-module-xrdp"
DE_XSESSION[5]="gnome-session --session=gnome-flashback-metacity"

DE_NAME[6]="Cinnamon"
DE_RAM[6]="~600 MB"
DE_X11[6]="✓ X11"
DE_X11_COLOR[6]="$GRN"
DE_PACKAGES[6]="xorg xserver-xorg xserver-xorg-core
                cinnamon cinnamon-core nemo gnome-terminal
                dbus-x11 pipewire-module-xrdp"
DE_XSESSION[6]="cinnamon-session"

DE_NAME[7]="KDE Plasma"
DE_RAM[7]="~800 MB"
DE_X11[7]="✗ Wayland"
DE_X11_COLOR[7]="$RED"
DE_PACKAGES[7]="xorg xserver-xorg xserver-xorg-core
                kde-plasma-desktop plasma-workspace plasma-nm
                konsole dolphin kwin-x11
                dbus-x11 pipewire-module-xrdp"
DE_XSESSION[7]="startplasma-x11"

DE_NAME[8]="GNOME"
DE_RAM[8]="~1.5 GB"
DE_X11[8]="✗ Wayland"
DE_X11_COLOR[8]="$RED"
DE_PACKAGES[8]="xorg xserver-xorg xserver-xorg-core
                gnome-core gnome-session gnome-terminal nautilus
                dbus-x11 pipewire-module-xrdp"
DE_XSESSION[8]="gnome-session"

# ── Mode A categories: only LXDE/Xfce/MATE supported; all others unsupported ─
DE_CATEGORY[1]="recommended"   # LXDE
DE_CATEGORY[2]="recommended"   # Xfce
DE_CATEGORY[3]="recommended"   # MATE
DE_CATEGORY[4]="unsupported"   # LXQt
DE_CATEGORY[5]="unsupported"   # GNOME Flashback
DE_CATEGORY[6]="caution"       # Cinnamon — confirmed working via Mode A
DE_CATEGORY[7]="unsupported"   # KDE Plasma — Wayland only
DE_CATEGORY[8]="unsupported"   # GNOME

# ── Mode B categories: LXQt confirmed working; GNOME unsupported ─────────────
DE_CATEGORY_B[1]="recommended"  # LXDE
DE_CATEGORY_B[2]="recommended"  # Xfce
DE_CATEGORY_B[3]="recommended"  # MATE
DE_CATEGORY_B[4]="recommended"  # LXQt — confirmed working via tasksel
DE_CATEGORY_B[5]="caution"      # GNOME Flashback
DE_CATEGORY_B[6]="caution"      # Cinnamon
DE_CATEGORY_B[7]="caution"      # KDE Plasma
DE_CATEGORY_B[8]="unsupported"  # GNOME — Wayland-only, black screen on xRDP

# ── Tasksel task names for Mode B ─────────────────────────────────────────────
TASKSEL_TASK[1]="lxde-desktop"
TASKSEL_TASK[2]="xfce-desktop"
TASKSEL_TASK[3]="mate-desktop"
TASKSEL_TASK[4]="lxqt-desktop"
TASKSEL_TASK[5]=""              # no standalone tasksel task for GNOME Flashback
TASKSEL_TASK[6]="cinnamon-desktop"
TASKSEL_TASK[7]="kde-desktop"
TASKSEL_TASK[8]="gnome-desktop"

# ── Apps bundled with every Mode A install ────────────────────────────────────
COMMON_APPS="chromium remmina remmina-plugin-rdp"
# ── Category badge ────────────────────────────────────────────────────────────
category_badge() {
    case "$1" in
        recommended) echo -e "${GRN}Recommended${RST}" ;;
        caution)     echo -e "${YLW}Caution    ${RST}" ;;
        unsupported) echo -e "${RED}Unsupported${RST}" ;;
    esac
}

# ── DE selection table ────────────────────────────────────────────────────────
show_de_menu() {
    echo
    echo -e "${BLD}  Available Desktop Environments:${RST}"
    separator
    printf "  %-5s %-20s %-10s %-12s %s\n" \
        "No." "Name" "RAM Idle" "X11/xRDP" "Category"
    separator

    for i in $(seq 1 $DE_COUNT); do
        cat="${DE_CATEGORY[$i]}"
        badge=$(category_badge "$cat")

        if [[ "$cat" == "unsupported" ]]; then
            printf "  %-5s ${STK}%-20s${RST} %-10s ${DE_X11_COLOR[$i]}%-12s${RST} %b\n" \
                "$i)" "${DE_NAME[$i]}" "${DE_RAM[$i]}" "${DE_X11[$i]}" "$badge"
        elif [[ "${DE_X11[$i]}" == "✗ Wayland" ]]; then
            printf "  %-5s ${STK}%-20s${RST} %-10s ${RED}${STK}%-12s${RST} %b\n" \
                "$i)" "${DE_NAME[$i]}" "${DE_RAM[$i]}" "${DE_X11[$i]}" "$badge"
        else
            printf "  %-5s %-20s %-10s ${DE_X11_COLOR[$i]}%-12s${RST} %b\n" \
                "$i)" "${DE_NAME[$i]}" "${DE_RAM[$i]}" "${DE_X11[$i]}" "$badge"
        fi
    done

    separator
    echo -e "  ${GRN}Recommended${RST}  — X11-native, light, proven with xRDP"
    echo -e "  ${YLW}Caution    ${RST}  — works with ~/.xsession workaround; heavier RAM"
    echo -e "  ${RED}Unsupported${RST}  — incompatible with xRDP or requires GPU"
    echo -e "  ${DIM}  ★ = top pick for VPS${RST}"
    echo
}

# ═════════════════════════════════════════════════════════════════════════════
# SHARED: purge existing DE + xRDP + users
# ═════════════════════════════════════════════════════════════════════════════
purge_existing() {
    echo
    echo -e "${CYN}  [0/?] Purging existing DE + xRDP installation...${RST}"
    # Broad wildcard purge — covers tasksel bundles and manual installs alike.
    # Pattern covers package names, not just the ones we explicitly installed.
    apt-get purge -y         mate-* libmate-* debian-mate-*         gnome-* libgnome-* gir1.2-mate* gir1.2-gnome*         xfce4* xfwm4* xfdesktop4* thunar* libxfce4* xfce4-*         lxde* lxde-* lxterminal* pcmanfm* openbox*         lxqt* lxqt-* qterminal* pcmanfm-qt*         cinnamon* nemo*         kde-* plasma-* konsole* dolphin* kwin*         gdm3* lightdm* sddm*         xrdp* xorgxrdp*         pipewire* wireplumber* pipewire-module-xrdp* pulseaudio* libcanberra*         xdg-desktop-portal*         chromium* remmina*         tasksel*         pinentry-gnome3 libpam-gnome-keyring         libblockdev* libgnome-games-support*         gnome-games-support* 2>/dev/null || true
    apt-get autoremove --purge -y
    apt-get autoclean
    rm -rf         /usr/share/xsessions         /etc/xrdp /usr/lib/xrdp /usr/share/xrdp         /usr/share/wayland-sessions         /usr/share/sddm /usr/share/gdm         /etc/X11/Xwrapper.config
    echo -e "  ${GRN}✓ Previous installation cleared.${RST}"
}

# ═════════════════════════════════════════════════════════════════════════════
# SHARED: remove existing /home/* users and create new xRDP user
# ═════════════════════════════════════════════════════════════════════════════
setup_rdp_user() {
    # ── Detect existing users ─────────────────────────────────────────────────
    EXISTING_USERS=()
    for home_dir in /home/*/; do
        u=$(basename "$home_dir")
        id "$u" &>/dev/null && EXISTING_USERS+=("$u")
    done

    if [[ ${#EXISTING_USERS[@]} -gt 0 ]]; then
        echo
        echo -e "${YLW}  Existing user(s) in /home:${RST}"
        for u in "${EXISTING_USERS[@]}"; do
            echo -e "    •  ${BLD}${u}${RST}"
        done
        echo -e "${DIM}  These will be removed and replaced by the new xRDP user.${RST}"
    fi

    # ── Prompt for new username ───────────────────────────────────────────────
    echo
    echo -e "${BLD}  Create xRDP user${RST}"
    echo -e "${DIM}  xRDP authenticates via password — root login is blocked.${RST}"
    echo
    while true; do
        read -rp "  Enter new xRDP username: " NEW_USER
        [[ -z "$NEW_USER" ]] && echo -e "${RED}  Username cannot be empty.${RST}" && continue
        break
    done

    echo -e "${CYN}  Set password for '${NEW_USER}':${RST}"
    while true; do
        read -rsp "  Password: " pw1; echo
        read -rsp "  Confirm : " pw2; echo
        if [[ "$pw1" != "$pw2" ]]; then
            echo -e "${RED}  Passwords do not match.${RST}"
        elif [[ ${#pw1} -lt 4 ]]; then
            echo -e "${RED}  Too short (minimum 4 characters).${RST}"
        else
            break
        fi
    done

    # ── Remove existing users ─────────────────────────────────────────────────
    if [[ ${#EXISTING_USERS[@]} -gt 0 ]]; then
        echo
        echo -e "${CYN}  Removing existing user(s)...${RST}"
        for old_user in "${EXISTING_USERS[@]}"; do
            loginctl terminate-user "$old_user" 2>/dev/null || true
            loginctl disable-linger "$old_user" 2>/dev/null || true
            pkill -9 -u "$old_user" 2>/dev/null || true
            sleep 1
            userdel -r -f "$old_user"
            if [[ $? -ne 0 ]]; then
                echo -e "${YLW}  userdel had issues — cleaning /home/${old_user} manually.${RST}"
                rm -rf "/home/${old_user}"
            else
                echo -e "  ${GRN}✓ Removed '${old_user}'${RST}"
            fi
        done
    fi

    # ── Create new user ───────────────────────────────────────────────────────
    useradd -m -s /bin/bash "$NEW_USER"
    # Validate home directory was created — useradd -m can silently fail
    # if a previous user with the same UID left stale state. mkhomedir_helper
    # creates the home dir from /etc/skel if missing.
    if [[ ! -d "/home/${NEW_USER}" ]]; then
        echo -e "${YLW}  Home dir missing — creating via mkhomedir_helper...${RST}"
        mkhomedir_helper "$NEW_USER"
    fi
    echo "${NEW_USER}:${pw1}" | chpasswd
    usermod -aG sudo "$NEW_USER"
    echo -e "  ${GRN}✓ User '${NEW_USER}' created and added to sudo.${RST}"
}

# ═════════════════════════════════════════════════════════════════════════════
# SHARED: download and run Griffon's xrdp-installer as the new user
# ═════════════════════════════════════════════════════════════════════════════
run_xrdp_installer() {
    local rdp_user="$1"
    local rdp_uid
    rdp_uid=$(id -u "$rdp_user")

    echo
    echo -e "${CYN}  Installing xRDP via Griffon xrdp-installer-1.5.5.sh...${RST}"
    separator
    echo -e "${DIM}  Credit: Griffon — http://www.c-nergy.be/blog${RST}"
    echo

    apt-get install -y --no-install-recommends lsb-release curl

    local xrdp_script="/tmp/xrdp-installer-1.5.5.sh"
    curl -fsSL \
        https://raw.githubusercontent.com/setiyadi-ben/Linux-Engineer-Applied-Practice/refs/heads/main/l-e-a-p/deployment-workflow/scripts/configs/xrdp-installer-1.5.5.sh \
        -o "$xrdp_script"
    chmod +x "$xrdp_script"

    # Run as new non-root user via su — avoids sudo password prompt
    # when script is already running as root.
    echo -e "${CYN}  Running xrdp-installer as '${rdp_user}'...${RST}"
    su - "$rdp_user" -c         "XDG_RUNTIME_DIR=/run/user/${rdp_uid} HOME=/home/${rdp_user} bash $xrdp_script --unsupported"
}

# ═════════════════════════════════════════════════════════════════════════════
# SHARED: write ~/.xsession for the xRDP user
# ═════════════════════════════════════════════════════════════════════════════
write_xsession() {
    local rdp_user="$1"
    local xsession_cmd="$2"

    local xsession_file="/home/${rdp_user}/.xsession"

    # xRDP reads ~/.xsession to determine which DE to launch.
    # Without this file, xRDP falls back to /etc/X11/Xsession which
    # cannot reliably detect the installed DE when started via SSH/xrdp
    # context — resulting in black screen or wrong DE for most environments.
    # Writing the exact session command here guarantees correct DE launch.
    echo "#!/bin/sh" > "$xsession_file"
    echo "exec ${xsession_cmd}" >> "$xsession_file"
    chmod +x "$xsession_file"
    chown "${rdp_user}:${rdp_user}" "$xsession_file"

    echo -e "  ${GRN}✓ ~/.xsession written: exec ${xsession_cmd}${RST}"
}

# ═════════════════════════════════════════════════════════════════════════════
# SHARED: install and enable PipeWire for xRDP audio
# ═════════════════════════════════════════════════════════════════════════════
setup_pipewire() {
    local rdp_user="$1"
    local rdp_uid
    rdp_uid=$(id -u "$rdp_user")

    echo
    echo -e "${CYN}  Installing PipeWire audio stack...${RST}"
    separator

    # Install PipeWire + PulseAudio compatibility layer + xRDP audio bridge.
    # pulseaudio is masked (not removed) so apt does not re-pull it as dep.
    # pipewire-module-xrdp creates xrdp-sink/xrdp-source inside xRDP sessions.
    apt-get install -y pipewire pipewire-pulse wireplumber pipewire-module-xrdp

    # Mask PulseAudio so it cannot start and compete with PipeWire
    su - "$rdp_user" -c         "XDG_RUNTIME_DIR=/run/user/${rdp_uid} systemctl --user mask pulseaudio.service pulseaudio.socket"         2>/dev/null || true

    # Enable PipeWire services — they activate on next user login via socket
    su - "$rdp_user" -c         "XDG_RUNTIME_DIR=/run/user/${rdp_uid} systemctl --user enable pipewire pipewire-pulse wireplumber"

    echo -e "  ${GRN}✓ PipeWire installed and enabled for '${rdp_user}'.${RST}"
    echo -e "  ${DIM}  xrdp-sink will appear after first xRDP login.${RST}"
}

# ═════════════════════════════════════════════════════════════════════════════
# OPTION 1A — Install DE (Minimal apt, no bloat)
# ═════════════════════════════════════════════════════════════════════════════
install_mode_a() {
    header
    echo -e "${BLD}  [ OPTION 1 ] Install DE — Mode A: Minimal (apt, no bloat)${RST}"
    separator
    echo
    echo -e "  Installs only the DE core packages via apt."
    echo -e "  ${GRN}+${RST} Chromium + Remmina included"
    echo -e "  ${GRN}+${RST} ~/.xsession written for reliable xRDP DE detection"
    echo -e "  ${YLW}~${RST} Audio via SSH X11 forwarding only (e.g. Bitvise)"
    echo -e "  ${RED}✗${RST} Audio will NOT work via Windows RDP or other RDP clients"
    echo

    show_de_menu

    read -rp "  Select DE [1-${DE_COUNT}]: " de_choice
    if ! [[ "$de_choice" =~ ^[0-9]+$ ]] || \
       [[ "$de_choice" -lt 1 ]] || [[ "$de_choice" -gt $DE_COUNT ]]; then
        echo -e "${RED}  Invalid choice.${RST}"; pause; return
    fi

    CHOSEN_NAME="${DE_NAME[$de_choice]}"
    CHOSEN_PACKAGES="${DE_PACKAGES[$de_choice]}"
    CHOSEN_CAT="${DE_CATEGORY[$de_choice]}"
    CHOSEN_XSESSION="${DE_XSESSION[$de_choice]}"

    if [[ "$CHOSEN_CAT" == "unsupported" ]]; then
        echo
        echo -e "${RED}  ╔══════════════════════════════════════════════════════════════════╗"
        echo    "  ║  WARNING: This DE is Unsupported with xRDP.                    ║"
        echo    "  ║  You are likely to get a black screen or no session.           ║"
        echo -e "  ╚══════════════════════════════════════════════════════════════════╝${RST}"
        echo
        read -rp "  Proceed anyway? [y/N]: " w
        [[ "$w" =~ ^[Yy]$ ]] || { echo "  Cancelled."; pause; return; }
    elif [[ "$CHOSEN_CAT" == "caution" ]]; then
        echo
        echo -e "${YLW}  CAUTION: ${CHOSEN_NAME} — heavier RAM, proceed at your own discretion.${RST}"
        read -rp "  Continue? [y/N]: " w
        [[ "$w" =~ ^[Yy]$ ]] || { echo "  Cancelled."; pause; return; }
    fi

    echo
    echo -e "${YLW}  ┌──────────────────────────────────────────────────────────────────┐"
    echo    "  │  About to install (Mode A):                                      │"
    printf  "  │    DE        : %-51s│\n" "$CHOSEN_NAME"
    printf  "  │    Apps      : %-51s│\n" "Chromium, Remmina + RDP plugin"
    printf  "  │    xSession  : %-51s│\n" "$CHOSEN_XSESSION"
    echo    "  │    xRDP      : Griffon xrdp-installer-1.5.5.sh                  │"
    echo    "  │  System reboots when done. Connect via RDP on port 3389.        │"
    echo -e "  └──────────────────────────────────────────────────────────────────┘${RST}"
    echo
    read -rp "  Continue? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "  Cancelled."; pause; return; }

    purge_existing
    setup_rdp_user

    echo
    echo -e "${CYN}  [1/5] Updating package list...${RST}"
    apt-get update -y

    echo
    echo -e "${CYN}  [2/5] Installing ${CHOSEN_NAME} (--no-install-recommends)...${RST}"
    separator
    # --no-install-recommends keeps the install lean — no office suite, games,
    # or print stack. Core DE packages + explicit additions in DE_PACKAGES are
    # sufficient for a working xRDP session.
    # shellcheck disable=SC2086
    apt-get install -y --no-install-recommends $CHOSEN_PACKAGES

    echo
    echo -e "${CYN}  [3/5] Installing Chromium + Remmina...${RST}"
    separator
    apt-get install -y $COMMON_APPS

    run_xrdp_installer "$NEW_USER"

    echo
    echo -e "${CYN}  [4/5] Writing ~/.xsession and Xwrapper.config...${RST}"
    write_xsession "$NEW_USER" "$CHOSEN_XSESSION"
    # xserver-xorg-legacy creates /etc/X11/Xwrapper.config as empty file.
    # Must set allowed_users=anybody so non-root xRDP sessions can start Xorg.
    printf "allowed_users=anybody\nneeds_root_rights=yes\n"         > /etc/X11/Xwrapper.config

    setup_pipewire "$NEW_USER"

    echo
    echo -e "${GRN}  ✓ Mode A installation complete.${RST}"
    echo -e "${GRN}    User: ${NEW_USER} | DE: ${CHOSEN_NAME} | xRDP: ready${RST}"
    echo -e "  ${DIM}⚠ Reminder: xRDP port 3389 is currently public. Consider firewall rules${RST}"
    echo -e "  ${DIM}  to restrict access to your static IP and VPN internal range.${RST}"
    echo
    echo -e "  ${GRN}✓ (with audio)${RST}  Login via Bitvise SSH first, then open a new Remote Desktop connection"
    echo -e "  ${RED}✗ (no audio) ${RST}  Any RDP client → [VPS_IP]:3389 — username: ${NEW_USER}"
    echo -e "  ${DIM}  * Audio only works over X11 forwarding — SSH login is required first.${RST}"
    echo
    echo -e "${CYN}  [5/5] Rebooting in 5 seconds...${RST}"
    echo -e "${DIM}  (Ctrl+C to cancel reboot)${RST}"
    sleep 5
    reboot
}

# ═════════════════════════════════════════════════════════════════════════════
# OPTION 2 — Install DE (Tasksel bundle, includes bloat + better audio)
# ═════════════════════════════════════════════════════════════════════════════
install_mode_b() {
    header
    echo -e "${BLD}  [ OPTION 2 ] Install DE — Mode B: Bundle (tasksel, full packages)${RST}"
    separator
    echo
    echo -e "  Installs the full official Debian DE bundle via tasksel."
    echo -e "  ${GRN}+${RST} Office suite, extra apps, and all recommends included"
    echo -e "  ${GRN}+${RST} PipeWire installed — audio works via SSH X11 forwarding"
    echo -e "  ${YLW}~${RST} Larger disk footprint (~3–8 GB depending on DE)"
    echo -e "  ${YLW}~${RST} ~/.xsession written for reliable xRDP DE detection"
    echo -e "  ${RED}✗${RST} Audio via Windows RDP or other RDP clients still unresolved"
    echo
    echo -e "  ${BLD}tasksel will open its own interactive menu to select the DE.${RST}"
    echo -e "${DIM}  All existing DEs + users will be purged first. A new xRDP user${RST}"
    echo -e "${DIM}  will be created before tasksel runs.${RST}"
    echo
    echo -e "  Available tasksel DE tasks for reference:"
    separator
    printf "  %-20s %-10s %-12s %s\n" "Name" "RAM Idle" "X11/xRDP" "tasksel task"
    separator
    for i in $(seq 1 $DE_COUNT); do
        task="${TASKSEL_TASK[$i]}"
        [[ -z "$task" ]] && task="(not available)"
        cat="${DE_CATEGORY_B[$i]}"
        badge=$(category_badge "$cat")
        if [[ "$cat" == "unsupported" ]]; then
            printf "  ${STK}%-20s${RST} %-10s ${DE_X11_COLOR[$i]}%-12s${RST} %b  %s\n" \
                "${DE_NAME[$i]}" "${DE_RAM[$i]}" "${DE_X11[$i]}" "$badge" "$task"
        else
            printf "  %-20s %-10s ${DE_X11_COLOR[$i]}%-12s${RST} %b  %s\n" \
                "${DE_NAME[$i]}" "${DE_RAM[$i]}" "${DE_X11[$i]}" "$badge" "$task"
        fi
    done
    separator
    echo -e "  ${DIM}  After tasksel closes, xRDP installer runs and ~/.xsession is written.${RST}"
    echo -e "  ${DIM}  The DE you select in tasksel must match what gets written to ~/.xsession.${RST}"
    echo -e "  ${DIM}  Script will ask which DE you selected so it can write the correct command.${RST}"
    echo

    read -rp "  Continue? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "  Cancelled."; pause; return; }

    purge_existing
    setup_rdp_user

    echo
    echo -e "${CYN}  [1/3] Installing tasksel + DE bundle...${RST}"
    separator
    apt-get update -y
    apt-get install -y tasksel
    # tasksel opens its own ncurses menu — user selects DE interactively
    tasksel

    # Ask which DE was selected so we can write the correct ~/.xsession
    echo
    echo -e "${BLD}  Which DE did you select in tasksel?${RST}"
    echo -e "${DIM}  This is needed to write the correct ~/.xsession for xRDP.${RST}"
    echo
    for i in $(seq 1 $DE_COUNT); do
        [[ -n "${TASKSEL_TASK[$i]}" ]] && \
        [[ "${DE_CATEGORY_B[$i]}" != "unsupported" ]] && \
        echo "    $i)  ${DE_NAME[$i]}"
    done
    echo
    read -rp "  Enter number: " de_choice
    if ! [[ "$de_choice" =~ ^[0-9]+$ ]] || \
       [[ "$de_choice" -lt 1 ]] || [[ "$de_choice" -gt $DE_COUNT ]] || \
       [[ -z "${TASKSEL_TASK[$de_choice]}" ]]; then
        echo -e "${YLW}  Invalid or unavailable choice — skipping ~/.xsession write.${RST}"
        CHOSEN_NAME="unknown"
        CHOSEN_XSESSION=""
    else
        CHOSEN_NAME="${DE_NAME[$de_choice]}"
        CHOSEN_XSESSION="${DE_XSESSION[$de_choice]}"
    fi

    run_xrdp_installer "$NEW_USER"

    if [[ -n "$CHOSEN_XSESSION" ]]; then
        echo
        echo -e "${CYN}  [2/4] Writing ~/.xsession for '${NEW_USER}'...${RST}"
        write_xsession "$NEW_USER" "$CHOSEN_XSESSION"
    else
        echo -e "${YLW}  [2/4] Skipped ~/.xsession — write it manually if xRDP shows black screen.${RST}"
    fi

    setup_pipewire "$NEW_USER"

    echo
    echo -e "${GRN}  ✓ Mode B installation complete.${RST}"
    echo -e "${GRN}    User: ${NEW_USER} | DE: ${CHOSEN_NAME} | xRDP: ready${RST}"
    echo -e "  ${DIM}⚠ Reminder: xRDP port 3389 is currently public. Consider firewall rules${RST}"
    echo -e "  ${DIM}  to restrict access to your static IP and VPN internal range.${RST}"
    echo
    echo -e "  ${GRN}✓ (with audio)${RST}  Login via Bitvise SSH first, then open a new Remote Desktop connection"
    echo -e "  ${RED}✗ (no audio) ${RST}  Any RDP client → [VPS_IP]:3389 — username: ${NEW_USER}"
    echo -e "  ${DIM}  * Audio only works over X11 forwarding — SSH login is required first.${RST}"
    echo
    echo -e "${CYN}  [4/4] Rebooting in 5 seconds...${RST}"
    echo -e "${DIM}  (Ctrl+C to cancel reboot)${RST}"
    sleep 5
    reboot
}


# ═════════════════════════════════════════════════════════════════════════════
# MAIN MENU
# ═════════════════════════════════════════════════════════════════════════════
main_menu() {
    require_root

    while true; do
        header

        EXISTING=()
        for d in /home/*/; do
            u=$(basename "$d")
            id "$u" &>/dev/null && EXISTING+=("$u")
        done
        if [[ ${#EXISTING[@]} -gt 0 ]]; then
            echo -e "  xRDP user(s): ${GRN}${BLD}${EXISTING[*]}${RST}"
        else
            echo -e "  xRDP user(s): ${YLW}none found in /home${RST}"
        fi
        echo

        echo -e "  ${BLD}Select an option:${RST}"
        echo
        echo   "    1)  Install DE — Mode A: Minimal (apt, no bloat)"
        echo   "    2)  Install DE — Mode B: Bundle (tasksel, full packages)"
        echo   "    0)  Exit"
        echo
        separator
        echo -e "  ${DIM}xRDP installer: xrdp-installer-1.5.5.sh by Griffon — http://www.c-nergy.be/blog${RST}"
        separator
        read -rp "  Choice [0-2]: " choice

        case "$choice" in
            1) install_mode_a ;;
            2) install_mode_b ;;
            0) echo; echo "  Exiting."; echo; exit 0 ;;
            *) echo -e "${RED}  Invalid choice.${RST}"; sleep 1 ;;
        esac
    done
}

main_menu