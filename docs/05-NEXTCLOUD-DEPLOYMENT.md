# Nextcloud AIO Deployment

Deployment di Nextcloud All-in-One (AIO) su OCI con dominio personalizzato e Let's Encrypt SSL.

## Prerequisites

- ✅ Docker e Docker Compose installati
- ✅ Firewall UFW configurato (porte 80, 443, 8080 aperte)
- ✅ Dominio configurato e funzionante
- ✅ Dominio che punta all'IP dell'istanza

## Overview Nextcloud AIO

Nextcloud AIO è un container "all-in-one" che include:

- Nextcloud (file sync, calendar, contacts, tasks)
- Database (PostgreSQL)
- Redis cache
- Imaginary (image processing)
- Collabora Online (document editing) [opzionale]
- Talk (video calls) [opzionale]
- Backup automatici

**Architettura**:

- Un "mastercontainer" sulla porta 8080 gestisce tutti i servizi
- Crea e gestisce automaticamente gli altri container necessari
- Configurazione via interfaccia web

## Step 1: Preparazione sull'istanza OCI

### 1.1 Crea directory per dati

**Sull'istanza OCI via SSH**:

```bash
# Crea directory principale
sudo mkdir -p /opt/nextcloud

# Imposta proprietario
sudo chown -R ubuntu:ubuntu /opt/nextcloud

# Verifica
ls -la /opt/nextcloud
```

### 1.2 Trasferisci docker-compose.yml sull'istanza

**Dal tuo PC locale**:

```bash
# Dalla root del progetto
scp -i ~/.ssh/TUA_CHIAVE docker/docker-compose.yml ubuntu@TUO_IP:/home/ubuntu/
```

Oppure usa il file `.env` con lo script:

```bash
# Crea script di deploy
./scripts/deploy-nextcloud.sh
```

**Sull'istanza OCI**, sposta il file:

```bash
mkdir -p ~/nextcloud
mv ~/docker-compose.yml ~/nextcloud/
cd ~/nextcloud
```

## Step 2: Verifica configurazione firewall OCI

**IMPORTANTE**: Oltre a UFW, devi verificare le **Security Lists** di OCI!

### 2.1 Dalla console OCI web

1. Vai a: **Networking → Virtual Cloud Networks**
2. Seleziona la tua VCN
3. Clicca su **Security Lists**
4. Seleziona **Default Security List**
5. Aggiungi **Ingress Rules**:

| Source CIDR | Protocol | Port Range | Description      |
| ----------- | -------- | ---------- | ---------------- |
| 0.0.0.0/0   | TCP      | 80         | HTTP             |
| 0.0.0.0/0   | TCP      | 443        | HTTPS            |
| 0.0.0.0/0   | TCP      | 8080       | Nextcloud AIO    |
| 0.0.0.0/0   | TCP      | 3478       | Talk (opzionale) |

**NOTA**: Senza queste regole, anche con UFW configurato, il traffico non arriverà all'istanza!

## Step 3: Avvio Nextcloud AIO

### 3.1 Avvia il mastercontainer

**Sull'istanza OCI**:

```bash
cd ~/nextcloud

# Avvia Nextcloud AIO
docker compose up -d

# Verifica che sia in esecuzione
docker compose ps
```

**Output atteso**:

```
NAME                              IMAGE                          STATUS
nextcloud-aio-mastercontainer    nextcloud/all-in-one:latest    Up 10 seconds
```

### 3.2 Verifica logs

```bash
# Segui i logs
docker compose logs -f

# Aspetta circa 30-60 secondi per l'inizializzazione
# Quando vedi "AIO startup successful!" è pronto
```

### 3.3 Ottieni password iniziale AIO

```bash
# Mostra la password generata automaticamente
docker exec nextcloud-aio-mastercontainer grep password /mnt/docker-aio-config/data/configuration.json
```

**SALVA QUESTA PASSWORD!** Ti servirà per il primo accesso.

## Step 4: Configurazione iniziale via Web

### 4.1 Accedi all'interfaccia AIO

Apri il browser e vai a:

```
https://your-domain.example.com:8443
```

**NOTA**: Usa **HTTPS** (porta 8443), non HTTP!

### 4.2 Accetta certificato self-signed

Il browser mostrerà un warning sul certificato - è normale per il primo accesso.

- Chrome/Edge: Clicca "Advanced" → "Proceed to..."
- Firefox: "Advanced" → "Accept the Risk"

### 4.3 Login con password

1. Inserisci la **password ottenuta** al punto 3.3
2. Clicca "Log in"

### 4.4 Configura dominio Nextcloud

Nell'interfaccia AIO:

1. **Domain**: Inserisci `your-domain.example.com`
2. **Let's Encrypt**: Seleziona **"Enable"**
3. Clicca **"Submit domain"**

AIO verificherà:

- ✅ DNS corretto (dominio → IP)
- ✅ Porte 80 e 443 raggiungibili
- ✅ Generazione certificato Let's Encrypt

**Se fallisce**: Controlla Security Lists OCI (Step 2.1)!

### 4.5 Seleziona componenti opzionali

Puoi abilitare (raccomandato per te):

