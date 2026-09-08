#!/usr/bin/env bash
# =============================================================================
# Modular Desktop Environment & xRDP Manager
# =============================================================================

# ── ANSI Colors ──────────────────────────────────────────────────────────────
RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
CYN='\033[0;36m'
BLD='\033[1m'
DIM='\033[2m'
RST='\033[0m'

# ── DE Definitions for Table & .xsession ─────────────────────────────────────
DE_NAME=("" "LXDE" "Xfce" "MATE" "LXQt" "GNOME Flashback" "Cinnamon" "KDE Plasma" "GNOME")
DE_RAM=("" "~150 MB" "~200 MB" "~250 MB" "~300 MB" "~400 MB" "~600 MB" "~800 MB" "~1.5 GB")
DE_X11=("" "✓ X11" "✓ X11" "✓ X11" "✓ X11" "✓ X11" "✓ X11" "✗ Wayland" "✗ Wayland")
DE_XSESSION=("" "startlxde" "startxfce4" "mate-session" "startlxqt" "gnome-session --session=gnome-flashback-metacity" "cinnamon-session" "startplasma-x11" "gnome-session")

require_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[!] Jalankan script ini dengan sudo atau sebagai root.${RST}"
        exit 1
    fi
}

pause() {
    echo
    read -rp "Tekan [Enter] untuk kembali ke menu utama..."
}

show_de_table() {
    echo -e "${CYN}${BLD}  Referensi Kebutuhan Desktop Environment (DE)${RST}"
    echo -e "${DIM}  ──────────────────────────────────────────────────────────${RST}"
    printf "  %-4s %-18s %-10s %-12s\n" "No" "Nama DE" "Idle RAM" "Kompabilitas"
    echo -e "${DIM}  ──────────────────────────────────────────────────────────${RST}"
    for i in {1..8}; do
        if [[ "${DE_X11[$i]}" == *"✗"* ]]; then
            printf "  %-4s %-18s %-10s ${RED}%-12s${RST}\n" "$i)" "${DE_NAME[$i]}" "${DE_RAM[$i]}" "${DE_X11[$i]}"
        else
            printf "  %-4s %-18s %-10s ${GRN}%-12s${RST}\n" "$i)" "${DE_NAME[$i]}" "${DE_RAM[$i]}" "${DE_X11[$i]}"
        fi
    done
    echo -e "${DIM}  ──────────────────────────────────────────────────────────${RST}"
}

# ── 1. Purge DE ──────────────────────────────────────────────────────────────
purge_de() {
    echo -e "\n${CYN}[*] Memulai pembersihan Desktop Environment & xRDP...${RST}"
    apt-get purge -y \
        mate-* libmate-* debian-mate-* gnome-* libgnome-* gir1.2-mate* gir1.2-gnome* \
        xfce4* xfwm4* xfdesktop4* thunar* libxfce4* lxde* lxde-* lxterminal* pcmanfm* openbox* \
        lxqt* qterminal* pcmanfm-qt* cinnamon* nemo* kde-* plasma-* konsole* dolphin* kwin* \
        gdm3* lightdm* sddm* xrdp* xorgxrdp* pipewire* wireplumber* pulseaudio* \
        tasksel* chromium* remmina* 2>/dev/null || true
    
    apt-get autoremove --purge -y
    apt-get autoclean
    rm -rf /usr/share/xsessions /etc/xrdp /usr/lib/xrdp /usr/share/xrdp /usr/share/wayland-sessions /etc/X11/Xwrapper.config
    echo -e "${GRN}✓ Purge selesai. Data user di /home tetap dipertahankan.${RST}"
}

