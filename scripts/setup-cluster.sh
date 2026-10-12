#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib.sh
source "$ROOT_DIR/scripts/lib.sh"
require_command kind
require_command kubectl
CONTEXT="kind-${CLUSTER_NAME}"

if kind get clusters | grep -Fxq "$CLUSTER_NAME"; then
  info "Reusing existing kind cluster '$CLUSTER_NAME'."
else
  info "Creating kind cluster '$CLUSTER_NAME' (first run may download node images)."
  kind create cluster --name "$CLUSTER_NAME" --config "$ROOT_DIR/kind-config.yaml" --wait 120s
fi

kubectl config use-context "$CONTEXT" >/dev/null
info "Waiting up to 120 seconds for the control plane node."
kubectl wait --context "$CONTEXT" --for=condition=Ready "node/${CLUSTER_NAME}-control-plane" --timeout=120s
kubectl --context "$CONTEXT" get nodes
printf '\nContext: %s\n' "$CONTEXT"
