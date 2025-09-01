#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(dirname "$(realpath "$0")")" 
TARGET_ROOT="${TARGET_ROOT:-/srv}"

# --- ensure initdb files have correct EOL/perms for container ---
INITDB_DIR="$BASE_DIR/initdb"
if [ -d "$INITDB_DIR" ]; then
  echo "[start_deploy] fixing initdb files in $INITDB_DIR"
  # convert CRLF -> LF
  sed -i 's/\r$//' "$INITDB_DIR"/* || true
  # make render script executable
  chmod 0755 "$INITDB_DIR/render-init.sh" || true
  # if running as root, chown to postgres uid (999) so container can write
  if [ "$(id -u)" -eq 0 ]; then
    chown -R 999:999 "$INITDB_DIR" || true
  else
    echo "[start_deploy] not root: ensure $INITDB_DIR is writable by container user (suggestion: sudo chown -R 999:999 $INITDB_DIR)"
  fi
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
docker compose up -d