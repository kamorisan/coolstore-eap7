#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT_NAME="${PROJECT_NAME:-admin-dev}"
APP_NAME="${APP_NAME:-coolstore-eap7}"

echo "======================================"
echo " 02-BUILD: EAP 7 Git S2I Build"
echo " プロジェクト: ${PROJECT_NAME}"
echo " アプリケーション: ${APP_NAME}"
echo "======================================"

oc project "${PROJECT_NAME}"

if ! oc get bc "${APP_NAME}" >/dev/null 2>&1; then
    echo "エラー: BuildConfig ${APP_NAME} が存在しません"
    echo "先に ${SCRIPT_DIR}/01-setup.sh を実行してください"
    exit 1
fi

oc start-build "${APP_NAME}" \
    --follow \
    --wait

LATEST_BUILD="$(
    oc get builds \
        -l "buildconfig=${APP_NAME}" \
        --sort-by=.metadata.creationTimestamp \
        -o jsonpath='{.items[-1:].metadata.name}'
)"

BUILD_PHASE="$(
    oc get build "${LATEST_BUILD}" \
        -o jsonpath='{.status.phase}'
)"

echo "Latest Build: ${LATEST_BUILD}"
echo "Build Phase: ${BUILD_PHASE}"

if [ "${BUILD_PHASE}" != "Complete" ]; then
    echo "エラー: ビルドが成功していません"
    oc logs "build/${LATEST_BUILD}" --tail=300 || true
    exit 1
fi

if ! oc get istag "${APP_NAME}:latest" >/dev/null 2>&1; then
    echo "エラー: ImageStreamTag ${APP_NAME}:latest がありません"
    exit 1
fi

echo "======================================"
echo "ビルドが完了しました"
echo "次のコマンド:"
echo "  ${SCRIPT_DIR}/03-deploy.sh"
echo "======================================"
