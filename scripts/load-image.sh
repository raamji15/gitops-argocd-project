#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib.sh
source "$ROOT_DIR/scripts/lib.sh"
require_command docker
require_command kind
require_command kubectl
if [[ "$#" -gt 1 ]]; then die "Usage: $0 [image-tag]"; fi
IMAGE="${1:-${IMAGE_TAG:-$(expected_image)}}"
[[ "$IMAGE" =~ ^[a-z0-9]+([._/-][a-z0-9]+)*:[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$ ]] || die "Invalid image reference '$IMAGE'."
CLUSTER_NAME="${KIND_CLUSTER_NAME:-gitops-demo}"
kind get clusters | grep -Fxq "$CLUSTER_NAME" || die "kind cluster '$CLUSTER_NAME' does not exist. Run scripts/setup-cluster.sh."
docker image inspect "$IMAGE" >/dev/null 2>&1 || die "Local image '$IMAGE' not found. Run scripts/build-image.sh '$IMAGE' first."

info "Loading $IMAGE into kind cluster '$CLUSTER_NAME'."
kind load docker-image "$IMAGE" --name "$CLUSTER_NAME"
printf '\nImage presence in kind node (best effort):\n'
if docker exec "${CLUSTER_NAME}-control-plane" crictl images 2>/dev/null | grep -F "$IMAGE"; then
  info "Image is present in the control-plane node."
elif docker exec "${CLUSTER_NAME}-control-plane" ctr -n k8s.io images list 2>/dev/null | grep -F "$IMAGE"; then
  info "Image is present in the control-plane node."
else
  printf 'Could not independently inspect node image list; kind load command completed.\n'
fi
printf '\nNext: scripts/deploy-argocd-app.sh with GIT_REPO_URL configured.\n'
