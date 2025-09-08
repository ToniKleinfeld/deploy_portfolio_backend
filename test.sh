#!/bin/bash
set -e

docker compose down

docker system prune -a --volumes

bash start_deploy.sh

docker compose logs reverse-proxy acme-companion
docker compose logs join coderr videoflix

docker compose exec reverse-proxy cat /etc/nginx/conf.d/default.conf

docker inspect deploy_portfolio_backend-join-1 | grep -A10 -B5 "Labels"
docker inspect deploy_portfolio_backend-coderr-1 | grep -A10 -B5 "Labels"  
docker inspect deploy_portfolio_backend-videoflix-1 | grep -A10 -B5 "Labels"

docker compose exec reverse-proxy cat /etc/nginx/conf.d/default.conf | grep -A5 -B5 "server_name.*toni-kleinfeld"
