1. disable enterprise repo
2. apt update && apt upgrade
3. download and install vpn

wget https://raw.githubusercontent.com/setiyadi-ben/Linux-Engineer-Applied-Practice/refs/heads/main/linux%20server%20environment%20setup/autoinstall_softether-vpnclient.sh && \
chmod +x autoinstall_softether-vpnclient.sh && ./autoinstall_softether-vpnclient.sh

#=== select 1, 1, 7

4. copy config via ssh sftp | using bitvise login as root place config to /usr/local/vpnclient
5. run script to connect vpn

wget https://raw.githubusercontent.com/setiyadi-ben/Linux-Engineer-Applied-Practice/refs/heads/main/linux%20server%20environment%20setup/vpnclient_modular.sh && \
chmod +x vpnclient_modular.sh && ./vpnclient_modular.sh

#=== select 1, terus redo select 2

6. masuk ke etc/network/interfaces

nano /etc/network/interfaces

=== taruh ini

auto vmbr1

iface vmbr1 inet static
        address 10.20.0.3/20
        bridge-ports vpn
        bridge-stp off
        bridge-fd 0

7. ifreload -a dan tes ping ke 10.20.0.1 atau 10.20.0.2

login webmin pakai root dan paswword root juga, turnkey untuk webdav
fail2ban-client set webmin-auth unbanip 10.20.15.250