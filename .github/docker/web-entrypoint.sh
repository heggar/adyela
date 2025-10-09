#!/bin/sh
set -e

# Este script se ejecuta como root.

# Reemplaza $PORT en la plantilla de Nginx y crea el archivo de configuración final
echo "INFO: Procesando plantilla de Nginx con el puerto PORT=${PORT}"
envsubst '$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

echo "INFO: Configuración final de Nginx:"
cat /etc/nginx/conf.d/default.conf
echo "---------------------------"

# Inicia Nginx en primer plano, pero ahora como el usuario 'nginx'
echo "INFO: Iniciando Nginx como usuario 'nginx'..."
exec su-exec nginx nginx -g "daemon off;"

