# Patching Security Vulnerabilities
## [**back to Linux-Engineer-Applied-Practice**](../README.md)

### Why Linux server infrastructure need routine patches and upgrades?

<p align="justify">Yeah, simply because I have been attacked by those bastards who continously trying to get in into every connected linux servers. The most common thing is to make the bussiness of it, attacking the server and infecting it and use the full computing power to infect every vulnerable linux servers in this world.</p>

</p>Look, what they do to my only one development server.</p>

<p align="center"><img src="/image-files/hacked-1.png"></p>
<p align="center"><img src="/image-files/hacked-2.png"></p>


<p>As a living example, in this section I'm doing anything I can do to make sure the attack can be minimalized or surely can be avoided. To make sure we as a man who has resposibility as a Linux Engineer to make sure the system can working seamlessly.</p>

### Procedures:

#### 1. Check all package lists, depends on your distro | apt | dnf | yum | ... etc
<p align="justify">Some VPS provider may not let you able to use custom ISO images, yet you need to use the stock ISO installations. So checking this would make you aware that there was multiple unused applications which can be the one that providing backdoors to the attackers. </p>

#### 2. Check your network via shell to see the open active ports and find out foreign ip attacks.

<p align="justify">This can be done by simply, typing..</p>

```sh
netstat -tan
```

#### 3. Install fail2ban to block unwanted brute force attacks.

```sh
apt-get update && upgrade
apt install fail2ban
```
