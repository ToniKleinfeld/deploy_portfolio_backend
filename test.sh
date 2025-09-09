#!/bin/bash
set -e

docker compose down

docker system prune -a --volumes

git pull

bash start_deploy.sh

sleep 10

docker compose logs reverse-proxy acme-companion
docker compose logs join coderr videoflix

