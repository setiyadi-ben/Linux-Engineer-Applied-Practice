# sdn-simple_provisioning.sh

Memberi guest (LXC/VM) jaringan sendiri di node Proxmox yang hanya punya **satu IP** (VPS ber-IP publik,
atau server di belakang NAT), lewat SDN zone tipe **Simple**. Satu file, dijalankan sebagai **root** di
node Proxmox, disimpan di `/root/`.

## Ringkasan

| Bagian | Perilaku |
|---|---|
| SNAT | Guest keluar ke internet lewat IP node (masquerade). |
| DHCP + IPAM `pve` | Memberi **IP, gateway, dan DNS host** (sama untuk LXC dan VM). |
| DNS guest | DNS **host**, dibaca dari `/etc/resolv.conf` host (NetBird bila ada, kalau direct DNS upstream host). Tanpa IP tertulis. |
| PowerDNS (opsional, `--domain`) | Mendaftarkan hostname guest dari IPAM ke domain lokal: `gitlab` menjadi `gitlab.id.local`. Tanpa `--domain`, tidak dipasang. |
| Recursor (bila `--domain`) | Di `.2` subnet. `id.local` diteruskan ke PowerDNS, sisanya ke DNS host. Ini alamat yang dipakai NetBird sebagai nameserver custom. |
| Cron (tiap 5 menit) | Menyamakan DNS guest + upstream recursor dengan DNS host, merapikan record PowerDNS yang basi, memastikan DNS host menjawab domain lokal. |
| Pembersih record | Kode Python tertanam di akhir file ini (bukan file terpisah). |

Konektivitas antar PVE/region ditangani NetBird (route `/16` + policy), bukan oleh skrip ini.

## Keputusan desain

Keputusan ini sengaja dibuat sederhana. Setiap bagian skrip mengikutinya; komentar di kepala skrip
mencatat hal yang sama.

1. **Satu skrip untuk semua PVE dan semua kebutuhan.** Tidak ada skrip atau mode "tambah subnet" / "hapus subnet".
2. **1 PVE = 1 zone = 1 vnet = 1 subnet**, dipotong dari scope `/16` region di NetBird lewat `--netid` dan `--slash`.
3. **Mulai `/24`.** Kalau alamat kurang, **naikkan `--slash`** (`/23`, `/22`) dengan **re-run**. Jangan menambah subnet kedua.
4. **Mengubah subnet = maintenance break besar.** Zone, vnet, subnet, dan IPAM dibuat ulang, dan guest kehilangan jaringan.
   Untuk mengantisipasi human error:
   - **Semua adapter yang terhubung ke vnet harus sudah dilepas manual** (config guest di seluruh cluster **dan** port bridge yang hidup).
     Kalau masih ada, skrip berhenti sebelum mengubah apa pun. Pagar ini tidak bisa dilewati dengan `--yes`.
   - `--no-flush` hanya untuk menerapkan ulang subnet yang **sama**. Subnet atau vnet yang berbeda ditolak.
   - Flush atas zone yang sudah ada meminta **nama vnet diketik** (dilewati bila `--yes`).
5. **Bentrok alamat antar PVE** (netid sama, atau blok yang saling beririsan) tidak terlihat oleh skrip karena tiap PVE berdiri sendiri.
   Diselesaikan manual: re-run PVE yang bentrok dengan netid/slash baru.
6. **Aturan akses antar PVE/region** (route, policy, peers) diatur di NetBird, di luar skrip.
7. **DNS guest = DNS host.** Host yang berisi DNS publik dan DNS lokal adalah satu-satunya sumber DNS guest.
   Nama NS PowerDNS mengikuti `hostname -f` node.

## Cara kerja DNS

```
guest (LXC/VM)
  -> DNS dari DHCP = DNS host (NetBird lokal di pve-1, mis. 100.83.115.131)
       *.id.local  -> NetBird meneruskan ke nameserver custom 10.10.1.2 (recursor pve-1)
                        -> recursor: id.local -> PowerDNS auth 127.0.0.1:5300 (record guest dari IPAM)
       *.sgp.local -> NetBird meneruskan ke 10.20.1.2 (recursor PVE region sgp)
       nama publik -> resolver asli yang disimpan NetBird
```

- **Sumber DNS** adalah nameserver non-loopback pertama di `/etc/resolv.conf` host. Kalau tidak ada, dicoba
  `/run/systemd/resolve/resolv.conf`, lalu `UPSTREAMS` (`1.1.1.1 8.8.8.8 9.9.9.9`). `/etc/resolv.conf` host tidak pernah ditulis.
