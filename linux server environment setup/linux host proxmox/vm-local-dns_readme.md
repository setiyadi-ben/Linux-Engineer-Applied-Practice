# vm-local-dns: VM Debian cloud-init dengan domain global `*.local` yang resolve dan mencakup banyak apex region domain

Membuat VM Debian di SDN Proxmox (L-E-A-P) me-resolve nama `*.local` dari semua region (`kuma.id.local`, `x.sgp.local`, ...)
tanpa mematikan DNS publik. Ada dua file yang dipakai terpisah: **cloud-init** untuk template VM baru, dan **skrip shell** untuk
VM yang sudah berjalan.

## 1. Masalah dan solusi

VM dengan `systemd-resolved` menerima DNS dari DHCP (DNS host, mis. NetBird `100.83.115.131`), tetapi nama `*.local` tidak
dikirim ke DNS itu karena `.local` dicadangkan untuk mDNS. Nama publik (`ifconfig.me`) lewat DNS biasa, nama lokal tidak.
LXC dan guest tanpa `systemd-resolved` tidak terkena.

Kedua file menerapkan hal yang sama: routing domain pada link ethernet VM (yang tampil sebagai `Link 2` di `resolvectl status`)
lewat drop-in systemd-networkd:

```
/etc/systemd/network/<file .network milik link>.d/10-local-domain.conf

[Network]
Domains=~local          # semua *.local dikirim ke DNS link ini, yaitu DNS dari DHCP
DNSDefaultRoute=yes     # wajib menyertai ~local; tanpa ini link berhenti jadi default route dan nama publik tidak resolve
```

Satu `~local` mencakup semua apex region domain (`id.local`, `sgp.local`, `jp.local`, ...), jadi region baru tidak perlu
daftar domain tambahan. Tidak ada IP DNS yang ditulis, drop-in berada di `/etc` (tidak ditimpa netplan/cloud-init), dan skrip
idempotent.

## 2. Dua file dan kapan memakainya

| File | Dipakai untuk | Isi | Bagian |
|---|---|---|---|
| `vm-local-dns.cloud-config.yaml` | Template VM baru (lalu di-clone) | cloud-init user-data: update paket, password root, SSH password, guest agent, dan skrip DNS tertanam (isinya identik dengan `vm-local-dns.sh`). | 3 |
| `vm-local-dns.sh` | VM yang sudah berjalan | Skrip bash oneshot, idempotent. | 4 |

---

## 3. File 1: `vm-local-dns.cloud-config.yaml` (template VM baru)

Alur:

```
3.1 Snippet (sekali, di node)   isi "apa yang dikerjakan VM saat boot pertama": paket, password, SSH, agent, ~local
3.2 VM debian-vm-template       hardware + disk dari image Debian resmi + drive cloud-init + DHCP + cicustom; tag template-qcow2
3.3 Jalankan sekali             paket terbarui dan ~local terpasang; tunggu selesai, lalu matikan
3.4 Full clone                  satu clone per VM baru
```

### 3.1 Siapkan snippet (sekali, di node)

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

### 3.2 Buat VM `debian-vm-template` (GUI, Create VM)

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

### 3.3 Jalankan sekali, lalu matikan

1. Start `debian-vm-template`.
2. Buka **Console, xterm.js** (display serial terminal 0 membuat console noVNC kosong) dan login sebagai root dengan password
   dari langkah 3.1 butir 3.
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

### 3.4 Full clone untuk instance baru

Klik kanan `debian-vm-template`, **Clone**: Mode **Full Clone**, isi Name, lalu Clone. Clone mewarisi paket yang sudah terbarui,
guest agent, dan drop-in `~local`. Untuk memperbarui template di kemudian hari, jalankan lagi `debian-vm-template`, `apt update`
dan `apt upgrade`, lalu matikan.

---

## 4. File 2: `vm-local-dns.sh` (VM yang sudah berjalan)

Untuk VM yang sudah ada dan tidak dibuat dari template di bagian 3. Skrip ini melakukan hal yang sama dengan bagian cloud-init
(drop-in `~local` + default route), tanpa mengubah paket, password, atau SSH.

### 4.1 Pakai

Jalankan di dalam VM sebagai root:

```bash
./vm-local-dns.sh -t kuma.id.local          # terapkan, lalu tes resolve
./vm-local-dns.sh --no-reconfigure          # tanpa menyentuh lease DHCP / sesi SSH
./vm-local-dns.sh --undo                    # hapus drop-in buatan skrip
```

Idempotent: tanpa perubahan, tidak ada yang ditulis dan link tidak di-reconfigure.

### 4.2 Opsi dan kode keluar

| Opsi | Fungsi |
|---|---|
| `-i IFACE` | Pilih link (bawaan: link default route). |
| `-d DOMAIN` | Routing domain tanpa tanda `~`; boleh diulang (bawaan: `local`). |
| `-t NAMA` | Tes resolve `NAMA` setelah diterapkan. |
| `--no-reconfigure` | Pasang domain lewat `resolvectl` tanpa `networkctl reconfigure`; drop-in berlaku penuh pada reconfigure/boot berikutnya. |
| `--undo` | Hapus drop-in buatan skrip. |

| Kode | Arti |
|---|---|
| `0` | Sesuai. |
| `1` | Gagal diterapkan atau belum persisten. |
| `2` | Argumen atau lingkungan salah. |
| `3` | Link bukan systemd-networkd. |
| `4` | Konfigurasi benar tetapi tes `-t` gagal (cek DNS host/NetBird, bukan VM). |

