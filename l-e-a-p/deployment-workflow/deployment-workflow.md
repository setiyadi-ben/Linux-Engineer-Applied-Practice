# System Overview

```
                Internet
                   │
                   ▼
           Reverse Proxy (HTTPS)
                   │
                   ▼
              Docker Network
          ┌────────┴─────────┐
          │                  │
      Java Web App       Database
          │
          ▼
      Monitoring

Admin Access
   ├─ SSH
   └─ VPN
```
# Deployment sequence:

1. Provision VPS
2. Apply base system hardening
3. Configure reverse proxy and TLS
4. Deploy services via docker-compose
5. Enable monitoring
6. Test application health
7. Validate backup and restore procedure
8. 

## 1. Provision VPS
- Buy any cheap VPS from any provider that offers root access and has minimum 8GB of ram and more than 50GB storage.
- Set up root password and login via ssh. Login using publickey also available using this script here.
- Set up the vpn for tunneling connection using this script here. For detailed network design refer to this link. 
- Install gitlab service and docker dependencies.
- (Optional) using linux desktop mode can be achievable using tasksel script here. It can be used for remote desktop session.

## 2. Apply base system hardening
- Using fail2ban to prevent incoming bruteforce login attacks from public networks. Bans will be triggered after continuously 3x login failure attempts, and it will lasts for 10 years. It also has feature to exclude the IP address from banning (not recommended).

## 3. Install Docker and Dependencies
- WIth container technology, we can ship our app fast and automate manual things like installing every dependecies one by one. The process itself was simple, it requires scripts, proper documentaion for provisioning and maintenance and this kind of job will be handled by the engineer.