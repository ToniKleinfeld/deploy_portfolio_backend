#!/bin/bash
set -e

# Stoppe alles
docker compose down

# Entferne eventuelle beschädigte Container/Networks
docker system prune -f

# Starte neu ohne Healthcheck
docker compose up -d postgres redis

# Warte auf Postgres
until docker compose exec postgres pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" >/dev/null 2>&1; do
  echo "Waiting for PostgreSQL..."
  sleep 2
done

# Starte Backend Services
docker compose up -d join coderr videoflix videoflix_worker
sleep 10

# Starte reverse-proxy (ohne Healthcheck)
docker compose up -d reverse-proxy acme-companion

# Prüfe Status nach 30 Sekunden
sleep 30
docker compose ps

# Wenn reverse-proxy stabil läuft, teste Labels
if [ "$(docker compose ps reverse-proxy --format '{{.State}}')" = "running" ]; then
  echo "✓ Reverse-proxy läuft stabil!"
  
  # Jetzt die nginx config prüfen
  docker compose exec reverse-proxy cat /etc/nginx/conf.d/default.conf | grep -A5 -B5 "toni-kleinfeld"
  
  # Test Konnektivität
  docker compose exec reverse-proxy sh -c "nc -zv join 8001" && echo "✓ Join erreichbar"
  docker compose exec reverse-proxy sh -c "nc -zv coderr 8002" && echo "✓ Coderr erreichbar"
  docker compose exec reverse-proxy sh -c "nc -zv videoflix 8003" && echo "✓ Videoflix erreichbar"
else
  echo "✗ Reverse-proxy startet immer noch neu!"
  docker compose logs reverse-proxy --tail 20
fi