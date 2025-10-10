#!/bin/sh
set -e

# Renderizar la plantilla con el PORT
envsubst '$PORT' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf

# En la imagen unprivileged el PID ya va a /tmp; basta con daemon off
exec nginx -g "daemon off;"