- ✅ **Nextcloud Office** (editing documenti)
- ✅ **Nextcloud Talk** (video calls)
- ⬜ **ClamAV** (antivirus - usa molta RAM, skippa per ora)
- ✅ **Imaginary** (image processing)

### 4.6 Abilita backup automatici

1. Nella sezione "Backup":

   - ✅ Abilita "Automated backups"
   - Retention: **7 giorni** (default)
   - Location: `/mnt/docker-aio-config/data/backups/`

2. Clicca **"Start containers"**

### 4.7 Attendi deployment

AIO scaricherà e configurerà tutti i container (circa 10-15 minuti):

- nextcloud-aio-apache
- nextcloud-aio-database
- nextcloud-aio-redis
- nextcloud-aio-nextcloud
- E altri in base ai componenti selezionati

**Monitora il progresso** nella dashboard AIO.

## Step 5: Prima configurazione Nextcloud

### 5.1 Accesso a Nextcloud

Quando tutti i container sono "Running", accedi a:

```
https://your-domain.example.com
```

Dovrebbe mostrarti la pagina di login Nextcloud con **certificato SSL valido**! 🎉

### 5.2 Crea admin user

1. **Username**: (usa quello configurato in .env, es: `pandagan_queen`)
2. **Password**: (password forte configurata in .env)
3. Clicca "Install"

### 5.3 Configurazione iniziale Nextcloud

Nextcloud ti guiderà attraverso:

1. Installazione app raccomandate (accetta)
2. Tour delle funzionalità (puoi skippare)

## Step 6: Verifica funzionamento

### 6.1 Test funzionalità base

- ✅ Dashboard carica correttamente
- ✅ SSL certificato valido (lucchetto verde)
- ✅ File upload funziona
- ✅ Calendar app disponibile
- ✅ Contacts app disponibile
- ✅ Tasks app disponibile

### 6.2 Verifica container

**Sull'istanza OCI**:

```bash
# Lista tutti i container Nextcloud
docker ps -a | grep nextcloud

# Verifica logs
docker compose logs nextcloud-aio-mastercontainer

# Verifica risorse
docker stats
```

### 6.3 Test backup

Nella dashboard AIO (porta 8443):

1. Vai a **"Backup"**
2. Clicca **"Create backup now"**
3. Attendi completamento
4. Verifica che il backup sia listato

## Step 7: Configurazioni post-deployment

### 7.1 Configura email notifications (opzionale)

In Nextcloud:

1. **Settings → Administration → Basic settings**
2. Configura SMTP per notifiche email

### 7.2 Installa app Calendar, Contacts, Tasks

Dovrebbero essere già installate, verifica:

1. **Apps → Office & text**
2. **Apps → Organization**
3. Abilita: Calendar, Contacts, Tasks, Deck

### 7.3 Configura External Storage (opzionale)

Per usare lo storage OCI:

1. **Settings → Administration → External storage**
2. Configura mount point se necessario

## Troubleshooting

### Errore: Domain validation failed

**Causa**: Firewall OCI blocca porte 80/443

**Soluzione**:

1. Verifica Security Lists OCI (porta 80, 443)
2. Verifica UFW sull'istanza: `sudo ufw status`
3. Testa connettività: `curl -I http://your-domain.example.com`

### Errore: Cannot access port 8443

**Causa**: Firewall blocca porta 8080/8443

**Soluzione**:

```bash
# Verifica UFW
sudo ufw status | grep 8080

# Se necessario
sudo ufw allow 8080/tcp
sudo ufw allow 8443/tcp
sudo ufw reload
```

### Container crashano continuamente

**Causa**: Poca RAM disponibile

**Soluzione**:

```bash
# Verifica memoria
free -h

# Controlla logs
docker logs nextcloud-aio-nextcloud

# Disabilita componenti opzionali pesanti (ClamAV)
```

### Let's Encrypt SSL fallisce

**Causa**: Rate limiting o DNS non propagato

**Soluzione**:

1. Verifica DNS: `nslookup your-domain.example.com`
2. Attendi 5 minuti e riprova
3. Verifica email in LETSENCRYPT_EMAIL è valida

## Comandi utili

```bash
# Avvia/ferma stack
docker compose up -d
docker compose down

# Restart
docker compose restart

# Logs real-time
docker compose logs -f

# Backup manuale
# Usa interfaccia AIO porta 8443

# Update Nextcloud
# Usa interfaccia AIO porta 8443

# Verifica salute container
docker ps
docker stats
```

## Security Best Practices

1. **Password admin forte**: Min 16 caratteri
2. **2FA abilitato**: Settings → Security
3. **Backup regolari**: Testa restore ogni mese
4. **Updates**: Controlla update settimanali
5. **Logs monitoring**: Controlla logs per attività sospette

## Performance Tuning (opzionale)

### Redis cache

È già incluso in AIO, verifica funzioni:

```bash
docker exec -it nextcloud-aio-redis redis-cli
> PING
PONG
```

### PHP memory limit

Se necessario, modifica in AIO interface → Settings

## Next Steps

Una volta Nextcloud funzionante:
→ Procedi a `docs/06-DATA-MIGRATION.md` per importare i dati
