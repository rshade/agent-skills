#!/bin/bash
set -euo pipefail

# Ensures skill-test-base image is available locally.
# Tries GHCR pull first, falls back to local build.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GHCR_IMAGE="ghcr.io/rshade/agent-skills/skill-test-base:latest"
LOCAL_TAG="skill-test-base"

# SKIP_PULL=true forces local build (useful when testing Dockerfile changes)
if [ "${SKIP_PULL:-}" = "true" ]; then
    echo "SKIP_PULL=true, building locally..."
    docker build -t "$LOCAL_TAG" -f "$SCRIPT_DIR/Dockerfile" "$SCRIPT_DIR/"
    exit 0
fi

echo "Pulling base image from GHCR..."
if docker pull "$GHCR_IMAGE" 2>/dev/null; then
    echo "Pulled $GHCR_IMAGE successfully."
    docker tag "$GHCR_IMAGE" "$LOCAL_TAG"
else
    echo "Pull failed (no auth or image not found). Building locally..."
    docker build -t "$LOCAL_TAG" -f "$SCRIPT_DIR/Dockerfile" "$SCRIPT_DIR/"
fi
