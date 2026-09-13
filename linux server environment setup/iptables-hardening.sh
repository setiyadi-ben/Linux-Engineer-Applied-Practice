#!/bin/bash
set -e

# Peran interface (dikonfirmasi via ifconfig di server ini):
#   eth0   -> public WAN asli, pegang IP publik langsung (bukan bridge-port)
#   vmbr0  -> network privat untuk LXC, sekaligus tempat klien SoftEther VPN
#             nongol (tap_softether di-bridge ke sini, jadi secara netfilter
#             traffic dari situ terlihat sebagai "vmbr0", bukan "tap_softether")
#   wg0    -> WireGuard, VPN point-to-point asli
WAN_IF="eth0"
LXC_VPN_IF="vmbr0"   # network privat LXC + SoftEther bridge
VPN_IF="wg0"          # WireGuard

# ---------------------------------------------------------------------
# 1. Set default policy ACCEPT DULU, baru flush.
#    Kalau urutan dibalik (flush dulu baru set policy) dan policy lama
#    kebetulan masih DROP, ada jendela waktu chain kosong + policy DROP
#    yang bisa memutus sesi SSH yang lagi kamu pakai buat jalanin script
#    ini, sebelum sempat sampai baris ACCEPT.
# ---------------------------------------------------------------------
sudo iptables -P INPUT ACCEPT
sudo ip6tables -P INPUT ACCEPT
sudo iptables -F INPUT
sudo ip6tables -F INPUT

# 2. Loopback & Established/Related
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo ip6tables -A INPUT -i lo -j ACCEPT
sudo ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 3. EXPLICIT ACCEPT: SSH & RDP dari network LXC/SoftEther (vmbr0) & WireGuard (wg0)
sudo iptables -A INPUT -i "$LXC_VPN_IF" -p tcp -m multiport --dports 22,3389 -j ACCEPT
sudo iptables -A INPUT -i "$VPN_IF" -p tcp -m multiport --dports 22,3389 -j ACCEPT
sudo ip6tables -A INPUT -i "$LXC_VPN_IF" -p tcp -m multiport --dports 22,3389 -j ACCEPT
sudo ip6tables -A INPUT -i "$VPN_IF" -p tcp -m multiport --dports 22,3389 -j ACCEPT

# 4. EXPLICIT DROP: SSH & RDP diblokir khusus di eth0 (public WAN)
#    Port lain (80, 443, 3128, 8080, dst.) tetap terbuka karena default policy ACCEPT.
sudo iptables -A INPUT -i "$WAN_IF" -p tcp -m multiport --dports 22,3389 -j DROP
sudo ip6tables -A INPUT -i "$WAN_IF" -p tcp -m multiport --dports 22,3389 -j DROP

# 5. Simpan permanen
sudo netfilter-persistent save