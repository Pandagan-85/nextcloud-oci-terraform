# Nextcloud AIO - Aggiornamenti e Troubleshooting

Come funzionano gli aggiornamenti in Nextcloud AIO, perché possono rompersi da soli
e come diagnosticare il guasto più probabile: il **disallineamento di versione** fra
mastercontainer e container figli.

---

## Il modello di aggiornamento AIO

In AIO ci sono due livelli che si aggiornano in modo **indipendente**:

| Livello | Container | Chi lo aggiorna |
| --- | --- | --- |
| Regista | `nextcloud-aio-mastercontainer` | `nextcloud-aio-watchtower`, in automatico |
| Figli | `apache`, `nextcloud`, `database`, `redis`, `notify-push`, `collabora`, `imaginary` | **Solo a mano**, dalla UI AIO |

Questo è il punto critico: **watchtower aggiorna solo il mastercontainer.** I container
figli restano fermi finché qualcuno non apre la UI e preme *Start and update containers*.

Se nessuno apre la UI per settimane, il mastercontainer avanza da solo. Prima o poi
arriva una release che cambia il modo in cui i figli vengono creati, e le immagini
vecchie non sono più compatibili con il regista nuovo. Lo stack si rompe **senza che
nessuno abbia toccato niente**, tipicamente di notte, durante la finestra di backup
(il backup ferma e riavvia tutti i container: è lì che il disallineamento esplode).

---

## Sintomi

- Il browser mostra "servizio non disponibile" sul dominio Nextcloud
- I client CalDAV/CardDAV iniziano a segnalare errori di sincronizzazione
- La macchina sembra **sana**: disco, RAM e load bassi (è il segnale controintuitivo,
  perché con i servizi fermi le risorse non vengono consumate)
- `docker ps` mostra un container AIO in `Restarting`, gli altri `healthy`
- I container AIO hanno un uptime breve e uguale fra loro, mentre gli altri
  (Caddy, Jellyfin, Komga, monitoring) sono su da settimane

Quest'ultimo contrasto è la firma del problema: qualcosa ha riavviato **solo** lo
stack AIO.

---

## Diagnosi

### 1. Stato dei container

```bash
docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'
```

Cerca chi è in `Restarting` e confronta gli uptime.

### 2. Perché non parte

```bash
docker logs --tail 60 --timestamps nextcloud-aio-apache
```

Un errore che si ripete a intervalli regolari (ogni ~60s) è un restart loop, non un
crash occasionale.

### 3. Confronto delle versioni - il test decisivo

```bash
# Immagine del container che non parte
docker image inspect ghcr.io/nextcloud-releases/aio-apache:latest --format '{{.Created}}'

# Immagine del mastercontainer
docker image inspect nextcloud/all-in-one:latest --format '{{.Created}}'
```

Le due date devono appartenere alla **stessa release**: in una installazione sana
distano pochi secondi, perché le immagini vengono buildate insieme. Se distano
settimane, hai trovato la causa.

### 4. Conferme utili

```bash
# Il container è stato ricreato o solo riavviato? Quanti restart?
docker inspect nextcloud-aio-apache \
  --format 'Created: {{.Created}}{{"\n"}}Started: {{.State.StartedAt}}{{"\n"}}Restarts: {{.RestartCount}}'

# Come viene creato: rootfs read-only e tmpfs sulle dir di runtime
docker inspect nextcloud-aio-apache \
  --format 'ReadOnlyRootFS: {{.HostConfig.ReadonlyRootfs}}{{"\n"}}Tmpfs: {{json .HostConfig.Tmpfs}}'
```

Attenzione a un'apparente contraddizione: una directory può **esistere nell'immagine**
ma non nel container in esecuzione, se il mastercontainer ci monta sopra un tmpfs
vuoto. Verificare l'immagine con `docker run --rm --entrypoint ls <img> -ld /percorso`
non basta da solo.

---

## Il fix

Il fix è **riallineare tutte le immagini figlie** al mastercontainer, non rattoppare
il singolo container rotto.

### Accedere alla UI AIO

La porta 8080 non è esposta pubblicamente: serve un tunnel SSH.

```bash
# Da lasciare aperto in un secondo terminale
ssh -L 8080:localhost:8080 YOUR_SSH_ALIAS
```

