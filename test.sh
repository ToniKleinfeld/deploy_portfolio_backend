#!/bin/bash
set -e

echo "=== Stopping and cleaning up ==="
docker compose down --remove-orphans --volumes

echo "=== System cleanup ==="
docker system prune -af --volumes

echo "=== Starting deployment ==="
bash start_deploy.sh

echo "=== Waiting for services to stabilize ==="
sleep 30

echo "=== Checking virtual hosts configuration ==="
docker compose exec reverse-proxy cat /etc/nginx/conf.d/default.conf | grep -A5 -B5 "server_name.*toni-kleinfeld" || echo "No virtual hosts found yet"

echo "=== Container status ==="
docker compose ps

echo "=== Reverse proxy and acme logs ==="
docker compose logs --tail=50 reverse-proxy acme-companion

echo "=== Django apps logs ==="
docker compose logs --tail=20 join coderr videoflix

