#!/bin/bash

# 1. Bersihkan dulu rule INPUT lama agar tidak menumpuk (Opsional tapi direkomendasikan)
sudo iptables -F INPUT
sudo ip6tables -F INPUT

# 2. Set Default Policy ke ACCEPT (Trafik eth0 bawaannya diizinkan semua)
sudo iptables -P INPUT ACCEPT
sudo ip6tables -P INPUT ACCEPT

# 3. Izinkan Loopback & Status Koneksi Terkait (Established/Related)
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo ip6tables -A INPUT -i lo -j ACCEPT
sudo ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 4. EXPLICIT ACCEPT: Izinkan SSH & RDP khusus dari Interface VPN (vmbr0 & wg0)
sudo iptables -A INPUT -i vmbr0 -p tcp -m multiport --dports 22,3389 -j ACCEPT
sudo iptables -A INPUT -i wg0 -p tcp -m multiport --dports 22,3389 -j ACCEPT
sudo ip6tables -A INPUT -i vmbr0 -p tcp -m multiport --dports 22,3389 -j ACCEPT
sudo ip6tables -A INPUT -i wg0 -p tcp -m multiport --dports 22,3389 -j ACCEPT

# 5. EXPLICIT DROP: Blokir SSH & RDP KHUSUS dari Public WAN (eth0)
# Perhatikan: Port 80, 443, 3128, 8080 TIDAK DIBLOKIR karena default policy sudah ACCEPT
sudo iptables -A INPUT -i eth0 -p tcp -m multiport --dports 22,3389 -j DROP
sudo ip6tables -A INPUT -i eth0 -p tcp -m multiport --dports 22,3389 -j DROP

# 6. Simpan Permanen
sudo netfilter-persistent save