#!/bin/bash
set -e

echo "=== Loading environment ==="
if [ -f .env ]; then
  set -o allexport; . ./.env; set +o allexport
fi

echo "=== Stopping all services ==="
docker compose down

echo "=== Starting infrastructure ==="
docker compose up -d postgres redis

echo "=== Waiting for Postgres ==="
until docker compose exec postgres pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" >/dev/null 2>&1; do
  echo "Waiting for PostgreSQL..."
  sleep 2
done
echo "PostgreSQL is ready!"

echo "=== Starting backend services one by one ==="

echo "Starting join..."
docker compose up -d join
sleep 10
echo "Join logs:"
docker compose logs --tail 10 join

echo "Starting coderr..."
docker compose up -d coderr
sleep 10
echo "Coderr logs:"
docker compose logs --tail 10 coderr

echo "Starting videoflix..."
docker compose up -d videoflix videoflix_worker
sleep 10
echo "Videoflix logs:"
docker compose logs --tail 10 videoflix

echo "=== Testing backend connectivity ==="
sleep 5

echo "Testing join on port 8001..."
docker compose exec join curl -f http://localhost:8001/ && echo "✓ Join OK" || echo "✗ Join FAIL"

echo "Testing coderr on port 8002..."
docker compose exec coderr curl -f http://localhost:8002/ && echo "✓ Coderr OK" || echo "✗ Coderr FAIL"

echo "Testing videoflix on port 8003..."
docker compose exec videoflix curl -f http://localhost:8003/ && echo "✓ Videoflix OK" || echo "✗ Videoflix FAIL"

echo "=== Starting reverse proxy ==="
docker compose up -d reverse-proxy acme-companion

echo "=== Waiting for reverse proxy to stabilize ==="
sleep 15

echo "=== Final status ==="
docker compose ps

echo "=== Checking nginx config ==="
docker compose exec reverse-proxy cat /etc/nginx/conf.d/default.conf | grep -A10 -B5 "server_name\|proxy_pass" || echo "Could not get nginx config"