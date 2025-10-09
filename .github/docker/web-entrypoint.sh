#!/bin/sh
set -e

# Replace $PORT in the Nginx config template with the value of the PORT env var
# and output it to the final config file.
echo "INFO: Processing Nginx template with PORT=${PORT}"
envsubst '$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

echo "INFO: Nginx configuration:"
cat /etc/nginx/conf.d/default.conf
echo "---------------------------"

# Start Nginx in the foreground
echo "INFO: Starting Nginx..."
exec nginx -g "daemon off;"
