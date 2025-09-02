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

python manage.py makemigrations --noinput
python manage.py migrate --noinput
python manage.py collectstatic --noinput

# Create a superuser using environment variables
# (Dein Superuser-Erstellungs-Code bleibt gleich)
python manage.py shell <<EOF
import os
from django.contrib.auth import get_user_model

User = get_user_model()
username = os.environ.get('DJANGO_SUPERUSER_USERNAME', 'admin')
email = os.environ.get('DJANGO_SUPERUSER_EMAIL', 'admin@example.com')
password = os.environ.get('DJANGO_SUPERUSER_PASSWORD', 'adminpassword')

if not User.objects.filter(username=username).exists():
    print(f"Creating superuser '{username}'...")
    # Korrekter Aufruf: username hier übergeben
    User.objects.create_superuser(username=username, email=email, password=password)
    print(f"Superuser '{username}' created.")
else:
    print(f"Superuser '{username}' already exists.")
EOF

exec gunicorn --chdir /app config.wsgi:application --workers 2 --threads 2 --bind 0.0.0.0:8000 --timeout 300