#!/bin/bash

set -e

# 1Panel 多应用第三方仓库安装脚本
# 用法：
#   bash install.sh                              # 直连 GitHub
#   bash install.sh https://ghfast.top           # 使用 GitHub 加速代理
#   bash install.sh https://gh-proxy.com         # 使用其他代理

PROXY_PREFIX="${1:-}"
REPO_NAME="lingdiansr/1panel-appstore"
BRANCH="main"
PANEL_LOCAL_APPS="/opt/1panel/resource/apps/local"
TEMP_DIR=$(mktemp -d)

if [ -n "${PROXY_PREFIX}" ]; then
  REPO_URL="${PROXY_PREFIX}/https://github.com/${REPO_NAME}.git"
else
  REPO_URL="https://github.com/${REPO_NAME}.git"
fi

echo "============================================"
echo "  1Panel 第三方应用仓库 (lingdiansr) 安装器"
echo "============================================"
echo ""

if [ -n "${PROXY_PREFIX}" ]; then
  echo "使用代理: ${PROXY_PREFIX}"
  echo ""
fi

if [ "$EUID" -ne 0 ]; then
  echo "请使用 root 权限运行此脚本"
  exit 1
fi

if [ ! -d "${PANEL_LOCAL_APPS}" ]; then
  echo "错误：未找到 1Panel 本地应用目录 ${PANEL_LOCAL_APPS}"
  echo "请确认 1Panel 已正确安装"
  exit 1
fi

if ! command -v git > /dev/null 2>&1; then
  echo "错误：未找到 git，请先安装 git"
  exit 1
fi

echo "克隆仓库到临时目录..."
git clone -b "${BRANCH}" --depth 1 "${REPO_URL}" "${TEMP_DIR}/repo"

echo "安装应用到 ${PANEL_LOCAL_APPS}..."
for APP_DIR in "${TEMP_DIR}/repo/apps"/*; do
  APP_NAME=$(basename "${APP_DIR}")
  echo "  - ${APP_NAME}"
  rm -rf "${PANEL_LOCAL_APPS:?}/${APP_NAME}"
  cp -r "${APP_DIR}" "${PANEL_LOCAL_APPS}/${APP_NAME}"
done

rm -rf "${TEMP_DIR}"

echo ""
echo "安装完成！"
echo "请在 1Panel 面板中打开「应用商店 → 本地应用」，点击「更新应用列表」后即可看到本仓库的应用。"
echo ""
