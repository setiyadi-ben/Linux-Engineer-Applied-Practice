# vm-local-dns: VM Debian cloud-init dengan `*.local` yang resolve

Panduan membuat template VM Debian di SDN Proxmox (L-E-A-P) yang bisa me-resolve nama `*.local` dari semua region
(`kuma.id.local`, `x.sgp.local`, ...), punya login SSH dengan password, paket terbarui, dan QEMU guest agent. Setiap VM baru
dibuat dengan full clone dari template itu.

## Masalah dan solusi

VM dengan `systemd-resolved` menerima DNS dari DHCP (DNS host, mis. NetBird `100.83.115.131`), tetapi nama `*.local` tidak
dikirim ke DNS itu karena `.local` dicadangkan untuk mDNS. Nama publik (`ifconfig.me`) lewat DNS biasa, nama lokal tidak.
LXC dan guest tanpa `systemd-resolved` tidak terkena.

Skrip `vm-local-dns.sh` menempelkan routing domain ke link ethernet VM (yang tampil sebagai `Link 2` di `resolvectl status`)
lewat drop-in systemd-networkd:

```
/etc/systemd/network/<file .network milik link>.d/10-local-domain.conf

[Network]
Domains=~local          # semua *.local (semua region) dikirim ke DNS link ini, yaitu DNS dari DHCP
DNSDefaultRoute=yes     # wajib menyertai ~local; tanpa ini link berhenti jadi default route dan nama publik tidak resolve
```

Tidak ada IP DNS yang ditulis, drop-in berada di `/etc` (tidak ditimpa netplan/cloud-init), dan skrip idempotent.

## File

| File | Fungsi |
|---|---|
| `vm-local-dns.cloud-config.yaml` | cloud-init user-data: update paket, password root, SSH password, guest agent, dan skrip DNS tertanam. |
| `vm-local-dns.sh` | Skrip yang sama, berdiri sendiri, untuk VM yang sudah berjalan. |

## Gambaran alur

```
A. Snippet (sekali, di node)   isi "apa yang dikerjakan VM saat boot pertama": paket, password, SSH, agent, ~local
B. VM debian-vm-template       hardware + disk dari image Debian resmi + drive cloud-init + DHCP + cicustom; tag template-qcow2
C. Jalankan sekali             paket terbarui dan ~local terpasang; tunggu selesai, lalu matikan
D. Full clone                  satu clone per VM baru
```

## A. Siapkan snippet (sekali, di node)

1. **Storage.** GUI: Datacenter, Storage, `local`, Edit, Content: centang **Snippets**, **Import**, dan **Disk image** (bila
   belum), lalu OK.
   - Snippets: tempat file cloud-init (`/var/lib/vz/snippets`).
   - Import: tempat image qcow2 untuk wizard.
   - Disk image: tempat disk VM dan drive cloud-init di storage `local`.
2. **Ambil file** `vm-local-dns.cloud-config.yaml`.
3. **Ganti password root SEBELUM menyalin.** Di file itu, ubah satu baris ini:
   ```yaml
   - {name: root, password: root, type: text}   # <-- EDIT: nama user dan password
   ```
4. **Salin ke node:**
   ```bash
   mkdir -p /var/lib/vz/snippets
   scp vm-local-dns.cloud-config.yaml root@pve-1:/var/lib/vz/snippets/vm-local-dns.yaml
   ```
   Cek di GUI: `local`, Snippets, file `vm-local-dns.yaml` muncul.
5. **Unduh image Debian resmi.** Buka https://cloud.debian.org/images/cloud/ dan pilih sendiri rilis Debian terbaru yang masih
   didukung (rilis lama akan EOL, jadi dokumen ini sengaja tidak menyebut satu rilis). Di folder rilis itu, masuk ke `latest/`
   dan salin alamat file `debian-<versi>-genericcloud-amd64.qcow2`. Lalu GUI: `local`, **Import**, **Download from URL**, tempel
   alamat itu, Query URL, Download. Opsional: isi Hash algorithm SHA-512 dan checksum dari `SHA512SUMS` di folder yang sama.

   `genericcloud` identik dengan `generic` tetapi kernelnya memuat lebih sedikit driver perangkat keras; pakai `generic` bila
   butuh driver lain.

## B. Buat VM `debian-vm-template` (GUI, Create VM)

