#!/usr/bin/env bash
# =============================================================================
# desktop-setup.sh
# Desktop Environment Manager — Headless Linux VPS + xRDP
# Repo: https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice
#
# Tested on  : Debian (Bullseye/Bookworm/Trixie), Ubuntu 22.04/24.04
# Should work: Any Debian/Ubuntu-based distro with apt + systemd
#
# Workflow:
#   1. Purge all existing DE + xRDP packages (clean slate)
#   2. Remove existing /home/* user(s)
#   3. Create new xRDP user (password-based, added to sudo)
#   4. Install chosen DE via tasksel (full official Debian bundle)
#   5. Run Griffon's xrdp-installer as the new user
#   6. Write ~/.xsession for the new user
#   7. Install PipeWire audio stack
#   8. Reboot
#
# Key workaround: writes ~/.xsession for the xRDP user so xRDP can
# reliably detect and launch the correct DE. Without ~/.xsession, xRDP
# falls back to a black screen or wrong DE.
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

# ── DE definitions ────────────────────────────────────────────────────────────
DE_COUNT=8

DE_NAME[1]="LXDE";           DE_RAM[1]="~150 MB";  DE_X11[1]="✓ X11";     DE_X11_COLOR[1]="$GRN"
DE_XSESSION[1]="startlxde";  DE_CATEGORY[1]="recommended"; TASKSEL_TASK[1]="lxde-desktop"

DE_NAME[2]="Xfce  ★";        DE_RAM[2]="~200 MB";  DE_X11[2]="✓ X11";     DE_X11_COLOR[2]="$GRN"
DE_XSESSION[2]="startxfce4"; DE_CATEGORY[2]="recommended"; TASKSEL_TASK[2]="xfce-desktop"

DE_NAME[3]="MATE";            DE_RAM[3]="~250 MB";  DE_X11[3]="✓ X11";     DE_X11_COLOR[3]="$GRN"
DE_XSESSION[3]="mate-session"; DE_CATEGORY[3]="recommended"; TASKSEL_TASK[3]="mate-desktop"

DE_NAME[4]="LXQt";            DE_RAM[4]="~300 MB";  DE_X11[4]="✓ X11";     DE_X11_COLOR[4]="$GRN"
DE_XSESSION[4]="startlxqt";  DE_CATEGORY[4]="recommended"; TASKSEL_TASK[4]="lxqt-desktop"
# LXQt confirmed working via tasksel

DE_NAME[5]="GNOME Flashback"; DE_RAM[5]="~400 MB";  DE_X11[5]="✓ X11";     DE_X11_COLOR[5]="$GRN"
DE_XSESSION[5]="gnome-session --session=gnome-flashback-metacity"
DE_CATEGORY[5]="caution";     TASKSEL_TASK[5]=""    # no dedicated tasksel task

DE_NAME[6]="Cinnamon";        DE_RAM[6]="~600 MB";  DE_X11[6]="✓ X11";     DE_X11_COLOR[6]="$GRN"
DE_XSESSION[6]="cinnamon-session"; DE_CATEGORY[6]="caution"; TASKSEL_TASK[6]="cinnamon-desktop"

DE_NAME[7]="KDE Plasma";      DE_RAM[7]="~800 MB";  DE_X11[7]="✗ Wayland"; DE_X11_COLOR[7]="$RED"
DE_XSESSION[7]="startplasma-x11"; DE_CATEGORY[7]="caution"; TASKSEL_TASK[7]="kde-desktop"

DE_NAME[8]="GNOME";           DE_RAM[8]="~1.5 GB";  DE_X11[8]="✗ Wayland"; DE_X11_COLOR[8]="$RED"
DE_XSESSION[8]="gnome-session"; DE_CATEGORY[8]="unsupported"; TASKSEL_TASK[8]="gnome-desktop"
# GNOME: Wayland-only, black screen on xRDP

# ── Category badge ────────────────────────────────────────────────────────────
category_badge() {
    case "$1" in
        recommended) echo -e "${GRN}Recommended${RST}" ;;
        caution)     echo -e "${YLW}Caution    ${RST}" ;;
        unsupported) echo -e "${RED}Unsupported${RST}" ;;
    esac
}

