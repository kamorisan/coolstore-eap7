#!/bin/bash

set -eo pipefail

INJECTED_DIR="$1"

source /usr/local/s2i/install-common.sh

echo "Installing PostgreSQL JDBC module"
install_modules "${INJECTED_DIR}/modules"

echo "Configuring PostgreSQL JDBC driver"
configure_drivers "${INJECTED_DIR}/drivers.env"

echo "Installing JMS deployment descriptor"

if [ -f "${INJECTED_DIR}/deployments/orders-jms.xml" ]; then
    cp \
      "${INJECTED_DIR}/deployments/orders-jms.xml" \
      /deployments/orders-jms.xml

    echo "Installed /deployments/orders-jms.xml"
else
    echo "ERROR: orders-jms.xml not found"
    exit 1
fi

echo "Custom EAP installation completed"
