#!/usr/bin/env bash
#
# Proxmox SDN provisioning untuk VPS l-e-a-p
#   SNAT (masquerade) + DHCP (dnsmasq SDN) + IPAM (pve) + DNS dinamis (PowerDNS)
#
# Prinsip:
#   1. TIDAK pakai `set -e` global. Setiap tahap berjalan terpisah; kegagalan
#      satu tahap dicatat, lalu script lanjut ke tahap berikutnya.
#   2. Inti jaringan (zone/vnet/subnet/SNAT/DHCP/IPAM) TIDAK bergantung pada
#      PowerDNS. Kalau PowerDNS gagal, zone dibuat tanpa DNS dinamis; perbaiki
#      PowerDNS lalu jalankan script ini lagi (idempotent) untuk menyambungkannya.
#   3. ALUR: tampilkan RENCANA singkat -> konfirmasi y/N -> FLUSH config lama (paket TIDAK
#      dihapus, TANPA backup) -> instalasi. Dengan --no-flush, script tetap idempotent dan
#      aman dijalankan ulang di server yang sudah jadi.
#   4. Jaringan diturunkan dari satu sumber: nama vnet eth1020 = 10.20.x.x, jadi subnet,
#      gateway, rentang DHCP, dan IP DNS semuanya berawalan 10.20 (lihat bagian VARIABEL).
#
# Pakai (opsi CLI mengalahkan environment, environment mengalahkan default):
#   ./sdn-vxlan_provisioning.sh
#   ./sdn-vxlan_provisioning.sh --vnet eth1020 --domain sgp.local
#   ./sdn-vxlan_provisioning.sh --vnet eth1030            # subnet 10.30.0.0/16, gw .1, dns .2, dhcp 10.30.0.101-10.30.255.254
#   ./sdn-vxlan_provisioning.sh --subnet 10.30.0.1/16     # vnet eth1030, gw 10.30.0.1
#   VNET=eth1020 DOMAIN=sgp.local ./sdn-vxlan_provisioning.sh
#   WAN_IP=203.0.113.10 SUBNET=10.30.0.0/16 GW=10.30.0.1 ./sdn-vxlan_provisioning.sh
#
# Log lengkap: /var/log/leap-sdn-setup.log
# Zone saat ini bertipe Simple (satu node). Tipe zone tidak bisa diubah nanti,
# jadi sambungan ke node lain (VXLAN) dibuat sebagai zone baru.

set -uo pipefail

usage() {
  cat <<EOF
Pakai: $0 [-n|--vnet NAMA] [-s|--subnet CIDR] [-d|--domain DOMAIN] [-y|--yes] [--no-flush] [-h|--help]

  -n, --vnet NAMA       nama VNet SDN (env: VNET, default: eth1020; diawali huruf, huruf/angka, maks 8 karakter)
  -s, --subnet CIDR     jaringan SDN (env: SUBNET, default: diturunkan dari vnet; 10.20.0.1/16 = gw 10.20.0.1)
  -d, --domain DOMAIN   zone DNS dinamis (env: DOMAIN, default: sgp.local)
  -y, --yes             lewati pertanyaan konfirmasi (env: ASSUME_YES=1)
      --no-flush        jangan hapus config lama; mode idempotent (env: FLUSH=0)

Vnet berakhiran 4 digit AABB (eth1020) = jaringan AA.BB.0.0/16; gateway/dhcp/dns ikut awalan itu.
Variabel lain lewat environment: ZONE GW DHCP_START DHCP_END DNS_IP DUMMY_IF
PDNS_ID PDNS_AUTH_PORT PDNS_API_PORT UPSTREAMS WAN_IF WAN_IP
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -n|--vnet)     [ $# -ge 2 ] || { echo "$1 butuh nilai" >&2; exit 2; }; VNET=$2; shift 2 ;;
    --vnet=*)      VNET=${1#*=}; shift ;;
    -s|--subnet)   [ $# -ge 2 ] || { echo "$1 butuh nilai" >&2; exit 2; }; SUBNET=$2; shift 2 ;;
    --subnet=*)    SUBNET=${1#*=}; shift ;;
    -d|--domain)   [ $# -ge 2 ] || { echo "$1 butuh nilai" >&2; exit 2; }; DOMAIN=$2; shift 2 ;;
    --domain=*)    DOMAIN=${1#*=}; shift ;;
    -y|--yes)      ASSUME_YES=1; shift ;;
    --no-flush)    FLUSH=0; shift ;;
    -h|--help)     usage; exit 0 ;;
    *)             echo "Opsi tidak dikenal: $1" >&2; usage >&2; exit 2 ;;
  esac
done

LOG=/var/log/leap-sdn-setup.log

