# Private DNS & Network Addressing Plan (10.20.0.0/20)

## 1. Standard Naming Convention DNS

Untuk menjaga konsistensi dan mempermudah identifikasi *environment*, jenis layanan, nomor *instance*, serta lokasi wilayah tanpa perlu membuka dokumen IPAM, digunakan standar penamaan DNS lokal sebagai berikut:

`<category>-<service>-<nomor>.<region>.local`

### Komponen Penamaan:
* **`<category>`** : Lingkungan operasional service.
    * `core` : Infrastruktur inti (DNS, Monitoring, Storage).
    * `prod` : Lingkungan Production.
    * `staging` : Lingkungan Staging (replika/mimic dari Production).
    * `dev` : Lingkungan Development / Sandbox.
* **`<service>`** : Jenis atau nama layanan yang dijalankan (contoh: `dns`, `zabbix`, `nas`, `apache`, `tomcat`, `mysql`, `pma`).
* **`<nomor>`** : Urutan atau nomor *instance* dari service tersebut (contoh: `1`, `2`).
* **`<region>`** : Kode lokasi/wilayah server (contoh: `sgp` untuk Singapore).
* **`.local`** : TLD internal khusus jaringan privat VPN / Local Bridge.

### Contoh Implementasi:
* `core-dns-1.sgp.local`
* `prod-apache-1.sgp.local`
* `staging-mysql-1.sgp.local`

---

## 2. Matriks Pemetaan IP & Hostname (`10.20.0.0/20`)

Berikut adalah tabel perencanaan alokasi IP statis dan domain lokal di seluruh subnet `10.20.0.0/20`:

> **Catatan:** pembagian per `/24` di tabel ini murni buat kerapian penomoran (biar gampang diingat mana Core, Prod, Staging, Dev) — **bukan** subnet/broadcast domain yang benar-benar terpisah. Secara real di jaringan, semuanya tetap satu flat `/20` dalam satu Virtual Hub SoftEther: semua device saling L2-adjacent, nggak ada router yang misahin satu blok `/24` dari blok lainnya.

| Subnet | Alamat IP | Hostname / Local DNS | Peran / Deskripsi Service |
| --- | --- | --- | --- |
| **Core VPS — Head Range**<br>`10.20.0.0/24`<br>Band `.1–.99`: VPN GW, bridge & core service (non-Docker) | `10.20.0.1` | — | SoftEther Virtual Hub (VPN Gateway), sumber jaringan `10.20.0.0/20` |
| | `10.20.0.2` | — | Interface `tap_softether` di Linux Host. Selama Docker masih mode bridge, seluruh service Docker diakses lewat IP ini sampai migrasi ke Macvlan |
| | `10.20.0.3` | `core-dns-1.sgp.local` | Alpine LXC Dnsmasq Server |
| | `10.20.0.4` | `core-zabbix-1.sgp.local` | Zabbix Monitoring Engine |
| | `10.20.0.5` | `core-nas-1.sgp.local` | Turnkey LXC NAS NFS & Public Mirror (Gabung) |
| **Core VPS — Branch Node Range**<br>Band `.100–.255`: reserved khusus Proxmox/hypervisor node (155 usable slot kalau mau tambah node lain / cluster) | `10.20.0.100` | `core-pve-1.sgp.local` | Proxmox Host — bridge `vmbr1` ke SoftEther VPN Client `vpn_vpn` |
| **Production**<br>`10.20.1.0/24` | `10.20.1.1` | `prod-apache-1.sgp.local` | Apache Reverse Proxy (Docker Macvlan) |
| | `10.20.1.2` | `prod-tomcat-1.sgp.local` | Java Tomcat Webapps (Docker Macvlan) |
| | `10.20.1.3` | `prod-mysql-1.sgp.local` | MySQL Database (Docker Macvlan) |
| | `10.20.1.4` | `prod-pma-1.sgp.local` | phpMyAdmin FPM Instance (Docker Macvlan) |
| **Staging**<br>`10.20.2.0/24`<br>*(Mimic Subnet 10.20.1.x)* | `10.20.2.1` | `staging-apache-1.sgp.local` | Apache Reverse Proxy Staging (Home Lab) |
| | `10.20.2.2` | `staging-tomcat-1.sgp.local` | Java Tomcat Webapps Staging (Home Lab) |
| | `10.20.2.3` | `staging-mysql-1.sgp.local` | MySQL Database Staging (Home Lab) |
| | `10.20.2.4` | `staging-pma-1.sgp.local` | phpMyAdmin FPM Staging (Home Lab) |
| **Development**<br>`10.20.3.0/24` | `10.20.3.x` | *(Tanpa Perancangan Statis)* | Area Bebas / Sandbox Testing (Tanpa aturan IP/DNS khusus). Proxmox host **tidak lagi** di-anchor di sini — sudah dipindah ke Core (`10.20.0.100`), lihat Bagian 3 |
| **Expansion**<br>`10.20.4.0/24 – 10.20.15.0/24` | — | — | Dibiarkan kosong murni tanpa alokasi (sisa 12 Subnet /24) |

---

## 3. Addressing Convention: Head Range vs Branch Node Range (`10.20.0.0/24`)

Subnet Core (`10.20.0.0/24`) dibagi jadi dua band:

| Band | Range | Peruntukan |
| --- | --- | --- |
| **Head** | `.1 – .99` | VPN Gateway (`10.20.0.1`), `tap_softether` bridge, dan core service non-Docker (DNS, Zabbix, NAS) |
| **Branch Node** | `.100 – .255` | Reserved untuk Proxmox atau hypervisor node lain yang nyambung ke hub via SoftEther VPN Client (155 slot — cukup buat beberapa node kalau mau cluster) |

Production/Docker (`10.20.1.0/24`) tetap terpisah, tidak kena aturan band ini.

**Aturan praktis:** IP Proxmox host wajib ada di dalam `10.20.0.0/24` (band `.100–.255` di atas), dan jangan pernah diset lebih kecil / di luar rentang itu dibanding VM/guest yang ada di baliknya. VM guest cuma tahu gateway VPN SoftEther di `10.20.0.1` — kalau IP Proxmox sendiri "terlalu jauh" dari situ (nyasar ke subnet lain seperti `10.20.2.x`/`10.20.3.x` yang harusnya buat guest), request dari VM bisa gagal nemu jalan balik lewat tunnel.

*(Catatan: mekanisme persisnya belum 100% terverifikasi murni dari sisi protokol IP — yang pasti sudah teruji jalan adalah Proxmox host ditaruh di band ini, terpisah dari range guest-nya.)*