| Tab | Isian |
|---|---|
| General | Name `debian-vm-template`; VM ID: bebas yang kosong. |
| OS | **Do not use any media**. Guest OS: Linux. |
| System | **Graphic card: Serial terminal 0**. Centang **Qemu Agent**. Sisanya default. |
| Disks | **Hapus disk bawaan `scsi0`** (ikon tempat sampah). Klik **Import**, pilih file qcow2 dari storage `local`, storage tujuan `local`, Bus SCSI. Centang **Advanced**, lalu **SSD emulation**. |
| CPU, Memory | Sesuaikan kebutuhan. |
| Network | Bridge: vnet SDN (contoh `eth1010`), model VirtIO. |
| Confirm | **Jangan** centang "Start after created". Finish. |

Urutan graphic card dan serial port sengaja berbeda: display **serial terminal 0** dipilih di wizard (tab System), tetapi
**serial port 0** baru ditambahkan setelah VM terbentuk (langkah di bawah).

Setelah VM terbentuk, GUI pada `debian-vm-template`:

1. **Hardware, Add, Serial Port**, nomor **0**.
2. **Hardware**: pilih **CD/DVD Drive** (kosong, `ide2`, hasil "Do not use any media"), lalu **Remove**.
3. **Hardware, Add, CloudInit Drive**: Bus/Device **IDE 2**, Storage **local**.
4. **Cloud-Init** (menu VM): **IP Config (net0)**, Edit, IPv4 **DHCP**, OK. Biarkan IPv6.
5. Tag: klik ikon pensil di samping "No Tags" di bagian atas, isi `template-qcow2`.

Lalu di shell node:

```bash
qm set <vmid> --cicustom "user=local:snippets/vm-local-dns.yaml"
qm cloudinit update <vmid>
qm config <vmid> | grep -E 'cloudinit|ipconfig0|cicustom|agent|serial0|vga|scsi0|net0'
```

Hasilnya harus memuat: drive cloud-init (`vm-<vmid>-cloudinit...`), `ipconfig0: ip=dhcp`,
`cicustom: user=local:snippets/vm-local-dns.yaml`, `agent: 1`, `serial0: socket`, `vga: serial0`, `scsi0: ...`, dan `net0: ...`.

Padanan CLI untuk langkah GUI di atas: `qm set <vmid> --agent enabled=1`, `--serial0 socket`, `--vga serial0`,
`--ide2 local:cloudinit`, `--ipconfig0 ip=dhcp`.

## C. Jalankan sekali, lalu matikan

1. Start `debian-vm-template`.
2. Buka **Console, xterm.js** (display serial terminal 0 membuat console noVNC kosong) dan login sebagai root dengan password
   dari langkah A3.
3. Tunggu cloud-init selesai dan periksa:
   ```bash
   cloud-init status --wait          # status: done
   cat /var/log/vm-local-dns.log
   resolvectl status                 # +DefaultRoute, Default Route: yes, DNS Domain: ~local
   ping -c1 ifconfig.me              # nama publik
   ping -c1 kuma.id.local            # nama lokal
   apt list --upgradable             # kosong: paket sudah terbarui
   systemctl is-active qemu-guest-agent
   ```
4. `poweroff`.

## D. Full clone untuk instance baru

Klik kanan `debian-vm-template`, **Clone**: Mode **Full Clone**, isi Name, lalu Clone. Clone mewarisi paket yang sudah terbarui,
guest agent, dan drop-in `~local`. Untuk memperbarui template di kemudian hari, jalankan lagi `debian-vm-template`, `apt update`
dan `apt upgrade`, lalu matikan.

## E. VM yang sudah berjalan

Jalankan skrip langsung di dalam VM sebagai root:

```bash
./vm-local-dns.sh -t kuma.id.local          # terapkan, lalu tes resolve
./vm-local-dns.sh --no-reconfigure          # tanpa menyentuh lease DHCP / sesi SSH
./vm-local-dns.sh --undo                    # hapus drop-in buatan skrip
```

Opsi lain: `-i IFACE`, `-d DOMAIN` (boleh diulang). Kode keluar: `0` sesuai, `1` gagal atau belum persisten, `2` argumen
salah, `3` link bukan systemd-networkd, `4` konfigurasi benar tetapi tes `-t` gagal (cek DNS host/NetBird, bukan VM).

