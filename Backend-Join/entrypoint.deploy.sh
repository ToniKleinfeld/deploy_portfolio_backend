#!/usr/bin/env bash
set -euo pipefail

python manage.py makemigrations --noinput
python manage.py migrate --noinput
python manage.py collectstatic --noinput

exec gunicorn --chdir /app core.wsgi:application --workers 2 --threads 2 --bind 0.0.0.0:8000 --timeout 120