### ===================== VARIABEL (bisa di-override lewat environment) =====================
: "${ZONE:=leapnet}"                 # SDN zone (simple)
# CATATAN PENAMAAN (dokumentasi saja, TIDAK dipakai logika script):
#   VNET   eth1020  = "eth" + 10.20 -> merujuk ke subnet 10.20.0.0/16 (SUBNET di bawah).
#   DOMAIN sgp.local = domain region SGP. Guest cukup diberi hostname biasa (web1),
#                      nama lengkapnya web1.sgp.local.
#   SGP dijadikan PUSAT untuk peering di masa depan, bila PVE di region lain
#   (Indonesia, Jepang, dst.) perlu interkoneksi. Region lain memakai pola yang
#   sama: VNet eth10XX untuk 10.XX.0.0/16 dan domain <region>.local, sehingga nama
#   antar region tidak bentrok. Batas nama VNet dari SDN: maks 8 karakter.
#
# INTENSI (belum direalisasikan; hanya penegasan arah, tidak ada logika untuk ini di script):
#   - SEMUA infrastruktur memakai TLD .local di SEMUA region (sgp.local, id.local, jp.local, ...).
#   - Setiap PowerDNS di tiap PVE akan saling mereplikasi record, sehingga VM/LXC yang dibuat
#     di satu region otomatis terlihat dari PVE region lain tanpa konfigurasi manual.
#   - Contoh yang dituju: di PVE Jepang VM/LXC dinamai "app1-test.jp" -> menjadi
#     "app1-test.jp.local", dan record itu tereplika ke semua PVE di Indonesia dan Singapura.
#
# CATATAN DESAIN untuk saat replikasi dikerjakan (agar tidak bentrok dengan DOMAIN di atas):
#   - Pilih SATU konvensi penamaan, jangan dicampur. Contoh salah: DOMAIN=jp.local dengan
#     hostname app1-test.jp menghasilkan app1-test.jp.jp.local.
#       * DOMAIN=<region>.local -> hostname polos (app1-test -> app1-test.jp.local)
#       * DOMAIN=local          -> hostname membawa region (app1-test.jp -> app1-test.jp.local)
#   - Replikasi PowerDNS standar (AXFR/NOTIFY) = satu master per zone. Dengan zone per region
#     (DOMAIN=<region>.local), tiap PowerDNS menjadi master untuk zone region-nya dan secondary
#     untuk zone region lain. Satu zone "local" yang ditulis dari banyak PVE sekaligus tidak
#     bisa direplikasi dengan cara standar itu.
#   - Saat replikasi dikerjakan, forward_zones dan negative_trustanchors di recursor cukup
#     memakai "local" (bukan ${DOMAIN}) agar semua zone region ikut ter-resolve.
#   - SOA-EDIT-API sudah diset di tahap PowerDNS (serial naik saat record dibuat lewat API),
#     yang dibutuhkan replikasi AXFR.

