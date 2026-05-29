# CaravanServer2

CaravanServer2 is a simple, stable home server stack for an Intel NUC running Debian stable in a headless setup.

The goal is to keep the system easy to maintain while providing a solid base for:

- Home Assistant
- Plex Media Server
- Mosquitto MQTT
- ESPHome
- Portainer
- Tailscale for remote access

The stack is designed to run behind a GL.iNet Opal router, with a fixed LAN address for the NUC and Docker Compose managing all services.

## Design goals

- Debian stable, no desktop
- No Proxmox
- No OpenWRT on the NUC
- Docker Compose for all services
- Stability over complexity
- Remote access through Tailscale instead of exposed internet ports

## Repository layout

- `docker-compose.yml` - main stack definition
- `.env.example` - example environment values
- `mosquitto/mosquitto.conf` - Mosquitto bootstrap configuration
- `docs/operations.md` - install, deploy, backup, restore, and security notes
- `.github/workflows/validate.yml` - CI validation workflow
- `.github/workflows/deploy-to-nuc.yml` - SSH-based deploy workflow
- `scripts/deploy-to-nuc.sh` - local rsync-based deploy helper

## Network ports

The stack uses only the ports needed for local management and integration.

| Service | Port | Notes |
| --- | --- | --- |
| Home Assistant | `8123` | Host networking |
| Plex | `32400` | Host networking |
| Mosquitto | `1883` | MQTT |
| ESPHome | `6052` | Host networking |
| Portainer | `9443` | HTTPS |
| Tailscale | n/a | No exposed web port |

## Quick start

1. Install Debian stable on the NUC.
2. Install Docker using the official Docker packages.
3. Copy this repository to `/opt/docker` on the NUC.
4. Copy `.env.example` to `.env` and adjust values as needed.
5. Create the runtime directories documented in `docs/operations.md`.
6. Start the stack:

```bash
docker compose up -d
```

## First deployment options

### Local deploy from your laptop

```bash
bash scripts/deploy-to-nuc.sh <nuc-host-or-ip> <ssh-user> ~/.ssh/id_ed25519
```

### GitHub Actions deploy

The repository includes a deploy workflow that can sync the repo to the NUC over SSH.

Important limitation:

- GitHub-hosted runners must be able to reach the NUC over SSH directly.
- If the NUC is only reachable through Tailscale, use a self-hosted runner or local deploy instead.

Required secrets for the deploy workflow:

- `NUC_HOST`
- `NUC_USER`
- `NUC_SSH_KEY`
- `NUC_KNOWN_HOSTS`

## Validation

The repository includes a GitHub Actions validation workflow that checks:

- Docker Compose configuration syntax
- shell script syntax
- required files
- required directory structure

## Operations

See `docs/operations.md` for:

- install and deployment details
- start/stop/update commands
- logs and status commands
- backup and restore guidance
- Mosquitto hardening steps
- Tailscale activation
- basic security recommendations

## Security notes

- Do not expose unnecessary ports to the internet.
- Use Tailscale for remote access and administration.
- Use strong passwords and SSH keys.
- Keep `.env` out of version control.
- Enable firewall rules only after SSH and Tailscale access are confirmed.

## Future expansion

The layout is intentionally simple so later additions such as SABnzbd, Sonarr, Radarr, and Prowlarr can be added without redesigning the stack.
