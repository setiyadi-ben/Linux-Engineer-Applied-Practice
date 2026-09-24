#!/bin/sh
set -e

HOSTS_FILE="/etc/hosts"

if [ "$(id -u)" -ne 0 ]; then
    echo "[!] Skrip ini wajib dijalankan sebagai root." >&2
    exit 1
fi

show_info() {
    echo "================================================================="
    echo "            L-E-A-P LOCAL DNS MANAGER (ALPINE LXC)               "
    echo "================================================================="
    echo "Lokasi Manual : $HOSTS_FILE"
    echo "Format Domain : <category>-<service>-<nomor>.<region>.local"
    echo "Reload Service: rc-service dnsmasq reload"
    echo "================================================================="
}

list_records() {
    echo ""
    echo "--- Daftar Entri DNS Lokal Saat Ini ($HOSTS_FILE) ---"
    grep -E '^[0-9]{1,3}\.' "$HOSTS_FILE" || echo "(Belum ada entri kustom)"
    echo "---------------------------------------------------------"
}

add_record() {
    echo ""
    echo "--- Tambah Entri DNS Baru ---"
    printf "Masukkan IP Address (misal: 10.20.1.3): "
    read ip_addr
    printf "Masukkan Hostname   (misal: prod-mysql-1.sgp.local): "
    read hostname

    if [ -z "$ip_addr" ] || [ -z "$hostname" ]; then
        echo "[!] IP Address dan Hostname tidak boleh kosong."
        return
    fi

    if grep -q -w "$hostname" "$HOSTS_FILE"; then
        echo "[!] Hostname '$hostname' sudah terdaftar di $HOSTS_FILE!"
        return
    fi

    echo "$ip_addr    $hostname" >> "$HOSTS_FILE"
    echo "[+] Berhasil menambahkan: $ip_addr -> $hostname"
    reload_dnsmasq
}

delete_record() {
    echo ""
    echo "--- Hapus Entri DNS ---"
    printf "Masukkan Hostname yang ingin dihapus: "
    read hostname

    if [ -z "$hostname" ]; then
        echo "[!] Hostname tidak boleh kosong."
        return
    fi

    if grep -q -w "$hostname" "$HOSTS_FILE"; then
        sed -i "/\b$hostname\b/d" "$HOSTS_FILE"
        echo "[+] Entri '$hostname' berhasil dihapus dari $HOSTS_FILE."
        reload_dnsmasq
    else
        echo "[!] Hostname '$hostname' tidak ditemukan."
    fi
}

update_record() {
    echo ""
    echo "--- Perbarui IP Hostname ---"
    printf "Masukkan Hostname yang ingin diperbarui IP-nya: "
    read hostname

    if grep -q -w "$hostname" "$HOSTS_FILE"; then
        printf "Masukkan IP Address Baru: "
        read new_ip
        sed -i "/\b$hostname\b/c\\$new_ip    $hostname" "$HOSTS_FILE"
        echo "[+] Entri '$hostname' diperbarui ke IP $new_ip."
        reload_dnsmasq
    else
        echo "[!] Hostname '$hostname' tidak ditemukan."
    fi
}

reload_dnsmasq() {
    echo "[*] Memuat ulang service dnsmasq..."
    rc-service dnsmasq reload
    echo "✓ Dnsmasq berhasil diperbarui."
}

while true; do
    show_info
    echo " [1] Lihat Daftar Entri DNS Lokal"
    echo " [2] Tambah Entri DNS Baru"
    echo " [3] Perbarui IP Entri DNS"
    echo " [4] Hapus Entri DNS"
    echo " [5] Muat Ulang (Reload) Dnsmasq Manual"
    echo " [0] Keluar"
    echo ""
    printf "Pilih opsi [0-5]: "
    read choice

    case "$choice" in
        1) list_records; printf "\nTekan [Enter] untuk kembali..."; read dummy ;;
        2) add_record; printf "\nTekan [Enter] untuk kembali..."; read dummy ;;
        3) update_record; printf "\nTekan [Enter] untuk kembali..."; read dummy ;;
        4) delete_record; printf "\nTekan [Enter] untuk kembali..."; read dummy ;;
        5) reload_dnsmasq; printf "\nTekan [Enter] untuk kembali..."; read dummy ;;
        0) echo "Keluar."; exit 0 ;;
        *) echo "[!] Pilihan tidak valid."; sleep 1 ;;
    esac
done