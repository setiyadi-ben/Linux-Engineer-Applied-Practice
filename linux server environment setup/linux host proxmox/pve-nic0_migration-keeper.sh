#!/usr/bin/env bash
# pve-nic0_migration-keeper.sh
# Menjaga NIC Proxmox tetap bernama nic0 dan vmbr0 tetap punya IP (.2, cadangan .254)
# setelah migrasi hardware fisik. Berjalan di setiap boot lewat systemd selama mode ENABLED.
#
# Alur (tiap boot, selama mode ENABLED):
#   1. NIC fisik yang link-nya up minta lease DHCP -> tahu IP/prefix/gateway jaringan itu (lease lalu dilepas)
#   2. kandidat IP .2, .250, .251, .252, .253, .254 di-ping; yang tidak menjawab dan paling kecil dipakai vmbr0
#   3. ditulis ke /etc/network/interfaces; nic0 dipin ke MAC NIC baru; /etc/hosts (banner :8006) ikut diubah
#   4. /etc/resolv.conf disetel ke 10.20.0.3 1.1.1.1 8.8.8.8 9.9.9.9
#   5. setelah jaringan naik: ping gateway; gagal -> rollback dari backup
#
# Pemakaian:
#   pve-nic0_migration-keeper.sh enable    pasang unit systemd, aktif mulai boot berikutnya (reboot untuk apply)
#   pve-nic0_migration-keeper.sh disable   matikan unit; konfigurasi hasil terakhir TIDAK dihapus
#   pve-nic0_migration-keeper.sh status    ringkasan 3 baris; masalah otomatis ditandai "!" lengkap dengan log
#   pve-nic0_migration-keeper.sh status -v tampilan lengkap + 20 baris log terakhir
#   pve-nic0_migration-keeper.sh dns       setel /etc/resolv.conf sekarang juga + jinakkan NetworkManager (tahan reboot)
#   (pre / post dipanggil oleh systemd, bukan manual)
#
# Log: journalctl -b -u pve-nic0-migration-keeper-pre -u pve-nic0-migration-keeper-post

set -o pipefail

SELF=/usr/local/sbin/pve-nic0_migration-keeper.sh
STATE_DIR=/var/lib/pve-nic0-migration-keeper
STATE=$STATE_DIR/state
MODE_STAMP=$STATE_DIR/mode_changed
BACKUP_ROOT=$STATE_DIR/backup
RUN_DIR=/run/pve-nic0-migration-keeper
HANDOFF=$RUN_DIR/handoff
IFACES=/etc/network/interfaces
HOSTS=/etc/hosts
LINK_OURS=/etc/systemd/network/00-pve-nic0-migration-keeper.link
LINK_DIRS=(/etc/systemd/network /usr/local/lib/systemd/network)
WANT_NIC=nic0
RESOLV=/etc/resolv.conf
DNS_SERVERS=(10.20.0.3 1.1.1.1 8.8.8.8 9.9.9.9)
RESOLV_OPTIONS="options timeout:2 attempts:2"   # kosongkan untuk tidak menambah baris options
CARRIER_WAIT=8         # detik menunggu link NIC naik
KEEP_BACKUPS=10
UNIT_PRE=pve-nic0-migration-keeper-pre.service
UNIT_POST=pve-nic0-migration-keeper-post.service

LOGFILE=$STATE_DIR/keeper.log      # log persisten (tampil di 'status'), terpisah dari journal

_lw() { { printf '%s %-4s %s\n' "$(date '+%F %T')" "$1" "$2" >> "$LOGFILE"; } 2>/dev/null; }
log()  { _lw INFO "$*"; }                                     # detail langkah: hanya ke file
say()  { echo "pve-nic0-keeper: $*"; _lw INFO "$*"; }         # ringkasan/perubahan: terminal atau journal + file
warn() { echo "pve-nic0-keeper: WARN: $*" >&2; _lw WARN "$*"; }
err()  { echo "pve-nic0-keeper: ERR: $*" >&2; _lw ERR "$*"; }
die()  { echo "pve-nic0-keeper: ERROR: $*" >&2; exit 1; }
need_root() { [ "$(id -u)" -eq 0 ] || die "harus dijalankan sebagai root"; }

