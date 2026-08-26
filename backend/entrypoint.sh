#!/bin/sh

set -e

echo "Applying database migrations..."
python manage.py migrate --noinput

echo "Starting Django backend with Gunicorn..."
exec gunicorn config.wsgi:application \
    --bind 0.0.0.0:8000 \
    --workers 2 \
    --timeout 60 \
    --access-logfile - \
    --error-logfile -