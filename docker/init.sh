#!/bin/bash
set -e

cd /workspace

if [ -d "frappe-bench/apps/frappe" ]; then
    echo "Bench already exists, skipping init"
    cd frappe-bench
    bench start
    exit 0
fi

echo "Creating new bench..."

# Ensure Node.js path is correct (needed by frappe)
export PATH="${NVM_DIR}/versions/node/v${NODE_VERSION_DEVELOP}/bin/:${PATH}"

# Initialize bench
bench init --skip-redis-config-generation frappe-bench

cd frappe-bench

# Use containers instead of localhost
bench set-mariadb-host mariadb
bench set-redis-cache-host redis://redis:6379
bench set-redis-queue-host redis://redis:6379
bench set-redis-socketio-host redis://redis:6379

# Remove redis, watch from Procfile (handled by docker-compose)
sed -i '/redis/d' ./Procfile
sed -i '/watch/d' ./Procfile

# Get apps
bench get-app erpnext --branch version-14
bench get-app hrms https://github.com/BabuMohanReddy/sample-hrms.git

# Create new site
bench new-site hrms.localhost \
    --force \
    --mariadb-root-password 123 \
    --admin-password admin \
    --no-mariadb-socket

# Install HRMS app
bench --site hrms.localhost install-app hrms
bench --site hrms.localhost set-config developer_mode 1
bench --site hrms.localhost enable-scheduler
bench --site hrms.localhost clear-cache
bench use hrms.localhost

# Start bench
bench start
