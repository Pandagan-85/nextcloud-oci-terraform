# VPN & Privacy Setup - Mullvad + Tailscale

Guida per configurare Mullvad VPN e Tailscale in coesistenza su Fedora Linux, e gestire la privacy DNS su Android/GrapheneOS.

## Panoramica

| Piattaforma | Setup | Costo |
|---|---|---|
| **Fedora Linux** | Mullvad + Tailscale insieme (nftables) | Mullvad 5 EUR/mese |
| **Android / GrapheneOS** | Switch manuale tra le due app | - |

- **Mullvad**: privacy navigazione (nasconde IP e DNS dall'ISP)
- **Tailscale**: accesso ai servizi privati (Jellyfin, Komga, Grafana) via MagicDNS

---

## Fedora Linux

### 1. Installa Mullvad

```bash
sudo dnf config-manager addrepo --from-repofile=https://repository.mullvad.net/rpm/stable/mullvad.repo
sudo dnf install mullvad-vpn

# Per l'icona nel system tray (GNOME)
sudo dnf install libappindicator-gtk3
```

### 2. Login e connessione

```bash
mullvad account login TUO_ACCOUNT_NUMBER
mullvad connect
mullvad status
```

### 3. Regole nftables per coesistenza con Tailscale

Mullvad blocca tutto il traffico che non passa dal suo tunnel. Queste regole escludono il traffico Tailscale (subnet `100.64.0.0/10`) dal tunnel Mullvad, permettendo a entrambi di funzionare.

Crea il file `/etc/nftables/mullvad_tailscale.conf`:

```
table inet mullvad_tailscale {
  chain output {
    type route hook output priority -100; policy accept;
    ip daddr 100.64.0.0/10 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
  }
  chain input {
    type filter hook input priority -100; policy accept;
    ip saddr 100.64.0.0/10 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
  }
}
```

Carica e rendi permanente:

```bash
sudo nft -f /etc/nftables/mullvad_tailscale.conf
echo 'include "/etc/nftables/mullvad_tailscale.conf"' | sudo tee -a /etc/nftables.conf
sudo systemctl enable --now nftables
```

### 4. Permetti traffico LAN

```bash
mullvad lan set allow
```

### 5. Verifica

```bash
# Mullvad funziona?
curl https://am.i.mullvad.net/connected

# Tailscale funziona attraverso Mullvad?
tailscale ping <nome-server>

# Jellyfin raggiungibile?
curl -k https://<tailscale-hostname>:8096
```

---

## Configurazione DNS su Tailscale (Admin Console)

Impostazioni nella pagina **DNS** della Tailscale Admin Console:

- **MagicDNS**: attivo (risolve i nomi `.ts.net`)
- **Global nameservers**: nessuno (ci pensa Mullvad per la navigazione)
- **Override DNS servers**: OFF

### Importante

Non impostare DNS manuali (es. 1.1.1.1) direttamente sui device. Con questa configurazione:

- **Mullvad attivo** -> Mullvad gestisce i DNS (suoi server privati)
- **Tailscale attivo** -> MagicDNS risolve `.ts.net`, il router gestisce il resto
- **Entrambi attivi (Fedora)** -> Mullvad per internet, MagicDNS per `.ts.net`

---

## Android / GrapheneOS

Android permette una sola VPN attiva alla volta. Non si possono usare Mullvad e Tailscale contemporaneamente.

### Setup

1. Installa **Mullvad VPN** dal Play Store / F-Droid / sito Mullvad
2. Installa **Tailscale** dal Play Store / F-Droid
3. **Non attivare** DNS personalizzato su Mullvad (i suoi DNS di default sono gia privati)

### Utilizzo

- **Navigazione con privacy** -> attiva Mullvad
- **Accesso a Jellyfin (video/musica/foto) / Komga / Grafana** -> attiva Tailscale

### Servizi accessibili via Tailscale

| Servizio | URL |
|---|---|
| Jellyfin | `https://<tailscale-hostname>:8096` |
| Komga | `https://<tailscale-hostname>:25600` |
| Grafana | `https://<tailscale-hostname>:3000` |
| AIO Admin | `https://<tailscale-hostname>:8443` |

---

## Ripristino DNS su Fedora (se necessario)

Se hai impostato DNS manuali e vuoi tornare ad automatico:

```bash
# Vedi connessione attiva
nmcli -t -f NAME connection show --active

# Rimuovi DNS manuali
nmcli connection modify "NOME_CONNESSIONE" ipv4.dns "" ipv4.ignore-auto-dns no
nmcli connection up "NOME_CONNESSIONE"

# Verifica
resolvectl status | grep -A2 "DNS Server"
```

---

## Troubleshooting

### Mullvad connesso ma nessuna navigazione

```bash
mullvad lan set allow
mullvad reconnect
```

### Tailscale non raggiungibile con Mullvad attivo

Verifica che le regole nftables siano caricate:

```bash
sudo nft list table inet mullvad_tailscale
```

Se non ci sono, ricaricale:

```bash
sudo nft -f /etc/nftables/mullvad_tailscale.conf
```

### Cambiare server Mullvad

```bash
mullvad relay set location it mil    # Italia, Milano
mullvad relay set location de ber    # Germania, Berlino
mullvad reconnect
```

### Stato completo

```bash
mullvad status
tailscale status
resolvectl status | grep -A2 "DNS Server"
sudo nft list ruleset | grep mullvad_tailscale
```
