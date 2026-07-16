#!/bin/bash

set -eo pipefail

INJECTED_DIR="$1"

source /usr/local/s2i/install-common.sh

echo "Installing PostgreSQL JDBC module"
install_modules "${INJECTED_DIR}/modules"

echo "Configuring PostgreSQL JDBC driver"
configure_drivers "${INJECTED_DIR}/drivers.env"

echo "Installing EAP custom configuration scripts"

mkdir -p "${JBOSS_HOME}/extensions"

cp "${INJECTED_DIR}/postconfigure.sh" \
   "${JBOSS_HOME}/extensions/postconfigure.sh"

cp "${INJECTED_DIR}/messaging.cli" \
   "${JBOSS_HOME}/extensions/messaging.cli"

chmod +x "${JBOSS_HOME}/extensions/postconfigure.sh"

echo "Custom EAP installation completed"