---

## 5. Referensi

### 5.1 Nilai yang di-hardcode: asal dan kegunaan

Semua nilai tetap di skrip dan YAML juga diberi komentar `HARDCODE` di tempatnya.

**Di Proxmox / prosedur (bagian 3)**

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

**Di cloud-init (`vm-local-dns.cloud-config.yaml`)**

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

**Di skrip shell (`vm-local-dns.sh`, bagian 4)**

| Nilai | Asal | Kegunaan |
|---|---|---|
| `/etc/systemd/network` | Direktori konfigurasi admin systemd-networkd. | Tempat drop-in; tidak ditimpa netplan (yang menulis di `/run`). |
| `10-local-domain.conf` | Nama bebas milik skrip. | `--undo` hanya menghapus file bernama ini. |
| `local` (domain bawaan) | TLD domain lokal L-E-A-P (`id.local`, `sgp.local`, ...). | Satu `~local` mencakup semua apex region domain. |
| `~` pada `~local` | Sintaks systemd untuk routing domain. | Kirim `*.local` ke DNS link ini tanpa menjadikannya search domain. |
| `DNSDefaultRoute=yes` | Opsi `systemd.network`. | Menjaga link tetap melayani nama publik setelah punya routing domain. |
| `1.1.1.1` | Alamat publik sembarang. | Hanya untuk bertanya ke kernel "keluar lewat link mana?"; tidak ada paket dikirim. |
| `Network File:` | Label baris keluaran `networkctl status`. | Menemukan file `.network` link, yang menentukan nama folder drop-in. |
| 10 detik | Batas tunggu praktis. | Waktu bagi networkd mendorong domain ke resolved setelah reconfigure. |
| `/etc/systemd/resolved.conf` dan `resolved.conf.d` | Lokasi setelan global systemd-resolved. | Hanya dibaca untuk memperingatkan `DNS=` tetap; tidak pernah diubah. |

### 5.2 Dari mana DNS dan domain datang

| Hal | Sumber |
|---|---|
| Alamat DNS | **DHCP** (`dhcp-dns-server` di subnet SDN). Butuh link naik dan DHCP berjalan, jadi tanpa IP juga tidak ada DNS. |
| `*.local` ke DNS itu | Routing domain `~local` + default route di link (bagian 3 atau 4). |
| "DNS domain" dan "DNS servers: use host settings" di tab Cloud-Init | Diisi Proxmox dari `resolv.conf` host ke network-config. Dengan DHCP, cloud-init tidak menurunkannya ke netplan, jadi alamat DNS tetap berasal dari DHCP. |
| Search domain (agar `ping kuma` menjadi `kuma.id.local`) | Tidak dikirim DHCP. Pakai nama lengkap (`kuma.id.local`). |

### 5.3 Yang perlu diketahui

- **`cicustom user=` mengganti user-data bawaan Proxmox** (bagian 3). Isian `ciuser`, `cipassword`, `sshkeys`, dan hostname dari
  Proxmox tidak dipakai. Jaringan (`ipconfig0`) tetap dari Proxmox. Hostname VM tetap `localhost`; ubah dengan
  `hostnamectl set-hostname` atau tambahkan `hostname:` dan `preserve_hostname: false` di YAML.
- **Hanya systemd-networkd.** Image Debian cloud dengan netplan memakainya. Bila link dikelola NetworkManager atau ifupdown,
  skrip keluar dengan kode 3 dan mencetak perintah sementara.
- **Nama interface** di VM bisa `ens18` atau `eth0`; skrip mendeteksinya dari default route.
- Setelan lama di `resolved.conf` (`DNS=` tetap, `Domains=~local` global) hanya diperingatkan. Hapus barisnya setelah drop-in
  berjalan.

### 5.4 Troubleshooting

| Gejala | Cek |
|---|---|
| `ip addr`: interface DOWN, tanpa IP; `apt update` gagal resolve | `qm config <vmid> \| grep ipconfig0` harus `ip=dhcp`. Bila kosong, set di Cloud-Init (IP Config net0, DHCP) lalu `qm cloudinit update <vmid>`. |
| `cloud-init status` menyebut degraded | Baca `/var/log/vm-local-dns.log` dan kode keluarnya (bagian 4.2). |
| `*.local` tidak resolve, publik resolve | `resolvectl status` harus memuat `~local`. Bila tidak: `/root/vm-local-dns.sh -t kuma.id.local`. |
| Publik gagal, `*.local` resolve | `Default Route` harus `yes`. Cadangan seketika: `resolvectl default-route <iface> yes`, lalu jalankan ulang skrip. |
| Skrip lolos tetapi `-t` gagal (kode 4) | DNS host/NetBird, bukan VM: `dig @<DNS-dari-DHCP> nama.id.local +short`. |
| Login root ditolak | `sshd -T \| grep -E 'permitrootlogin\|passwordauthentication'`; pastikan `00-ssh-auth.conf` ada. |
| Console kosong | Display serial terminal 0: pakai Console, xterm.js. |

### 5.5 Validasi

- YAML lolos `cloud-init schema` (cloud-init 26.2), dan skrip tertanam identik dengan `vm-local-dns.sh`.
- Skrip diuji untuk idempotensi, migrasi drop-in lama, perbaikan default route, fallback, dan `--undo`.