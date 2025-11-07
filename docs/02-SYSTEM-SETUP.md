# System Setup - Base Configuration

Configurazione base del sistema Ubuntu per hosting Nextcloud.

## Prerequisites

- ✅ Connessione SSH funzionante
- ✅ Utente con privilegi sudo (default: ubuntu)

## Step 1: Update del sistema

### 1.1 Update package lists e upgrade

```bash
# Update dei repository
sudo apt update

# Upgrade dei pacchetti esistenti
sudo apt upgrade -y

# [Opzionale] Full upgrade (include kernel updates)
sudo apt full-upgrade -y

# Pulizia pacchetti non necessari
sudo apt autoremove -y
sudo apt autoclean
```

**Tempo stimato**: 5-10 minuti (dipende dagli update disponibili)

**Note**:
- Se viene aggiornato il kernel, sarà necessario un reboot
- Il sistema potrebbe chiedere conferme per servizi da riavviare

### 1.2 Verifica reboot necessario

```bash
# Controlla se serve reboot
if [ -f /var/run/reboot-required ]; then
    cat /var/run/reboot-required
    cat /var/run/reboot-required.pkgs
    echo "Reboot required!"
else
    echo "No reboot required"
fi
```

Se necessario:
```bash
sudo reboot
# Attendi ~30 secondi, poi riconnettiti con ./scripts/ssh-connect.sh
```

## Step 2: Installazione pacchetti essenziali

### 2.1 Utility di base

```bash
sudo apt install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    net-tools \
    ufw \
    fail2ban \
    unattended-upgrades \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release
```

**Descrizione pacchetti**:
- `curl`, `wget`: Download file e API calls
- `git`: Version control (per questo progetto)
- `vim`, `htop`: Editor e monitor risorse
- `net-tools`: Networking utilities
- `ufw`: Firewall (uncomplicated firewall)
- `fail2ban`: Protezione brute-force
- `unattended-upgrades`: Security updates automatici
- Altri: Dipendenze per Docker e HTTPS

### 2.2 Configurazione timezone (opzionale)

```bash
# Verifica timezone corrente
timedatectl

# Imposta timezone (esempio: Europa/Roma)
sudo timedatectl set-timezone Europe/Rome

# Verifica
date
```

### 2.3 Configurazione hostname (opzionale)

```bash
# Verifica hostname corrente
hostname

# Cambia hostname (esempio: nextcloud-oci)
sudo hostnamectl set-hostname nextcloud-oci

# Aggiungi a /etc/hosts
sudo bash -c 'echo "127.0.1.1 nextcloud-oci" >> /etc/hosts'

# Verifica
hostname -f
```

## Step 3: Configurazione Security Updates automatici

### 3.1 Abilita unattended-upgrades

```bash
# Configura per auto-install security updates
sudo dpkg-reconfigure -plow unattended-upgrades
# Seleziona: Yes
```

### 3.2 [Opzionale] Personalizza configurazione

```bash
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
```

Verifica che queste linee siano presenti e uncommentate:
```
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::Automatic-Reboot "false";
```

## Step 4: Configurazione base SSH (hardening)

### 4.1 Backup configurazione SSH

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
```

### 4.2 Modifica configurazione SSH

```bash
sudo nano /etc/ssh/sshd_config
```

Verifica/modifica queste impostazioni:
```
# Disabilita root login (sicurezza)
PermitRootLogin no

# Solo autenticazione con chiave
PasswordAuthentication no
PubkeyAuthentication yes

# Altre best practices
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
```

### 4.3 Riavvia servizio SSH

```bash
# Test configurazione
sudo sshd -t

# Se OK, riavvia
sudo systemctl restart sshd

# Verifica status
sudo systemctl status sshd
```

**ATTENZIONE**: Non chiudere la sessione SSH corrente finché non hai testato una nuova connessione!

## Step 5: Verifica finale

```bash
# Info sistema
echo "=== System Info ==="
uname -a
echo ""

echo "=== Ubuntu Version ==="
lsb_release -a
echo ""

echo "=== Resources ==="
free -h
df -h /
echo ""

echo "=== Services ==="
systemctl is-active ssh
systemctl is-active ufw
systemctl is-active fail2ban
echo ""

echo "=== Installed packages ==="
dpkg -l | grep -E "docker|curl|git|ufw|fail2ban" | awk '{print $2, $3}'
```

## Troubleshooting

### Errore: Could not get lock /var/lib/apt/lists/lock

**Causa**: Altro processo sta usando apt

**Soluzione**:
```bash
# Attendi che finisca, oppure
sudo killall apt apt-get
sudo rm /var/lib/apt/lists/lock
sudo rm /var/lib/dpkg/lock*
sudo dpkg --configure -a
sudo apt update
```

### Errore dopo update SSH: Connection refused

**Causa**: Configurazione SSH errata

**Soluzione**:
```bash
# Dalla console OCI (Instance Console Connection)
sudo cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
sudo systemctl restart sshd
```

## Next Steps

Una volta completato il setup base:
→ Procedi a `docs/03-DOCKER-SETUP.md` per installare Docker
