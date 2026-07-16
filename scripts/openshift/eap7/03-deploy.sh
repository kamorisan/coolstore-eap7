#!/bin/bash

set -euo pipefail

PROJECT_NAME="${PROJECT_NAME:-admin-dev}"
APP_NAME="${APP_NAME:-coolstore-eap7}"

POSTGRESQL_SERVICE="${POSTGRESQL_SERVICE:-postgresql}"
POSTGRESQL_SECRET="${POSTGRESQL_SECRET:-coolstore-db-secret}"
DB_PORT="${DB_PORT:-5432}"

DB_POOL_NAME="${DB_POOL_NAME:-coolstore}"
DB_PREFIX="${DB_PREFIX:-DB}"
DB_DRIVER="${DB_DRIVER:-postgresql}"
DB_JNDI="${DB_JNDI:-java:jboss/datasources/CoolstoreDS}"

echo "======================================"
echo " 03-DEPLOY: EAP 7 Application"
echo " プロジェクト: ${PROJECT_NAME}"
echo " アプリケーション: ${APP_NAME}"
echo " PostgreSQL Service: ${POSTGRESQL_SERVICE}"
echo " PostgreSQL Secret: ${POSTGRESQL_SECRET}"
echo " Datasource JNDI: ${DB_JNDI}"
echo "======================================"

oc project "${PROJECT_NAME}"

if ! oc get istag "${APP_NAME}:latest" >/dev/null 2>&1; then
    echo "エラー: ImageStreamTag ${APP_NAME}:latest がありません"
    exit 1
fi

if ! oc get svc "${POSTGRESQL_SERVICE}" >/dev/null 2>&1; then
    echo "エラー: Service ${POSTGRESQL_SERVICE} がありません"
    exit 1
fi

if ! oc get secret "${POSTGRESQL_SECRET}" >/dev/null 2>&1; then
    echo "エラー: Secret ${POSTGRESQL_SECRET} がありません"
    exit 1
fi

for KEY in DB_NAME DB_USERNAME DB_PASSWORD; do
    VALUE="$(oc get secret "${POSTGRESQL_SECRET}" -o "jsonpath={.data.${KEY}}")"
    if [ -z "${VALUE}" ]; then
        echo "エラー: Secret ${POSTGRESQL_SECRET} に ${KEY} がありません"
        exit 1
    fi
done

ENDPOINT="$(
    oc get endpoints "${POSTGRESQL_SERVICE}" \
        -o jsonpath='{.subsets[*].addresses[*].ip}' \
        2>/dev/null || true
)"

if [ -z "${ENDPOINT}" ]; then
    echo "エラー: PostgreSQL ServiceにEndpointがありません"
    exit 1
fi

if ! oc get deployment "${APP_NAME}" >/dev/null 2>&1; then
    oc new-app "${APP_NAME}:latest" --name="${APP_NAME}"
fi

CONTAINER_NAME="$(
    oc get deployment "${APP_NAME}" \
        -o jsonpath='{.spec.template.spec.containers[0].name}'
)"

oc set env deployment/"${APP_NAME}" \
    DB_SERVICE_PREFIX_MAPPING="${DB_POOL_NAME}-postgresql=${DB_PREFIX}" \
    COOLSTORE_POSTGRESQL_SERVICE_HOST="${POSTGRESQL_SERVICE}" \
    COOLSTORE_POSTGRESQL_SERVICE_PORT="${DB_PORT}" \
    DB_JNDI="${DB_JNDI}" \
    DB_DRIVER="${DB_DRIVER}" \
    DB_NONXA="true" \
    DB_JTA="true" \
    DB_MIN_POOL_SIZE="1" \
    DB_MAX_POOL_SIZE="20" \
    DB_VALIDATE_ON_MATCH="true" \
    DB_BACKGROUND_VALIDATION="false"

oc patch deployment "${APP_NAME}" \
    --type='strategic' \
    -p="
spec:
  template:
    spec:
      containers:
        - name: ${CONTAINER_NAME}
          env:
            - name: DB_DATABASE
              valueFrom:
                secretKeyRef:
                  name: ${POSTGRESQL_SECRET}
                  key: DB_NAME
            - name: DB_USERNAME
              valueFrom:
                secretKeyRef:
                  name: ${POSTGRESQL_SECRET}
                  key: DB_USERNAME
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: ${POSTGRESQL_SECRET}
                  key: DB_PASSWORD
"

if ! oc get svc "${APP_NAME}" >/dev/null 2>&1; then
    oc expose deployment "${APP_NAME}" \
        --name="${APP_NAME}" \
        --port=8080 \
        --target-port=8080
fi

if ! oc get route "${APP_NAME}" >/dev/null 2>&1; then
    oc create route edge "${APP_NAME}" \
        --service="${APP_NAME}" \
        --port=8080 \
        --insecure-policy=Redirect
fi

oc rollout status deployment/"${APP_NAME}" --timeout=300s

CURRENT_RS="$(
    oc get rs \
        -l "deployment=${APP_NAME}" \
        --sort-by=.metadata.creationTimestamp \
        -o name |
        tail -1
)"

POD_TEMPLATE_HASH="$(
    oc get "${CURRENT_RS}" \
        -o jsonpath='{.metadata.labels.pod-template-hash}'
)"

oc wait \
    --for=condition=Ready \
    pod \
    -l "deployment=${APP_NAME},pod-template-hash=${POD_TEMPLATE_HASH}" \
    --timeout=300s

POD_NAME="$(
    oc get pods \
        -l "deployment=${APP_NAME},pod-template-hash=${POD_TEMPLATE_HASH}" \
        --field-selector=status.phase=Running \
        -o jsonpath='{.items[0].metadata.name}'
)"

if [ -z "${POD_NAME}" ]; then
    echo "エラー: Podを取得できません"
    exit 1
fi

CLI_READY=false

for I in $(seq 1 60); do
    if oc exec "${POD_NAME}" -- \
        /opt/eap/bin/jboss-cli.sh \
        --connect \
        --command=':read-attribute(name=server-state)' \
        >/dev/null 2>&1; then
        CLI_READY=true
        break
    fi

    echo "EAP管理インターフェース待機中 (${I}/60)"
    sleep 5
done

if [ "${CLI_READY}" != "true" ]; then
    echo "エラー: EAP管理インターフェースへ接続できません"
    oc logs "${POD_NAME}" --tail=300
    exit 1
fi

echo "Installed JDBC drivers:"
oc exec "${POD_NAME}" -- \
    /opt/eap/bin/jboss-cli.sh \
    --connect \
    --command='/subsystem=datasources:installed-drivers-list'

echo "Datasources:"
oc exec "${POD_NAME}" -- \
    /opt/eap/bin/jboss-cli.sh \
    --connect \
    --command='/subsystem=datasources:read-children-names(child-type=data-source)'

echo "ROOT.war:"
oc exec "${POD_NAME}" -- \
    /opt/eap/bin/jboss-cli.sh \
    --connect \
    --command='/deployment=ROOT.war:read-resource'

ROUTE_HOST="$(
    oc get route "${APP_NAME}" \
        -o jsonpath='{.spec.host}'
)"

echo "======================================"
echo "デプロイ完了"
echo "URL: https://${ROUTE_HOST}/"
echo "Pod: ${POD_NAME}"
echo "======================================"
