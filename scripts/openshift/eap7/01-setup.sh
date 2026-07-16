#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

USERNAME="$(oc whoami)"
PROJECT_NAME="${PROJECT_NAME:-admin-dev}"
APP_NAME="${APP_NAME:-coolstore-eap7}"

GIT_REPOSITORY="${GIT_REPOSITORY:-https://github.com/kamorisan/coolstore-eap7.git}"
GIT_REF="${GIT_REF:-ocp-s2i-eap7}"

EAP_BUILDER_IMAGE="${EAP_BUILDER_IMAGE:-registry.redhat.io/jboss-eap-7/eap74-els-openjdk8-openshift-rhel8:latest}"
CUSTOM_INSTALL_DIR="${CUSTOM_INSTALL_DIR:-s2i/eap-install}"

echo "======================================"
echo " 01-SETUP: EAP 7 Git S2I BuildConfig"
echo " ユーザー: ${USERNAME}"
echo " プロジェクト: ${PROJECT_NAME}"
echo " アプリケーション: ${APP_NAME}"
echo " Git: ${GIT_REPOSITORY}"
echo " Git Ref: ${GIT_REF}"
echo " Builder: ${EAP_BUILDER_IMAGE}"
echo "======================================"

oc whoami >/dev/null

if oc get project "${PROJECT_NAME}" >/dev/null 2>&1; then
    echo "プロジェクト ${PROJECT_NAME} は既に存在します"
else
    oc new-project "${PROJECT_NAME}"
fi

oc project "${PROJECT_NAME}"

if oc get bc "${APP_NAME}" >/dev/null 2>&1; then
    echo "BuildConfig ${APP_NAME} は既に存在します"
else
    oc new-build \
        "${EAP_BUILDER_IMAGE}" \
        --strategy=source \
        --name="${APP_NAME}" \
        --code="${GIT_REPOSITORY}"
fi

oc patch bc "${APP_NAME}" \
    --type=merge \
    -p "{
      \"spec\": {
        \"source\": {
          \"type\": \"Git\",
          \"git\": {
            \"uri\": \"${GIT_REPOSITORY}\",
            \"ref\": \"${GIT_REF}\"
          },
          \"contextDir\": \"\"
        }
      }
    }"

oc set env bc/"${APP_NAME}" \
    CUSTOM_INSTALL_DIRECTORIES="${CUSTOM_INSTALL_DIR}"

echo
echo "BuildConfig:"
oc get bc "${APP_NAME}"

echo
echo "Git source:"
oc get bc "${APP_NAME}" \
    -o jsonpath='{.spec.source.git.uri}{" @ "}{.spec.source.git.ref}{"\n"}'

echo
echo "Build environment:"
oc set env bc/"${APP_NAME}" --list

echo "======================================"
echo "セットアップが完了しました"
echo "次のコマンド:"
echo "  ${SCRIPT_DIR}/02-build.sh"
echo "======================================"
