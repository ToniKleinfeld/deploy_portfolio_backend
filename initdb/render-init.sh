#!/usr/bin/env bash
set -euo pipefail
# Render SQL from template once
if [ ! -f /docker-entrypoint-initdb.d/00-create-dbs-and-users.sql ]; then
  envsubst < /docker-entrypoint-initdb.d/00-create-dbs-and-users.sql.tpl \
    > /docker-entrypoint-initdb.d/00-create-dbs-and-users.sql
fi