#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib.sh
source "$ROOT_DIR/scripts/lib.sh"
require_command docker

if [[ "$#" -gt 1 ]]; then die "Usage: $0 [image-tag]"; fi
IMAGE="${1:-${IMAGE_TAG:-$(expected_image)}}"
[[ "$IMAGE" =~ ^[a-z0-9]+([._/-][a-z0-9]+)*:[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$ ]] || die "Unsafe/invalid image reference '$IMAGE'. Use repository:tag (no shell options or whitespace)."
info "Building $IMAGE from the repository root."
docker build --file "$ROOT_DIR/docker/Dockerfile" --tag "$IMAGE" "$ROOT_DIR"
printf '\nBuilt image: %s\n' "$IMAGE"
printf 'Next: scripts/load-image.sh %s\n' "$IMAGE"
