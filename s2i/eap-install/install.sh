#!/bin/bash

set -eo pipefail

INJECTED_DIR="$1"

source /usr/local/s2i/install-common.sh

echo "Installing PostgreSQL JDBC module"
install_modules "${INJECTED_DIR}/modules"

echo "Configuring PostgreSQL JDBC driver"
configure_drivers "${INJECTED_DIR}/drivers.env"

echo "Configuring JMS Topic"
if [ -f "${INJECTED_DIR}/extensions/configure.cli" ]; then
    mkdir -p "${JBOSS_HOME}/.s2i"
    cp "${INJECTED_DIR}/extensions/configure.cli" "${JBOSS_HOME}/.s2i/configure.cli"
    echo "JMS Topic configuration script copied to ${JBOSS_HOME}/.s2i/configure.cli"
fi

echo "PostgreSQL JDBC driver installation completed"
