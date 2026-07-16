#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")"

USERNAME=$(oc whoami)
PROJECT_NAME="${PROJECT_NAME:-${USERNAME}-wk}"
APP_NAME="${APP_NAME:-coolstore-eap7}"

# EAP 7.4 ELS + OpenJDK 8
EAP_BUILDER_IMAGE="${EAP_BUILDER_IMAGE:-registry.redhat.io/jboss-eap-7/eap74-els-openjdk8-openshift-rhel8:latest}"

# ELSイメージを利用できない場合の例
# EAP_BUILDER_IMAGE="registry.redhat.io/jboss-eap-7/eap74-openjdk8-openshift-rhel8:latest"

echo "======================================"
echo " 01-SETUP: EAP 7環境のセットアップ"
echo " ユーザー: ${USERNAME}"
echo " プロジェクト: ${PROJECT_NAME}"
echo " アプリケーション: ${APP_NAME}"
echo " Builder Image: ${EAP_BUILDER_IMAGE}"
echo "======================================"

echo "OpenShiftログイン状態を確認中..."
oc whoami >/dev/null

if oc get project "${PROJECT_NAME}" >/dev/null 2>&1; then
    echo "プロジェクト ${PROJECT_NAME} は既に存在します"
    oc project "${PROJECT_NAME}"
else
    echo "プロジェクト ${PROJECT_NAME} を作成します"
    oc new-project "${PROJECT_NAME}" \
        --description="Coolstore EAP 7 application for ${USERNAME}" \
        --display-name="Coolstore EAP7 - ${USERNAME}"
fi

echo "EAP 7 S2I BuildConfigを作成します"

oc new-build \
    "${EAP_BUILDER_IMAGE}" \
    --strategy=source \
    --binary=true \
    --name="${APP_NAME}" \
    --dry-run=client \
    -o yaml |
    oc apply -f -

echo
echo "作成されたBuildConfig:"
oc get buildconfig "${APP_NAME}"

echo "======================================"
echo "セットアップが完了しました"
echo
echo "次のコマンド:"
echo "  ./02-build.sh"
echo "======================================"