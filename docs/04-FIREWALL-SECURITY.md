# Firewall e Security Setup

Configurazione firewall UFW e protezione SSH con Fail2ban.

## Prerequisites

- ✅ Ubuntu 24.04 LTS
- ✅ UFW e Fail2ban installati
- ✅ Connessione SSH funzionante

## IMPORTANTE - Ordine delle operazioni

**ATTENZIONE**: Configurare il firewall in modo errato può bloccare la connessione SSH!

**Regola d'oro**:
1. **PRIMA** permetti SSH (porta 22)
2. **POI** abilita il firewall
3. **SOLO DOPO** aggiungi altre regole

## Step 1: Configurazione UFW (Uncomplicated Firewall)

### 1.1 Verifica status UFW

```bash
# Controlla se UFW è attivo
sudo ufw status verbose
```

Dovrebbe mostrare: `Status: inactive`

### 1.2 Configura regole di default

```bash
# NEGA tutto il traffico in entrata (default)
sudo ufw default deny incoming

# PERMETTI tutto il traffico in uscita
sudo ufw default allow outgoing
```

### 1.3 Permetti SSH (CRITICO!)

```bash
# PRIMA DI ABILITARE UFW, permetti SSH!
sudo ufw allow 22/tcp comment 'SSH'

# Verifica che la regola sia stata aggiunta
sudo ufw show added
```

**Dovrebbe mostrare**:
```
ufw allow 22/tcp comment 'SSH'
```

### 1.4 Permetti porte per Nextcloud

```bash
# HTTP (sarà rediretto a HTTPS)
sudo ufw allow 80/tcp comment 'HTTP'

# HTTPS (Nextcloud web interface)
sudo ufw allow 443/tcp comment 'HTTPS'

# Nextcloud AIO Apache port (se necessario)
sudo ufw allow 8080/tcp comment 'Nextcloud AIO'

# Nextcloud AIO Talk (WebRTC - opzionale)
sudo ufw allow 3478/tcp comment 'Nextcloud Talk TURN'
sudo ufw allow 3478/udp comment 'Nextcloud Talk TURN'
```

### 1.5 Verifica regole prima di abilitare

```bash
# Controlla tutte le regole che verranno applicate
sudo ufw show added
```

**Dovrebbe mostrare almeno**:
```
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
```

### 1.6 Abilita UFW

```bash
# Abilita il firewall
sudo ufw enable
```

Ti chiederà conferma:
```
Command may disrupt existing ssh connections. Proceed with operation (y|n)?
```

Rispondi: **y**

### 1.7 Verifica configurazione finale

```bash
# Verifica status dettagliato
sudo ufw status verbose

# Verifica regole numerate
sudo ufw status numbered
```

**Output atteso**:
```
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere                   # SSH
80/tcp                     ALLOW       Anywhere                   # HTTP
443/tcp                    ALLOW       Anywhere                   # HTTPS
...
```

### 1.8 Test connessione SSH

**NON CHIUDERE** la sessione corrente! Apri una **NUOVA** connessione SSH in un altro terminale:

```bash
# Dal tuo PC, in un NUOVO terminale
./scripts/ssh-connect.sh
```

Se funziona, UFW è configurato correttamente! ✅

## Step 2: Configurazione Fail2ban

### 2.1 Verifica installazione e status

```bash
# Verifica che fail2ban sia installato
which fail2ban-client

# Controlla status servizio
sudo systemctl status fail2ban
```

### 2.2 Configurazione SSH jail

Fail2ban usa "jails" per proteggere servizi. Configuriamo la jail SSH.

```bash
# Crea file di configurazione locale
sudo nano /etc/fail2ban/jail.local
```

Inserisci questa configurazione:

```ini
[DEFAULT]
# Ban per 1 ora (3600 secondi)
bantime = 3600

# Finestra temporale di 10 minuti
findtime = 600

# Massimo 5 tentativi in 10 minuti
maxretry = 5

# Ban action: usa UFW
banaction = ufw

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
```

Salva e chiudi (`Ctrl+O`, `Enter`, `Ctrl+X`)

### 2.3 Riavvia Fail2ban

```bash
# Riavvia servizio
sudo systemctl restart fail2ban

# Verifica che sia attivo
sudo systemctl status fail2ban

# Abilita all'avvio
sudo systemctl enable fail2ban
```

