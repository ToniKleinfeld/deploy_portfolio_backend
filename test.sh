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


# docker compose up --build --force-recreate -d reverse-proxy acme-companion
# sleep 5
# echo zu 1:
# docker compose exec reverse-proxy cat /etc/nginx/conf.d/default.conf
# docker compose exec reverse-proxy grep -A 10 -B 2 "location /static/" /etc/nginx/conf.d/default.conf

# echo zu 2:
# docker compose exec reverse-proxy nginx -T | grep -E "location.*{" | sort
# docker compose exec reverse-proxy nginx -T | grep -A 5 -B 2 "location /static/"
# docker compose exec reverse-proxy nginx -T | grep -A 5 -B 2 "location /media/"

# echo zu 3:
# docker compose exec reverse-proxy ls -la /etc/nginx/conf.d/
# docker compose exec reverse-proxy ls -la /etc/nginx/vhost.d/
# docker compose exec reverse-proxy cat /etc/nginx/conf.d/security.conf
# docker compose exec reverse-proxy cat /etc/nginx/conf.d/custom.conf
# docker compose exec reverse-proxy cat /etc/nginx/vhost.d/default

# echo zu 4:
# docker compose exec reverse-proxy nginx -t -c /etc/nginx/nginx.conf
# docker compose exec reverse-proxy nginx -T > nginx_full_config.txt