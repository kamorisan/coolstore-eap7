#!/usr/bin/env bash

set -o pipefail

CLI="/opt/eap/bin/jboss-cli.sh"
CLI_FILE="/opt/eap/extensions/messaging.cli"
LOG_FILE="/tmp/messaging-cli-output.log"

echo "======================================"
echo "Configuring orders JMS Topic"
echo "CLI file: ${CLI_FILE}"
echo "======================================"

if [ ! -f "${CLI_FILE}" ]; then
    echo "ERROR: ${CLI_FILE} does not exist"
    exit 1
fi

set +e

CLI_OUTPUT="$(
    "${CLI}" \
        --connect \
        --controller=localhost:9990 \
        --file="${CLI_FILE}" \
        2>&1
)"

CLI_RC=$?

set -e

printf '%s\n' "${CLI_OUTPUT}" | tee "${LOG_FILE}"

echo "JBoss CLI exit code: ${CLI_RC}"

if [ "${CLI_RC}" -ne 0 ]; then
    echo "ERROR: messaging.cli execution failed"
    exit "${CLI_RC}"
fi

echo "Verifying JMS Topic orders"

VERIFY_OUTPUT="$(
    "${CLI}" \
        --connect \
        --controller=localhost:9990 \
        --command='/subsystem=messaging-activemq/server=default/jms-topic=orders:read-resource' \
        2>&1
)"

VERIFY_RC=$?

printf '%s\n' "${VERIFY_OUTPUT}"

if [ "${VERIFY_RC}" -ne 0 ]; then
    echo "ERROR: JMS Topic orders was not created"
    exit "${VERIFY_RC}"
fi

if ! printf '%s\n' "${VERIFY_OUTPUT}" |
    grep -q '"outcome" => "success"'; then

    echo "ERROR: JMS Topic verification did not return success"
    exit 1
fi

echo "orders JMS Topic configuration completed successfully"
