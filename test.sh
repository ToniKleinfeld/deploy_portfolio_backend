#!/bin/bash
set -e

docker compose down

docker system prune -a --volumes

git pull

bash start_deploy.sh

sleep 10

docker compose logs reverse-proxy acme-companion
docker compose logs join coderr videoflix

docker compose exec reverse-proxy cat /etc/nginx/conf.d/default.conf

docker compose exec reverse-proxy cat /etc/nginx/conf.d/default.conf | grep -A5 -B5 "server_name.*toni-kleinfeld"
