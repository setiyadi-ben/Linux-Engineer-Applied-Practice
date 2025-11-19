# Automations | Restore Previous Config
## [**back to Linux-Engineer-Applied-Practice**](../README.md)

### Set-up right custom environment might be a burden when we as system enginner has hundreds or maybe thousand of servers available. So when we implementing this kind of scripts, we can relax and test after all the restoring progress were done.

```
/automation
│
├── restore.sh
└── configs/
    ├── jail.local
    ├── daemon.json (planned)
    ├── root-crontab (planned)
    ├── sshd_config
    ├── (put your public ssh keys here ".pub"")
```
#### What will be installed?
- security: fail2ban,
- utilities: htop, fastfetch

#### Whats working?
```
--> Fail2ban
- Fail2ban with built-in protection 3 fails ban 10 years.
- Add your IP to the fail2ban whitelists.
- Currently protected app: sshd, planned (casaos, jellyfin and more , ..)
--> SSH
- Insert your publickey *.pub to login without typing passwords.
- planned - toggle, enable || disable password authentication.
- planned - multi user or only root user
- planned - custom user rights creation.

For advanced sysadmins:
--> VPN - Softether VPN Server
- Interactive VPN installation procedures. (planned, not integrated yet)
```

<p align="Justify">This is the script code below, periodically will be updated whenever I succesfully implement in my environment infrastructure. If you wanna install it use this curl below: </p>


```sh
# Restore Previous Config *for root superuser
cd /opt && \
curl -fSSL -o restore.sh https://raw.githubusercontent.com/setiyadi-ben/Linux-Engineer-Applied-Practice/refs/heads/main/Automations/automation/restore.sh && \
chmod +x restore.sh && \
sudo ./restore.sh
```

```sh
# Restore Previous Config *for normal user and being member of sudo
sudo mkdir -p /opt/configs && \
sudo chown -R $(whoami):sudo /opt/configs && \
sudo chmod -R 2775 /opt/configs && \
cd /opt && \
curl -fSSL -o restore.sh https://raw.githubusercontent.com/setiyadi-ben/Linux-Engineer-Applied-Practice/refs/heads/main/Automations/automation/restore.sh && \
chmod +x restore.sh && \
sudo ./restore.sh
```