- **Upstream recursor** (`.`) memakai daftar DNS host yang sama (maksimal 3).
- **Nama NS/SOA/glue** PowerDNS mengikuti `hostname -f`: `pve-1` di `id.local` menjadi `pve-1.id.local`. Bila
  `hostname -f` sudah berakhiran domain, dipakai apa adanya.
### Siapa melakukan apa

| Komponen | Alamat | Peran | Diketahui guest? |
|---|---|---|---|
| DNS host (NetBird) | `100.83.115.131` | Resolver yang diterima guest dari DHCP. Meneruskan `*.id.local` ke recursor pve-1, `*.sgp.local` ke recursor region sgp, sisanya ke resolver asli. | **Ya**, satu-satunya |
| Recursor | `10.10.1.2:53` | Nameserver custom NetBird untuk domain lokal. Meneruskan `id.local` ke PowerDNS auth, sisanya ke DNS host. | Tidak langsung (lewat NetBird) |
| PowerDNS auth | `127.0.0.1:5300` | Menyimpan record guest dari IPAM. | Tidak |
| dnsmasq SDN | `10.10.1.1:53` | DHCP milik PVE; ikut mendengarkan di port 53. DHCP tidak lagi mengirim alamat ini ke guest. | Tidak |

Dari sisi guest cukup **satu** resolver (DNS host). Recursor ada karena NetBird perlu satu alamat untuk domain lokal; peran
teknisnya sekarang hanya meneruskan `id.local` ke PowerDNS auth.

Sisi VM (nama `*.local` di guest ber-`systemd-resolved`, dan template cloud-init) ada di **README-vm.md**.

## Pakai

```bash
chmod +x /root/sdn-simple_provisioning.sh
cd /root

# pve-2 Singapore: jalur masuk dari IP publik (VPS ber-IP publik)
./sdn-simple_provisioning.sh --dhcp-public-ip --vnet eth1020 --netid 1 --slash 24 --domain sgp.local

# pve-1 Indonesia: compute hardware (di belakang NAT)
./sdn-simple_provisioning.sh --dhcp-behind-nat --vnet eth1010 --netid 1 --slash 24 --domain id.local

# Hanya pasang cron + sync sekali (tanpa provisioning)
./sdn-simple_provisioning.sh --install-cron

# Satu siklus sinkron, manual (yang dipanggil cron)
./sdn-simple_provisioning.sh --sync-dns

# Pembersih record DNS: check | stale | all | rotate-key
./sdn-simple_provisioning.sh --dns check

# Hanya hapus config buatan skrip, tanpa instalasi
./sdn-simple_provisioning.sh --flush
```

Alur run penuh: **RENCANA** -> cek adapter -> konfirmasi (y/N; ketik nama vnet bila menghapus zone yang ada) ->
flush config lama -> paket -> PowerDNS -> recursor -> SDN -> rapikan record DNS -> cron -> verifikasi.

## Parameter

| Opsi | Env | Keterangan |
|---|---|---|
| `--dhcp-public-ip` | | Node VPS ber-IP publik (default vnet `eth1020`). Memberi peringatan bila IP di default route berupa alamat privat. |
| `--dhcp-behind-nat` | | Node di belakang NAT / double NAT (default vnet `eth1010`). **Menolak** subnet guest yang beririsan dengan jaringan di interface WAN. |
| `-n, --vnet NAMA` | `VNET` | Nama VNet. `eth1010` = jaringan `10.10.x.x`. Diawali huruf, maks 8 karakter. |
| `--netid N` | `NETID` | Oktet ke-3 subnet node ini, `0`-`255` (default `0`). Satu netid hanya untuk satu PVE dalam satu `/16`. |
| `--slash S` | `SLASH` | Panjang prefix subnet node, `16`-`29` (default `24`). |
| `-d, --domain DOMAIN` | `DOMAIN` | Pasang PowerDNS + recursor untuk domain ini. Tanpa opsi ini, tidak ada DNS lokal. |
| `-y, --yes` | `ASSUME_YES=1` | Lewati konfirmasi y/N dan ketik nama vnet. **Tidak** melewati pagar adapter. |
| `--flush` | `FLUSH_ONLY=1` | Hanya flush, tanpa instalasi. Tidak bisa dengan `--no-flush`. |
| `--no-flush` | `FLUSH=0` | Idempotent untuk subnet yang sama. Subnet/vnet berbeda ditolak. |
| `--sync-dns` | | Satu siklus cron (lihat bagian Cron). Tidak bisa dengan `--flush`/`--no-flush`. |
| `--install-cron` | | Pasang cron, lalu sync sekali. Tidak menyentuh paket/zone/vnet/subnet. |
| `--no-cron` | | Pada run penuh, jangan pasang cron. |
| `--dns MODE` | | Pembersih record: `check`, `stale`, `all`, `rotate-key`. |

