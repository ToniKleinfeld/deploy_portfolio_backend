#!/usr/bin/env bash
set -euo pipefail

echo "Wait for PostgreSQL $DB_HOST:$DB_PORT..."

# -q for "quiet" (no output except errors)
# The loop runs as long as pg_isready is *not* successful. (Exit-Code != 0)
while ! pg_isready -h "$DB_HOST" -p "$DB_PORT" -q; do
  echo "PostgreSQL is unavailable - sleep for 1 second"
  sleep 1
done

echo "PostgreSQL is ready - continue..."

python manage.py migrate --noinput
python manage.py collectstatic --noinput

exec gunicorn --chdir /app core.wsgi:application --workers 2 --threads 2 --bind 0.0.0.0:8001 --timeout 120