#!/bin/sh
set -e

# Reemplaza $PORT en la plantilla de Nginx y crea el archivo de configuración final
echo "INFO: Procesando plantilla de Nginx con el puerto PORT=${PORT}"
envsubst '$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

echo "INFO: Configuración final de Nginx:"
cat /etc/nginx/conf.d/default.conf
echo "---------------------------"

# Inicia Nginx en primer plano
echo "INFO: Iniciando Nginx..."
exec nginx -g "daemon off;"