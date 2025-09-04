#!/bin/bash
set -e

# Stoppe und starte erneut
docker compose down
docker compose up -d postgres redis

# Warte auf Postgres
until docker compose exec postgres pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" >/dev/null 2>&1; do
  sleep 2
done

# Starte Backend-Services
docker compose up -d join coderr videoflix videoflix_worker
sleep 15

# Starte Reverse Proxy mit Debug
docker compose up -d reverse-proxy acme-companion

# Warte und prüfe Logs
sleep 10
docker compose logs reverse-proxy | tail -20

# Prüfe ob Virtual Hosts jetzt generiert werden
docker compose exec reverse-proxy cat /etc/nginx/conf.d/default.conf | grep -A10 -B5 "toni-kleinfeld\|server_name.*join\|server_name.*coderr\|server_name.*videoflix"

# Prüfe welche Container docker-gen sieht
docker compose exec reverse-proxy ps aux | grep docker-gen

# Prüfe die docker-gen Logs speziell
docker compose logs reverse-proxy 2>&1 | grep -i "template\|container\|generated\|virtual"

# Test mit netcat aus dem nginx-proxy Container
docker compose exec reverse-proxy sh -c "
echo 'Testing connectivity...'
nc -zv join 8001 2>&1 && echo 'Join reachable' || echo 'Join NOT reachable'
nc -zv coderr 8002 2>&1 && echo 'Coderr reachable' || echo 'Coderr NOT reachable'  
nc -zv videoflix 8003 2>&1 && echo 'Videoflix reachable' || echo 'Videoflix NOT reachable'
"

# Prüfe ob nginx-proxy die Labels korrekt erkennt
docker compose logs reverse-proxy 2>&1 | grep -i "join\|coderr\|videoflix"