## Nilai yang di-hardcode: asal dan kegunaan

Semua nilai tetap di skrip dan YAML juga diberi komentar `HARDCODE` di tempatnya.

### Di Proxmox / prosedur

| Nilai | Asal | Kegunaan |
|---|---|---|
| `local` (storage) | Storage direktori bawaan di pve-1 (storage lain: `persistance_data`, `templates`). | Menyimpan Snippets, Import, disk VM, dan drive cloud-init. |
| `/var/lib/vz/snippets` | Folder snippets milik storage `local` (storage direktori di `/var/lib/vz`). | Proxmox membaca `user=local:snippets/<nama>` dari sini. |
| `vm-local-dns.yaml` | Nama bebas untuk file snippet. | Harus sama persis dengan nama di `--cicustom`. |
| `ide2` | Slot IDE ke-2; konvensi dokumentasi Proxmox untuk drive cloud-init. Kosong di sini karena CD/DVD bawaan "Do not use any media" (yang memakai `ide2`) dihapus lebih dulu. | Tempat drive cloud-init. Slot IDE kosong lain (mis. `ide0`) juga bisa; drive cloud-init tampil sebagai `media=cdrom` di slot mana pun. |
| `serial0` dan `vga serial0` | Image Debian cloud memakai console serial; konvensi dokumentasi Proxmox cloud-init. | Console xterm.js dan log boot terlihat. |
| `ipconfig0 ip=dhcp` | net0 berada di vnet SDN yang punya DHCP (dnsmasq SDN). | Memberi Proxmox jaringan untuk dituliskan ke VM; tanpa ini interface VM tetap DOWN. |
| `https://cloud.debian.org/images/cloud/` | Direktori resmi image cloud Debian. | Sumber disk VM; rilis dipilih sendiri agar dokumen tidak ikut usang saat rilis EOL. |
| `debian-vm-template`, tag `template-qcow2` | Penamaan dari pemilik repo. | Nama VM template dan tag pengelompokannya. |
| `eth1010` | Contoh nama vnet SDN pve-1 (region `id`). | Bridge net0; ganti sesuai vnet VM. |

### Di cloud-init (YAML)

| Nilai | Asal | Kegunaan |
|---|---|---|
| `ssh_pwauth`, `disable_root` | Kunci resmi cloud-init. | `ssh_pwauth: true` mengaktifkan SSH password; `disable_root: false` melepas pemblokiran kunci SSH untuk root (bawaan image `true`). |
| `package_update`, `package_upgrade` | Kunci resmi cloud-init. Menggantikan "Upgrade packages: Yes" bawaan Proxmox, yang tidak dipakai karena `cicustom user=` mengganti user-data bawaan. | Paket template terbarui setelah dijalankan sekali. |
| `root` / `root` | Permintaan pemilik repo. | Autentikasi awal root. **Edit sebelum disalin ke snippet.** |
| `/etc/ssh/sshd_config.d/00-ssh-auth.conf` | Debian meng-include `sshd_config.d/*.conf`; awalan `00-` dipilih sendiri. | `PermitRootLogin yes` dan `PasswordAuthentication yes`. sshd memakai nilai pertama yang ditemukan, jadi `00-` dibaca lebih dulu. |
| `/root/vm-local-dns.sh` | Preferensi pemilik repo: skrip di `/root`. | Mudah ditemukan dan dijalankan ulang. |
| `/var/log/vm-local-dns.log` | Nama bebas di `/var/log`. | Menyimpan keluaran skrip untuk diagnosa. |
| `ssh`, `qemu-guest-agent` | Nama unit dan paket resmi Debian. | Restart sshd (agar drop-in berlaku) dan pemasangan guest agent. |
| `bash -o pipefail` | Pilihan penulis skrip. | Kode keluar skrip, bukan `tee`, yang menentukan status `runcmd`. |

### Di `vm-local-dns.sh`