# --- Turunan jaringan: vnet, subnet, gateway, dhcp, dan dns saling cocok --------------------
# Aturan: nama vnet yang berakhiran 4 digit AABB mengacu ke dua oktet pertama jaringan
# (eth1020 = 10.20.x.x). Gateway, rentang DHCP, dan IP DNS memakai awalan yang sama.
# Nilai yang diberikan eksplisit (flag/environment) selalu menang, lalu dicek konsistensinya:
#   --vnet eth1020                -> subnet 10.20.0.0/16, gw 10.20.0.1, dns 10.20.0.2, dhcp 10.20.0.101-10.20.255.254
#   --subnet 10.30.0.0/16         -> vnet eth1030
#   --subnet 10.20.0.1/16         -> alamat host dipakai sebagai gateway (10.20.0.1)
#   --vnet eth1020 --subnet 10.30.0.0/16 -> DITOLAK (tidak cocok). Pakai nama vnet tanpa
#                                   4 digit akhir (mis. lan30) bila memang ingin menyimpang.
die()     { echo "$*" >&2; exit 2; }
is_ipv4() {
  [[ $1 =~ ^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$ ]] || return 1
  (( 10#${BASH_REMATCH[1]} <= 255 && 10#${BASH_REMATCH[2]} <= 255 && 10#${BASH_REMATCH[3]} <= 255 && 10#${BASH_REMATCH[4]} <= 255 ))
}
ip2int()  { local a b c d; IFS=. read -r a b c d <<<"$1"; echo $(( (10#$a << 24) | (10#$b << 16) | (10#$c << 8) | 10#$d )); }
int2ip()  { echo "$(( ($1 >> 24) & 255 )).$(( ($1 >> 16) & 255 )).$(( ($1 >> 8) & 255 )).$(( $1 & 255 ))"; }

_vnet_given=0; _subnet_given=0; _host_ip=""; _vn_a=""; _vn_b=""; NET_NOTE=""
if [ -n "${VNET:-}" ];   then _vnet_given=1;   fi
if [ -n "${SUBNET:-}" ]; then _subnet_given=1; fi
if [ "$_vnet_given" = 0 ] && [ "$_subnet_given" = 0 ]; then VNET=eth1020; fi

if [ -n "${VNET:-}" ] && [[ $VNET =~ ^[A-Za-z]+([0-9]{2})([0-9]{2})$ ]]; then
  _vn_a=$((10#${BASH_REMATCH[1]})); _vn_b=$((10#${BASH_REMATCH[2]}))
fi

if [ "$_subnet_given" = 1 ]; then
  [[ $SUBNET =~ ^([0-9.]+)/([0-9]{1,2})$ ]] || die "SUBNET '${SUBNET}' tidak valid: pakai format A.B.C.D/N."
  _sip=${BASH_REMATCH[1]}; _spfx=$((10#${BASH_REMATCH[2]}))
  { is_ipv4 "$_sip" && (( _spfx >= 8 && _spfx <= 24 )); } || die "SUBNET '${SUBNET}' tidak valid: IPv4 dengan prefix /8 sampai /24."
  _mask=$(( (0xFFFFFFFF << (32 - _spfx)) & 0xFFFFFFFF ))
  _ipint=$(ip2int "$_sip")
  NET=$(( _ipint & _mask ))
  if [ "$_ipint" -ne "$NET" ]; then _host_ip=$_sip; fi
  SUBNET="$(int2ip "$NET")/${_spfx}"
  _na=$(( (NET >> 24) & 255 )); _nb=$(( (NET >> 16) & 255 ))
  if [ "$_vnet_given" = 0 ]; then
    (( _na <= 99 && _nb <= 99 )) || die "SUBNET ${SUBNET} tidak bisa dijadikan nama vnet 8 karakter; set --vnet manual."
    VNET=$(printf 'eth%02d%02d' "$_na" "$_nb")
    NET_NOTE="vnet ${VNET} diturunkan dari subnet ${SUBNET}"
  elif [ -n "$_vn_a" ]; then
    { [ "$_vn_a" -eq "$_na" ] && [ "$_vn_b" -eq "$_nb" ]; } \
      || die "VNET ${VNET} (awalan ${_vn_a}.${_vn_b}) tidak cocok dengan SUBNET ${SUBNET}. Samakan, atau pakai nama vnet tanpa 4 digit akhir."
    NET_NOTE="vnet ${VNET} cocok dengan subnet ${SUBNET}"
  else
    NET_NOTE="vnet ${VNET} tidak berpola AABB: subnet dipakai apa adanya"
  fi
else
  _spfx=16
  if [ -n "$_vn_a" ]; then
    (( _vn_a >= 1 )) || die "VNET ${VNET}: oktet pertama 00 tidak valid."
    NET=$(( (_vn_a << 24) | (_vn_b << 16) ))
    NET_NOTE="subnet diturunkan dari nama vnet ${VNET}"
  else
    NET=$(( (10 << 24) | (20 << 16) ))
    NET_NOTE="vnet ${VNET} tidak berpola AABB: subnet default 10.20.0.0/16"
  fi
  _mask=$(( (0xFFFFFFFF << (32 - _spfx)) & 0xFFFFFFFF ))
  SUBNET="$(int2ip "$NET")/${_spfx}"
fi

: "${GW:=${_host_ip:-$(int2ip $((NET + 1)))}}"     # dipasang SDN di bridge $VNET
: "${DNS_IP:=$(int2ip $((NET + 2)))}"              # IP recursor (dummy). BUKAN $GW: port 53 di $GW dipakai dnsmasq SDN
: "${DHCP_START:=$(int2ip $((NET + 101)))}"                                  # ekor .1-.100 disisakan: gateway, dns, infrastruktur statis
: "${DHCP_END:=$(int2ip $(( (NET | (~_mask & 0xFFFFFFFF)) - 1 )))}"       # alamat terakhir sebelum broadcast (10.20.255.254 untuk /16)

# Konsistensi: semua alamat valid, di dalam subnet, tidak saling bentrok
for _p in GW DNS_IP DHCP_START DHCP_END; do
  _v=${!_p}
  is_ipv4 "$_v" || die "${_p} '${_v}' bukan IPv4 yang valid."
  [ $(( $(ip2int "$_v") & _mask )) -eq "$NET" ] || die "${_p} ${_v} berada di luar SUBNET ${SUBNET}."
done
_ds=$(ip2int "$DHCP_START"); _de=$(ip2int "$DHCP_END")
[ "$_ds" -le "$_de" ] || die "DHCP_START ${DHCP_START} harus <= DHCP_END ${DHCP_END}."
[ "$GW" != "$DNS_IP" ] || die "GW dan DNS_IP tidak boleh sama (port 53 di GW dipakai dnsmasq SDN)."
for _p in GW DNS_IP; do
  _v=$(ip2int "${!_p}")
  if [ "$_v" -ge "$_ds" ] && [ "$_v" -le "$_de" ]; then die "${_p} ${!_p} jatuh di dalam rentang DHCP ${DHCP_START}-${DHCP_END}."; fi
done
: "${DUMMY_IF:=dnsdummy}"
: "${DOMAIN:=sgp.local}"             # zone DNS dinamis (lihat catatan penamaan di atas)
: "${PDNS_ID:=leapdns}"              # nama entri DNS di SDN
: "${PDNS_AUTH_PORT:=5300}"
: "${PDNS_API_PORT:=8081}"
: "${UPSTREAMS:=1.1.1.1 8.8.8.8 9.9.9.9}"    # dipisah spasi; urutan = prioritas

: "${FLUSH:=1}"                      # 1 = flush config lama sebelum instalasi
: "${ASSUME_YES:=0}"                 # 1 = tanpa pertanyaan konfirmasi

: "${WAN_IF:=}"                      # kosong = deteksi dari default route (bridge pemegang IP publik)
: "${WAN_IP:=}"                      # kosong = deteksi dari $WAN_IF

PDNS_API="http://127.0.0.1:${PDNS_API_PORT}/api/v1/servers/localhost"

### ===================== HELPER =====================
OK_STAGES=()
FAILED_STAGES=()

log()  { printf '[%s] %s\n'    "$(date +%H:%M:%S)" "$*"; }
warn() { printf '[%s] !! %s\n' "$(date +%H:%M:%S)" "$*" >&2; }

# stage <nama> <fungsi> : jalankan fungsi di subshell dengan errexit; gagal = dicatat, bukan fatal
stage() {
  local name=$1 fn=$2 rc
  log "=== ${name} ==="
  ( set -e; "$fn" )
  rc=$?
  if [ "$rc" -eq 0 ]; then
    OK_STAGES+=("$name")
  else
    warn "tahap GAGAL: ${name} (kode ${rc})"
    FAILED_STAGES+=("$name")
  fi
}

wait_for() {   # wait_for <detik> <perintah...>
  local t=$1 i; shift
  for ((i = 0; i < t; i++)); do
    if "$@" >/dev/null 2>&1; then return 0; fi
    sleep 1
  done
  return 1
}

pdns_key() { grep -s '^api-key=' /etc/powerdns/pdns.conf | head -n1 | cut -d= -f2; }

pdns_healthy() {
  local k code
  k=$(pdns_key) || true
  [ -n "$k" ] || return 1
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 -H "X-API-Key: ${k}" "${PDNS_API}") || return 1
  [ "$code" = "200" ]
}

journal_tail() { journalctl -u "$1" -n 15 --no-pager -o cat 2>/dev/null | sed "s/^/   $1| /" || true; }

snat_rule()  { echo "-A POSTROUTING -s ${1:-$SUBNET} -o ${WAN_IF} -j SNAT --to-source ${WAN_IP}"; }
snat_count() { iptables -t nat -S POSTROUTING | grep -cxF -- "$(snat_rule "${1:-}")" || true; }

dedupe_snat() {   # tiap apply SDN bisa menambah rule SNAT yang sama; sisakan satu
  local n
  n=$(snat_count)
  while [ "${n:-0}" -gt 1 ]; do
    iptables -t nat -D POSTROUTING -s "$SUBNET" -o "$WAN_IF" -j SNAT --to-source "$WAN_IP" || break
    n=$((n - 1))
  done
}

sdn_apply() {
  pvesh set /cluster/sdn >/dev/null
  sleep 3
}

# --- pembaca config SDN (format cfg PVE: baris "tipe: id", lalu baris berindentasi) ---
cfg_vnets_in_zone()    { awk -v z="$ZONE" '/^vnet:/{v=$2} /^[ \t]+zone[ \t]/{if ($2==z) print v}' /etc/pve/sdn/vnets.cfg 2>/dev/null || true; }
cfg_subnets_of_vnet()  { awk -v n="$1" '/^subnet:/{s=$2} /^[ \t]+vnet[ \t]/{if ($2==n) print s}' /etc/pve/sdn/subnets.cfg 2>/dev/null || true; }
cfg_dnszone()          { awk -v z="$ZONE" '/^[a-z]+:/{c=$2} /^[ \t]+dnszone[ \t]/{if (c==z) print $2}' /etc/pve/sdn/zones.cfg 2>/dev/null || true; }
cfg_has_zone()         { grep -qs "^[a-z]*: ${ZONE}\$" /etc/pve/sdn/zones.cfg; }
cfg_has_dns()          { grep -qs "^powerdns: ${PDNS_ID}\$" /etc/pve/sdn/dns.cfg; }

guests_on_bridges() {   # guests_on_bridges <bridge...> : cetak "lxc/100 (bridge)" untuk guest yang memakainya
  local b f
  for b in "$@"; do
    for f in /etc/pve/nodes/*/lxc/*.conf /etc/pve/nodes/*/qemu-server/*.conf; do
      [ -f "$f" ] || continue
      if grep -qE "^net[0-9]+:.*bridge=${b}(,|\$)" "$f"; then
        echo "$(basename "$(dirname "$f")")/$(basename "$f" .conf) (${b})"
      fi
    done
  done
}

### ===================== PREFLIGHT (satu-satunya bagian yang fatal) =====================
# Validasi input dulu (murni string, tidak menyentuh sistem)
[[ $VNET =~ ^[a-zA-Z][a-zA-Z0-9]{0,7}$ ]] \
  || { echo "VNET '${VNET}' tidak valid: mulai huruf, hanya huruf/angka, maksimal 8 karakter." >&2; exit 2; }
[[ $DOMAIN =~ ^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$ ]] \
  || { echo "DOMAIN '${DOMAIN}' tidak valid: huruf kecil, angka, titik, dan strip saja." >&2; exit 2; }
case "$DOMAIN" in
  local|*.local)
    log "CATATAN: .local dicadangkan untuk mDNS (RFC 6762). Guest dengan avahi/nss-mdns, systemd-resolved" \
        "(mDNS aktif), macOS, atau Windows bisa mengabaikan DNS untuk nama *.local. Alpine/Debian minimal biasanya aman." ;;
esac

[ "$(id -u)" -eq 0 ] || { echo "Jalankan sebagai root." >&2; exit 1; }
command -v pvesh >/dev/null || { echo "pvesh tidak ditemukan: ini bukan node Proxmox." >&2; exit 1; }
[ -d /etc/pve/nodes ] || { echo "/etc/pve belum ter-mount (pve-cluster belum jalan?)." >&2; exit 1; }

if [ -z "$WAN_IF" ]; then
  WAN_IF=$(ip -4 route show default | awk '{for (i = 1; i < NF; i++) if ($i == "dev") { print $(i + 1); exit }}')
fi
if [ -z "$WAN_IP" ] && [ -n "$WAN_IF" ]; then
  WAN_IP=$(ip -4 -o addr show dev "$WAN_IF" | awk '{print $4}' | cut -d/ -f1 | head -n1)
fi
[ -n "$WAN_IF" ] && [ -n "$WAN_IP" ] || { echo "WAN_IF/WAN_IP tidak terdeteksi. Set manual: WAN_IF=vmbr0 WAN_IP=x.x.x.x $0" >&2; exit 1; }

### ===================== RENCANA + KONFIRMASI =====================
print_plan() {
  local vns dz extra_dz
  vns=$(cfg_vnets_in_zone | paste -sd, -)
  dz=$(cfg_dnszone | head -n1)
  extra_dz=""
  if [ -n "$dz" ] && [ "$dz" != "$DOMAIN" ]; then extra_dz=" & ${dz}"; fi
  echo "==================== RENCANA ===================="
  echo "Node    : $(hostname) | WAN ${WAN_IF} ${WAN_IP}"
  echo "SDN     : zone=${ZONE} vnet=${VNET} subnet=${SUBNET} gw=${GW} dhcp=${DHCP_START}-${DHCP_END}"
  echo "Turunan : ${NET_NOTE}"
  echo "DNS     : domain=${DOMAIN} recursor=${DNS_IP} upstream=${UPSTREAMS}"
  echo "Ada     : zone SDN ${ZONE}: $(cfg_has_zone && echo "ya (vnet: ${vns:-tidak ada}, zone DNS: ${dz:-tidak ada})" || echo "tidak ada")"
  if [ "$FLUSH" = 1 ]; then
    echo "FLUSH   : YA. Dihapus: zone+vnet+subnet SDN ${ZONE}, entri DNS ${PDNS_ID}, zone PowerDNS ${DOMAIN}${extra_dz},"
    echo "          config PowerDNS/recursor, dummy ${DUMMY_IF}, rule SNAT ${SUBNET}, file sysctl. Paket TIDAK dihapus."
    echo "PERINGATAN: NO BACKUP. Do it if you know what you are doing."
  else
    echo "FLUSH   : TIDAK (--no-flush): config lama dipertahankan, mode idempotent"
  fi
  echo "================================================="
}

confirm() {
  local ans
  [ "$ASSUME_YES" = 1 ] && return 0
  if [ ! -t 0 ]; then
    echo "Input bukan terminal: tambahkan --yes untuk melewati konfirmasi." >&2
    return 1
  fi
  read -r -p "Lanjutkan? [y/N] " ans
  case "$ans" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

print_plan | tee -a "$LOG"

# Flush menghapus vnet: guest yang masih memakainya akan kehilangan jaringan dan
# subnet berisi IP tidak bisa dihapus. Hentikan sebelum ada yang diubah.
if [ "$FLUSH" = 1 ]; then
  mapfile -t _vnets < <(cfg_vnets_in_zone)
  if [ "${#_vnets[@]}" -gt 0 ]; then
    mapfile -t _guests < <(guests_on_bridges "${_vnets[@]}")
    if [ "${#_guests[@]}" -gt 0 ]; then
      echo
      echo "DIBATALKAN: guest berikut masih memakai vnet yang akan dihapus:" >&2
      printf '  - %s\n' "${_guests[@]}" >&2
      echo "Hapus atau pindahkan dulu guest tersebut, atau jalankan dengan --no-flush. Tidak ada yang diubah." >&2
      exit 1
    fi
  fi
fi

echo
if ! confirm; then
  echo "Dibatalkan. Tidak ada yang diubah."
  exit 1
fi

# Log ke file baru dimulai SETELAH preflight dan konfirmasi: redirect lewat tee bersifat
# asinkron dan bisa menelan pesan yang dicetak tepat sebelum `exit`.
exec > >(tee -a "$LOG") 2>&1
log "Dikonfirmasi (flush=${FLUSH})"

### ===================== TAHAP 0: FLUSH CONFIG LAMA =====================
# Hanya menghapus yang dibuat script ini. TIDAK menyentuh: paket, zone/vnet SDN lain,
# zone PowerDNS lain, guest, /etc/network/interfaces. Nilai runtime sysctl tidak dikembalikan
# (host bisa saja dipakai NAT lain); hanya file persistennya yang dibuang.
st_flush() {
  local v s c z dz n changed=0 fails=0
  local -a vnets=() subnets=() old_cidrs=()

  # Flush = flush: TANPA backup (disengaja, sudah diperingatkan di RENCANA).
  # 1. SDN, urutan: subnet -> vnet -> zone -> entri DNS -> apply. Dikerjakan SEBELUM zone
  #    PowerDNS karena inilah yang paling mungkin gagal (mis. subnet masih berisi IP); kalau
  #    gagal di sini, zone DNS belum tersentuh. Domain lama dicatat dulu sebelum zone SDN hilang.
  dz=$(cfg_dnszone | head -n1)
  mapfile -t vnets < <(cfg_vnets_in_zone)
  for v in ${vnets[@]+"${vnets[@]}"}; do
    mapfile -t subnets < <(cfg_subnets_of_vnet "$v")
    for s in ${subnets[@]+"${subnets[@]}"}; do
      log "hapus subnet ${s} (vnet ${v})"
      c=$(sed -nE 's/^.*-([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)-([0-9]+)$/\1\/\2/p' <<<"$s")
      if [ -n "$c" ]; then old_cidrs+=("$c"); fi
      pvesh delete "/cluster/sdn/vnets/${v}/subnets/${s}" >/dev/null
      changed=1
    done
    log "hapus vnet ${v}"
    pvesh delete "/cluster/sdn/vnets/${v}" >/dev/null
    changed=1
  done
  if cfg_has_zone; then
    log "hapus zone SDN ${ZONE}"
    pvesh delete "/cluster/sdn/zones/${ZONE}" >/dev/null
    changed=1
  fi
  if cfg_has_dns; then
    log "hapus entri DNS SDN ${PDNS_ID}"
    pvesh delete "/cluster/sdn/dns/${PDNS_ID}" >/dev/null
    changed=1
  fi
  if [ "$changed" = 1 ]; then
    sdn_apply
    for v in ${vnets[@]+"${vnets[@]}"}; do
      if ! wait_for 20 bash -c "! ip link show '${v}'"; then
        warn "bridge ${v} masih ada setelah apply"
        fails=1
      fi
    done
  fi

  # 2. Zone PowerDNS (harus SEBELUM pdns.conf dibuang, karena pdnsutil membacanya).
  #    Termasuk zone dari domain lama yang tercatat di zone SDN, bila berbeda dari DOMAIN.
  if command -v pdnsutil >/dev/null 2>&1; then
    for z in $(printf '%s\n' "$DOMAIN" "$dz" | sort -u); do
      [ -n "$z" ] || continue
      if pdnsutil list-zone "$z" >/dev/null 2>&1; then
        log "hapus zone PowerDNS ${z}"
        pdnsutil delete-zone "$z"
      fi
    done
  fi

  # 3. Rule SNAT yang tersisa (apply SDN bisa meninggalkan duplikat), untuk subnet baru
  #    maupun subnet lama yang tercatat di config sebelumnya.
  for c in $(printf '%s\n' "$SUBNET" ${old_cidrs[@]+"${old_cidrs[@]}"} | sort -u); do
    n=0
    while [ "$(snat_count "$c")" -gt 0 ] && [ "$n" -lt 20 ]; do
      iptables -t nat -D POSTROUTING -s "$c" -o "$WAN_IF" -j SNAT --to-source "$WAN_IP" || break
      n=$((n + 1))
    done
  done

  # 4. Dummy interface, service, dan file config buatan script
  ifdown "$DUMMY_IF" >/dev/null 2>&1 || true
  ip link del "$DUMMY_IF" >/dev/null 2>&1 || true
  systemctl stop pdns pdns-recursor >/dev/null 2>&1 || true
  rm -f /etc/network/interfaces.d/leap-dns \
        /etc/powerdns/pdns.conf /etc/powerdns/recursor.conf \
        /etc/sysctl.d/99-leap-forward.conf /etc/sysctl.d/99-nonlocal-bind.conf \
        /usr/sbin/policy-rc.d

  [ "$fails" = 0 ]
}

### ===================== TAHAP 1: PAKET =====================
st_packages() {
  export DEBIAN_FRONTEND=noninteractive
  local rc=0

  # Cegah service start otomatis saat install: dnsmasq, pdns, dan recursor
  # sama-sama mencoba port 53 dan bisa membuat postinst gagal.
  printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d
  chmod +x /usr/sbin/policy-rc.d

  # Proxmox tanpa subscription: repo enterprise memberi error 401 di apt update.
  # Itu tidak fatal selama indeks paket Debian tetap terunduh.
  apt-get update -qq || warn "apt-get update melaporkan error (repo enterprise tanpa subscription?), lanjut"

  apt-get install -y pdns-server pdns-backend-sqlite3 pdns-recursor dnsmasq sqlite3 bind9-dnsutils \
    || rc=1

  rm -f /usr/sbin/policy-rc.d

  # dnsmasq bawaan tidak boleh jalan; SDN menjalankan instance-nya sendiri.
  systemctl disable --now dnsmasq >/dev/null 2>&1 || true

  return "$rc"
}

### ===================== TAHAP 2: POWERDNS AUTHORITATIVE =====================
st_pdns() {
  local DB=/var/lib/powerdns/pdns.sqlite3 KEY schema f

  # Pastikan hanya backend gsqlite3 yang dimuat
  for f in /etc/powerdns/pdns.d/*.conf; do
    [ -e "$f" ] || continue
    if grep -q '^launch' "$f"; then mv "$f" "${f}.disabled"; fi
  done

  # Mesin baru: paket TIDAK membuat schema. Import hanya jika tabel belum ada.
  mkdir -p /var/lib/powerdns
  if ! sqlite3 "$DB" 'select 1 from domains limit 1;' >/dev/null 2>&1; then
    schema=$(find /usr/share/doc/pdns-backend-sqlite3 -name 'schema.sqlite3.sql*' 2>/dev/null | head -n1)
    [ -n "$schema" ] || { warn "schema sqlite PowerDNS tidak ditemukan"; return 1; }
    log "import schema sqlite dari ${schema}"
    case "$schema" in
      *.gz) zcat "$schema" | sqlite3 "$DB" ;;
      *)    sqlite3 "$DB" < "$schema" ;;
    esac
  fi
  chown -R pdns:pdns /var/lib/powerdns

  # Pakai ulang key yang ada; kalau belum ada, buat acak.
  KEY=$(pdns_key) || true
  [ -n "$KEY" ] || KEY=$(openssl rand -hex 32)

  cat > /etc/powerdns/pdns.conf <<EOF
launch=gsqlite3
gsqlite3-database=${DB}
local-address=127.0.0.1
local-port=${PDNS_AUTH_PORT}
api=yes
api-key=${KEY}
webserver=yes
webserver-address=127.0.0.1
webserver-port=${PDNS_API_PORT}
webserver-allow-from=127.0.0.1
EOF
  chown root:pdns /etc/powerdns/pdns.conf
  chmod 640 /etc/powerdns/pdns.conf

  systemctl enable pdns >/dev/null 2>&1 || true
  if ! systemctl restart pdns; then
    warn "pdns gagal start:"; journal_tail pdns
    return 1
  fi
  if ! wait_for 20 pdns_healthy; then
    warn "API PowerDNS tidak merespons 200:"; journal_tail pdns
    return 1
  fi

  # Zone dibuat sekali saja
  if ! pdnsutil list-zone "$DOMAIN" >/dev/null 2>&1; then
    pdnsutil create-zone "$DOMAIN" "ns1.${DOMAIN}"
    pdnsutil add-record "$DOMAIN" ns1 A "$GW"
    pdnsutil replace-rrset "$DOMAIN" @ SOA 3600 "ns1.${DOMAIN}. hostmaster.${DOMAIN}. 1 10800 3600 604800 3600"
    pdnsutil set-meta "$DOMAIN" SOA-EDIT-API INCEPTION-INCREMENT
  fi
}

### ===================== TAHAP 3: RECURSOR + IP DUMMY =====================
st_recursor() {
  local u ups=""

  grep -qs 'interfaces.d' /etc/network/interfaces \
    || warn "/etc/network/interfaces tidak memuat interfaces.d/*; dummy interface tidak persisten"

  cat > /etc/network/interfaces.d/leap-dns <<EOF
auto ${DUMMY_IF}
iface ${DUMMY_IF} inet static
        address ${DNS_IP}/32
        pre-up ip link add ${DUMMY_IF} type dummy || true
        post-down ip link del ${DUMMY_IF} || true
EOF
  ifup "$DUMMY_IF" >/dev/null 2>&1 || true
  if ! ip -4 addr show dev "$DUMMY_IF" 2>/dev/null | grep -q "inet ${DNS_IP}/"; then
    warn "ifup tidak memasang ${DNS_IP}; pasang manual (tidak persisten sampai ifupdown2 membacanya)"
    ip link add "$DUMMY_IF" type dummy 2>/dev/null || true
    ip addr add "${DNS_IP}/32" dev "$DUMMY_IF" 2>/dev/null || true
    ip link set "$DUMMY_IF" up
  fi
  ip -4 addr show dev "$DUMMY_IF" | grep -q "inet ${DNS_IP}/"

  for u in $UPSTREAMS; do ups+="        - ${u}"$'\n'; done

  # Recursor 5.x hanya membaca YAML.
  #  - dont_query tanpa 127.0.0.0/8: forward ke auth lokal (127.0.0.1) harus boleh
  #  - negative_trustanchors: tanpa ini ${DOMAIN} = SERVFAIL (EDE 10, RRSIGs Missing)
  cat > /etc/powerdns/recursor.conf <<EOF
incoming:
  listen:
    - ${DNS_IP}
    - 127.0.0.1
  allow_from:
    - ${SUBNET}
    - 127.0.0.0/8
outgoing:
  dont_query:
    - 0.0.0.0/8
    - 192.0.0.0/24
    - 192.0.2.0/24
    - 198.51.100.0/24
    - 203.0.113.0/24
    - 240.0.0.0/4
    - ::/96
    - ::ffff:0:0/96
    - 100::/64
    - 2001:db8::/32
recursor:
  forward_zones:
    - zone: ${DOMAIN}
      forwarders:
        - 127.0.0.1:${PDNS_AUTH_PORT}
  forward_zones_recurse:
    - zone: .
      forwarders:
${ups}dnssec:
  negative_trustanchors:
    - name: ${DOMAIN}
      reason: zone lokal tanpa DNSSEC
EOF

  echo 'net.ipv4.ip_nonlocal_bind=1' > /etc/sysctl.d/99-nonlocal-bind.conf
  sysctl --system >/dev/null

  systemctl enable pdns-recursor >/dev/null 2>&1 || true
  if ! systemctl restart pdns-recursor; then
    warn "pdns-recursor gagal start:"; journal_tail pdns-recursor
    return 1
  fi
  if ! wait_for 15 rec_control ping; then
    warn "pdns-recursor tidak merespons:"; journal_tail pdns-recursor
    return 1
  fi
}

### ===================== TAHAP 4: SDN (zone/vnet/subnet lewat pvesh) =====================
# JANGAN tulis zones/vnets/subnets.cfg dengan tangan: IPAM tidak terdaftar
# dan alokasi IP gagal ("can't find any free ip in zone").
st_sdn() {
  local use_dns=0 KEY f cur zjson
  local -a dnsargs=()

  if pdns_healthy; then
    use_dns=1
  else
    warn "PowerDNS tidak sehat: zone dibuat TANPA DNS dinamis. Perbaiki PowerDNS lalu jalankan script ini lagi."
  fi

  mkdir -p /etc/pve/sdn

  # Forwarding bridge SDN -> WAN. Jangan mengandalkan SDN: di fresh install nilainya 0
  # (terbukti oleh verifikasi), dan tanpa ini guest punya rule SNAT tapi tidak punya internet.
  echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-leap-forward.conf
  sysctl -w net.ipv4.ip_forward=1 >/dev/null

  # Entri DNS di SDN (hanya jika PowerDNS sehat). dns.cfg disambungkan, bukan ditimpa.
  if [ "$use_dns" = 1 ]; then
    KEY=$(pdns_key)
    f=/etc/pve/sdn/dns.cfg
    cur=""
    if [ -f "$f" ]; then cur=$(cat "$f"); fi
    if printf '%s\n' "$cur" | grep -q "^powerdns: ${PDNS_ID}\$"; then
      cur=$(printf '%s\n' "$cur" | sed "/^powerdns: ${PDNS_ID}\$/,/^\$/ s|^\([[:space:]]*key \).*|\1${KEY}|")
    else
      cur="${cur}${cur:+$'\n\n'}powerdns: ${PDNS_ID}"$'\n\t'"key ${KEY}"$'\n\t'"url ${PDNS_API}"$'\n\t'"ttl 30"
    fi
    printf '%s\n' "$cur" > "$f"
    dnsargs=(--dns "$PDNS_ID" --dnszone "$DOMAIN")
  fi

  # Zone
  if ! pvesh get "/cluster/sdn/zones/${ZONE}" >/dev/null 2>&1; then
    pvesh create /cluster/sdn/zones --zone "$ZONE" --type simple --ipam pve --dhcp dnsmasq \
      ${dnsargs[@]+"${dnsargs[@]}"}
  elif [ "$use_dns" = 1 ]; then
    # Zone sudah ada. Sambungkan DNS jika belum (run sebelumnya saat PowerDNS mati)
    # atau ikuti DOMAIN yang berubah. Record di zone DNS lama tidak ikut pindah.
    zjson=$(pvesh get "/cluster/sdn/zones/${ZONE}" --output-format json)
    if ! grep -q "\"dns\" *: *\"${PDNS_ID}\"" <<<"$zjson" \
       || ! grep -q "\"dnszone\" *: *\"${DOMAIN}\"" <<<"$zjson"; then
      pvesh set "/cluster/sdn/zones/${ZONE}" --dns "$PDNS_ID" --dnszone "$DOMAIN"
    fi
  fi

  # VNet
  if ! pvesh get "/cluster/sdn/vnets/${VNET}" >/dev/null 2>&1; then
    pvesh create /cluster/sdn/vnets --vnet "$VNET" --zone "$ZONE"
    sdn_apply
  fi

  # Subnet (SNAT + DHCP + gateway)
  if ! pvesh get "/cluster/sdn/vnets/${VNET}/subnets" --output-format json 2>/dev/null \
       | grep -q "\"cidr\" *: *\"${SUBNET}\""; then
    pvesh create "/cluster/sdn/vnets/${VNET}/subnets" --subnet "$SUBNET" --type subnet \
      --gateway "$GW" --snat 1 --dhcp-dns-server "$DNS_IP" \
      --dhcp-range "start-address=${DHCP_START},end-address=${DHCP_END}"
    sdn_apply
  fi

  wait_for 20 ip link show "$VNET"
  dedupe_snat
}

### ===================== TAHAP 5: VERIFIKASI =====================
check() {   # check <deskripsi> <perintah...>
  local d=$1; shift
  if "$@" >/dev/null 2>&1; then log "OK     ${d}"; else warn "GAGAL  ${d}"; return 1; fi
}

st_verify() {
  local rc=0
  check "bridge ${VNET} memegang ${GW}"        bash -c "ip -4 addr show dev '${VNET}' | grep -q 'inet ${GW}/'" || rc=1
  check "ip_forward aktif"                     bash -c '[ "$(cat /proc/sys/net/ipv4/ip_forward)" = 1 ]'       || rc=1
  check "tepat 1 rule SNAT"                    bash -c "[ \"\$(iptables -t nat -S POSTROUTING | grep -cxF -- '$(snat_rule)')\" = 1 ]" || rc=1
  check "dnsmasq SDN listen ${GW}:53"          bash -c "ss -lnu | grep -q '${GW}:53'"                          || rc=1
  check "recursor listen ${DNS_IP}:53"         bash -c "ss -lnu | grep -q '${DNS_IP}:53'"                      || rc=1
  check "recursor meresolve internet"          wait_for 10 bash -c "dig +short +time=3 +tries=1 @${DNS_IP} cloudflare.com | grep -q ."  || rc=1
  if pdns_healthy; then
    # Terbukti dua kali: tepat setelah recursor dibuat ulang, query ke zone lokal bisa gagal
    # lebih dari 10 detik lalu normal sendiri. Beri 45 detik; bila tetap gagal, tampilkan status/EDE.
    if ! check "recursor meresolve ns1.${DOMAIN}" wait_for 45 bash -c "[ \"\$(dig +short +time=3 +tries=1 @${DNS_IP} ns1.${DOMAIN})\" = '${GW}' ]"; then
      rc=1
      dig +time=3 +tries=1 "@${DNS_IP}" "ns1.${DOMAIN}" +comments 2>&1 | grep -E 'status|EDE' | sed 's/^/   dig| /' || true
    fi
  else
    warn "SKIP   cek ns1.${DOMAIN} (PowerDNS tidak sehat)"; rc=1
  fi
  check "IPAM pve terdaftar"                   pvesh get /cluster/sdn/ipams/pve/status                         || rc=1
  return "$rc"
}

### ===================== JALANKAN =====================
if [ "$FLUSH" = 1 ]; then
  stage "flush config lama" st_flush
  if [ "${#FAILED_STAGES[@]}" -gt 0 ]; then
    warn "Flush GAGAL: instalasi TIDAK dilanjutkan agar tidak menumpuk di atas state yang setengah terhapus."
    warn "Periksa pesan di atas, perbaiki penyebabnya, lalu jalankan ulang."
    exit 1
  fi
fi

stage "paket"                  st_packages
stage "powerdns authoritative" st_pdns
stage "recursor + dummy ip"    st_recursor
stage "sdn zone/vnet/subnet"   st_sdn
stage "verifikasi"             st_verify

### ===================== RINGKASAN =====================
echo
log "----- RINGKASAN -----"
log "Berhasil: ${OK_STAGES[*]:-(tidak ada)}"
if [ "${#FAILED_STAGES[@]}" -gt 0 ]; then
  warn "Gagal   : ${FAILED_STAGES[*]}"
  warn "Perbaiki penyebabnya (lihat ${LOG}) lalu jalankan script ini lagi; aman diulang."
  exit 1
fi
log "Semua tahap berhasil."

# ----------------------------------------------------------------------------------
# GUEST (LXC/VM) — urutan penting:
#   1. Set hostname SEBELUM net0 DHCP dipasang. Nama di IPAM/DNS diambil dari
#      hostname saat IP pertama dialokasikan; mengganti hostname sesudahnya
#      tidak memperbarui IPAM.
#   2. net0 harus DHCP (IP statis tidak masuk IPAM, jadi tidak ada record DNS).
#
#   pct create <CTID> <template> --hostname web1 \
#       --net0 name=eth0,bridge=${VNET},ip=dhcp,type=veth \
#       --nameserver ${DNS_IP} --searchdomain ${DOMAIN}
#
#   Hostname web1 menjadi web1.${DOMAIN}. Region lain memakai domain sendiri
#   (mis. id.local), jadi web1 di tiap region tidak bentrok.
#
# Cek: dig @${DNS_IP} web1.${DOMAIN} +short
# ----------------------------------------------------------------------------------