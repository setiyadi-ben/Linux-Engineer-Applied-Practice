Berikut adalah draf dokumentasi final dengan format Markdown. Panduan ini menggunakan gaya bahasa campuran Indonesia dan Inggris secara profesional (*formal mix*), dengan memadatkan instruksi ke dalam 4 *sections* utama agar mudah dibaca dan diimplementasikan.

---

## 1. Webmin Login & Fail2Ban Mitigation

Akses antarmuka Webmin melalui *browser* di `[https://10.20.1.1:12321](https://10.20.1.1:12321)` menggunakan *credential* `root`. TurnKey OS dilengkapi dengan sistem proteksi *brute-force* Fail2Ban; jika Anda mengalami gagal *login* sebanyak 3 kali, IP VPN klien akan otomatis terkena *banned*.

Jika koneksi terblokir, lakukan proses *unban* via terminal Host VPS:

```bash
# Masuk ke dalam container NAS
sudo lxc-attach -n nas

# Opsional: Reset password jika diperlukan
passwd root

# Hapus IP Anda dari daftar blokir (Ganti dengan IP VPN aktual Anda)
fail2ban-client set webmin-auth unbanip <IP_VPN_ANDA>

```

## 2. Local User & Folder Management

Lakukan konfigurasi *local users* dan pembuatan direktori penyimpanan melalui Webmin.

1. Masuk ke menu **System > Users and Groups**. Buat *group* baru dengan nama `nas`.
2. Klik **Create a new user** (contoh: `user1`). Set bagian *Password* menjadi *No password required*, dan pastikan *user* tersebut di-*assign* ke dalam *group* `nas` yang baru dibuat.
3. Navigasi ke **Tools > File Manager**, lalu buka direktori `/mnt`.
4. Buat folder `privat` dan setel *Ownership* ke `root:nas` dengan *Permissions* `770`.
5. Buat folder `public` dan setel *Ownership* ke `www-data:nas` dengan *Permissions* `775`.

## 3. Samba Windows File Sharing Setup

Integrasikan *shared folder* agar dapat diakses secara lokal (*read & write*) melalui jaringan VPN.

1. Buka menu **Servers > Samba Windows File Sharing**. *Select* semua *shared folder default* yang ada dan hapus jika tidak diperlukan.
2. Klik **Create a new file share**, pilih direktori `/mnt/privat`, lalu sesuaikan *owner* dan *permissions* sesuai ketentuan Step 2. Ulangi proses ini untuk membuat direktori `/mnt/public`.
3. Klik kembali masing-masing *shared folder* yang baru saja dibuat, masuk ke tab **Security and Access Control**, lalu setel opsi **Writable** menjadi *Yes* agar data bisa ditulis. Klik **Save**.
4. Kembali ke halaman utama Samba, lalu klik **Convert Users**. Lakukan konversi untuk *local accounts* yang telah Anda buat satu per satu, tetapkan *password* Samba, lalu klik *Convert User*.

## 4. Apache Configuration & Service Restart

Publikasikan folder `public` ke internet tanpa mengekspos jaringan VPN privat.

1. Masuk ke **Servers > Apache Webserver > Global configuration**, lalu pilih opsi **Edit Config Files**.
2. Tambahkan *script* berikut di sekitar baris ke-175:
```text
Alias /public /mnt/public
<Directory /mnt/public>
    Require all granted
    Options FollowSymLinks Indexes
</Directory>

```


3. Simpan perubahan konfigurasi (*Save*).
4. Jalankan perintah berikut di dalam terminal *container* untuk mengaplikasikan semua konfigurasi jaringan dan *file sharing*:
```bash
systemctl restart apache2 webmin smbd nmbd

```



**Aksesibilitas Akhir:** Direktori publik kini dapat diakses secara global via `http://<IP-WAN>:8080/public`, sementara *private storage* tervalidasi hanya dapat diakses melalui protokol Samba (`\\10.20.1.1\privat`) via jaringan SoftEther VPN.

---