#!/bin/bash
#
# ==============================================================
# linux-container.sh
# --------------------------------------------------------------
# PURPOSE
#   One-shot helper to prepare an LXC (Linux Container) host and
#   fetch a TurnKey Linux template, in a single run.
#
# MECHANISM (runs in this order, stops early if a step fails)
#
#   STEP 1 - HOST CHECK
#     - Detect the host Linux distribution using `lsb_release`
#       (the package is auto-installed if it's missing).
#     - Report the distro name, version, and codename, and flag
#       whether the host is on an LTS release (Ubuntu LTS
#       codenames) or a Debian stable release.
#     - Verify that `lxc-create` is already installed. If it is
#       not, the script prints the install command and exits,
#       since downloading a template is pointless without the
#       tool that will use it.
#
#   STEP 2 - TEMPLATE SELECTION + DOWNLOAD
#     - TurnKey Linux images are NOT reachable through the
#       stock `lxc-create -t download` template index, because
#       TurnKey serves its images from its own mirror instead of
#       the central linuxcontainers.org project.
#     - This script fetches the directory listing from the
#       TurnKey Proxmox mirror:
#         http://mirror.turnkeylinux.org/turnkeylinux/images/proxmox/
#     - Despite the folder being named "proxmox", these .tar.gz
#       files are plain LXC rootfs tarballs and work fine on a
#       stock Debian-based LXC host, no Proxmox hypervisor
#       required.
#     - The listing is parsed into an interactive menu. Only
#       AFTER a template is selected does the script execute the
#       actual download with `wget`.
#
#   Both steps live in one file so you check readiness first,
#   then pick and download only if the host actually qualifies -
#   no need to run two separate scripts by hand.
#
# DISK NOTE
#   The manual steps printed at the end (lxc-create -> wipe
#   rootfs -> extract tarball) intentionally omit the `-B`
#   backingstore flag, so LXC falls back to the "dir" backend:
#   the container rootfs is just a plain directory on the host
#   filesystem, with no preallocated size, sharing the host's
#   main drive directly and flexibly.
# ==============================================================

set -e

# ---------------- STEP 1: HOST CHECK ----------------

if ! command -v lsb_release >/dev/null 2>&1; then
    echo "[*] lsb_release tidak ditemukan, mencoba instalasi..."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -qq
        sudo apt-get install -y lsb-release
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y redhat-lsb-core
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y redhat-lsb-core
    else
        echo "[!] Tidak bisa auto-install lsb_release. Install manual dulu." >&2
        exit 1
    fi
fi

DISTRO_ID=$(lsb_release -is)
DISTRO_DESC=$(lsb_release -ds)
DISTRO_RELEASE=$(lsb_release -rs)
DISTRO_CODENAME=$(lsb_release -cs)

echo "================================"
echo " Info Host Linux"
echo "================================"
echo "Distro    : $DISTRO_DESC"
echo "ID        : $DISTRO_ID"
echo "Release   : $DISTRO_RELEASE"
echo "Codename  : $DISTRO_CODENAME"
echo "================================"

UBUNTU_LTS_CODENAMES="bionic focal jammy noble"
IS_LTS="tidak diketahui"

case "$DISTRO_ID" in
    Ubuntu)
        if echo "$UBUNTU_LTS_CODENAMES" | grep -qw "$DISTRO_CODENAME"; then
            IS_LTS="YA - Ubuntu LTS ($DISTRO_CODENAME)"
        else
            IS_LTS="BUKAN - rilis interim, dukungan pendek (9 bulan)"
        fi
        ;;
    Debian)
        IS_LTS="Debian stable ($DISTRO_CODENAME) - didukung ~5 tahun via proyek Debian LTS/ELTS"
        ;;
    *)
        IS_LTS="Distro selain Ubuntu/Debian, cek siklus dukungan secara manual"
        ;;
esac

echo "Status LTS: $IS_LTS"
echo "================================"

