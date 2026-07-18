#!/bin/bash

set -euo pipefail

PROJECT_NAME="${PROJECT_NAME:-user01-dev}"
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
    echo "新規Deploymentを作成します..."
    oc new-app "${APP_NAME}:latest" --name="${APP_NAME}"

    CONTAINER_NAME="$(
        oc get deployment "${APP_NAME}" \
            -o jsonpath='{.spec.template.spec.containers[0].name}'
    )"

    echo "環境変数を設定します..."
    oc patch deployment "${APP_NAME}" \
        --type='strategic' \
        -p="
spec:
  template:
    spec:
      containers:
        - name: ${CONTAINER_NAME}
          env:
            - name: DB_SERVICE_PREFIX_MAPPING
              value: ${DB_POOL_NAME}-postgresql=${DB_PREFIX}
            - name: COOLSTORE_POSTGRESQL_SERVICE_HOST
              value: ${POSTGRESQL_SERVICE}
            - name: COOLSTORE_POSTGRESQL_SERVICE_PORT
              value: \"${DB_PORT}\"
            - name: DB_JNDI
              value: ${DB_JNDI}
            - name: DB_DRIVER
              value: ${DB_DRIVER}
            - name: DB_NONXA
              value: \"true\"
            - name: DB_JTA
              value: \"true\"
            - name: DB_MIN_POOL_SIZE
              value: \"1\"
            - name: DB_MAX_POOL_SIZE
              value: \"20\"
            - name: DB_VALIDATE_ON_MATCH
              value: \"true\"
            - name: DB_BACKGROUND_VALIDATION
              value: \"false\"
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
else
    echo "既存のDeploymentが見つかりました。スキップします。"
fi

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

echo ""
echo "Deploymentのロールアウトを待機しています..."
oc rollout status deployment/"${APP_NAME}" --timeout=300s

echo "Podの準備完了を待機しています..."
oc wait \
    --for=condition=Ready \
    pod \
    -l "deployment=${APP_NAME}" \
    --timeout=300s

# 最新のRunning状態のPodを取得
POD_NAME="$(
    oc get pods \
        -l "deployment=${APP_NAME}" \
        --field-selector=status.phase=Running \
        --sort-by=.metadata.creationTimestamp \
        -o jsonpath='{.items[-1:].metadata.name}'
)"

if [ -z "${POD_NAME}" ]; then
    echo "エラー: Podを取得できません"
    exit 1
fi

echo ""
echo "EAP起動ログを確認しています..."
sleep 10

STARTUP_LOG="$(oc logs "${POD_NAME}" 2>&1)"

if echo "${STARTUP_LOG}" | grep -q "WFLYSRV0025"; then
    echo "✓ EAPが正常に起動しました (WFLYSRV0025)"
elif echo "${STARTUP_LOG}" | grep -q "WFLYSRV0026"; then
    echo "⚠ EAPがエラー付きで起動しました (WFLYSRV0026)"
    echo ""
    echo "最近のエラーログ:"
    echo "${STARTUP_LOG}" | grep -E "ERROR|WARN" | tail -10
else
    echo "⚠ EAP起動ログを確認できませんでした"
fi

if echo "${STARTUP_LOG}" | grep -q "orders JMS Topic configuration completed successfully"; then
    echo "✓ JMS Topic 'orders' が作成されました"
fi

ROUTE_HOST="$(
    oc get route "${APP_NAME}" \
        -o jsonpath='{.spec.host}'
)"

echo ""
echo "======================================"
echo "デプロイ完了"
echo "Application URL: https://${ROUTE_HOST}/"
echo "Pod: ${POD_NAME}"
echo ""
echo "検証コマンド:"
echo "  oc logs ${POD_NAME}"
echo "  oc exec ${POD_NAME} -- /opt/eap/bin/jboss-cli.sh --connect --command='deployment-info'"
echo "======================================"
