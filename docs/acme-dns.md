# ACME-DNS Setup Guide

## Directory Setup

```bash
mkdir -p ~/acme-dns/config
mkdir -p ~/acme-dns/data
```

## Configuration

### config/config.cfg

```ini
[general]
listen = "0.0.0.0:53"
protocol = "both"
domain = "auth.example.com"
nsname = "auth.example.com"
nsadmin = "admin.example.com"

records = [
  "auth.example.com. A  YOUR.VPS.IP.ADDR",
  "auth.example.com. NS auth.example.com."
]

[database]
engine = "sqlite3"
connection = "/var/lib/acme-dns/acme-dns.db"

[api]
ip = "0.0.0.0"
port = "80"
tls = "none"

[logconfig]
loglevel = "info"
logtype = "stdout"
logformat = "text"
```

### docker-compose.yml

```yaml
version: "3.8"
services:
  acme-dns:
    image: joohoi/acme-dns:latest
    container_name: acme-dns
    restart: always
    ports:
      - "53:53/udp"
      - "53:53/tcp"
      - "127.0.0.1:8000:80"
    volumes:
      - ./config:/etc/acme-dns:ro
      - ./data:/var/lib/acme-dns
```

## DNS Records

### A Record
- **Type:** A
- **Name/Host:** auth
- **Value:** YOUR.VPS.IP.ADDR

### NS Record
- **Type:** NS
- **Host:** auth
- **Value:** auth.example.com.

## ACME-DNS Registration

```bash
curl -s -X POST http://127.0.0.1:8000/register | jq .
```

### CNAME Record (after registration)
- **Type:** CNAME
- **Host:** _acme-challenge
- **Value:** `<fulldomain>` from registration response

## acme.sh Setup

```bash
curl https://get.acme.sh | sh
export PATH="$HOME/.acme.sh:$PATH"
```

### ~/.acme.sh/account.conf

```bash
ACMEDNS_BASE_URL="http://127.0.0.1:8000"
ACMEDNS_USERNAME="<from registration>"
ACMEDNS_PASSWORD="<from registration>"
ACMEDNS_SUBDOMAIN="<from registration>"
```

## Certificate Issuance

```bash
acme.sh --set-default-ca --server letsencrypt
acme.sh --issue -d "example.com" -d "*.example.com" --dns dns_acmedns
```

## Certificate Installation

```bash
sudo mkdir -p /etc/nginx/ssl

acme.sh --install-cert -d example.com \
  --key-file /path/to/key.key \
  --fullchain-file /path/to/fullchain.cer \
  --reloadcmd "sudo systemctl reload nginx"
```

## Auto-Renewal (crontab)

```cron
30 2 10 * * /home/user/.acme.sh/acme.sh --cron --home /home/user/.acme.sh >/dev/null 2>&1
```