# ── DE selection table ────────────────────────────────────────────────────────
show_de_table() {
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
# Purge existing DE + xRDP
# ═════════════════════════════════════════════════════════════════════════════
purge_existing() {
    echo
    echo -e "${CYN}  [0/?] Purging existing DE + xRDP installation...${RST}"
    apt-get purge -y \
        mate-* libmate-* debian-mate-* \
        gnome-* libgnome-* gir1.2-mate* gir1.2-gnome* \
        xfce4* xfwm4* xfdesktop4* thunar* libxfce4* xfce4-* \
        lxde* lxde-* lxterminal* pcmanfm* openbox* \
        lxqt* lxqt-* qterminal* pcmanfm-qt* \
        cinnamon* nemo* \
        kde-* plasma-* konsole* dolphin* kwin* \
        gdm3* lightdm* sddm* \
        xrdp* xorgxrdp* \
        pipewire* wireplumber* pipewire-module-xrdp* pulseaudio* libcanberra* \
        xdg-desktop-portal* \
        chromium* remmina* \
        tasksel* \
        pinentry-gnome3 libpam-gnome-keyring \
        libblockdev* libgnome-games-support* \
        gnome-games-support* 2>/dev/null || true
    apt-get autoremove --purge -y
    apt-get autoclean
    rm -rf \
        /usr/share/xsessions \
        /etc/xrdp /usr/lib/xrdp /usr/share/xrdp \
        /usr/share/wayland-sessions \
        /usr/share/sddm /usr/share/gdm \
        /etc/X11/Xwrapper.config
    echo -e "  ${GRN}✓ Previous installation cleared.${RST}"
}

# ═════════════════════════════════════════════════════════════════════════════
# Remove existing /home/* users and create new xRDP user
# ═════════════════════════════════════════════════════════════════════════════
setup_rdp_user() {
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

    useradd -m -s /bin/bash "$NEW_USER"
    if [[ ! -d "/home/${NEW_USER}" ]]; then
        echo -e "${YLW}  Home dir missing — creating via mkhomedir_helper...${RST}"
        mkhomedir_helper "$NEW_USER"
    fi
    echo "${NEW_USER}:${pw1}" | chpasswd
    usermod -aG sudo "$NEW_USER"
    echo -e "  ${GRN}✓ User '${NEW_USER}' created and added to sudo.${RST}"
}

# ═════════════════════════════════════════════════════════════════════════════
# Download and run Griffon's xrdp-installer as the new user
# ═════════════════════════════════════════════════════════════════════════════
run_xrdp_installer() {
    local rdp_user="$1"

    echo
    echo -e "${CYN}  Installing xRDP via Griffon xrdp-installer-1.5.5.sh...${RST}"
    separator
    echo -e "${DIM}  Credit: Griffon — http://www.c-nergy.be/blog${RST}"
    echo

    apt-get install -y --no-install-recommends lsb-release curl

    # Griffon script rejects root — must run as normal user via su -.
    # Griffon uses sudo internally; pipe from curl removes TTY so sudo cannot
    # prompt for password. Grant temporary NOPASSWD for the duration of install,
    # then remove immediately after.
    echo "${rdp_user} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/xrdp-install-tmp
    chmod 440 /etc/sudoers.d/xrdp-install-tmp

    echo -e "${CYN}  Running xrdp-installer as '${rdp_user}'...${RST}"
    curl -fsSL \
        https://raw.githubusercontent.com/setiyadi-ben/Linux-Engineer-Applied-Practice/refs/heads/main/l-e-a-p/deployment-workflow/scripts/configs/xrdp-installer-1.5.5.sh \
        | su - "$rdp_user" -c "bash -s -- --unsupported"

    rm -f /etc/sudoers.d/xrdp-install-tmp
    echo -e "  ${GRN}✓ Temporary NOPASSWD sudoers rule removed.${RST}"
}

# ═════════════════════════════════════════════════════════════════════════════
# Write ~/.xsession for the xRDP user
# ═════════════════════════════════════════════════════════════════════════════
write_xsession() {
    local rdp_user="$1"
    local xsession_cmd="$2"
    local xsession_file="/home/${rdp_user}/.xsession"

    echo "#!/bin/sh" > "$xsession_file"
    echo "exec ${xsession_cmd}" >> "$xsession_file"
    chmod +x "$xsession_file"
    chown "${rdp_user}:${rdp_user}" "$xsession_file"

    echo -e "  ${GRN}✓ ~/.xsession written: exec ${xsession_cmd}${RST}"
}

# ═════════════════════════════════════════════════════════════════════════════
# Install and enable PipeWire for xRDP audio
# ═════════════════════════════════════════════════════════════════════════════
setup_pipewire() {
    local rdp_user="$1"
    local rdp_uid
    rdp_uid=$(id -u "$rdp_user")

    echo
    echo -e "${CYN}  Installing PipeWire audio stack...${RST}"
    separator

    apt-get install -y pipewire pipewire-pulse wireplumber pipewire-module-xrdp

    su - "$rdp_user" -c \
        "XDG_RUNTIME_DIR=/run/user/${rdp_uid} systemctl --user mask pulseaudio.service pulseaudio.socket" \
        2>/dev/null || true

    su - "$rdp_user" -c \
        "XDG_RUNTIME_DIR=/run/user/${rdp_uid} systemctl --user enable pipewire pipewire-pulse wireplumber"

    echo -e "  ${GRN}✓ PipeWire installed and enabled for '${rdp_user}'.${RST}"
    echo -e "  ${DIM}  xrdp-sink will appear after first xRDP login.${RST}"
}

# ═════════════════════════════════════════════════════════════════════════════
# Install extra applications (Remmina, Chromium)
# ═════════════════════════════════════════════════════════════════════════════
install_extra_apps() {
    echo
    echo -e "${CYN}  [2/4] Installing extra applications (Remmina, Chromium)...${RST}"
    separator
    apt-get install -y remmina remmina-plugin-rdp remmina-plugin-vnc chromium
    echo -e "  ${GRN}✓ Remmina and Chromium installed.${RST}"
}

# ═════════════════════════════════════════════════════════════════════════════
# Install DE (single flow)
# ═════════════════════════════════════════════════════════════════════════════
install_de() {
    local de_choice="$1"

    CHOSEN_NAME="${DE_NAME[$de_choice]}"
    CHOSEN_XSESSION="${DE_XSESSION[$de_choice]}"
    CHOSEN_CAT="${DE_CATEGORY[$de_choice]}"
    CHOSEN_TASK="${TASKSEL_TASK[$de_choice]}"

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
    echo    "  │  About to install:                                               │"
    printf  "  │    DE          : %-49s│\n" "$CHOSEN_NAME"
    printf  "  │    tasksel task: %-49s│\n" "${CHOSEN_TASK:-(not available)}"
    printf  "  │    xSession    : %-49s│\n" "$CHOSEN_XSESSION"
    echo    "  │    xRDP        : Griffon xrdp-installer-1.5.5.sh                │"
    echo    "  │    Extra apps  : Remmina (RDP/VNC client) + Chromium browser    │"
    echo    "  │    Audio       : PipeWire (SSH X11 forwarding only)             │"
    echo    "  │  System reboots when done. Connect via RDP on port 3389.        │"
    echo -e "  └──────────────────────────────────────────────────────────────────┘${RST}"
    echo
    read -rp "  Continue? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "  Cancelled."; pause; return; }

    purge_existing
    setup_rdp_user

    echo
    echo -e "${CYN}  [1/4] Installing tasksel + DE bundle...${RST}"
    separator
    apt-get update -y
    apt-get install -y tasksel

    if [[ -n "$CHOSEN_TASK" ]]; then
        echo -e "${CYN}  Installing tasksel task: ${CHOSEN_TASK}...${RST}"
        tasksel install "$CHOSEN_TASK"
    else
        echo -e "${YLW}  No dedicated tasksel task for ${CHOSEN_NAME}.${RST}"
        echo -e "${DIM}  Opening tasksel interactive menu — select the closest available task.${RST}"
        tasksel
    fi

    install_extra_apps

    run_xrdp_installer "$NEW_USER"

    echo
    echo -e "${CYN}  [3/4] Writing ~/.xsession...${RST}"
    write_xsession "$NEW_USER" "$CHOSEN_XSESSION"

    setup_pipewire "$NEW_USER"

    echo
    echo -e "${GRN}  ✓ Installation complete.${RST}"
    echo -e "${GRN}    User: ${NEW_USER} | DE: ${CHOSEN_NAME} | xRDP: ready${RST}"
    separator
    echo -e "  ${DIM}⚠ Reminder: xRDP port 3389 is currently public. Consider firewall rules${RST}"
    echo -e "  ${DIM}  to restrict access to your static IP and VPN internal range.${RST}"
    echo
    echo -e "  ${GRN}✓ (with audio)${RST}  Login via Bitvise SSH first, then open Remote Desktop"
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
        separator
        echo -e "  ${GRN}+${RST} Full official Debian DE bundle via tasksel"
        echo -e "  ${GRN}+${RST} ~/.xsession written for reliable xRDP DE detection"
        echo -e "  ${YLW}~${RST} Audio via SSH X11 forwarding only (e.g. Bitvise)"
        echo -e "  ${RED}✗${RST} Audio will NOT work via Windows RDP or other RDP clients"
        separator

        show_de_table

        echo -e "  ${DIM}Select a DE number to install, or 0 to exit.${RST}"
        echo
        separator
        echo -e "  ${DIM}xRDP installer: xrdp-installer-1.5.5.sh by Griffon — http://www.c-nergy.be/blog${RST}"
        separator
        read -rp "  Choice [0-${DE_COUNT}]: " choice

        if [[ "$choice" == "0" ]]; then
            echo; echo "  Exiting."; echo; exit 0
        elif [[ "$choice" =~ ^[0-9]+$ ]] && \
             [[ "$choice" -ge 1 ]] && [[ "$choice" -le $DE_COUNT ]]; then
            install_de "$choice"
        else
            echo -e "${RED}  Invalid choice.${RST}"; sleep 1
        fi
    done
}

main_menu