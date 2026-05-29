# Caravanserver Operations

Deze set bestanden is bedoeld voor een headless Debian server op de Intel NUC.
De compose-stack verwacht de volgende doelpaden op de NUC:

- `/opt/docker/homeassistant`
- `/opt/docker/plex`
- `/opt/docker/mosquitto`
- `/opt/docker/esphome`
- `/opt/docker/portainer`
- `/opt/docker/tailscale`
- `/srv/media`
- `/srv/downloads`

## Netwerk en poorten

Deze stack gebruikt bewust alleen de poorten die nodig zijn voor lokaal beheer en integratie.

| Service | Toegang | Poort |
| --- | --- | --- |
| Home Assistant | HTTP | `8123` |
| Plex | HTTP/Web | `32400` |
| Mosquitto | MQTT | `1883` |
| ESPHome | Web UI | `6052` |
| Portainer | HTTPS | `9443` |
| Tailscale | geen losse webpoort | n.v.t. |

Opmerkingen:

- Home Assistant draait in `host`-network mode, daarom staat de poort niet als expliciete `ports:` mapping in compose.
- Plex draait eveneens in `host`-network mode zodat discovery en DLNA-achtig gedrag later niet onnodig complex worden.
- ESPHome draait in `host`-network mode zodat de webinterface en device discovery stabiel zijn.
- Tailscale heeft geen klassieke open poort nodig; remote beheer gaat via de tailnet-verbinding.

## Eerste keer op de NUC

1. Kopieer `docker-compose.yml` en `.env.example` naar de NUC.
2. Hernoem `.env.example` naar `.env`.
3. Pas `.env` aan indien nodig.
4. Maak de mapstructuur aan:

```bash
sudo mkdir -p /opt/docker/{homeassistant,plex,mosquitto/{data,log},esphome,portainer,tailscale} /srv/{media,downloads}
sudo cp mosquitto/mosquitto.conf /opt/docker/mosquitto/mosquitto.conf
```

5. Stel eigenaar en rechten in op de Docker-data indien je niet als root werkt.

## Deployment opties

Er zijn twee praktische manieren om deze repository naar de NUC te krijgen:

1. Handmatig met `rsync` of `scp`.
2. Via GitHub Actions, mits de NUC via SSH bereikbaar is.

### Optie 1: lokaal deploy-script

Gebruik `scripts/deploy-to-nuc.sh` vanaf je laptop:

```bash
bash scripts/deploy-to-nuc.sh <nuc-host-or-ip> <ssh-user> ~/.ssh/id_ed25519
```

Dit synchroniseert de repository naar `/opt/docker/` op de NUC en start daarna de stack.

### Optie 2: GitHub Actions

De workflow `.github/workflows/deploy-to-nuc.yml` kan de repository naar de NUC synchroniseren.

Benodigde GitHub secrets:

- `NUC_HOST`
- `NUC_USER`
- `NUC_SSH_KEY`
- `NUC_KNOWN_HOSTS`

Belangrijke beperking:

- GitHub Actions kan alleen naar een machine deployen die vanaf de GitHub runner via SSH bereikbaar is.
- Als de NUC alleen via Tailscale bereikbaar is, dan werkt GitHub Actions meestal niet direct zonder extra netwerkbrug of self-hosted runner.
- Voor een caravanopstelling is een lokale deploy vanaf je laptop of een self-hosted runner vaak robuuster.

## Testpipeline

De repository bevat een CI-workflow die minstens deze controles uitvoert:

- Docker Compose configuratie valide
- Shellscript syntax geldig
- Vereiste configuratiebestanden aanwezig
- Poorten en paden documentatie aanwezig

De workflow is bedoeld als snelle rooktest, niet als vervanging voor een echte deploy-test op de NUC.

## Starten

```bash
docker compose up -d
```

## Stoppen

```bash
docker compose down
```

## Herstarten

```bash
docker compose restart
```

## Status

```bash
docker compose ps
docker ps
```

## Logs

```bash
docker compose logs -f --tail=200
docker compose logs -f homeassistant
docker compose logs -f plex
docker compose logs -f mosquitto
docker compose logs -f esphome
docker compose logs -f portainer
docker compose logs -f tailscale
```

## Updaten

```bash
docker compose pull
docker compose up -d
docker image prune -f
```

## MQTT hardenen na bootstrap

De broker staat initieel in bootstrap-modus met anonieme toegang aan.
Zodra je een vaste MQTT-gebruiker wilt gebruiken:

1. Zet in `/opt/docker/mosquitto/mosquitto.conf` `allow_anonymous false`.
2. Maak een passwordfile aan.
3. Herstart de broker.

Voorbeeld:

```bash
docker run --rm -it -v /opt/docker/mosquitto:/mosquitto eclipse-mosquitto:2 mosquitto_passwd -c /mosquitto/mosquitto.passwd homeassistant
```

Pas daarna de config aan om die passwordfile te gebruiken.

## Tailscale activeren

De Tailscale-container draait eerst alleen de daemon. Verbind hem daarna met je tailnet:

```bash
docker compose exec tailscale tailscale up --hostname=caravan-nuc
```

Gebruik eventueel een auth key als je dat later toevoegt.

## Functionele tests

- Home Assistant: `http://<nuc-ip>:8123`
- Plex: `http://<nuc-ip>:32400/web`
- ESPHome: `http://<nuc-ip>:6052`
- Portainer: `https://<nuc-ip>:9443`
- MQTT: poort `1883`
- Tailscale: zichtbaar in de Tailnet en bereikbaar vanaf laptop of telefoon

## Backup

Minimaal back-uppen:

- `/opt/docker`
- `/srv/media`
- `/srv/downloads` als je downloads wilt behouden

Eenvoudige tar-backup:

```bash
sudo tar -czf /path/to/backup/caravanserver-$(date +%F).tar.gz /opt/docker /srv/media /srv/downloads
```

Eenvoudige rsync-backup:

```bash
sudo rsync -aHAX --delete /opt/docker/ /path/to/backup/opt-docker/
sudo rsync -aHAX --delete /srv/media/ /path/to/backup/media/
```

## Restore

1. Installeer Debian, Docker en Compose opnieuw.
2. Zet de mapstructuur terug.
3. Plaats de backup terug op dezelfde paden.
4. Herstel `docker-compose.yml` en `.env`.
5. Start de stack opnieuw met `docker compose up -d`.

## Security

- Geen internet-portforwards nodig voor deze stack.
- Gebruik Tailscale voor remote beheer.
- Gebruik sterke wachtwoorden.
- Zet SSH-keylogin aan zodra de login met sleutels werkt.
- Voeg UFW pas toe nadat SSH en Tailscale correct werken.

## Laatste opmerking

Deze configuratie is bewust simpel gehouden. De services kunnen later worden uitgebreid met SABnzbd, Sonarr, Radarr en Prowlarr zonder de basisstructuur te veranderen.
