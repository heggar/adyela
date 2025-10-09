#!/bin/sh
set -e

echo "===== INICIANDO SCRIPT DE DIAGNÓSTICO ====="
echo "Usuario actual: $(whoami)"

echo "\n--- Verificando contenido de /etc/nginx/nginx.conf ---"
# Este comando nos mostrará si la corrección del PID se aplicó.
cat /etc/nginx/nginx.conf | grep pid || echo "Directiva 'pid' no encontrada."
echo "----------------------------------------------------"

# Reemplaza $PORT en la plantilla de Nginx y crea el archivo de configuración final
echo "\nINFO: Procesando plantilla de Nginx con el puerto PORT=${PORT}"
envsubst '$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

echo "\n--- Verificando permisos y contenido del archivo de configuración ---"
ls -l /etc/nginx/conf.d/default.conf
echo "----------------------------------------------------"

echo "\nINFO: Configuración final de Nginx:"
cat /etc/nginx/conf.d/default.conf
echo "---------------------------"

echo "\nINFO: Iniciando Nginx..."
# Inicia Nginx en primer plano, cambiando al usuario 'nginx'
exec su-exec nginx nginx -g "daemon off;"

