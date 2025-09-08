#!/bin/bash
set -e

docker compose down

docker system prune -a --volumes

bash start_deploy.sh

docker compose logs reverse-proxy acme-companion
docker compose logs join coderr videoflix