#!/bin/sh
set -e

echo "===== INICIANDO SCRIPT DE DIAGNÓSTICO ====="
echo "Usuario actual: $(whoami)"

echo "\n--- Verificando la directiva 'pid' en /etc/nginx/nginx.conf ---"
cat /etc/nginx/nginx.conf | grep 'pid ' || echo "Directiva 'pid' no encontrada."
echo "----------------------------------------------------"

echo "\n--- Verificando la directiva 'error_log' en /etc/nginx/nginx.conf ---"
cat /etc/nginx/nginx.conf | grep 'error_log' || echo "Directiva 'error_log' no encontrada."
echo "----------------------------------------------------"

echo "\nINFO: Procesando plantilla de Nginx con el puerto PORT=${PORT}"
envsubst '$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

echo "\n--- Verificando permisos y contenido del archivo de configuración ---"
ls -l /etc/nginx/conf.d/default.conf
echo "----------------------------------------------------"

echo "\nINFO: Iniciando Nginx en modo de depuración..."
# Inicia Nginx en primer plano, cambiando al usuario 'nginx'

exec nginx -g 'daemon off; pid /tmp/nginx.pid;'