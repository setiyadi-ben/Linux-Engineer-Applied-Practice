# Network Architecture Plan (10.20.0.0/20)

> **Status**: Docker saat ini masih memakai bridge biasa, sehingga seluruh service Docker diakses lewat `10.20.0.2` (interface `tap_softether` di Linux Host). Skema Docker Macvlan `10.20.1.0/24` pada dokumen ini adalah desain target setelah migrasi.

## 1. Tabel Arsitektur Subnet 10.20.0.0/20 (Revisi Akhir)

| Subnet | Lokasi Operasi | Komponen & Metode Deploy | Keterangan Port & Akses Jaringan |
| --- | --- | --- | --- |
| **10.20.0.0/24** | VPS (Cloud) | **Core Infrastructure** (dipasang di Linux Host atau LXC):<br>• **Linux Host OS**: SoftEther VPN (Cert Only), Fail2ban, Squid Proxy (opsional)<br>• **Alpine LXC**: Dnsmasq (DNS lokal)<br>• **Turnkey LXC**: Public Mirror, Zabbix Engine (Templat Proxmox), NAS NFS | **Akses Publik Langsung**:<br>• **1194**: SoftEther VPN<br>• **3128**: Squid Proxy (opsional, port contoh, dapat diatur lewat script)<br>• **8080**: Public Mirror<br>*(Tanpa port 5555. SSH & RDP via VPN internal; Squid hanya fallback jika 1194 diblokir ISP)* |
| **10.20.1.0/24** | VPS (Cloud) | **Production**:<br>• **Docker Macvlan** (mengikuti mask /20, alokasi IP dimulai dari `10.20.1.1`): Apache Reverse Proxy (`10.20.1.1`), Apache Tomcat (Production Modular Monolith App), MySQL, phpMyAdmin | **Akses Publik**:<br>• **80 / 443**: hanya lewat Apache Reverse Proxy<br>Tomcat, MySQL, dan phpMyAdmin tidak terekspos ke publik. Dipisah dari core agar metrik CPU, RAM, & Net I/O produksi terukur presisi. |
| **10.20.2.0/24** | Proxmox (Home Lab) | **Staging Environment**: mimic dari Production | — |
| **10.20.3.0/24** | Proxmox (Home Lab) | **Development Environment**: tanpa aturan baku | — |
| **10.20.4.0/24 – 10.20.15.0/24** | — | **Reserved / Subnet Ekspansi Masa Depan** | Dibiarkan kosong murni tanpa alokasi (sisa 12 Subnet /24). |

---

## 2. Keamanan Sistem: Keputusan Engineering untuk Menekan Attack Surface

Arsitektur hybrid ini sengaja dibuat ramping: layanan yang tidak wajib publik disembunyikan di balik VPN, dan setiap komponen tambahan harus punya alasan yang jelas.

| Keputusan Engineering | Dampak terhadap Attack Surface |
| --- | --- |
| **SSH (22) dan RDP (3389) ditutup dari WAN**; akses admin lewat VPN internal `10.20.0.0/20` (fallback via Squid jika 1194 diblokir ISP) | Management plane tidak terlihat dari internet, sehingga tidak ada target *brute-force* langsung ke SSH/RDP. |
| **SoftEther cert-only** dengan *virtual hub isolation*; port manajemen 5555 tidak dibuka | Pintu masuk VPN hanya menerima klien bersertifikat, dan port manajemen SoftEther tidak terekspos. |
| **Port publik dibatasi**: hanya 80/443 (Apache), 1194 (VPN), dan 8080 (Public Mirror); Squid (contoh 3128) opsional dan tidak wajib aktif | Daftar layanan yang bisa dipindai dari luar pendek dan terdokumentasi. |
| **Database tanpa port-binding ke IP publik**; MySQL dan phpMyAdmin hanya via jaringan internal/VPN | Data tidak bisa dijangkau langsung dari WAN. |
| **Packet filtering minimal**: explicit drop 22 dan 3389 di `eth0`, ditambah Fail2ban untuk log autentikasi SoftEther | Aturan yang sedikit lebih mudah diaudit dan kecil peluang salah konfigurasi. |
| **Segmentasi subnet**: core (`10.20.0.0/24`), production (`10.20.1.0/24`, Docker Macvlan), staging dan development di Home Lab (`10.20.2.0/24`, `10.20.3.0/24`) | Trafik VPS ke Home Lab hanya lewat VPN tunnel, dan vhost staging di Apache dibatasi `Require ip 10.20.0.0/20`. |
| **Tanpa Kubernetes dan tanpa nested virtualization** (Zabbix dan NAS NFS di Turnkey LXC) | Komponen yang harus di-*patch* dan diamankan lebih sedikit. |

### Trade-off yang Diterima
Arsitektur ini bergantung pada satu *VPN tunnel* (SoftEther, port 1194) untuk akses admin dan koneksi antara VPS dan Home Lab. Jika tunnel terputus, akses SSH/RDP dan jalur proxy ke staging/development ikut terputus. Jika port 1194 diblokir ISP, Squid Proxy (opsional) dapat dipakai sebagai jalur fallback. Kompromi ini diterima demi menjaga arsitektur tetap sederhana, aman, dan hemat biaya infrastruktur untuk skala SaaS *modular monolith*.