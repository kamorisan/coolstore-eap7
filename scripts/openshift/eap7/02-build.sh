#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")"

USERNAME=$(oc whoami)
PROJECT_NAME="${PROJECT_NAME:-${USERNAME}-wk}"
APP_NAME="${APP_NAME:-coolstore-eap7}"

echo "======================================"
echo " 02-BUILD: EAP 7アプリケーションのビルド"
echo " ユーザー: ${USERNAME}"
echo " プロジェクト: ${PROJECT_NAME}"
echo " アプリケーション: ${APP_NAME}"
echo "======================================"

oc project "${PROJECT_NAME}"

if ! oc get buildconfig "${APP_NAME}" >/dev/null 2>&1; then
    echo "エラー: BuildConfig ${APP_NAME} が存在しません"
    echo "先に ./01-setup.sh を実行してください"
    exit 1
fi

echo "ソースコードをEAP 7 S2I Builderへ送信します"

oc start-build "${APP_NAME}" \
    --from-dir=. \
    --follow \
    --wait

echo
echo "最新ビルドの状態:"
oc get builds \
    --selector="buildconfig=${APP_NAME}" \
    --sort-by=.metadata.creationTimestamp

LATEST_BUILD=$(oc get builds \
    --selector="buildconfig=${APP_NAME}" \
    --sort-by=.metadata.creationTimestamp \
    -o name |
    tail -1)

if [ -n "${LATEST_BUILD}" ]; then
    BUILD_PHASE=$(oc get "${LATEST_BUILD}" -o jsonpath='{.status.phase}')

    if [ "${BUILD_PHASE}" != "Complete" ]; then
        echo "エラー: ビルドが正常終了していません: ${BUILD_PHASE}"
        exit 1
    fi
fi

echo "======================================"
echo "ビルドが完了しました"
echo
echo "生成されたImageStream:"
oc get imagestream "${APP_NAME}"
echo
echo "次のコマンド:"
echo "  ./03-deploy.sh"
echo "======================================"