| Nilai | Asal | Kegunaan |
|---|---|---|
| `/etc/systemd/network` | Direktori konfigurasi admin systemd-networkd. | Tempat drop-in; tidak ditimpa netplan (yang menulis di `/run`). |
| `10-local-domain.conf` | Nama bebas milik skrip. | `--undo` hanya menghapus file bernama ini. |
| `local` (domain bawaan) | TLD domain lokal L-E-A-P (`id.local`, `sgp.local`, ...). | Satu `~local` mencakup semua region. |
| `~` pada `~local` | Sintaks systemd untuk routing domain. | Kirim `*.local` ke DNS link ini tanpa menjadikannya search domain. |
| `DNSDefaultRoute=yes` | Opsi `systemd.network`. | Menjaga link tetap melayani nama publik setelah punya routing domain. |
| `1.1.1.1` | Alamat publik sembarang. | Hanya untuk bertanya ke kernel "keluar lewat link mana?"; tidak ada paket dikirim. |
| `Network File:` | Label baris keluaran `networkctl status`. | Menemukan file `.network` link, yang menentukan nama folder drop-in. |
| 10 detik | Batas tunggu praktis. | Waktu bagi networkd mendorong domain ke resolved setelah reconfigure. |
| `/etc/systemd/resolved.conf` dan `resolved.conf.d` | Lokasi setelan global systemd-resolved. | Hanya dibaca untuk memperingatkan `DNS=` tetap; tidak pernah diubah. |

## Dari mana DNS dan domain datang

| Hal | Sumber |
|---|---|
| Alamat DNS | **DHCP** (`dhcp-dns-server` di subnet SDN). Butuh link naik dan DHCP berjalan, jadi tanpa IP juga tidak ada DNS. |
| `*.local` ke DNS itu | `vm-local-dns.sh` (routing domain `~local` + default route di link). |
| "DNS domain" dan "DNS servers: use host settings" di tab Cloud-Init | Diisi Proxmox dari `resolv.conf` host ke network-config. Dengan DHCP, cloud-init tidak menurunkannya ke netplan, jadi alamat DNS tetap berasal dari DHCP. |
| Search domain (agar `ping kuma` menjadi `kuma.id.local`) | Tidak dikirim DHCP. Pakai nama lengkap (`kuma.id.local`). |

## Yang perlu diketahui

- **`cicustom user=` mengganti user-data bawaan Proxmox.** Isian `ciuser`, `cipassword`, `sshkeys`, dan hostname dari Proxmox tidak
  dipakai. Jaringan (`ipconfig0`) tetap dari Proxmox. Hostname VM tetap `localhost`; ubah dengan `hostnamectl set-hostname` atau
  tambahkan `hostname:` dan `preserve_hostname: false` di YAML.
- **Hanya systemd-networkd.** Image Debian cloud dengan netplan memakainya. Bila link dikelola NetworkManager atau ifupdown,
  skrip keluar dengan kode 3 dan mencetak perintah sementara.
- **Nama interface** di VM bisa `ens18` atau `eth0`; skrip mendeteksinya dari default route.
- Setelan lama di `resolved.conf` (`DNS=` tetap, `Domains=~local` global) hanya diperingatkan. Hapus barisnya setelah drop-in
  berjalan.

## Troubleshooting

| Gejala | Cek |
|---|---|
| `ip addr`: interface DOWN, tanpa IP; `apt update` gagal resolve | `qm config <vmid> \| grep ipconfig0` harus `ip=dhcp`. Bila kosong, set di Cloud-Init (IP Config net0, DHCP) lalu `qm cloudinit update <vmid>`. |
| `cloud-init status` menyebut degraded | Baca `/var/log/vm-local-dns.log` dan kode keluarnya (bagian E). |
| `*.local` tidak resolve, publik resolve | `resolvectl status` harus memuat `~local`. Bila tidak: `/root/vm-local-dns.sh -t kuma.id.local`. |
| Publik gagal, `*.local` resolve | `Default Route` harus `yes`. Cadangan seketika: `resolvectl default-route <iface> yes`, lalu jalankan ulang skrip. |
| Skrip lolos tetapi `-t` gagal (kode 4) | DNS host/NetBird, bukan VM: `dig @<DNS-dari-DHCP> nama.id.local +short`. |
| Login root ditolak | `sshd -T \| grep -E 'permitrootlogin\|passwordauthentication'`; pastikan `00-ssh-auth.conf` ada. |
| Console kosong | Display serial terminal 0: pakai Console, xterm.js. |

## Validasi

- YAML lolos `cloud-init schema` (cloud-init 26.2), dan skrip tertanam identik dengan `vm-local-dns.sh`.
- Skrip diuji untuk idempotensi, migrasi drop-in lama, perbaikan default route, fallback, dan `--undo`.