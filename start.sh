#!/bin/bash
set -e

# --- Start SSH daemon (background) ---
# Set root password from env var, then launch sshd.
echo "root:${SSH_ROOT_PASSWORD:-pow1fu}" | chpasswd
/usr/sbin/sshd
echo "[start.sh] sshd listening on port 22"

# --- Original hermes startup (unchanged below) ---

mkdir -p /data/.hermes/cron /data/.hermes/sessions /data/.hermes/logs \
         /data/.hermes/memories /data/.hermes/skills /data/.hermes/platforms/pairing \
         /data/.hermes/hooks /data/.hermes/cache/images /data/.hermes/cache/audio \
         /data/.hermes/workspace /data/.hermes/skins /data/.hermes/plans \
         /data/.hermes/home

printf 'docker\n' > /data/.hermes/.install_method

if [ ! -f /data/.hermes/config.yaml ] && [ -f /opt/hermes-agent/cli-config.yaml.example ]; then
  cp /opt/hermes-agent/cli-config.yaml.example /data/.hermes/config.yaml
fi

[ ! -f /data/.hermes/.env ] && touch /data/.hermes/.env

if [ ! -f /data/.hermes/auth.json ] && [ -n "${HERMES_AUTH_JSON_BOOTSTRAP}" ]; then
  printf '%s' "${HERMES_AUTH_JSON_BOOTSTRAP}" > /data/.hermes/auth.json
  chmod 600 /data/.hermes/auth.json
fi

rm -f /data/.hermes/gateway.pid

if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  : "${HERMES_DASHBOARD_PUBLIC_URL:=https://${RAILWAY_PUBLIC_DOMAIN}}"
  export HERMES_DASHBOARD_PUBLIC_URL
fi

exec python /app/server.py
