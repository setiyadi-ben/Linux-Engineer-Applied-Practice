# Linux-Engineer-Applied-Practice (L-E-A-P)
<!-- ⬜❌✅ Checklist-->

## 1. Project Scope

This repository demonstrates a single-node production-style Linux application hosting platform.

The focus of this phase includes:

- Linux system administration
- Structured network design
- Container-based application hosting
- Monitoring implementation
- Backup and recovery procedures

This project does not simulate a distributed cloud system.
It represents a controlled, production-oriented baseline suitable for small-to-mid scale environments.

The previous exploratory version of this repository is archived for reference:

- 📄 File archive at [🌿 Historical branch](https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/branches)

The earlier version documents broader experimentation before the scope was refined into a production-focused baseline.

---

## 2. System Overview

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

Live Application Endpoint:

- https://l-e-a-p.softether.net  
- https://109.123.234.97:443  

The system runs on a single VPS and includes:

- Linux host with SSH access and fail2ban protection
- VPN tunnel access via SoftEther
- Docker runtime for containerized application services
- Reverse proxy for HTTPS access
- Database with persistent storage (internal network only)
- Monitoring service accessible through the internal network
- Backup and recovery procedures

---

## 3. Network Design

The network structure follows structured IP planning principles:

- Public exposure limited to:
  - 22 (SSH)
  - 443 (HTTPS)
  - VPN port 1194

- Internal Docker bridge network for service isolation
- Database accessible only from internal network
- Clear separation between:
  - Public access layer
  - Application layer
  - Data layer

Protocol selection (TCP/UDP) is determined by service characteristics and transport requirements.

---
## 4. Infrastructure Layout

### Compute Environment
- VPS (8GB RAM)
- Linux operating system
- System hardening
- SSH administrative access
- fail2ban protection

### Network Access Layer
- Public HTTPS access
- SSH administrative access
- VPN tunnel via SoftEther for internal access

### Application Runtime Layer
- Docker runtime
- Containerized application services
- Reverse proxy for TLS termination

### Data Layer
- Database service
- Persistent storage via Docker volumes

## 5. Application Stack

- Java-based web application
- Containerized runtime
- Database backend (internal access only)
- Persistent storage via Docker volumes
- Health endpoint enabled

The application is packaged and deployed in a production-style environment rather than a local development setup.

---

## 6. Deployment Workflow

Deployment sequence:

1. Provision VPS
2. Apply base system hardening
3. Install Docker and dependencies
4. Deploy services via docker-compose
5. Configure reverse proxy and TLS
6. Enable monitoring
7. Test application health
8. Validate backup and restore procedure

The system is designed to be reproducible from a clean host.

---

## 7. Monitoring & Observability

Monitoring covers:

- CPU usage
- Memory usage
- Disk utilization
- Container status
- Service availability

Monitoring is performed using Zabbix for host and service metrics.

Monitoring dashboards are restricted to the internal network and accessed through the VPN layer.

---

## 8. Backup & Recovery

Backup procedures include:

- Scheduled database dumps
- Docker volume backup
- Restore procedure documentation
- Recovery validation testing

Restore procedures are periodically tested to ensure service recovery in case of system failure.

---

## 9. Resource Planning

| Component    | CPU     | RAM     | Storage | Exposure |
|--------------|---------|---------|---------|----------|
| Host OS      | 1 core  | 512MB   | 10GB    | No       |
| Java App     | 1 core  | 512MB   | 1GB     | via proxy |
| Database     | 1 core  | 512MB   | 5GB     | Internal |
| Monitoring   | shared  | 256MB   | minimal | Internal |
| VPN          | minimal | 128MB   | minimal | Limited  |

Capacity planning is estimated based on:

- Observed idle-state host measurements
- JVM baseline memory behavior under default configuration
- Typical lightweight database memory footprint
- Docker runtime overhead
- Monitoring agent resource usage

Allocations are intentionally conservative to prevent resource contention under moderate load.

---

## Future Direction

The current scope establishes a stable operational baseline.

Future improvements will focus on:

- Application lifecycle refinement (build, package, release discipline)
- JVM configuration tuning and resource optimization
- Log management enhancement
- Service dependency handling and graceful restart procedures

Expansion will remain aligned with practical infrastructure roles before gradually extending toward deeper application engineering responsibilities.