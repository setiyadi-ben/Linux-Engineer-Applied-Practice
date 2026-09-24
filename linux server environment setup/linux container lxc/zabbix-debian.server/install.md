# Installation
1. Create lxc container from base debian. Find from proxmox's CT Template.
2. Install sql server using ==> apt install mariadb-server -y
3. Follow the instructions from here ==> https://www.zabbix.com/download?  select "debian" and choose Server, Frontend, Agent.
4. To configure  monitoring host & docker use agent2, watch this ==> https://www.youtube.com/watch?v=NzTPqVE71ew&t=311s
5. Insert dnsmasq server inside /etc/resolv.host

```
nameserver 10.20.0.3
# dns public resolver
nameserver 1.1.1.1
nameserver 8.8.8.8
nameserver 9.9.9.9
options timeout:1 attempts:4
```

=== DON'T FORGET TO MAKE A TEMPLATE, SO NEXT DEPLOYMENT IS FASTER RATHER THAN STARTING OVER FROM FIRST STEP========