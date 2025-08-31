#!/bin/sh

# Replace placeholders with environment variables
find /usr/share/nginx/html/assets -type f -name "*.js" -exec sed -i "s|__BACKEND_URL__|${VITE_BACKEND_URL}|g" {} +
find /usr/share/nginx/html/assets -type f -name "*.js" -exec sed -i "s|__PROOF_SERVICE_URL__|${VITE_PROOF_SERVICE_URL}|g" {} +
sed -i "s|__PORT__|${PORT}|g" /etc/nginx/conf.d/default.conf

# Start Nginx
nginx -g 'daemon off;'