# ---------------------------------------------------------------- helper python
# Parser/editor /etc/network/interfaces. Hanya menyentuh stanza nic0 dan vmbr0.
ifpy() { python3 - "$@" <<'PY'
import re, shlex, sys

START = re.compile(r'^(auto|allow-\S+|iface|source|source-directory|mapping)\s')
IND = '    '


def load(path):
    blocks, cur = [], None
    for ln in open(path).read().splitlines():
        if START.match(ln):
            t = ln.split()
            cur = {'kw': t[0], 'name': t[1] if len(t) > 1 else '',
                   'fam': t[2] if len(t) > 2 else '', 'lines': [ln]}
            blocks.append(cur)
        else:
            if cur is None:
                cur = {'kw': '', 'name': '', 'fam': '', 'lines': []}
                blocks.append(cur)
            cur['lines'].append(ln)
    return blocks


def opt(b, key):
    for i, l in enumerate(b['lines'][1:], 1):
        t = l.split(None, 1)
        if t and t[0] == key:
            return i, (t[1].strip() if len(t) > 1 else '')
    return None, None


def setopt(b, key, val):
    i, _ = opt(b, key)
    if i is not None:
        ind = re.match(r'\s*', b['lines'][i]).group(0)
        b['lines'][i] = '%s%s %s' % (ind, key, val)
        return
    pos = 1
    for j, l in enumerate(b['lines'][1:], 1):
        if l.strip() and not l.strip().startswith('#'):
            pos = j + 1
    b['lines'].insert(pos, '%s%s %s' % (IND, key, val))


def find(blocks, name):
    for b in blocks:
        if b['kw'] == 'iface' and b['name'] == name and b['fam'] == 'inet':
            return b
    return None


def cmd_get(path):
    bl = load(path)
    v = find(bl, 'vmbr0')
    addr = prefix = gw = ports = ''
    if v:
        _, a = opt(v, 'address')
        if a:
            a = a.split()[0]
            if '/' in a:
                addr, prefix = a.split('/', 1)
            else:
                addr = a
        _, g = opt(v, 'gateway')
        gw = g or ''
        _, p = opt(v, 'bridge-ports')
        ports = p or ''
    others = []
    for b in bl:
        if b['kw'] == 'iface' and b['name'] != 'vmbr0':
            for k in ('bridge-ports', 'bond-slaves', 'bond_slaves'):
                _, val = opt(b, k)
                if val:
                    others += val.split()
    for k, val in (('CFG_ADDR', addr), ('CFG_PREFIX', prefix), ('CFG_GW', gw),
                   ('CFG_PORTS', ports), ('CFG_OTHER_PORTS', ' '.join(others))):
        print('%s=%s' % (k, shlex.quote(val)))


def cmd_fix(path, out, nic, addr, prefix, gw):
    bl = load(path)

    if find(bl, nic) is None:
        new = {'kw': 'iface', 'name': nic, 'fam': 'inet',
               'lines': ['iface %s inet manual' % nic, '']}
        idx = None
        for i, b in enumerate(bl):
            if b['kw'] == 'auto' and b['name'] == 'vmbr0':
                idx = i
                break
        if idx is None:
            bl.append(new)
        else:
            bl.insert(idx, new)

    v = find(bl, 'vmbr0')
    if v is None:
        bl.append({'kw': 'auto', 'name': 'vmbr0', 'fam': '',
                   'lines': ['', 'auto vmbr0']})
        v = {'kw': 'iface', 'name': 'vmbr0', 'fam': 'inet',
             'lines': ['iface vmbr0 inet static']}
        bl.append(v)
        setopt(v, 'bridge-stp', 'off')
        setopt(v, 'bridge-fd', '0')
    else:
        t = v['lines'][0].split()
        if len(t) < 4 or t[3] != 'static':
            v['lines'][0] = 'iface vmbr0 inet static'

    setopt(v, 'address', '%s/%s' % (addr, prefix))
    setopt(v, 'gateway', gw)
    _, ports = opt(v, 'bridge-ports')
    if ports is None or nic not in ports.split():
        setopt(v, 'bridge-ports', nic)

    text = '\n'.join(l for b in bl for l in b['lines']) + '\n'
    open(out, 'w').write(text)

    bl2 = load(out)
    chk, vv = find(bl2, nic), find(bl2, 'vmbr0')
    ok = bool(chk and vv
              and opt(vv, 'address')[1] == '%s/%s' % (addr, prefix)
              and opt(vv, 'gateway')[1] == gw
              and nic in (opt(vv, 'bridge-ports')[1] or '').split())
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    m = sys.argv[1]
    if m == 'get':
        cmd_get(sys.argv[2])
    elif m == 'fix':
        cmd_fix(*sys.argv[2:8])
PY
}

# Kandidat IP node dari subnet DHCP: offset .2 lalu .250-.254 dari alamat jaringan
# pemakaian: netcalc cands <ip> <prefix> [ip-yang-dikecualikan ...]
netcalc() { python3 - "$@" <<'PY'
import ipaddress, sys

ip, pref = sys.argv[2], sys.argv[3]
skip = set(sys.argv[4:])
n = ipaddress.ip_interface('%s/%s' % (ip, pref)).network
for off in (2, 250, 251, 252, 253, 254):
    c = n.network_address + off
    if n.network_address < c < n.broadcast_address and str(c) not in skip:
        print(c)
PY
}

# ---------------------------------------------------------------- state
load_state() {
    S_GW=""; S_PFX=""; S_IP=""; S_NIC_MAC=""
    LAST_RUN=0; LAST_RESULT="-"
    # shellcheck disable=SC1090
    [ -f "$STATE" ] && . "$STATE"
    return 0
}

save_state() {
    mkdir -p "$STATE_DIR"
    {
        printf 'S_GW=%q\n' "$S_GW"
        printf 'S_PFX=%q\n' "$S_PFX"
        printf 'S_IP=%q\n' "$S_IP"
        printf 'S_NIC_MAC=%q\n' "$S_NIC_MAC"
        printf 'LAST_RUN=%q\n' "$(date +%s)"
        printf 'LAST_RESULT=%q\n' "$LAST_RESULT"
    } > "$STATE.tmp" && mv -f "$STATE.tmp" "$STATE"
}

