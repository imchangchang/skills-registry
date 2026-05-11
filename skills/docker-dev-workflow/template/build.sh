#!/bin/bash
set -e

# ============================================
# 配置区 - 根据项目需求修改以下变量
# ============================================
IMAGE_NAME="my-project-build:latest"
BUILD_COMMAND="make"
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKDIR="$(pwd)"

echo "Building Docker image: $IMAGE_NAME"
docker build -f "$SCRIPT_DIR/Dockerfile.build" -t "$IMAGE_NAME" "$SCRIPT_DIR"

echo ""
echo "Workdir: $WORKDIR"

# CI 环境检测
if [ -n "$CI" ] || [ -n "$GITLAB_CI" ] || [ -n "$GITHUB_ACTIONS" ]; then
    DOCKER_RUN_ARGS="--rm"
    echo "[INFO] CI mode (no TTY)"
else
    DOCKER_RUN_ARGS="--rm -it"
    echo "[INFO] Local mode (interactive TTY)"
fi

docker run $DOCKER_RUN_ARGS \
  -u "$(id -u):$(id -g)" \
  -v "$WORKDIR:$WORKDIR" \
  -w "$WORKDIR" \
  "$IMAGE_NAME" \
  /bin/bash -c "
    echo \"Running in container...\";
    $BUILD_COMMAND;
  "
