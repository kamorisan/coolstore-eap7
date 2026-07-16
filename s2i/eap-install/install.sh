#!/bin/bash

set -eo pipefail

INJECTED_DIR="$1"

source /usr/local/s2i/install-common.sh

echo "Installing PostgreSQL JDBC module"
install_modules "${INJECTED_DIR}/modules"

echo "Configuring PostgreSQL JDBC driver"
configure_drivers "${INJECTED_DIR}/drivers.env"

echo "PostgreSQL JDBC driver installation completed"