# ── 2. Purge DE & Delete Specific User ───────────────────────────────────────
delete_specific_user() {
    purge_de
    echo -e "\n${CYN}[*] Deteksi User di /home...${RST}"
    
    mapfile -t EXISTING_USERS < <(for d in /home/*/; do u=$(basename "$d"); id "$u" &>/dev/null && echo "$u"; done)
    
    if [[ ${#EXISTING_USERS[@]} -eq 0 ]]; then
        echo -e "${YLW}Tidak ada user yang ditemukan di /home.${RST}"
        return
    fi

    echo -e "Pilih user yang ingin dihapus beserta datanya:"
    for i in "${!EXISTING_USERS[@]}"; do
        echo "  $((i+1))) ${EXISTING_USERS[$i]}"
    done
    echo "  0) Batal"
    
    read -rp "Pilihan: " u_choice
    if [[ "$u_choice" -gt 0 ]] && [[ "$u_choice" -le "${#EXISTING_USERS[@]}" ]]; then
        target_del="${EXISTING_USERS[$((u_choice-1))]}"
        echo -e "${RED}Menghapus user '$target_del' dan direktori /home/$target_del...${RST}"
        loginctl terminate-user "$target_del" 2>/dev/null || true
        pkill -9 -u "$target_del" 2>/dev/null || true
        sleep 1
        userdel -r -f "$target_del"
        echo -e "${GRN}✓ User '$target_del' berhasil dihapus.${RST}"
    else
        echo -e "${DIM}Dibatalkan.${RST}"
    fi
}

# ── 3. Setup xRDP & .xsession ────────────────────────────────────────────────
setup_xrdp() {
    echo -e "\n${CYN}[*] Setup xRDP & .xsession${RST}"
    read -rp "Apakah Anda ingin membuat user baru untuk xRDP? [y/N]: " create_new
    
    TARGET_USER=""
    
    if [[ "$create_new" =~ ^[Yy]$ ]]; then
        read -rp "Masukkan username baru: " TARGET_USER
        useradd -m -s /bin/bash "$TARGET_USER"
        echo -e "${CYN}Set password untuk $TARGET_USER:${RST}"
        passwd "$TARGET_USER"
        usermod -aG sudo "$TARGET_USER"
        echo -e "${GRN}✓ User '$TARGET_USER' dibuat dan masuk grup sudo.${RST}"
    else
        mapfile -t EXISTING_USERS < <(for d in /home/*/; do u=$(basename "$d"); id "$u" &>/dev/null && echo "$u"; done)
        if [[ ${#EXISTING_USERS[@]} -eq 0 ]]; then
            echo -e "${RED}Tidak ada user! Buat user terlebih dahulu.${RST}"
            return
        fi
        echo -e "\nPilih user untuk instalasi xRDP:"
        for i in "${!EXISTING_USERS[@]}"; do
            echo "  $((i+1))) ${EXISTING_USERS[$i]}"
        done
        read -rp "Pilihan: " u_choice
        if [[ "$u_choice" -gt 0 ]] && [[ "$u_choice" -le "${#EXISTING_USERS[@]}" ]]; then
            TARGET_USER="${EXISTING_USERS[$((u_choice-1))]}"
        else
            echo -e "${RED}Pilihan tidak valid.${RST}"
            return
        fi
    fi

    echo -e "\n${YLW}Pilih DE yang akan ditulis ke ~/.xsession untuk $TARGET_USER:${RST}"
    for i in {1..8}; do
        echo "  $i) ${DE_NAME[$i]} (${DE_XSESSION[$i]})"
    done
    read -rp "Pilih nomor [1-8]: " session_choice
    
    if [[ "$session_choice" -ge 1 ]] && [[ "$session_choice" -le 8 ]]; then
        CHOSEN_XSESSION="${DE_XSESSION[$session_choice]}"
    else
        CHOSEN_XSESSION="startxfce4" # Fallback
    fi

    # Griffon xRDP Install with su - trick
    echo -e "\n${CYN}[*] Menjalankan xrdp-installer (Griffon) sebagai '$TARGET_USER'...${RST}"
    apt-get install -y --no-install-recommends lsb-release curl sudo
    
    echo "${TARGET_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/xrdp-tmp
    chmod 440 /etc/sudoers.d/xrdp-tmp

    curl -fsSL https://raw.githubusercontent.com/setiyadi-ben/Linux-Engineer-Applied-Practice/refs/heads/main/linux%20server%20environment%20setup/xrdp-installer-1.5.5.sh | su - "$TARGET_USER" -c "bash -s -- --unsupported"
    
    rm -f /etc/sudoers.d/xrdp-tmp

    # Write .xsession
    XFILE="/home/${TARGET_USER}/.xsession"
    echo "#!/bin/sh" > "$XFILE"
    echo "exec $CHOSEN_XSESSION" >> "$XFILE"
    chmod +x "$XFILE"
    chown "${TARGET_USER}:${TARGET_USER}" "$XFILE"
    echo -e "${GRN}✓ ~/.xsession ditulis: exec $CHOSEN_XSESSION${RST}"

    # PipeWire Audio Setup
    apt-get install -y pipewire pipewire-pulse wireplumber pipewire-module-xrdp
    T_UID=$(id -u "$TARGET_USER")
    su - "$TARGET_USER" -c "XDG_RUNTIME_DIR=/run/user/${T_UID} systemctl --user mask pulseaudio.service pulseaudio.socket 2>/dev/null" || true
    su - "$TARGET_USER" -c "XDG_RUNTIME_DIR=/run/user/${T_UID} systemctl --user enable pipewire pipewire-pulse wireplumber"
    echo -e "${GRN}✓ xRDP & Audio berhasil di-setup untuk '$TARGET_USER'.${RST}"
}

# ── 4. Install DE via Tasksel ────────────────────────────────────────────────
install_tasksel() {
    echo -e "\n${CYN}[*] Mempersiapkan Tasksel...${RST}"
    apt-get update -y
    apt-get install -y tasksel
    echo -e "${GRN}✓ Menjalankan antarmuka Tasksel...${RST}"
    tasksel
    echo -e "\n${GRN}Instalasi via Tasksel selesai.${RST}"
    echo -e "${DIM}Sebaiknya lakukan reboot jika DE baru saja diinstal.${RST}"
}

# ── Main Menu Loop ───────────────────────────────────────────────────────────
main_menu() {
    require_root
    while true; do
        clear
        echo -e "${BLD}==========================================================${RST}"
        echo -e "${CYN}${BLD}     Desktop Environment & xRDP Manager (Modular)         ${RST}"
        echo -e "${BLD}==========================================================${RST}"
        echo
        show_de_table
        echo
        echo -e "${BLD}  Menu Opsi:${RST}"
        echo -e "  ${GRN}1)${RST} Purge DE (Keep User Data)"
        echo -e "  ${GRN}2)${RST} Purge DE & Delete Specific User"
        echo -e "  ${GRN}3)${RST} Setup xRDP & .xsession (via xrdp-installer)"
        echo -e "  ${GRN}4)${RST} Install DE via Tasksel (Auto Root)"
        echo -e "  ${RED}0)${RST} Keluar"
        echo
        read -rp "Pilih opsi [0-4]: " menu_choice

        case "$menu_choice" in
            1) purge_de; pause ;;
            2) delete_specific_user; pause ;;
            3) setup_xrdp; pause ;;
            4) install_tasksel; pause ;;
            0) echo "Keluar."; exit 0 ;;
            *) echo -e "${RED}Pilihan tidak valid.${RST}"; sleep 1 ;;
        esac
    done
}

main_menu