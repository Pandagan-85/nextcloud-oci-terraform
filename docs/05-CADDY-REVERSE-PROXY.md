# Caddy Reverse Proxy Setup per Nextcloud AIO

Guida alla configurazione di Caddy come reverse proxy per Nextcloud AIO su Oracle Cloud Infrastructure.

## Perché serve un reverse proxy?

Nextcloud AIO su ambienti cloud (come OCI) **non può gestire direttamente SSL** sulla porta 443 standard perché:

- La validazione del dominio fallisce (chicken-and-egg problem)
- Il container Apache interno usa porta custom (11000)
- Let's Encrypt ha bisogno di accesso diretto alla porta 80/443

**Soluzione**: Caddy gestisce SSL (Let's Encrypt automatico) e fa proxy verso AIO.

## Architettura

```
Internet
   ↓
OCI Security Lists (firewall cloud)
   ↓ port 80, 443
Caddy Reverse Proxy
   ↓ port 11000 (interno)
Nextcloud AIO Apache
   ↓
Nextcloud + Database + Redis + ...
```

## File di configurazione

### docker-compose.yml

```yaml
version: "3.8"

services:
  nextcloud-aio-mastercontainer:
    image: nextcloud/all-in-one:latest
    container_name: nextcloud-aio-mastercontainer
    restart: always
    ports:
      - "8080:8080" # AIO admin interface
      - "8443:8443" # AIO admin HTTPS
    environment:
      - APACHE_PORT=11000
      - APACHE_IP_BINDING=0.0.0.0
      - SKIP_DOMAIN_VALIDATION=true # Caddy gestisce SSL
      - TZ=Europe/Rome
    volumes:
      - nextcloud_aio_mastercontainer:/mnt/docker-aio-config
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - nextcloud-aio

  caddy:
    image: caddy:latest
    container_name: caddy-reverse-proxy
    restart: always
    ports:
      - "80:80" # HTTP (redirect to HTTPS)
      - "443:443" # HTTPS
      - "443:443/udp" # HTTP/3
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    networks:
      - nextcloud-aio
    depends_on:
      - nextcloud-aio-mastercontainer

networks:
  nextcloud-aio:
    name: nextcloud-aio

volumes:
  nextcloud_aio_mastercontainer:
  caddy_data:
  caddy_config:
```

### Caddyfile

```
pandagan-oci.duckdns.org {
    # Reverse proxy to Nextcloud AIO Apache
    reverse_proxy nextcloud-aio-apache:11000

    # Security headers
    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Frame-Options "SAMEORIGIN"
        X-Content-Type-Options "nosniff"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "no-referrer"
    }

    # Enable compression
    encode gzip

    # Logs
    log {
        output file /data/access.log
        level INFO
    }
}
```

## Deployment

### 1. Preparazione file

```bash
# Sul PC locale
cd /home/pandagan/Projects/nextcloud-oci-terraform

# Trasferisci file sull'istanza
scp docker/docker-compose.yml docker/Caddyfile ubuntu@YOUR_IP:/home/ubuntu/nextcloud/
```

### 2. Deploy stack completo

```bash
# Sull'istanza OCI via SSH
cd ~/nextcloud

# Avvia tutto
docker compose up -d

# Verifica container
docker ps

# Monitora logs Caddy per certificato SSL
docker logs -f caddy-reverse-proxy
```

Dovresti vedere nei logs:

```
certificate obtained successfully for pandagan-oci.duckdns.org
```

### 3. Configurazione AIO

1. Accedi a: `https://YOUR_IP:8080`
2. Login con password generata
3. Configura dominio: `your-domain.duckdns.org`
4. Seleziona componenti opzionali
5. Avvia container

## Verifica funzionamento

### Porta 443 in ascolto (Caddy)

```bash
sudo netstat -tlnp | grep 443
```

Output atteso:

```
tcp  0.0.0.0:443  0.0.0.0:*  LISTEN  <PID>/docker-proxy
```

### Certificato SSL valido

```bash
curl -I https://your-domain.duckdns.org
```

Output atteso:

```
HTTP/2 200
server: Caddy
```

### Accesso da browser

```
https://your-domain.duckdns.org
```

- ✅ Certificato SSL valido (Let's Encrypt)
- ✅ Pagina login Nextcloud
- ✅ Nessun warning sicurezza

## Troubleshooting

### Errore: Connection refused port 443

**Causa**: Caddy non avviato o crashato

**Soluzione**:

```bash
docker logs caddy-reverse-proxy
docker restart caddy-reverse-proxy
```

### Errore: certificate obtain failed

**Causa**: DNS non configurato o porte bloccate

**Soluzione**:

```bash
# Verifica DNS
nslookup your-domain.duckdns.org 8.8.8.8

# Verifica Security Lists OCI hanno porte 80, 443 aperte
# Verifica UFW
sudo ufw status | grep -E "80|443"
```

### Errore: 502 Bad Gateway

**Causa**: Apache AIO non raggiungibile

**Soluzione**:

```bash
# Verifica Apache AIO
docker ps | grep apache

# Verifica che sia sulla stessa rete
docker network inspect nextcloud-aio

# Verifica porta 11000
docker exec nextcloud-aio-apache netstat -tlnp | grep 11000
```

### Reset completo se problemi persistenti

```bash
# Ferma tutto
docker compose down

# Rimuovi container
docker ps -aq | xargs docker rm -f

# Rimuovi volumi (ATTENZIONE: cancella dati!)
docker volume rm $(docker volume ls -q | grep nextcloud)
docker volume rm $(docker volume ls -q | grep caddy)

# Riavvia pulito
docker compose up -d
```

## Gestione certificati

### Rinnovo automatico

Caddy **rinnova automaticamente** i certificati Let's Encrypt prima della scadenza. Non serve configurazione.

### Verifica scadenza

```bash
# Da browser: clicca sul lucchetto → Certificato → Scade il...

# Da CLI
echo | openssl s_client -connect your-domain.duckdns.org:443 2>/dev/null | openssl x509 -noout -dates
```

### Forzare rinnovo manuale

```bash
# Rimuovi certificati cached
docker exec caddy-reverse-proxy rm -rf /data/caddy/certificates/*

# Riavvia Caddy
docker restart caddy-reverse-proxy

# Monitora rinnovo
docker logs -f caddy-reverse-proxy
```

## Performance e ottimizzazioni

### HTTP/3 (QUIC)

Già abilitato con `443:443/udp` nel docker-compose.yml.

Verifica:

```bash
curl -I --http3 https://your-domain.duckdns.org
```

### Compressione gzip

Già abilitata nel Caddyfile con `encode gzip`.

### Caching (opzionale)

Per migliorare performance, aggiungi al Caddyfile:

```
pandagan-oci.duckdns.org {
    # ... configurazione esistente ...

    # Cache static assets
    @static {
        path *.css *.js *.jpg *.png *.gif *.ico *.woff *.woff2
    }
    header @static Cache-Control "public, max-age=31536000"
}
```

## Security Best Practices

### HSTS Preload

Per massima sicurezza, registra il dominio nella HSTS Preload List:
https://hstspreload.org/

### Rate Limiting (opzionale)

Proteggi da brute force aggiungendo al Caddyfile:

```
pandagan-oci.duckdns.org {
    # Rate limit login attempts
    @login {
        path /login*
    }
    rate_limit @login {
        zone login
        key {remote_host}
        events 5
        window 1m
    }
}
```

### Logs monitoring

```bash
# Tail logs real-time
docker exec caddy-reverse-proxy tail -f /data/access.log

# Analizza tentativi di accesso
docker exec caddy-reverse-proxy grep "POST /login" /data/access.log
```

## Backup configurazione

```bash
# Backup Caddyfile
cp ~/nextcloud/Caddyfile ~/nextcloud/Caddyfile.backup

# Backup certificati Caddy (automatico nei volumi)
docker run --rm -v caddy_data:/data -v $(pwd):/backup ubuntu tar czf /backup/caddy-data-backup.tar.gz /data
```

## Update Caddy

```bash
# Pull latest image
docker pull caddy:latest

# Riavvia con nuova versione
docker compose up -d caddy

# Verifica versione
docker exec caddy-reverse-proxy caddy version
```

## Monitoring

### Status check script

```bash
#!/bin/bash
# ~/nextcloud/check-caddy.sh

if docker ps | grep -q caddy-reverse-proxy; then
    echo "✅ Caddy running"
else
    echo "❌ Caddy NOT running"
    docker compose up -d caddy
fi

# Check SSL certificate expiry
DAYS=$(echo | openssl s_client -connect pandagan-oci.duckdns.org:443 2>/dev/null | openssl x509 -noout -checkend $((30*86400)))
if [ $? -eq 0 ]; then
    echo "✅ SSL certificate valid (>30 days)"
else
    echo "⚠️ SSL certificate expiring soon!"
fi
```

## Next Steps

Una volta Caddy e Nextcloud funzionanti:
→ Procedi a `docs/06-DATA-MIGRATION.md` per importare i dati