Lanjutan: `-s, --subnet CIDR` (pengganti `--netid/--slash`, tidak bisa digabung) dan `--dhcp-only` (SNAT + DHCP saja,
mengabaikan `--domain`). Variabel environment lain: `ZONE GW DHCP_START DHCP_END DNS_IP DUMMY_IF PDNS_ID
PDNS_AUTH_PORT PDNS_API_PORT UPSTREAMS WAN_IF WAN_IP BACKUP_DIR SYNC_LOG CRON_FILE`.

## Alokasi jaringan

Satu rule NetBird `/16` per region (contoh: `10.10.0.0/16` untuk region `id`, `10.20.0.0/16` untuk `sgp`). Tiap PVE
mengambil satu potongan lewat `--netid` dan `--slash`, dengan netid **berbeda** di region yang sama.

Di dalam subnet: `.1` gateway, `.2` recursor (bila `--domain`), `.3` cadangan, DHCP dari `.4` sampai alamat sebelum broadcast.

| Perintah | Subnet | Gateway | Recursor | Rentang DHCP | Alamat DHCP |
|---|---|---|---|---|---|
| `--vnet eth1010 --netid 1 --slash 24` | `10.10.1.0/24` | `10.10.1.1` | `10.10.1.2` | `.1.4` - `.1.254` | 251 |
| `--vnet eth1010 --netid 0 --slash 23` | `10.10.0.0/23` | `10.10.0.1` | `10.10.0.2` | `.0.4` - `.1.254` | 507 |
| `--vnet eth1010 --netid 4 --slash 22` | `10.10.4.0/22` | `10.10.4.1` | `10.10.4.2` | `.4.4` - `.7.254` | 1019 |
| `--vnet eth1020 --netid 7 --slash 24` | `10.20.7.0/24` | `10.20.7.1` | `10.20.7.2` | `.7.4` - `.7.254` | 251 |

### Tumbuh dari `/24`

Blok yang lebih besar harus **sejajar**: `/23` mulai di netid genap, `/22` di kelipatan 4, `/21` di kelipatan 8.
Skrip menolak netid yang tidak sejajar dan menyarankan nilai terdekat.

| Dari | Ke | Hasil |
|---|---|---|
| netid 0 `/24` | `/23`, `/22` | `.1` dan `.2` **tidak berpindah** (`10.10.0.1`, `10.10.0.2`). Ruang tumbuh aman. |
| netid 1 `/24` | `/23` | **Tidak bisa** di netid 1. Harus netid 0 (`10.10.0.0/23`) atau netid 2. Gateway dan recursor ikut pindah (`10.10.0.1`, `10.10.0.2`), jadi nameserver custom NetBird **harus diperbarui**. |

Karena itu, untuk PVE baru pilih netid awal dengan ruang tumbuh: netid `0`, `4`, `8`, ... bila nanti butuh `/22`.
Skrip tidak melihat PVE lain, jadi catat alokasi (PVE, netid, slash, domain) di tempat yang kamu kelola. Bentrok diselesaikan
dengan re-run manual PVE yang bersangkutan.

## Re-run

### Terapkan ulang subnet yang sama

`--no-flush` dengan netid/slash/vnet yang **sama**. Tidak menghapus apa pun dan aman dengan guest berjalan: pasang ulang
paket/service, samakan DNS, rapikan record, pasang cron, verifikasi. Kalau subnet atau vnet berbeda, skrip menolak.

### Butuh alamat lebih (naik `/24` -> `/23` atau `/22`)

Ini maintenance break. Urutannya:

1. **Rencanakan blok baru** yang sejajar dan tidak bentrok dengan PVE lain di `/16` yang sama (lihat tabel di atas).
2. **Catat adapter yang ada:**
   ```bash
   grep -H '^net' /etc/pve/nodes/*/lxc/*.conf /etc/pve/nodes/*/qemu-server/*.conf | grep 'bridge=eth1010'
   ls /sys/class/net/eth1010/brif/
   ```
3. **Lepaskan SEMUA adapter** yang terhubung ke vnet (hentikan guest bila perlu):
   ```bash
   pct set <id> --delete net0     # LXC
   qm  set <id> --delete net0     # VM
   ```
   Atau pindahkan ke bridge lain. Port yang masih ada di `brif/` juga dihitung.