if command -v lxc-create >/dev/null 2>&1; then
    echo "[OK] lxc-create sudah terpasang, lanjut ke pemilihan template."
else
    echo "[!] lxc-create belum terpasang. Pasang dulu dengan:"
    echo "    sudo apt-get install -y lxc lxc-templates"
    echo "[!] Menghentikan script - pasang lxc-create lalu jalankan ulang."
    exit 1
fi

echo ""

# ---------------- STEP 2: TEMPLATE SELECTION + DOWNLOAD ----------------

BASE_URL="http://mirror.turnkeylinux.org/turnkeylinux/images/proxmox/"
DOWNLOAD_DIR="${1:-$HOME/lxc-templates}"

mkdir -p "$DOWNLOAD_DIR"

echo "[*] Mengambil daftar template dari $BASE_URL ..."
LIST=$(wget -qO- "$BASE_URL" \
    | grep -oE 'href="[^"]+\.gz"' \
    | sed -E 's/href="([^"]+)"/\1/' \
    | sort -u)

if [ -z "$LIST" ]; then
    echo "[!] Gagal mengambil daftar template, atau tidak ada file .tar.gz." >&2
    echo "    Cek koneksi atau buka manual: $BASE_URL" >&2
    exit 1
fi

mapfile -t TEMPLATES <<< "$LIST"

echo ""
echo "Pilih template TurnKey yang mau didownload:"
PS3="Masukkan nomor pilihan: "
select TEMPLATE in "${TEMPLATES[@]}" "Batal"; do
    if [ "$TEMPLATE" == "Batal" ]; then
        echo "Dibatalkan."
        exit 0
    elif [ -n "$TEMPLATE" ]; then
        echo "[*] Dipilih: $TEMPLATE"
        break
    else
        echo "Pilihan tidak valid, coba lagi."
    fi
done

FULL_URL="${BASE_URL}${TEMPLATE}"
echo "[*] Mendownload $TEMPLATE ke $DOWNLOAD_DIR ..."
wget -c "$FULL_URL" -P "$DOWNLOAD_DIR"

echo "[OK] Selesai: $DOWNLOAD_DIR/$TEMPLATE"
echo ""
echo "Langkah lanjutan manual (buat wadah lalu ganti rootfs-nya):"
echo "  sudo lxc-create -n <nama> -t download -- -d debian -r bookworm -a amd64"
echo "  sudo rm -rf /var/lib/lxc/<nama>/rootfs/*"
echo "  sudo tar -xf $DOWNLOAD_DIR/$TEMPLATE -C /var/lib/lxc/<nama>/rootfs/"
echo "  sudo lxc-start -n <nama> -d"
echo ""
echo "Inisialisasi TurnKey (WAJIB - No default passwords, semua password"
echo "diset saat inisialisasi: https://www.turnkeylinux.org/docs/inithooks):"
echo "  sudo lxc-attach -n <nama> -- turnkey-init"
echo "  (muncul menu interaktif: set password root, password Samba, aktifkan Webmin, dll)"
echo ""
echo "Masuk ke dalam container:"
echo "  sudo lxc-attach -n <nama>"
echo ""
echo "Start / stop container:"
echo "  sudo lxc-start -n <nama> -d      # start, jalan di background"
echo "  sudo lxc-stop  -n <nama>         # stop, graceful shutdown"
echo ""
echo "Hapus container (harus di-stop dulu):"
echo "  sudo lxc-stop -n <nama>"
echo "  sudo lxc-destroy -n <nama>"
echo ""
echo "Kalau container-nya banyak, cara melihat & memilih salah satunya:"
echo "  sudo lxc-ls -f                   # daftar semua container + status (RUNNING/STOPPED)"
echo "  sudo lxc-info -n <nama>          # detail status 1 container tertentu"
echo "  -> tinggal ganti <nama> di semua perintah di atas sesuai container targetnya"