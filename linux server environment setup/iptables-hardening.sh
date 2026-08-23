# 1. Izinkan SSH & RDP dari Interface VPN
sudo iptables -A INPUT -i vmbr0 -p tcp -m multiport --dports 22,3389 -j ACCEPT
sudo iptables -A INPUT -i wg0 -p tcp -m multiport --dports 22,3389 -j ACCEPT

# 2. Blokir SSH & RDP dari Public WAN (eth0)
sudo iptables -A INPUT -i eth0 -p tcp -m multiport --dports 22,3389 -j DROP

# 3. Blokir juga di IPv6 (karena Port 3389 kamu listen di IPv6 :::3389)
sudo ip6tables -A INPUT -i eth0 -p tcp -m multiport --dports 22,3389 -j DROP

# 4. Simpan Permanen
sudo netfilter-persistent save