4. **Jalankan skrip tanpa `--no-flush`** dengan netid/slash baru, lalu ketik nama vnet saat diminta:
   ```bash
   ./sdn-simple_provisioning.sh --dhcp-behind-nat --vnet eth1010 --netid 0 --slash 23 --domain id.local
   ```
5. **Pasang kembali adapter** dengan DHCP (hostname diset **sebelum** net0 dipasang):
   ```bash
   pct set <id> --net0 name=eth0,bridge=eth1010,ip=dhcp,type=veth
   qm  set <id> --net0 virtio,bridge=eth1010
   ```
   Guest mendapat IP baru dari IPAM, dan record DNS terdaftar ulang.
6. **Perbarui NetBird** bila alamat recursor berubah (`.2` subnet baru), dan periksa PVE lain yang mungkin bentrok.

Yang tidak dikerjakan skrip: melepas adapter, memindahkan guest, dan mengubah NetBird. Itu disengaja.

## Cron dan sinkron DNS

`/etc/cron.d/leap-sdn-dns` memanggil `--sync-dns` tiap 5 menit. Dipasang otomatis pada run penuh (kecuali `--no-cron`) dan
dihapus oleh `--flush`. Satu siklus melakukan:

1. `dhcp-dns-server` semua subnet di zone = DNS host. Apply SDN hanya bila ada yang berubah.
2. Drop-in lama `dhcp-option=6` dibuang bila masih ada (opsi kosong itu membatalkan DNS dari PVE).
3. Upstream recursor disamakan dengan DNS host (restart recursor hanya bila berubah).
4. Record PowerDNS dirapikan: `--check` dulu, `--stale` hanya bila ada selisih dengan IPAM.
5. DNS host dites menjawab `<hostname -f>` (mis. `pve-1.id.local`).
6. Cadangan zone/SQLite di `/var/backups/leap-dns` yang lebih dari 14 hari dihapus.

Diam bila tidak ada perubahan. Log: `/var/log/leap-sdn-sync.log` (dengan tanggal). Lock bersama run penuh
(`/run/leap-sdn-provision.lock`) mencegah cron menyela provisioning. Pasang cron di **satu node per cluster**, karena config
SDN bersifat cluster-wide.

## Pembersih record DNS (`--dns`)

Sumber kebenaran adalah IPAM `pve`. Record A/AAAA yang tidak cocok dihapus atau dikoreksi (mis. satu hostname dengan lima IP
karena entri IPAM dibuang tanpa jalur penghapusan DNS milik PVE). SOA, NS, dan glue disamakan dengan `hostname -f`.

| Mode | Fungsi |
|---|---|
| `check` | Bandingkan dengan IPAM tanpa mengubah apa pun. Kode keluar `3` bila ada selisih. |
| `stale` | Koreksi A/AAAA yang tidak sesuai IPAM (paling aman; dipakai cron). |
| `all` | Hapus semua record kecuali SOA/NS/glue, lalu isi ulang dari IPAM. |
| `rotate-key` | Ganti API key PowerDNS (`pdns.conf` + `dns.cfg`), restart pdns sekali, lalu apply SDN. |

Sebelum mengubah, zone dicadangkan ke `/var/backups/leap-dns/`. Tidak menghapus file atau tabel SQLite.

## Membuat guest

```bash
pct create 100 local:vztmpl/<template> --hostname gitlab \
    --net0 name=eth0,bridge=eth1010,ip=dhcp,type=veth
```

- Set hostname **sebelum** `net0` DHCP dipasang. Mengganti hostname sesudahnya tidak memperbarui IPAM.
- Pakai `ip=dhcp` (IP statis tidak masuk IPAM, jadi tidak ada record DNS).
- Tidak perlu `--nameserver` atau DNS cloud-init: DHCP sudah memberi DNS host, untuk LXC maupun VM.
- Dengan `--domain id.local`, nama `gitlab.id.local` terdaftar di PowerDNS. Cek: `dig @10.10.1.2 gitlab.id.local +short`.
- Guest yang sudah jalan memakai DNS baru setelah `networkctl renew eth0` atau reboot.

## Flush

```bash
./sdn-simple_provisioning.sh --flush
```

Menghapus zone, vnet, dan subnet SDN `leapnet`; entri DNS SDN; zone PowerDNS; config PowerDNS dan recursor; interface dummy;
rule SNAT; file sysctl; drop-in dnsmasq buatan skrip; dan cron. Service `pdns` dan `pdns-recursor` di-*disable*.
**Tanpa backup.**

Tidak diubah: paket, file DB PowerDNS di `/var/lib/powerdns`, dan nilai runtime `ip_forward`. Flush dibatalkan bila masih ada
adapter yang terhubung ke vnet.

