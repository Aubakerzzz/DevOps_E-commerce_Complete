#!/bin/bash
set -euxo pipefail
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx curl ca-certificates git build-essential
# Install Node.js 22 from NodeSource.
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs
npm install --global pm2
systemctl enable nginx
systemctl start nginx
mkdir -p /opt/leyo