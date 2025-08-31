#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(dirname "$(realpath "$0")")" 
TARGET_ROOT="${TARGET_ROOT:-/srv}"        

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
docker compose up -d --build --no-cache