# ---------------------------------------------------------------- jaringan
# Minta lease DHCP lewat dhclient bawaan, di mount-namespace privat:
# /etc/resolv.conf dan file lease asli "disamarkan" dengan file kosong sementara, jadi dhclient-script
# TIDAK BISA mengubah resolv.conf asli, dan tidak ada lease lama yang dipakai (jalur TIMEOUT di
# dhclient-script memasang IP + DNS dari lease lama, itu yang membuat run ke-2 dst. berbeda dari run pertama).
# Hasil: D_IP D_PFX D_GW. Lease TETAP terpasang di iface sampai dhcp_down dipanggil.
dhcp_up() { # iface
    local iface=$1 a lease_real=/var/lib/dhcp/dhclient.leases t0=$SECONDS
    D_IP=""; D_PFX=""; D_GW=""
    command -v dhclient >/dev/null || { warn "dhclient tidak ada (apt install isc-dhcp-client)"; return 1; }
    command -v unshare >/dev/null || { warn "unshare tidak ada (paket util-linux)"; return 1; }
    mkdir -p "$(dirname "$lease_real")"
    [ -e "$lease_real" ] || : > "$lease_real"
    [ -e "$RESOLV" ] || : > "$RESOLV"
    : > "$RUN_DIR/dhclient.leases"; : > "$RUN_DIR/resolv.scratch"
    ip link set dev "$iface" up 2>/dev/null
    timeout 20 unshare --mount sh -c '
        mount --bind "$1" "$2" && mount --bind "$3" "$4" || exit 97
        exec dhclient -1 -v "$5"
    ' keeper "$RUN_DIR/resolv.scratch" "$RESOLV" "$RUN_DIR/dhclient.leases" "$lease_real" "$iface" \
        > "$RUN_DIR/dhclient.log" 2>&1
    unleak
    log "dhclient di $iface selesai dalam $((SECONDS - t0))s"
    a=$(ip -4 -o addr show dev "$iface" scope global 2>/dev/null | awk '{print $4; exit}')
    D_IP=${a%/*}; D_PFX=${a#*/}
    D_GW=$(ip -4 route show default dev "$iface" 2>/dev/null | awk '{print $3; exit}')
    if [ -z "$a" ] || [ -z "$D_GW" ]; then
        warn "DHCP di $iface tidak lengkap (ip='${a:-}' gateway='${D_GW:-}')"
        [ -s "$RUN_DIR/dhclient.log" ] && tail -n 5 "$RUN_DIR/dhclient.log" | sed 's/^/pve-nic0-keeper: dhclient: /' >&2
        return 1
    fi
    return 0
}

# Hentikan dhclient dan bersihkan IP/route sementara di iface (resolv.conf tidak pernah tersentuh)
dhcp_down() { # iface
    local iface=$1 i
    pkill -f "dhclient -1 -v $iface" 2>/dev/null
    for i in 1 2 3; do pgrep -f "dhclient -1 -v $iface" >/dev/null 2>&1 || break; sleep 1; done
    pkill -9 -f "dhclient -1 -v $iface" 2>/dev/null
    ip -4 addr flush dev "$iface" 2>/dev/null
    ip -4 route flush dev "$iface" 2>/dev/null
    unleak
    return 0
}

# Jaring pengaman: bind mount sementara dhclient tidak boleh pernah terlihat di namespace utama
unleak() {
    local m
    for m in "$RESOLV" /var/lib/dhcp/dhclient.leases; do
        if findmnt -rn -M "$m" >/dev/null 2>&1; then
            warn "$m ternyata mountpoint (bind mount bocor); dilepas"
            umount -l "$m" 2>/dev/null
        fi
    done
}

# ping dari iface (yang sedang memegang IP lease): 0 = ada yang menjawab = IP terpakai
ip_taken() { ping -n -q -c 2 -W 1 -I "$1" "$2" >/dev/null 2>&1; }

# gateway terjangkau dari vmbr0: ping, atau sudah ada entri ARP-nya
gw_ok() {
    ping -n -q -c 2 -W 2 -I vmbr0 "$1" >/dev/null 2>&1 ||
        ip neigh show dev vmbr0 "$1" 2>/dev/null | grep -q lladdr
}

# ---------------------------------------------------------------- NIC
list_phys() {
    local p n
    for p in /sys/class/net/*; do
        n=${p##*/}
        [ -e "$p/device" ] || continue
        [ -d "$p/wireless" ] && continue
        [ -d "$p/bridge" ] && continue
        case " ${CFG_OTHER_PORTS:-} " in *" $n "*) continue ;; esac
        echo "$n"
    done
}

