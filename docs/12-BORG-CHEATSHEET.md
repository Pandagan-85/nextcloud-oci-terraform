# Borg Backup - Cheatsheet Comandi VM

Riferimento rapido per gestire i backup BorgBackup sulla VM OCI.

**Repository path:** `/mnt/nextcloud-data/borg-backups/borg`

---

## Setup Sessione

Per evitare di inserire la password ad ogni comando:

```bash
export BORG_PASSPHRASE="LA_TUA_PASSWORD"
```

La password è salvata in `/home/ubuntu/nextcloud/.env`.

---

## Listare i Backup

```bash
# Lista tutti i backup disponibili (nome + data)
sudo -E borg list /mnt/nextcloud-data/borg-backups/borg
```

---

## Dimensioni e Info

```bash
# Info generali del repository (spazio totale, dedup, compressione)
sudo -E borg info /mnt/nextcloud-data/borg-backups/borg

# Info di un singolo backup specifico
sudo -E borg info /mnt/nextcloud-data/borg-backups/borg::NOME_BACKUP
```

---

## Verificare Integrità

```bash
# Check integrità repository
sudo -E borg check /mnt/nextcloud-data/borg-backups/borg
```

---

## Esplorare Contenuto di un Backup

```bash
# Lista file contenuti in un backup
sudo -E borg list /mnt/nextcloud-data/borg-backups/borg::NOME_BACKUP

# Cercare un file specifico
sudo -E borg list /mnt/nextcloud-data/borg-backups/borg::NOME_BACKUP | grep "nomefile"
```

---

## Cancellare Backup

```bash
# Cancella un singolo backup
sudo -E borg delete /mnt/nextcloud-data/borg-backups/borg::NOME_BACKUP

# Pruning automatico (applica retention policy)
sudo -E borg prune /mnt/nextcloud-data/borg-backups/borg \
  --keep-daily=7 --keep-weekly=4 --keep-monthly=6

# Compatta il repository dopo cancellazione (recupera spazio disco)
sudo -E borg compact /mnt/nextcloud-data/borg-backups/borg
```

---

## Verificare Spazio Disco

```bash
# Spazio sul volume persistente
df -h /mnt/nextcloud-data/

# Dimensione directory backup
sudo du -sh /mnt/nextcloud-data/borg-backups/
```

---

## Log e Monitoraggio

```bash
# Log del pruning automatico
sudo tail -50 /var/log/borg-prune.log

# Verifica cronjob pruning attivo
sudo crontab -l | grep borg

# Log ultimo backup AIO
sudo docker logs --tail 50 nextcloud-aio-borgbackup
```

---

_Last updated: April 2025_
