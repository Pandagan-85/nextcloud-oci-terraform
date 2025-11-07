# Docker Installation - Ubuntu 24.04 ARM64

Installazione Docker Engine e Docker Compose su Oracle Cloud A1.Flex (ARM architecture).

## Prerequisites

- ✅ Ubuntu 24.04 LTS aggiornato
- ✅ Pacchetti base installati (curl, ca-certificates, gnupg)
- ✅ Connessione internet funzionante

## Step 1: Rimozione versioni precedenti (se presenti)

```bash
# Rimuovi eventuali installazioni Docker precedenti
sudo apt remove -y docker docker-engine docker.io containerd runc

# Questo è safe anche se non c'è nulla installato
```

## Step 2: Setup Docker Repository

### 2.1 Aggiungi GPG key ufficiale Docker

```bash
# Crea directory per keyrings
sudo install -m 0755 -d /etc/apt/keyrings

# Scarica e aggiungi GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Imposta permessi corretti
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

### 2.2 Aggiungi repository Docker

```bash
# Aggiungi repository alle sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 2.3 Update package index

```bash
sudo apt update
```

## Step 3: Installazione Docker Engine

### 3.1 Installa Docker e componenti

```bash
sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
```

**Componenti installati**:
- `docker-ce`: Docker Engine
- `docker-ce-cli`: Docker CLI
- `containerd.io`: Container runtime
- `docker-buildx-plugin`: Build multi-platform images
- `docker-compose-plugin`: Docker Compose V2

### 3.2 Verifica installazione

```bash
# Verifica versione Docker
docker --version

# Verifica versione Docker Compose
docker compose version

# Verifica status servizio
sudo systemctl status docker
```

### 3.3 Abilita Docker all'avvio

```bash
# Abilita servizio Docker
sudo systemctl enable docker

# Verifica che sia enabled
sudo systemctl is-enabled docker
```

## Step 4: Configurazione permessi utente

### 4.1 Aggiungi utente corrente al gruppo docker

```bash
# Aggiungi user al gruppo docker (evita sudo per ogni comando)
sudo usermod -aG docker $USER

# Verifica gruppi
groups $USER
```

**IMPORTANTE**: Per applicare le modifiche ai gruppi, devi:
1. Disconnetterti e riconnetterti via SSH, OPPURE
2. Usare: `newgrp docker`

### 4.2 Applica modifiche

**Opzione A - Riconnetti SSH** (consigliato):
```bash
exit
# Poi dal tuo PC: ./scripts/ssh-connect.sh
```

**Opzione B - Usa newgrp**:
```bash
newgrp docker
```

### 4.3 Test permessi

```bash
# Questo comando NON deve richiedere sudo
docker ps

# Se funziona, i permessi sono corretti!
```

## Step 5: Test installazione completa

### 5.1 Test con container hello-world

```bash
# Scarica ed esegui container di test
docker run hello-world
```

**Output atteso**:
```
Hello from Docker!
This message shows that your installation appears to be working correctly.
...
```

### 5.2 Test Docker Compose

```bash
# Verifica che docker compose sia funzionante
docker compose version
```

### 5.3 Informazioni sistema Docker

```bash
# Info dettagliate Docker
docker info

# Verifica architettura (deve essere arm64/aarch64)
docker info | grep -i architecture
```

## Step 6: Configurazione Docker (ottimizzazioni)

### 6.1 Configura logging (evita log troppo grandi)

```bash
# Crea file configurazione daemon
sudo mkdir -p /etc/docker

sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
```

### 6.2 Riavvia Docker per applicare

```bash
# Riavvia servizio
sudo systemctl restart docker

# Verifica che sia running
sudo systemctl status docker

# Verifica configurazione applicata
docker info | grep -A 5 "Log"
```

## Step 7: Verifica finale

```bash
echo "=== Docker Installation Summary ==="
echo ""
echo "Docker Version:"
docker --version
echo ""
echo "Docker Compose Version:"
docker compose version
echo ""
echo "Docker Service Status:"
sudo systemctl is-active docker
echo ""
echo "Architecture:"
docker info | grep "Architecture"
echo ""
echo "Storage Driver:"
docker info | grep "Storage Driver"
echo ""
echo "User Groups:"
groups
echo ""
echo "Running Containers:"
docker ps
echo ""
```

**Checklist finale**:
- ✅ Docker version >= 24.x
- ✅ Docker Compose version >= 2.x
- ✅ Architecture: arm64/aarch64
- ✅ User nel gruppo docker
- ✅ docker ps funziona senza sudo
- ✅ hello-world container funziona

## Comandi Docker utili

```bash
# Lista container attivi
docker ps

# Lista tutti i container (anche stopped)
docker ps -a

# Lista immagini
docker images

# Rimuovi container stopped
docker container prune

# Rimuovi immagini unused
docker image prune

# Pulizia completa (ATTENZIONE: rimuove tutto!)
docker system prune -a

# Logs di un container
docker logs CONTAINER_NAME

# Stats real-time
docker stats
```

## Troubleshooting

### Errore: permission denied while trying to connect to Docker daemon

**Causa**: User non nel gruppo docker

**Soluzione**:
```bash
sudo usermod -aG docker $USER
# Poi disconnetti/riconnetti SSH
```

### Errore: Cannot connect to the Docker daemon

**Causa**: Servizio Docker non running

**Soluzione**:
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

### Errore: Package 'docker-ce' has no installation candidate

**Causa**: Repository non configurato correttamente

**Soluzione**:
```bash
# Ripeti step 2 configurazione repository
sudo apt update
sudo apt-cache policy docker-ce
```

## Next Steps

Ora che Docker è installato e funzionante:
→ Procedi a `docs/04-FIREWALL-SECURITY.md` per configurare UFW e Fail2ban