# Isi CAND (semua NIC fisik) dan LINKED (yang link-nya up, nic0 didahulukan)
select_nic() {
    local n t=0 has_nic0=0 any=0
    CAND=(); LINKED=()
    while IFS= read -r n; do CAND+=("$n"); [ "$n" = "$WANT_NIC" ] && has_nic0=1; done < <(list_phys)
    [ ${#CAND[@]} -gt 0 ] || return 1
    for n in "${CAND[@]}"; do ip link set dev "$n" up 2>/dev/null; done
    while [ $t -lt $CARRIER_WAIT ]; do
        for n in "${CAND[@]}"; do
            [ "$(cat "/sys/class/net/$n/carrier" 2>/dev/null)" = 1 ] || continue
            # kalau nic0 ada, beri dia waktu dulu sebelum NIC lain dipertimbangkan
            if [ "$n" != "$WANT_NIC" ] && [ $has_nic0 -eq 1 ] && [ $t -lt 6 ]; then continue; fi
            any=1
        done
        [ $any -eq 1 ] && break
        sleep 1; t=$((t + 1))
    done
    [ $any -eq 1 ] || return 1
    sleep 2
    for n in "${CAND[@]}"; do
        [ "$(cat "/sys/class/net/$n/carrier" 2>/dev/null)" = 1 ] || continue
        if [ "$n" = "$WANT_NIC" ]; then LINKED=("$n" "${LINKED[@]}"); else LINKED+=("$n"); fi
    done
    [ ${#LINKED[@]} -gt 0 ]
}

ensure_bk() {
    [ -n "${BK:-}" ] && return 0
    BK=$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)
    mkdir -p "$BK/links"
    cp -p "$IFACES" "$BK/interfaces" 2>/dev/null
    cp -p "$HOSTS" "$BK/hosts" 2>/dev/null
    cp -p "$RESOLV" "$BK/resolv.conf" 2>/dev/null
    return 0
}

prune_backups() {
    # shellcheck disable=SC2012
    ls -1dt "$BACKUP_ROOT"/*/ 2>/dev/null | tail -n +$((KEEP_BACKUPS + 1)) | xargs -r rm -rf
}

# Pastikan ada aturan .link yang mengunci MAC NIC terpilih ke nic0 (berlaku di boot berikutnya)
pin_nic0() { # mac
    local mac=${1,,} d lf found=0
    for d in "${LINK_DIRS[@]}"; do
        for lf in "$d"/*.link; do
            [ -e "$lf" ] || continue
            grep -qiE '^[[:space:]]*Name=nic0[[:space:]]*$' "$lf" || continue
            if grep -qiE "^[[:space:]]*MACAddress=$mac[[:space:]]*$" "$lf"; then
                found=1
            elif [ "$lf" != "$LINK_OURS" ]; then
                ensure_bk
                mv -f "$lf" "$BK/links/"
                say "pinning lama (MAC berbeda) dipindah ke backup: $lf"
                CHANGED=1
            fi
        done
    done
    if [ $found -eq 0 ]; then
        printf '[Match]\nMACAddress=%s\n\n[Link]\nName=%s\n' "$mac" "$WANT_NIC" > "$LINK_OURS"
        say "pinning baru: $mac -> $WANT_NIC ($LINK_OURS)"
        CHANGED=1
    fi
}

# Rename langsung di boot ini (interface harus down)
runtime_rename() { # cur
    local cur=$1
    [ "$cur" = "$WANT_NIC" ] && return 0
    if [ -e "/sys/class/net/$WANT_NIC" ]; then
        warn "nama $WANT_NIC sedang dipakai NIC lain, dipindah ke ${WANT_NIC}-old"
        ip link set dev "$WANT_NIC" down 2>/dev/null
        ip link set dev "$WANT_NIC" name "${WANT_NIC}-old" 2>/dev/null
    fi
    ip link set dev "$cur" down 2>/dev/null
    if ip link set dev "$cur" name "$WANT_NIC" 2>/dev/null; then
        say "rename langsung: $cur -> $WANT_NIC"
        CHANGED=1
    else
        warn "rename $cur -> $WANT_NIC gagal"
    fi
}

hosts_render() { # ip
    local short fq
    short=$(hostname -s 2>/dev/null || hostname)
    fq=$(hostname -f 2>/dev/null); [ -n "$fq" ] || fq=$short
    awk -v ip="$1" -v fq="$fq" -v sh="$short" '
        BEGIN { done = 0 }
        /^[[:space:]]*#/ { print; next }
        {
            m = 0
            for (i = 2; i <= NF; i++) if ($i == sh || $i == fq) m = 1
            if (m && $1 !~ /^127\./ && $1 != "::1") {
                if (!done) { if (fq == sh) print ip, sh; else print ip, fq, sh; done = 1 }
                next
            }
            print
        }
        END { if (!done) { if (fq == sh) print ip, sh; else print ip, fq, sh } }' "$HOSTS"
}

resolv_render() {
    local s
    # pertahankan baris search/domain/komentar; nameserver dan options diganti
    [ -e "$RESOLV" ] && grep -vE '^[[:space:]]*(nameserver|options)([[:space:]]|$)' "$RESOLV"
    for s in "${DNS_SERVERS[@]}"; do echo "nameserver $s"; done
    [ -n "$RESOLV_OPTIONS" ] && echo "$RESOLV_OPTIONS"
    return 0
}

# ---------------------------------------------------------------- NetworkManager
# "Wired connection 1" = profil otomatis NetworkManager. NM menjalankan DHCP-nya sendiri di nic0 (anggota
# vmbr0), menimpa /etc/resolv.conf dengan DNS gateway, lalu koneksi macet. Jadi NM dijinakkan: tidak boleh
# membuat profil otomatis, tidak boleh menyentuh resolv.conf, dan tidak boleh mengelola nic*/vmbr*.
NM_CONF=/etc/NetworkManager/conf.d/90-pve-nic0-keeper.conf
NM_CONF_BODY='# dipasang oleh pve-nic0_migration-keeper.sh
[main]
no-auto-default=*
dns=none
rc-manager=unmanaged

[keyfile]
unmanaged-devices=interface-name:nic*;interface-name:vmbr*;interface-name:fwbr*;interface-name:fwpr*;interface-name:fwln*;interface-name:tap*;interface-name:veth*
'

nm_present() { [ -d /etc/NetworkManager ] || command -v nmcli >/dev/null 2>&1; }
nm_guard_ok() { printf '%s' "$NM_CONF_BODY" | cmp -s - "$NM_CONF" 2>/dev/null; }

# nm_guard 0 = hanya file konfigurasi (aman saat boot, NM belum jalan); 1 = sekalian terapkan ke NM yang sedang jalan
nm_guard() {
    local runtime=${1:-0} changed=0 uuid name
    nm_present || return 0
    if ! nm_guard_ok; then
        mkdir -p "$(dirname "$NM_CONF")"
        printf '%s' "$NM_CONF_BODY" > "$NM_CONF" && { say "NetworkManager dijinakkan: $NM_CONF"; changed=1; }
    fi
    if [ "$runtime" = 1 ] && command -v nmcli >/dev/null 2>&1 && systemctl is-active --quiet NetworkManager 2>/dev/null; then
        [ $changed -eq 1 ] && timeout 15 nmcli general reload >/dev/null 2>&1
        [ -e "/sys/class/net/$WANT_NIC" ] && timeout 10 nmcli device set "$WANT_NIC" managed no >/dev/null 2>&1
        while IFS=: read -r uuid name; do
            case "$name" in
                "Wired connection "[0-9]*)
                    timeout 15 nmcli connection delete uuid "$uuid" >/dev/null 2>&1 && say "profil otomatis NetworkManager dihapus: $name" ;;
            esac
        done < <(nmcli -t -f UUID,NAME connection show 2>/dev/null)
    fi
    return 0
}

# Daftar nameserver di resolv.conf persis sama dengan DNS_SERVERS?
resolv_ok() {
    [ "$(awk '/^nameserver[[:space:]]/{print $2}' "$RESOLV" 2>/dev/null | paste -sd' ' -)" = "${DNS_SERVERS[*]}" ]
}

# Idempotent: tidak melakukan apa-apa kalau sudah sesuai; dipanggil di awal, akhir, dan lewat trap EXIT.
# DNS harus tetap di segala kondisi, jadi tidak ada jalur yang diam-diam melewatinya.
apply_resolv() {
    local target content tmp
    unleak
    if [ -L "$RESOLV" ]; then
        target=$(readlink -f "$RESOLV" 2>/dev/null)
        case "$target" in
            /run/*|/var/run/*|"")
                ensure_bk
                readlink "$RESOLV" > "$BK/resolv.symlink" 2>/dev/null
                warn "$RESOLV adalah symlink ke ${target:-?}; diganti file biasa supaya DNS tetap"
                rm -f "$RESOLV"; : > "$RESOLV"
                ;;
        esac
    fi
    target=$(readlink -f "$RESOLV" 2>/dev/null || echo "$RESOLV")
    resolv_ok && return 0
    content=$(resolv_render)
    [ -n "$content" ] || return 1
    ensure_bk
    tmp=$(mktemp "$(dirname "$target")/resolv.nic0keeper.XXXXXX" 2>/dev/null)
    if [ -n "$tmp" ] && printf '%s\n' "$content" > "$tmp" && chmod 644 "$tmp" && mv -f "$tmp" "$target" 2>/dev/null; then
        :
    else
        [ -n "$tmp" ] && rm -f "$tmp"
        printf '%s\n' "$content" > "$target"      # tulis langsung; tetap bisa walau mv ditolak
    fi
    if resolv_ok; then
        say "DNS diperbarui: ${DNS_SERVERS[*]}"
        CHANGED=1
    else
        err "DNS GAGAL diperbarui di $target ($(ls -l "$target" 2>&1 | awk '{$1=$1; print}'))"
        return 1
    fi
}

# ---------------------------------------------------------------- PRE (sebelum networking.service)
cmd_pre() {
    need_root
    mkdir -p "$STATE_DIR" "$BACKUP_ROOT" "$RUN_DIR"
    rm -f "$HANDOFF"
    if [ "$(wc -l < "$LOGFILE" 2>/dev/null || echo 0)" -gt 400 ]; then
        tail -n 200 "$LOGFILE" > "$LOGFILE.tmp" && mv -f "$LOGFILE.tmp" "$LOGFILE"
    fi
    log "=== pre mulai (uptime $(cut -d' ' -f1 /proc/uptime)s) ==="
    CHANGED=0; IF_CHANGED=0; BK=""; NEWIP=""; NEW_GW=""; NEW_PFX=""; NET_STATE="dhcp"
    D_IP=""; D_PFX=""; D_GW=""
    load_state
    # DNS dijamin di segala kondisi: disetel di awal, dan dicek lagi apa pun yang terjadi (error, return, dll.)
    nm_guard 0
    apply_resolv
    trap 'apply_resolv' EXIT

    [ -r "$IFACES" ] || { warn "$IFACES tidak terbaca, dilewati"; return 0; }
    [ -f "$IFACES.new" ] && warn "$IFACES.new (perubahan pending dari GUI) ada; tidak disentuh"
    eval "$(ifpy get "$IFACES")"

    CLUSTER=0
    [ -f /etc/corosync/corosync.conf ] && CLUSTER=1

    if ! select_nic; then
        say "tidak ada NIC fisik dengan link; jaringan tidak diubah"
        apply_resolv
        return 0
    fi
    log "NIC fisik: ${CAND[*]} | link up: ${LINKED[*]}"

    local n c tmp
    CUR=${LINKED[0]}

    if [ "$CLUSTER" -eq 1 ]; then
        NET_STATE="cluster"
        say "node cluster terdeteksi; DHCP/IP//etc/hosts dilewati (hanya nic0, bridge-ports, DNS)"
        NEWIP=$CFG_ADDR; NEW_PFX=$CFG_PREFIX; NEW_GW=$CFG_GW
    else
        # 1. minta lease DHCP -> tahu subnet dan gateway jaringan ini
        for n in "${LINKED[@]}"; do
            if dhcp_up "$n"; then
                CUR=$n
                log "DHCP di $n: $D_IP/$D_PFX gateway $D_GW"
                # 2. ping kandidat .2, .250-.254; tidak menjawab = kosong, ambil yang terkecil
                for c in $(netcalc cands "$D_IP" "$D_PFX" "$D_GW" "$D_IP"); do
                    if ip_taken "$n" "$c"; then
                        log "$c menjawab ping; dilewati"
                    else
                        NEWIP=$c; NEW_GW=$D_GW; NEW_PFX=$D_PFX
                        break
                    fi
                done
                dhcp_down "$n"
                break
            fi
            dhcp_down "$n"
        done
        if [ -z "$NEWIP" ]; then
            NET_STATE="no-ip"
            warn "IP baru tidak bisa ditentukan (DHCP gagal atau semua kandidat terpakai); alamat vmbr0 tidak diubah"
        fi
    fi

    NIC_MAC=$(cat "/sys/class/net/$CUR/address")
    # semua NIC yang kita naikkan dimatikan lagi; networking.service yang akan mengurus
    for n in "${CAND[@]}"; do ip link set dev "$n" down 2>/dev/null; done

    # 3. nic0: pinning untuk boot berikutnya + rename langsung
    pin_nic0 "$NIC_MAC"
    runtime_rename "$CUR"

    # 4. /etc/network/interfaces dan /etc/hosts
    if [ -n "$NEWIP" ] && [ -n "$NEW_GW" ] && [ -n "$NEW_PFX" ]; then
        tmp=$(mktemp "$(dirname "$IFACES")/interfaces.nic0keeper.XXXXXX")
        if ifpy fix "$IFACES" "$tmp" "$WANT_NIC" "$NEWIP" "$NEW_PFX" "$NEW_GW"; then
            if ! cmp -s "$tmp" "$IFACES"; then
                ensure_bk
                chmod 644 "$tmp"; mv -f "$tmp" "$IFACES"
                say "interfaces diperbarui: vmbr0 $NEWIP/$NEW_PFX gw $NEW_GW, bridge-ports $WANT_NIC"
                CHANGED=1; IF_CHANGED=1
            else
                rm -f "$tmp"
            fi
        else
            rm -f "$tmp"
            warn "validasi interfaces gagal; file tidak diubah"
        fi

        if [ "$CLUSTER" -eq 0 ]; then
            tmp=$(mktemp "$(dirname "$HOSTS")/hosts.nic0keeper.XXXXXX")
            hosts_render "$NEWIP" > "$tmp"
            if [ -s "$tmp" ] && ! cmp -s "$tmp" "$HOSTS"; then
                ensure_bk
                chmod 644 "$tmp"; mv -f "$tmp" "$HOSTS"
                say "/etc/hosts diperbarui: $NEWIP"
                CHANGED=1; IF_CHANGED=1
            else
                rm -f "$tmp"
            fi
        fi
    fi

    # 5. DNS: selalu disetel, tidak bergantung pada hasil DHCP
    apply_resolv

    [ -n "$BK" ] && prune_backups
    {
        printf 'CHANGED=%q\n' "$CHANGED"
        printf 'IF_CHANGED=%q\n' "$IF_CHANGED"
        printf 'BK=%q\n' "$BK"
    } > "$HANDOFF"
    say "pre selesai dalam ${SECONDS}s (changed=$CHANGED, status=$NET_STATE, ip=${NEWIP:-tetap})"
    return 0
}

# ---------------------------------------------------------------- POST (setelah networking.service)
cmd_post() {
    need_root
    mkdir -p "$STATE_DIR" "$RUN_DIR"
    CHANGED=0; IF_CHANGED=0; BK=""
    # shellcheck disable=SC1090
    [ -f "$HANDOFF" ] && . "$HANDOFF"
    load_state
    log "=== post mulai (uptime $(cut -d' ' -f1 /proc/uptime)s) ==="
    # setelah networking.service selesai: pastikan tidak ada yang menimpa DNS selama boot
    nm_guard 1
    apply_resolv
    trap 'apply_resolv' EXIT
    eval "$(ifpy get "$IFACES")"

    local ok=0 i
    if [ -n "$CFG_GW" ]; then
        for i in 1 2 3 4; do
            gw_ok "$CFG_GW" && { ok=1; break; }
            sleep 2
        done
    fi

    if [ $ok -eq 1 ]; then
        S_GW=$CFG_GW; S_PFX=$CFG_PREFIX; S_IP=$CFG_ADDR
        S_NIC_MAC=$(cat "/sys/class/net/$WANT_NIC/address" 2>/dev/null || echo "")
        LAST_RESULT=OK
        # banner console "https://IP:8006" mengikuti /etc/hosts
        systemctl cat pvebanner.service >/dev/null 2>&1 && systemctl restart --no-block pvebanner.service
        log "OK: vmbr0 $CFG_ADDR, gateway $CFG_GW terjangkau"
    else
        warn "gateway ${CFG_GW:-?} tidak terjangkau dari vmbr0"
        {
            echo "pve-nic0-keeper: diagnosa: $(ip -4 -br addr show vmbr0 2>&1 | head -1)"
            echo "pve-nic0-keeper: diagnosa: route: $(ip -4 route show default 2>&1 | head -1)"
            echo "pve-nic0-keeper: diagnosa: neigh: $(ip neigh show dev vmbr0 2>&1 | head -2 | tr '\n' ';')"
            echo "pve-nic0-keeper: diagnosa: ping: $(ping -n -c 1 -W 2 -I vmbr0 "${CFG_GW:-127.0.0.1}" 2>&1 | tail -2 | tr '\n' ';')"
        } >&2
        if [ "$IF_CHANGED" = 1 ] && [ -n "$BK" ] && [ -f "$BK/interfaces" ]; then
            cp -p "$BK/interfaces" "$IFACES"
            [ -f "$BK/hosts" ] && cp -p "$BK/hosts" "$HOSTS"
            timeout 30 ifreload -a >/dev/null 2>&1 || warn "ifreload gagal/lewat batas waktu saat rollback"
            LAST_RESULT=ROLLED_BACK
            err "interfaces/hosts di-rollback dari $BK (DNS tetap)"
        else
            LAST_RESULT=NO_GATEWAY
        fi
    fi
    save_state
    say "post selesai dalam ${SECONDS}s (hasil=$LAST_RESULT)"
    return 0
}

# ---------------------------------------------------------------- enable / disable / status
write_units() {
    cat > /etc/systemd/system/$UNIT_PRE <<EOF
[Unit]
Description=pve-nic0-keeper: cek NIC dan IP vmbr0 sebelum jaringan
DefaultDependencies=no
After=systemd-udevd.service systemd-udev-trigger.service local-fs.target pvenetcommit.service
Before=network-pre.target networking.service
Conflicts=shutdown.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=$SELF pre
TimeoutStartSec=75
TimeoutStopSec=15

[Install]
WantedBy=multi-user.target
EOF
    cat > /etc/systemd/system/$UNIT_POST <<EOF
[Unit]
Description=pve-nic0-keeper: verifikasi jaringan setelah networking
After=networking.service $UNIT_PRE

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=$SELF post
TimeoutStartSec=45
TimeoutStopSec=15

[Install]
WantedBy=multi-user.target
EOF
}

cmd_enable() {
    need_root
    local missing=()
    command -v python3 >/dev/null || missing+=(python3)
    command -v dhclient >/dev/null || missing+=(isc-dhcp-client)
    command -v ping >/dev/null || missing+=(iputils-ping)
    command -v unshare >/dev/null || missing+=(util-linux)
    [ ${#missing[@]} -eq 0 ] || die "paket belum ada: apt install ${missing[*]}"

    mkdir -p "$STATE_DIR"
    if [ "$(readlink -f "$0")" != "$SELF" ]; then
        install -m 755 "$0" "$SELF" || die "gagal memasang ke $SELF"
    fi
    write_units
    systemctl daemon-reload
    systemctl enable "$UNIT_PRE" "$UNIT_POST" >/dev/null 2>&1 || die "systemctl enable gagal"
    date +%s > "$MODE_STAMP"
    nm_guard 1
    apply_resolv
    say "ENABLED. Jaringan baru berlaku mulai boot berikutnya; reboot untuk menerapkan (DNS sudah disetel sekarang)."
    say "Cek hasil setelah boot: pve-nic0_migration-keeper.sh status"
}

cmd_disable() {
    need_root
    systemctl disable "$UNIT_PRE" "$UNIT_POST" >/dev/null 2>&1
    date +%s > "$MODE_STAMP"
    nm_guard 1
    apply_resolv
    say "DISABLED. Tidak jalan lagi mulai boot berikutnya; konfigurasi jaringan tidak diubah, DNS tetap disetel."
}

cmd_status() {
    local verbose=0 en mc boot mode pend res dur pre_s post_s nicst="$WANT_NIC TIDAK ADA" live file gwst="?"
    local nmact="" nmtxt="tidak terpasang" nmprof="-" nmguard=ok dnsst resolvlist p mp
    local prob=()
    [ "${1:-}" = "-v" ] && verbose=1
    load_state
    en=$(systemctl is-enabled "$UNIT_PRE" 2>/dev/null || true)
    mc=$(cat "$MODE_STAMP" 2>/dev/null || echo 0)
    boot=$(( $(date +%s) - $(cut -d. -f1 /proc/uptime) ))
    [ "$en" = enabled ] && mode=ENABLED || mode=DISABLED
    if [ "$mc" -gt "$boot" ]; then pend="ya (reboot)"; else pend="tidak"; fi

    # hasil run terakhir + durasi (dari log)
    if [ "${LAST_RUN:-0}" -gt 0 ]; then
        res="$LAST_RESULT $(date -d "@$LAST_RUN" '+%m-%d %H:%M')"
        [ "$LAST_RESULT" = OK ] || prob+=("hasil run terakhir: $LAST_RESULT")
    else
        res="belum pernah"
    fi
    pre_s=$(grep 'pre selesai dalam' "$LOGFILE" 2>/dev/null | tail -1 | sed -n 's/.*dalam \([0-9]*\)s.*/\1/p')
    post_s=$(grep 'post selesai dalam' "$LOGFILE" 2>/dev/null | tail -1 | sed -n 's/.*dalam \([0-9]*\)s.*/\1/p')
    dur="pre ${pre_s:--}s, post ${post_s:--}s"
    if [ "${pre_s:-0}" -gt 45 ] || [ "${post_s:-0}" -gt 45 ]; then prob+=("boot lambat: $dur (batas 45s)"); fi
    if [ "$mode" = ENABLED ] && [ "${LAST_RUN:-0}" -lt "$boot" ]; then
        prob+=("belum ada run yang selesai di boot ini")
    fi

    # nic0, vmbr0, gateway
    if [ -d "/sys/class/net/$WANT_NIC/device" ]; then
        nicst="$WANT_NIC $(cat "/sys/class/net/$WANT_NIC/operstate" 2>/dev/null) $(cat "/sys/class/net/$WANT_NIC/address")"
        [ "$(cat "/sys/class/net/$WANT_NIC/operstate" 2>/dev/null)" = up ] || prob+=("link $WANT_NIC tidak up")
    else
        prob+=("$WANT_NIC tidak ditemukan")
    fi
    live=$(ip -4 -o addr show dev vmbr0 2>/dev/null | awk '{print $4}' | paste -sd, -)
    CFG_ADDR=""; CFG_PREFIX=""; CFG_GW=""; CFG_PORTS=""
    [ -r "$IFACES" ] && eval "$(ifpy get "$IFACES")"
    file="${CFG_ADDR:-?}/${CFG_PREFIX:-?}"
    case ",$live," in *",$file,"*) ;; *) prob+=("vmbr0 live (${live:-kosong}) beda dengan file ($file)") ;; esac
    if [ -n "$CFG_GW" ]; then
        if ping -n -q -c 1 -W 1 -I vmbr0 "$CFG_GW" >/dev/null 2>&1; then gwst=ok
        else gwst="TIDAK terjangkau"; prob+=("gateway $CFG_GW tidak terjangkau"); fi
    fi

    # DNS dan NetworkManager
    resolvlist=$(awk '/^nameserver/{print $2}' "$RESOLV" 2>/dev/null | paste -sd' ' -)
    if resolv_ok; then dnsst="ok"; else
        dnsst="TIDAK sesuai"
        prob+=("DNS tidak sesuai (isi: ${resolvlist:-kosong}); jalankan: $0 dns")
    fi
    if nm_present; then
        nmact=$(systemctl is-active NetworkManager 2>/dev/null || true)
        if command -v nmcli >/dev/null 2>&1 && [ "$nmact" = active ]; then
            nmprof=$(nmcli -t -f NAME connection show 2>/dev/null | grep -c '^Wired connection [0-9]')
        fi
        nm_guard_ok || { nmguard="BELUM"; prob+=("penjaga NetworkManager belum terpasang; jalankan: $0 dns"); }
        [ "$nmprof" != "-" ] && [ "$nmprof" != 0 ] && prob+=("ada $nmprof profil 'Wired connection'; jalankan: $0 dns")
        nmtxt="${nmact:-mati}, penjaga $nmguard, profil liar $nmprof"
    fi

    if [ $verbose -eq 1 ]; then
        echo "Mode         : $mode (pending: $pend)"
        echo "Run terakhir : $res ($dur)"
        echo "nic0         : $nicst"
        echo "vmbr0 live   : ${live:-kosong}"
        echo "vmbr0 file   : $file gw ${CFG_GW:-?} ports ${CFG_PORTS:-?} (gateway $gwst)"
        echo "DNS          : ${resolvlist:-kosong} ($dnsst)"
        echo "NetworkManager: $nmtxt"
        if [ -s "$LOGFILE" ]; then echo "Log (20 terakhir):"; tail -n 20 "$LOGFILE" | sed 's/^/  /'; fi
    else
        echo "$mode | run terakhir: $res ($dur) | pending: $pend"
        echo "$nicst | vmbr0 $file gw ${CFG_GW:-?} ($gwst)"
        echo "DNS $dnsst | NM: $nmtxt"
    fi

    if [ ${#prob[@]} -gt 0 ]; then
        for p in "${prob[@]}"; do echo "! $p"; done
        if ! resolv_ok; then
            mp=$(findmnt -rn -M "$RESOLV" 2>/dev/null | head -1 | cut -c1-60)
            echo "  dns: $(ls -l "$RESOLV" 2>&1 | awk '{$1=$1; print}') | mountpoint: ${mp:-tidak} | isi: $(grep -v '^#' "$RESOLV" 2>/dev/null | head -4 | tr '\n' ';')"
        fi
        if [ $verbose -eq 0 ] && [ -s "$LOGFILE" ]; then echo "log:"; tail -n 5 "$LOGFILE" | sed 's/^/  /'; fi
    fi
    return 0
}

cmd_dns() {
    need_root
    mkdir -p "$STATE_DIR"
    nm_guard 1
    if resolv_ok; then say "DNS sudah sesuai: ${DNS_SERVERS[*]}"; else apply_resolv; fi
}

usage() {
    echo "Pemakaian: pve-nic0_migration-keeper.sh {enable|disable|status [-v]|dns}"
    exit 1
}

case "${1:-}" in
    enable)  cmd_enable ;;
    disable) cmd_disable ;;
    status)  cmd_status "${2:-}" ;;
    dns)     cmd_dns ;;
    pre)     cmd_pre ;;
    post)    cmd_post ;;
    *)       usage ;;
esac