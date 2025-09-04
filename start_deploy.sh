#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(dirname "$(realpath "$0")")" 
TARGET_ROOT="${TARGET_ROOT:-/srv}"

# ensure required tools (envsubst or python3) are present; install on Ubuntu if missing
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    echo "[start_deploy] not running as root and sudo not available — cannot install packages" >&2
  fi
fi

check_and_install() {
  cmd="$1"
  pkg="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[start_deploy] $cmd not found — attempting to install package: $pkg"
    $SUDO apt-get update -qq
    DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y "$pkg"
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "[start_deploy] failed to install $pkg; please install $cmd manually" >&2
      exit 1
    fi
  fi
}

# envsubst is provided by gettext-base on Ubuntu
check_and_install envsubst gettext-base
check_and_install python3 python3

INITDB_DIR="$BASE_DIR/initdb"
TPL="$INITDB_DIR/00-create-dbs-and-users.sql.tpl"
OUT="$INITDB_DIR/00-create-dbs-and-users.sql"

if [ -f "$TPL" ]; then
  echo "[start_deploy] rendering $TPL -> $OUT"
  # load .env for values
  if [ -f "$BASE_DIR/.env" ]; then
    set -o allexport; . "$BASE_DIR/.env"; set +o allexport
  fi

  # ensure LF
  sed -i 's/\r$//' "$INITDB_DIR"/* || true

  if command -v envsubst >/dev/null 2>&1; then
    envsubst < "$TPL" > "$OUT"
  elif command -v python3 >/dev/null 2>&1 && [ -f "$INITDB_DIR/render_tpl.py" ]; then
    python3 "$INITDB_DIR/render_tpl.py" "$TPL" "$OUT"
  else
    echo "[start_deploy] ERROR: no renderer found (envsubst or python3+render_tpl.py required)" >&2
    exit 1
  fi

  chmod 0644 "$OUT" || true
  if [ "$(id -u)" -eq 0 ]; then
    chown -R 999:999 "$INITDB_DIR" || true
  else
    echo "[start_deploy] warning: run as root to chown initdb to UID 999 (postgres user) or ensure mount writable."
  fi

  echo "[start_deploy] rendered file preview:"
  sed -n '1,120p' "$OUT" || true
fi

declare -A MAP=( ["Backend-Join"]="Backend-Join" ["backend.Coderr"]="backend.Coderr" ["Videoflix"]="Videoflix" )

for src in "${!MAP[@]}"; do
  src_base="${BASE_DIR}/${src}"
  target="${TARGET_ROOT}/${MAP[$src]}"
  mkdir -p "$target"
  [ -f "${src_base}/entrypoint.deploy.sh" ] && cp -f "${src_base}/entrypoint.deploy.sh" "${target}/entrypoint.deploy.sh" && chmod 0755 "${target}/entrypoint.deploy.sh"
  [ -f "${src_base}/worker.deploy.sh" ] && cp -f "${src_base}/worker.deploy.sh" "${target}/worker.deploy.sh" && chmod 0755 "${target}/worker.deploy.sh"
  [ -f "${src_base}/Dockerfile.deploy" ] && cp -f "${src_base}/Dockerfile.deploy" "${target}/Dockerfile.deploy"
done

cd "$BASE_DIR"
docker compose build --no-cache

# Start services in order: first Postgres and Redis
docker compose up -d postgres redis

# Wait until Postgres is ready
echo "Waiting for PostgreSQL to be ready..."
until docker compose exec postgres pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" >/dev/null 2>&1; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 2
done
echo "PostgreSQL is ready!"

# Then start backend services
docker compose up -d join coderr videoflix videoflix_worker

sleep 10

# Finally start reverse-proxy and acme-companion
docker compose up -d reverse-proxy acme-companion

# check reverse-proxy is healthy 
MAX_TRIES=15
for i in $(seq 1 $MAX_TRIES); do
  cid=$(docker compose ps -q reverse-proxy 2>/dev/null || true)
  [ -n "$cid" ] || { sleep 2; continue; }
  status=$(docker inspect -f '{{.State.Health.Status}}' "$cid" 2>/dev/null || echo "none")
  if [ "$status" = "healthy" ]; then
    echo "reverse-proxy healthy"
    break
  fi
  echo "waiting for reverse-proxy health... ($i/$MAX_TRIES)"
  sleep 5
done

if [ "$status" != "healthy" ]; then
  echo "reverse-proxy did not become healthy - showing recent logs:"
  docker compose logs --tail 200 reverse-proxy
fi