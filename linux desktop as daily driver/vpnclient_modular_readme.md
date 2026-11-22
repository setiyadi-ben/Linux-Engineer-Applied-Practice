# vpnclient_modular.sh

Script interaktif untuk import dan connect SoftEther VPN Client di Linux dari file `.vpn`.

**Prasyarat:** SoftEther VPN Client sudah terpasang di `/usr/local/vpnclient` dan script dijalankan sebagai root.

## Cara pakai

1. **Windows**: di SoftEther VPN Client Manager, buat connection setting, klik kanan, pilih *Export Connection Setting*, simpan sebagai file `.vpn`.

2. **Linux (mesin target)**: buka file `.vpn` di text editor Windows, copy isinya, lalu paste lewat nano:

   ```bash
   nano /home/<user>/nama.vpn
   ```

   Simpan dengan `Ctrl+O`, `Enter`, lalu `Ctrl+X`.
   Lokasi yang dideteksi script: `/usr/local/vpnclient`, `/opt`, dan `/home/<user>`.

3. Taruh script di `/root`, lalu jalankan:

   ```bash
   cd /root
   chmod +x vpnclient_modular.sh
   ./vpnclient_modular.sh
   ```

4. Selanjutnya ikuti instruksi di CLI.