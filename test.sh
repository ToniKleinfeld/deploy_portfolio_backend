#!/bin/bash
set -e

docker compose exec reverse-proxy curl -H "Host: join.toni-kleinfeld.com" http://join:8001/ 2>/dev/null | head -1
docker compose exec reverse-proxy curl -H "Host: coderr.toni-kleinfeld.com" http://coderr:8002/ 2>/dev/null | head -1  
docker compose exec reverse-proxy curl -H "Host: videoflix.toni-kleinfeld.com" http://videoflix:8003/ 2>/dev/null | head -1


docker compose up -d reverse-proxy acme-companion
sleep 30


docker compose exec reverse-proxy cat /etc/nginx/conf.d/default.conf | grep -A10 -B5 "toni-kleinfeld"