### 2.4 Verifica jails attive

```bash
# Lista jails attive
sudo fail2ban-client status

# Dettagli jail SSH
sudo fail2ban-client status sshd
```

**Output atteso**:
```
Status for the jail: sshd
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /var/log/auth.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
```

## Step 3: Test e verifica sicurezza

### 3.1 Test UFW

```bash
# Verifica regole attive
sudo ufw status numbered

# Log del firewall (ultimi 20)
sudo tail -20 /var/log/ufw.log
```

### 3.2 Test Fail2ban

```bash
# Status generale
sudo fail2ban-client status

# Log fail2ban (ultimi 30)
sudo tail -30 /var/log/fail2ban.log
```

### 3.3 [Opzionale] Simula attacco SSH

**ATTENZIONE**: Fai questo solo se hai un'altra sessione SSH aperta!

```bash
# Da un altro PC/macchina, prova login errati multipli
# Dopo 5 tentativi, l'IP sarà bannato per 1 ora
```

Verifica il ban:
```bash
sudo fail2ban-client status sshd
```

Rimuovi un ban manualmente (se serve):
```bash
sudo fail2ban-client set sshd unbanip IP_ADDRESS
```

## Step 4: Comandi utili

### UFW

```bash
# Abilita/disabilita
sudo ufw enable
sudo ufw disable

# Aggiungi regola
sudo ufw allow PORT/PROTOCOL

# Rimuovi regola per numero
sudo ufw status numbered
sudo ufw delete NUMBER

# Reset completo (ATTENZIONE!)
sudo ufw reset

# Reload configurazione
sudo ufw reload
```

### Fail2ban

```bash
# Status generale
sudo fail2ban-client status

# Status jail specifica
sudo fail2ban-client status JAIL_NAME

# Unban IP
sudo fail2ban-client set JAIL_NAME unbanip IP

# Reload configurazione
sudo fail2ban-client reload

# Restart
sudo systemctl restart fail2ban
```

## Step 5: Verifica finale sicurezza

```bash
echo "=== Security Configuration Summary ==="
echo ""
echo "UFW Status:"
sudo ufw status
echo ""
echo "Fail2ban Status:"
sudo systemctl is-active fail2ban
echo ""
echo "SSH Jail Status:"
sudo fail2ban-client status sshd
echo ""
echo "Open Ports:"
sudo ss -tulpn | grep LISTEN
echo ""
```

**Checklist sicurezza**:
- ✅ UFW attivo e configurato
- ✅ SSH (22) permesso
- ✅ HTTP (80) e HTTPS (443) permessi
- ✅ Fail2ban attivo
- ✅ SSH jail configurata
- ✅ Connessione SSH funzionante

## Troubleshooting

### Errore: Cannot connect via SSH dopo aver abilitato UFW

**Causa**: Porta 22 non permessa

**Soluzione** (dalla console OCI):
```bash
sudo ufw allow 22/tcp
sudo ufw reload
```

### Fail2ban non banna nessuno

**Causa**: Log path errato o filtro non funzionante

**Soluzione**:
```bash
# Verifica log path
ls -la /var/log/auth.log

# Test filtro
sudo fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf
```

### Voglio whitelistare il mio IP

Aggiungi a `/etc/fail2ban/jail.local` sotto `[DEFAULT]`:
```ini
ignoreip = 127.0.0.1/8 ::1 YOUR_IP_ADDRESS
```

Poi:
```bash
sudo systemctl restart fail2ban
```

## Security Best Practices

1. **Monitoraggio regolare**:
   ```bash
   sudo fail2ban-client status sshd
   sudo tail -f /var/log/fail2ban.log
   ```

2. **Backup configurazione**:
   ```bash
   sudo cp /etc/fail2ban/jail.local /etc/fail2ban/jail.local.backup
   sudo cp /etc/ufw/user.rules /etc/ufw/user.rules.backup
   ```

3. **Update regolari**:
   ```bash
   sudo apt update && sudo apt upgrade fail2ban ufw
   ```

## Next Steps

Ora che la sicurezza è configurata:
→ Procedi a `docs/05-NEXTCLOUD-DEPLOYMENT.md` per il deployment di Nextcloud AIO
