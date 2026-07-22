#!/bin/bash

set -eo pipefail

INJECTED_DIR="$1"

echo "======================================"
echo "EAP 8 Custom Installation"
echo "======================================"

# EAP 8 uses /opt/server instead of /opt/eap
SERVER_HOME="${SERVER_HOME:-/opt/server}"

echo "Installing PostgreSQL JDBC module for EAP 8"
mkdir -p "${SERVER_HOME}/modules/system/layers/base/org/postgresql/main"
cp -r "${INJECTED_DIR}/modules/org/postgresql/main/"* \
   "${SERVER_HOME}/modules/system/layers/base/org/postgresql/main/"

echo "Installing EAP 8 post-configuration scripts"
mkdir -p "${SERVER_HOME}/extensions"

cp "${INJECTED_DIR}/postconfigure.sh" \
   "${SERVER_HOME}/extensions/postconfigure.sh"

cp "${INJECTED_DIR}/configuration/datasource.cli" \
   "${SERVER_HOME}/extensions/datasource.cli"

cp "${INJECTED_DIR}/configuration/messaging.cli" \
   "${SERVER_HOME}/extensions/messaging.cli"

cp "${INJECTED_DIR}/delayedpostconfigure.sh" \
   "${SERVER_HOME}/extensions/delayedpostconfigure.sh"

chmod +x "${SERVER_HOME}/extensions/postconfigure.sh"
chmod +x "${SERVER_HOME}/extensions/delayedpostconfigure.sh"

echo "Installed files:"
ls -l "${SERVER_HOME}/extensions" 2>/dev/null || echo "Extensions directory created"

echo "PostgreSQL JDBC module:"
ls -l "${SERVER_HOME}/modules/system/layers/base/org/postgresql/main/" 2>/dev/null || echo "Module directory created"

echo "======================================"
echo "Custom EAP 8 installation completed"
echo "======================================"
