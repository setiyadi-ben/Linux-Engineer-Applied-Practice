Download and paste proxmox iso to usb stick which has yumi exfat installed
select the target hardisk and set the following
hdsize == maxroot
maxvz == 0

after installation, go to proxmox shell and type
lvextend -l +100%FREE /dev/pve/root
resize2fs /dev/pve/root
check with df-h

go to repository and disable all and add non-subscription repo
install proxmox_desktop-init.sh

######################################################################################
cp /etc/apt/sources.list.d/debian.sources /etc/apt/sources.list.d/debian.sources.bak.$(date +%s) && cat <<EOF > /etc/apt/sources.list.d/debian.sources
Types: deb deb-src
URIs: http://mirror.sg.gs/debian/
Suites: trixie trixie-updates
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb deb-src
URIs: http://mirror.sg.gs/debian-security/
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
apt-get update && apt-get full-upgrade -y && apt-get autoremove --purge -y && apt-get clean && reboot
#######################################################################################

Restore Backup management 1010 vm and save mac for vmbr1 or use tiny11-vm_management.qcow2
1. Access Bitvise pve
2. connect to vps server using softether vpn server 
3. generate vpn config from softether vpn server
4. paste the config via bitvise sftp
5. run script via bitvise shell | 
 autoinstall_softether-vpnclient.sh 
 wget https://raw.githubusercontent.com/setiyadi-ben/Linux-Engineer-Applied-Practice/refs/heads/main/linux%20server%20environment%20setup/linux%20host%20proxmox/autoinstall_softether-vpnclient.sh && chmod +x autoinstall_softether-vpnclient.sh &&./autoinstall_softether-vpnclient.sh
6. paste vpn config, make sur to test the vpn connection before doing that! and run the script
vpnclient_modular.sh
wget https://raw.githubusercontent.com/setiyadi-ben/Linux-Engineer-Applied-Practice/refs/heads/main/linux%20server%20environment%20setup/linux%20host%20proxmox/vpnclient_modular.sh && chmod +x vpnclient_modular.sh &&./vpnclient_modular.sh
7. Restore dns.
wget https://raw.githubusercontent.com/setiyadi-ben/Linux-Engineer-Applied-Practice/refs/heads/main/linux%20server%20environment%20setup/linux%20host%20proxmox/pve-nic0_migration-keeper.sh && chmod +x pve-nic0_migration-keeper.sh &&./pve-nic0_migration-keeper.sh dns


https://raw.githubusercontent.com/setiyadi-ben/Linux-Engineer-Applied-Practice/refs/heads/main/linux%20server%20environment%20setup/linux%20host%20vps/autoinstall_softether-server.sh && chmod +x autoinstall_softether-server.sh &&./autoinstall_softether-server.sh




7. After connected restore vmbr1 mac
8. Test ping to the gateway server

login from linux host with new username
and type
sudo su and install tasksel there, select lxde or xfce

