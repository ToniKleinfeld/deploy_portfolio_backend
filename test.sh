#!/bin/bash
set -e

docker compose logs -f reverse-proxy acme-companion

docker exec $(docker-compose ps -q reverse-proxy) cat /etc/nginx/conf.d/default.conf | grep -A10 "server_name.*toni-kleinfeld"

docker logs $(docker-compose ps -q acme-companion) | tail -20

docker compose exec reverse-proxy curl -I http://join:8001/
docker compose exec reverse-proxy curl -I http://coderr:8002/
docker compose exec reverse-proxy curl -I http://videoflix:8003/

docker compose exec reverse-proxy nslookup join
docker compose exec reverse-proxy nslookup coderr
docker compose exec reverse-proxy nslookup videoflix