## Verifikasi dan troubleshooting

Tahap verifikasi memeriksa bridge, `ip_forward`, SNAT (tepat satu rule), dnsmasq, `dhcp-dns-server`, DNS host, recursor, NS lokal,
dan IPAM. Cron mencatat hanya saat status berubah.

**Menguji resolver satu per satu.** Tulis `@` di depan alamat server. Tanpa `@`, `dig 10.10.1.2 kuma.id.local` menganggap
`10.10.1.2` sebagai *nama* yang ditanyakan, dan semua query tetap lewat resolver bawaan guest, jadi hasilnya tidak membuktikan apa pun
tentang `10.10.1.1` atau `10.10.1.2`.

```bash
dig @100.83.115.131 kuma.id.local +short   # DNS host (yang dipakai guest)
dig @10.10.1.2      kuma.id.local +short   # recursor
dig @127.0.0.1 -p 5300 kuma.id.local +short # PowerDNS auth (di pve-1)
dig @10.10.1.1      kuma.id.local +short   # dnsmasq SDN
```

**Guest dengan systemd-resolved: `*.local` tidak resolve walau DNS dari DHCP benar.** `.local` dicadangkan untuk mDNS, jadi
systemd-resolved tidak mengirim nama `*.local` ke DNS dari DHCP kecuali link punya routing domain `~local`. Perbaikannya ada di sisi
VM: `vm-local-dns.sh` (atau cloud-init `vm-local-dns.cloud-config.yaml`). Lihat **README-vm.md**. LXC dan guest tanpa
systemd-resolved tidak terkena.

**DNS host tidak menjawab domain lokal.** Peringatan menyebut domain dan alamat recursor. Resolver host harus meneruskan domain itu
ke recursor (di NetBird: nameserver custom untuk domain tersebut). Skrip tidak mengubah NetBird.

**`recursor meresolve <NS>` gagal.** `SERVFAIL` dengan `EDE: 22 (No Reachable Authority)` berarti recursor tidak mendapat jawaban dari
PowerDNS auth. Cek:

```bash
dig @<alamat-recursor> pve-1.id.local +short        # via recursor
dig @127.0.0.1 -p 5300 pve-1.id.local +short        # auth langsung (harus = gateway)
ss -lnup | grep -E ':(53|5300)\b'
journalctl -u pdns -u pdns-recursor -n 30 --no-pager
```

- Auth menjawab, recursor tidak: masalah di recursor/forward (`recursor.conf`).
- Auth juga gagal: masalah di PowerDNS auth (service, port 5300, database zone).
- Normal saat dicek ulang: keterlambatan setelah recursor dibuat ulang; jalankan skrip lagi.

## Kode keluar

| Kode | Arti |
|---|---|
| `0` | Semua tahap berhasil (atau `--flush`/`--sync-dns` selesai) |
| `1` | Preflight, pagar adapter, `--no-flush` ditolak, konfirmasi dibatalkan, atau salah satu tahap gagal |
| `2` | Argumen/nilai tidak valid |
| `3` | Hanya `--dns check`: ada selisih dengan IPAM |

## Catatan

- **Skrip tidak menyentuh `/etc/resolv.conf` host.** DNS host dikelola NetBird.
- **Beberapa PVE dengan domain yang sama** tidak otomatis berbagi record: tiap PowerDNS hanya mengenal guest-nya sendiri, dan
  NetBird tidak menggabungkan jawaban antar nameserver. Pakai domain berbeda per PVE, atau tunggu replikasi (lihat catatan di skrip).
- **Server di belakang NAT = double NAT.** Koneksi masuk dari luar ke guest tidak langsung bisa.
- SNAT + DHCP hanya memberi internet; **tidak membatasi** akses guest ke jaringan privat lain atau ke host. Atur lewat firewall
  Proxmox dan ACL NetBird.
- `hostname -f` di guest dibuat Proxmox dari search domain resolver host, bukan dari DHCP atau skrip.
- Tipe zone tidak bisa diubah. Hubungan ke node lain lewat NetBird.
- Domain `.local` dicadangkan untuk mDNS (RFC 6762). Untuk guest ber-`systemd-resolved`, pasang `vm-local-dns.sh` (README-vm.md).
- Dari versi lama (DHCP tanpa DNS, `/16`): jalankan **tanpa** `--no-flush` setelah semua adapter dilepas, supaya subnet lama dibuat
  ulang. Untuk subnet yang sama (`/24` yang sudah ada), `--no-flush` cukup dan drop-in lama dibuang otomatis.