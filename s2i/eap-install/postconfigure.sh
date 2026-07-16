#!/usr/bin/env bash

set -eo pipefail

echo "Configuring orders JMS Topic"

/opt/eap/bin/jboss-cli.sh \
  --file=/opt/eap/extensions/messaging.cli

echo "orders JMS Topic configuration completed"
