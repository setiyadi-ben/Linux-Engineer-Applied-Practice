# Topology Architecture Plan (10.20.0.0/20)

Dokumen ini mengatur alur lalu lintas jaringan, segmentasi akses, dan titik masuk (*entry point*) antara Cloud VPS dan Home Lab Proxmox. Untuk detail pemetaan IP subnet dan standar penamaan domain, rujuk ke `network-plan.md` dan `localdns-plan.md`.

## 1. Visualisasi Topologi & Traffic Flow

```text
                      PUBLIC INTERNET
                             │
        ┌────────────────────┴────────────────────┐
        │                                         │
 (Public Users)                            (Administrator)
        │                                         │
HTTP/HTTPS (80/443) / 8080                VPN Tunnel (1194)
        │                                         │
        ▼                                         ▼
Reverse Proxy (Apache)                  SoftEther VPN Gateway
(prod-apache-1.sgp.local / 10.20.1.1)         (10.20.0.1)
        │                                         │
  ┌─────┴──────────────┐                          ▼
  │                    │                ┌───────────────────┐
  │ (Local Bridge)     │                │ Management Plane  │
  ▼                    │                │ (Subnet 10.20.0.x)│
┌─────────────────────┐│                │                   │
│ Production App      ││                │  • SSH Host / RDP │
│ Subnet 10.20.1.0/24 ││                │  • Zabbix Engine  │
│ [Docker Macvlan]    ││                │  • NAS NFS        │
│ • Java App Tomcat   ││                └─────────┬─────────┘
│ • MySQL             ││                          │
│ • phpMyAdmin FPM    ││ (Proxy via VPN)     VPN Tunnel
└─────────────────────┘│                          │
                       └────────────┐             ▼
                              ┌─────┴─────────────┐
                              │ Home Lab Proxmox  │
                              │ (10.20.2.0 - 3.0) │
                              └───────────────────┘

```

---

## 2. Contoh Konfigurasi Reverse Proxy Staging (Apache)

Berikut adalah skenario penerapan *real-application* Reverse Proxy Apache yang fleksibel menembus jalur VPN internal ke Home Lab Proxmox:

```apache
# =============================================================================
# OPSI A: Target via Local DNS Domain (Direkomendasikan - Berbasis Hostname)
# Memanfaatkan Dnsmasq (core-dns-1.sgp.local: 10.20.0.3)
# =============================================================================
<VirtualHost *:443>
    ServerName staging.l-e-a-p.net
    # Atau ServerName staging-tomcat-1.sgp.local

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/server.crt
    SSLCertificateKeyFile /etc/ssl/certs/server.key

    ProxyPreserveHost On

    # Forwarding menggunakan Local DNS Name menembus VPN Tunnel
    ProxyPass        / http://staging-tomcat-1.sgp.local:8080/
    ProxyPassReverse / http://staging-tomcat-1.sgp.local:8080/

    <Location />
        Require ip 10.20.0.0/20
    </Location>
</VirtualHost>

# =============================================================================
# OPSI B: Target via Direct IP + Port (Fallback - Tanpa Resolver DNS)
# Menembus langsung ke IP privat container Staging di Proxmox
# =============================================================================
<VirtualHost *:443>
    ServerName staging-app.l-e-a-p.net

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/server.crt
    SSLCertificateKeyFile /etc/ssl/certs/server.key

    ProxyPreserveHost On

    # Forwarding langsung ke IP statis Home Lab Proxmox
    ProxyPass        / http://10.20.2.2:8080/
    ProxyPassReverse / http://10.20.2.2:8080/

    <Location />
        Require ip 10.20.0.0/20
    </Location>
</VirtualHost>

```

---

## 3. Segmentasi Layer & Kebijakan Akses

### A. Public Traffic Layer (WAN Direct)

* **Pintu Masuk Terbuka**: Port `80` / `443` (Apache Reverse Proxy), `1194` (SoftEther VPN), dan `8080` (Public Mirror). Squid Proxy bersifat opsional (lihat bagian 3.B).
* **Alur Trafik Web**: User Publik $\rightarrow$ Port `80`/`443` $\rightarrow$ Reverse Proxy (`prod-apache-1.sgp.local` / `10.20.1.1`) $\rightarrow$ Diteruskan ke Production App lokal via Docker Macvlan (`10.20.1.x`) atau ke Staging/Dev di Home Lab Proxmox (`10.20.2.x` / `10.20.3.x`) melalui VPN Tunnel.
* **Proteksi Exposure**: Port `22` (SSH), `3389` (RDP), dan port internal database ditutup total dari IP publik WAN.

### B. Management Plane Layer (Private VPN)

* **Pintu Masuk**: Port `1194` (SoftEther VPN — *cert-only auth*, *virtual hub isolation*).
* **Fallback (Opsional)**: Jika port `1194` diblokir ISP, koneksi dapat melalui Squid Proxy (contoh port `3128`, port dapat diatur lewat script dan layanan tidak wajib aktif). Jalur ini dipakai untuk akses SSH awal sebelum seluruh trafik dialihkan lewat VPN.
* **Alur Trafik Admin**: Administrator $\rightarrow$ Encrypted SoftEther Tunnel $\rightarrow$ Subnet Internal (`10.20.0.0/20`).
* **Scope Akses**: Memberikan akses penuh ke SSH VPS Host, Console/GUI Proxmox Home Lab, Zabbix Dashboard (`core-zabbix-1.sgp.local`), phpMyAdmin FPM (`prod-pma-1.sgp.local`), dan MySQL (`prod-mysql-1.sgp.local`).

### C. Inter-Service Communication & DNS

* **Local Resolver**: Seluruh kueri nama domain diproses oleh `core-dns-1.sgp.local` (`10.20.0.3`).
* **Docker Macvlan**: Container di subnet Production (`10.20.1.0/24`) berkomunikasi via IP statis dedicated Layer 2 menggunakan domain internal `.local`.
* **Cross-Site Linking**: Traffic Reverse Proxy ke Home Lab Proxmox (`10.20.2.0/24` & `10.20.3.0/24`) terhubung transparan melalui enkripsi VPN Tunnel.

---

## 4. Security Surface & Fail-Safe Rules

### A. Firewall Ingress (`iptables`)

* *Policy Default*: `ACCEPT` untuk trafik umum di `eth0`.
* *Explicit Drop*: Port `22` (SSH) dan `3389` (RDP) diblokir khusus pada interface `eth0` (WAN).

### B. Automated Protection

* Fail2ban aktif memantau log autentikasi SoftEther (`1194`) di Linux Host OS dan mengeksekusi *auto-ban* jika terdeteksi indikasi *brute-force*.

### C. Internal Database Isolation

* Database MySQL (`prod-mysql-1.sgp.local`) tidak memiliki *port-binding* ke IP publik dan hanya dapat diakses melalui jaringan internal/VPN.