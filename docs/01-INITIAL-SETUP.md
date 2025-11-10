# Initial Setup Guide - OCI Instance

Questa guida ti accompagna nel setup iniziale dell'istanza Oracle Cloud.

## Prerequisites

- ✅ Istanza OCI A1.Flex creata
- ✅ Coppia di chiavi SSH generata e scaricata
- ✅ IP pubblico dell'istanza disponibile

## Step 1: Configurazione locale

### 1.1 Crea il file di configurazione

```bash
# Dalla root del progetto
cp .env.example .env
```

### 1.2 Modifica .env con i tuoi valori

Apri `.env` e compila:

```bash
# IMPORTANTE: Usa il tuo editor preferito
nano .env  # oppure vim, code, etc.
```

Campi da configurare:

- `OCI_INSTANCE_IP`: L'IP pubblico dalla console OCI
- `OCI_SSH_KEY_PATH`: Path alla tua chiave privata (es: `~/.ssh/id_rsa_oci`)
- Gli altri campi possono rimanere di default per ora

### 1.3 Verifica permessi chiave SSH

La chiave SSH deve avere permessi corretti:

```bash
chmod 600 ~/.ssh/NOME_TUA_CHIAVE
```

## Step 2: Prima connessione

### 2.1 Test connessione

Usa lo script fornito:

```bash
# Rendi eseguibile lo script
chmod +x scripts/ssh-connect.sh

# Connetti
./scripts/ssh-connect.sh
```

Se tutto è corretto, dovresti vedere:

```
Connecting to OCI instance...
IP: xxx.xxx.xxx.xxx
User: ubuntu

Welcome to Ubuntu...
```

### 2.2 [Opzionale] Configura SSH config

Per semplificare le connessioni future, puoi aggiungere una entry in `~/.ssh/config`:

```bash
# Manualmente aggiungi questo al file ~/.ssh/config
Host nextcloud-oci
    HostName YOUR_INSTANCE_IP
    User ubuntu
    IdentityFile ~/.ssh/YOUR_KEY_NAME
    StrictHostKeyChecking accept-new
```

Poi potrai connetterti semplicemente con:

```bash
ssh nextcloud-oci
```

## Step 3: Verifica sistema

Una volta connesso, verifica il sistema:

```bash
# Info sistema
uname -a
cat /etc/os-release

# Risorse disponibili
free -h
df -h
nproc

# Rete
ip addr show
```

Dovresti vedere:

- **OS**: Ubuntu 22.04 o 24.04 LTS (ARM64)
- **RAM**: ~24GB
- **CPU**: 4 cores (ARM Ampere)
- **Disco**: ~100GB

## Troubleshooting

### Errore: Permission denied (publickey)

**Causa**: Chiave SSH non corretta o permessi sbagliati

**Soluzione**:

```bash
# Verifica permessi
ls -la ~/.ssh/YOUR_KEY_NAME
# Deve mostrare: -rw------- (600)

# Correggi se necessario
chmod 600 ~/.ssh/YOUR_KEY_NAME
```

### Errore: Connection timeout

**Causa**: Firewall OCI o Security List bloccano SSH

**Soluzione**: Dalla console OCI:

1. Vai a Networking → Virtual Cloud Networks
2. Seleziona la VCN dell'istanza
3. Security Lists → Default Security List
4. Verifica regola Ingress per porta 22 (SSH)
5. Deve esistere: `0.0.0.0/0 → TCP:22`

### Errore: Host key verification failed

**Causa**: Chiave host cambiata (istanza ricreata)

**Soluzione**:

```bash
ssh-keygen -R YOUR_INSTANCE_IP
```

## Next Steps

Una volta connesso con successo:
→ Procedi a `docs/02-SYSTEM-SETUP.md` per il setup del sistema
