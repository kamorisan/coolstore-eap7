#!/usr/bin/env bash

set -o pipefail

# EAP 8 uses /opt/server
CLI="/opt/server/bin/jboss-cli.sh"
EXTENSIONS_DIR="/opt/server/extensions"

echo "======================================"
echo "EAP 8 Post Configuration"
echo "======================================"

# 1. Configure PostgreSQL Datasource
DATASOURCE_CLI="${EXTENSIONS_DIR}/datasource.cli"
echo "Configuring PostgreSQL Datasource..."

if [ -f "${DATASOURCE_CLI}" ]; then
    set +e
    DS_OUTPUT="$(${CLI} --connect --controller=localhost:9990 --file=${DATASOURCE_CLI} 2>&1)"
    DS_RC=$?
    set -e

    printf '%s\n' "${DS_OUTPUT}" | tee /tmp/datasource-cli-output.log

    if [ "${DS_RC}" -ne 0 ]; then
        echo "ERROR: datasource.cli execution failed"
        exit "${DS_RC}"
    fi
    echo "✓ Datasource configuration completed"
else
    echo "WARNING: ${DATASOURCE_CLI} not found, skipping datasource configuration"
fi

# 2. Configure JMS Topic
MESSAGING_CLI="${EXTENSIONS_DIR}/messaging.cli"
echo ""
echo "Configuring JMS Topic orders..."

if [ -f "${MESSAGING_CLI}" ]; then
    set +e
    MSG_OUTPUT="$(${CLI} --connect --controller=localhost:9990 --file=${MESSAGING_CLI} 2>&1)"
    MSG_RC=$?
    set -e

    printf '%s\n' "${MSG_OUTPUT}" | tee /tmp/messaging-cli-output.log

    if [ "${MSG_RC}" -ne 0 ]; then
        echo "ERROR: messaging.cli execution failed"
        exit "${MSG_RC}"
    fi
    echo "✓ JMS Topic configuration completed"
else
    echo "WARNING: ${MESSAGING_CLI} not found, skipping messaging configuration"
fi

echo "======================================"
echo "EAP 8 Post Configuration Completed"
echo "======================================"