Poi nel browser: **`https://localhost:8080`** (non `http`; il certificato è
self-signed, l'avviso va accettato).

Se la porta 8080 locale è occupata, usa `-L 8081:localhost:8080` e vai su
`https://localhost:8081`.

### Recuperare la passphrase AIO

È diversa dalla passphrase della chiave SSH. Se non è a portata di mano:

```bash
sudo python3 -c "import json;print(json.load(open('/var/lib/docker/volumes/nextcloud_aio_mastercontainer/_data/data/configuration.json'))['password'])"
```

### La procedura

1. **Stop containers** - attendi che si fermino **tutti**; un container in restart
   loop richiede il timeout, quindi ci mette più del solito
2. **Start and update containers** - questo pulsante, non un semplice *Start*: uno
   Start ricrea i container dalle **stesse immagini vecchie** e il loop riparte
3. Lascia lavorare: scarica le immagini nuove ed esegue le migrazioni del database

Non chiudere il terminale del tunnel durante l'operazione: il lavoro proseguirebbe
lato server, ma perderesti la visibilità sul progresso.

### Sul backup preventivo

La UI suggerisce di fare un backup prima di aggiornare. Se il servizio è già
irraggiungibile da ore, **i dati non sono cambiati dall'ultimo backup riuscito**:
quel backup è a tutti gli effetti lo stato attuale e rifarlo aggiunge solo attesa a
un disservizio in corso. Controlla data ed esito nella sezione *Backup and restore*
della UI prima di decidere.

---

## Verifica post-fix

Da **fuori**, che è ciò che conta davvero:

```bash
# Deve rispondere 302 (redirect al login)
curl -sS -o /dev/null -w 'HTTP %{http_code} in %{time_total}s\n' https://your-domain.example.com/

# Deve rispondere 401: l'endpoint c'è e chiede autenticazione
curl -sS -o /dev/null -w 'HTTP %{http_code}\n' https://your-domain.example.com/remote.php/dav/

# maintenance:false e needsDbUpgrade:false = migrazioni completate
curl -sS https://your-domain.example.com/status.php
```

La **prima** richiesta dopo un riavvio può richiedere 10-15 secondi (opcache PHP
freddo). Ripeti il test: a regime deve stare sotto i 200 ms. Se resta lenta, è un
problema vero.

Dalla macchina, controlla che il contatore dei restart sia tornato a zero e resti lì:

```bash
docker inspect nextcloud-aio-apache \
  --format 'Status: {{.State.Status}} | Restarts: {{.RestartCount}}'
```

I client CalDAV/CardDAV si riallineano da soli: non serve toccarli.

---

## Caso reale: incidente del 17 settembre 2026

Cronologia ricostruita, utile come riferimento:

| Ora (UTC) | Evento |
| --- | --- |
| 04:01:59 | Backup Borg completato con successo |
| ~04:02 | Watchtower aggiorna il mastercontainer ad **AIO v14.1.1** |
| 04:03:11 | Il nuovo mastercontainer **ricrea** i container figli |
| 04:03+ | `nextcloud-aio-apache` entra in restart loop |
| ~10:00 | Il guasto viene scoperto dagli avvisi CalDAV, dopo ~6 ore |

**Causa:** il mastercontainer v14.1.1 crea i figli con rootfs read-only e un tmpfs
vuoto su `/run`. L'immagine `aio-apache` ferma al 18 agosto si aspettava invece di
trovare `/run/supervisord` già presente nell'immagine (`/var/run` è un symlink a
`/run`). Il tmpfs copriva quella directory, supervisord non trovava dove scrivere il
pidfile e moriva all'avvio:

```text
Error: The directory named as part of the path /var/run/supervisord/supervisord.pid does not exist
```

375 restart in sei ore. Senza apache, Caddy non aveva più un backend su
`nextcloud-aio-apache:11000` e restituiva errore a browser e client DAV.

**Risoluzione:** *Stop containers* + *Start and update containers* dalla UI. Tutte le
immagini figlie riallineate alla release del mastercontainer, Nextcloud aggiornato
alla 34.0.4, nessuna perdita di dati.

---

## Prevenzione

- **Controlla la UI AIO periodicamente** (una volta al mese è sufficiente): se
  compare *Update available* sui container figli, applicalo con calma invece di
  scoprirlo durante un guasto
- **Non lasciare passare mesi fra un update e l'altro**: più il divario cresce, più
  è probabile che il mastercontainer faccia un salto incompatibile
- **Alert sul restart loop**: Prometheus e cAdvisor sono già attivi in questo stack
  (vedi [`09-CICD-MONITORING.md`](09-CICD-MONITORING.md)). Una regola sul contatore
  dei restart accorcia il rilevamento da ore a minuti - qui il disservizio è durato
  una notte intera ed è stato scoperto dai client, non dal monitoraggio
- **Guarda le date, non gli stati**: in questo tipo di guasto `docker ps` mostra
  quasi tutto `healthy`. Sono le date di build delle immagini a dire la verità
