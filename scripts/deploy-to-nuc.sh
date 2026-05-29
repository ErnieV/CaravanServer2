#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "usage: $0 <host> <user> <ssh-key-path>" >&2
  exit 1
fi

host="$1"
user="$2"
key_path="$3"

rsync -az --delete \
  --exclude '.git' \
  --exclude '.github' \
  --exclude '.DS_Store' \
  -e "ssh -i ${key_path}" \
  ./ "${user}@${host}:/opt/docker/"

ssh -i "${key_path}" "${user}@${host}" 'bash -s' <<'EOF'
set -euo pipefail
sudo mkdir -p /opt/docker/{homeassistant,plex,mosquitto/{data,log},esphome,portainer,tailscale} /srv/{media,downloads}
if [ -f /opt/docker/.env.example ] && [ ! -f /opt/docker/.env ]; then
  sudo cp /opt/docker/.env.example /opt/docker/.env
fi
cd /opt/docker
sudo docker compose up -d
EOF
