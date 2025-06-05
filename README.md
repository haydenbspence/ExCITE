# ExCITE
Educators Clinical Informatics Training Environment

# OpenEMR on Azure VM (Ubuntu 24.04 LTS) with Docker Compose

Deploy the **IUPUI‑SOIC OpenEMR** container to an Azure virtual machine, reverse‑proxied by **Apache 2**, secured with HTTPS (Let’s Encrypt), and ready for FHIR.

> **Container:** `ghcr.io/iupui-soic/seiri22:latest`

---

## Table of Contents
1. [Prerequisites](#prerequisites)  
2. [Additional Setup Support](#additional-setup-support)  
3. [Provision VM](#provision-vm)  
4. [Install Docker](#install-docker)  
5. [Create Service Account](#create-service-account)  
6. [Prepare Volumes](#prepare-volumes)  
7. [Deploy with Compose](#deploy-with-compose)  
8. [Configure Apache 2](#configure-apache-2)  
9. [Add HTTPS](#add-https)  
10. [Load Terminologies](#load-terminologies)  
11. [Enable FHIR](#enable-fhir)  
12. [Maintenance](#maintenance)  
13. [Troubleshooting](#troubleshooting)  
14. [Known Azure Issue](#known-azure-issue)  

---

## Prerequisites

| Item | Notes |
|------|-------|
| **Azure subscription** | Contributor role or higher |
| **SSH key pair** | `.pem` (macOS/Linux) or `.ppk` (PuTTY) |
| **DNS name** | `openemr.example.com` (recommended) |
| **Local workstation** | Bash/Zsh or PowerShell with `ssh`, `scp` |
| **MIMIC-IV dataset** | DUA must be signed and data accessed through https://physionet.org/content/mimiciv/3.1/ |
| **OpenEMR Translated Data** | MIMIC-IV must be formatted for OpenEMR through https://github.com/iupui-soic/mimic-openemr-etl/tree/main |
---

## Additional Setup Support

Additional setup support, as well as the source container for OpenEMR used in this deployment, is available through the Indiana University github repository: https://github.com/iupui-soic/openemr/tree/seiri22

Please see their INSTALL.MD for further documentation and setup instructions. https://github.com/iupui-soic/openemr/blob/seiri22/INSTALL.MD

---

## Provision VM

| Setting | Value |
|---------|-------|
| Image | **Ubuntu 24.04 LTS** |
| Size | B2ms (≥ 2 vCPU, 8 GiB) |
| Auth | **SSH key** |
| Inbound ports | **22**, **80**, **443**, **8080** |
| Disk | Premium SSD LRS, 64 GiB+ |

SSH:

```bash
ssh -i /path/to/key.pem azureuser@<PUBLIC_IP>
```
---

## Install Docker

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y ca-certificates curl gnupg lsb-release

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl enable --now docker containerd
```
---

## Create Service Account

```bash
sudo adduser --disabled-password --gecos "" oemr
sudo usermod -aG docker oemr

# test
sudo -u oemr docker run --rm hello-world
```
---

## Prepare Volumes

*The following are retrieved from pre-created MIMIC-IV formatted volumes*


```bash
sudo -u oemr docker volume create oemr_databasevolume
sudo -u oemr docker volume create oemr_sitevolume
sudo -u oemr docker volume create oemr_logvolume01
```
---

## Deploy with Compose

Modify \`/home/oemr/docker-compose.yml\`:

```yaml
version: "3.1"

services:
  mysql:
    image: mariadb:10.11
    restart: always
    command: ["mysqld","--character-set-server=utf8mb4","--innodb_buffer_pool_size=1G"]
    environment:
      MYSQL_ROOT_PASSWORD: root
    volumes:
      - oemr_databasevolume:/var/lib/mysql
    ports:
      - "3306:3306"

  openemr:
    image: ghcr.io/iupui-soic/seiri22:latest
    restart: always
    environment:
      MYSQL_HOST: mysql
      MYSQL_ROOT_PASS: root
      MYSQL_USER: openemr
      MYSQL_PASS: openemr
      OE_USER: admin
      OE_PASS: pass
    depends_on:
      - mysql
    volumes:
      - oemr_sitevolume:/var/www/localhost/htdocs/openemr/sites
      - oemr_logvolume01:/var/log
    ports:
      - "8080:80"

volumes:
  oemr_databasevolume:
    external: true
  oemr_sitevolume:
    external: true
  oemr_logvolume01:
    external: true
```

Start:

```bash
cd /home/oemr
sudo -u oemr docker compose up -d
```

---

## Configure Apache 2

```bash
sudo apt install -y apache2 libapache2-mod-proxy-html libxml2-dev
sudo a2enmod proxy proxy_http headers rewrite ssl
```

Create \`/etc/apache2/sites-available/openemr.conf\`:

```apache
<VirtualHost *:80>
    ServerName openemr.example.com

    ProxyPreserveHost On
    ProxyPass  /  http://localhost:8080/
    ProxyPassReverse / http://localhost:8080/

    ErrorLog  ${APACHE_LOG_DIR}/openemr_error.log
    CustomLog ${APACHE_LOG_DIR}/openemr_access.log combined
</VirtualHost>
```

```bash
sudo a2dissite 000-default.conf
sudo a2ensite openemr.conf
sudo systemctl reload apache2
```

---

## Add HTTPS

```bash
sudo apt install -y certbot python3-certbot-apache
sudo certbot --apache -d openemr.example.com \
  --redirect --agree-tos -m you@example.com
sudo certbot renew --dry-run
```

---

## Load Terminologies

1. **LOINC** → *Admin ▸ Config ▸ Coding ▸ Codes ▸ Import*  
2. **SNOMED CT, CPT, RXNORM** → *Admin ▸ Config ▸ Coding ▸ External Data Loads*

---

## Enable FHIR

Docs:  
<https://github.com/iupui-soic/openemr/blob/master/API_README.md#authorization>  
<https://github.com/iupui-soic/openemr/blob/master/FHIR_README.md>

```bash
curl https://openemr.example.com/apis/fhir/metadata
```

---

## Maintenance

| Task | Command |
|------|---------|
| Update containers | \`sudo -u oemr docker compose pull && docker compose up -d\` |
| Ubuntu patches | \`sudo apt update && sudo apt upgrade\` |
| Renew TLS | \`sudo certbot renew --dry-run\` |
| Logs | Rotate files in \`oemr_logvolume01\` |

---

## Troubleshooting

| Issue | Action |
|-------|--------|
| SSH blocked | Check NSG inbound rule for port 22 |
| Containers crash | \`docker compose logs --tail 100\` |
| Login fails | Default \`admin/pass\` on fresh DB; else use seeded creds |
| “Invisible key” (Azure DMS) | See [Known Azure Issue](#known-azure-issue) |

---

## Known Azure Issue

Azure Database Migration Service’s online MySQL mode may fail with an **invisible key** error.  
Disable “Migration with Azure Blob Storage (Preview)” per Microsoft docs:  
<https://learn.microsoft.com/azure/dms/known-issues-azure-mysql-fs-online>

---
