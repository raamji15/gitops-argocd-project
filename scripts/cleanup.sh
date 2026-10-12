#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib.sh
source "$ROOT_DIR/scripts/lib.sh"
require_command kubectl
require_command kind
DELETE_APP=false
DELETE_NAMESPACE=false
DELETE_CLUSTER=false
for arg in "$@"; do
  case "$arg" in
    --confirm-app-delete) DELETE_APP=true ;;
    --confirm-namespace-delete) DELETE_NAMESPACE=true ;;
    --confirm-cluster-delete) DELETE_CLUSTER=true ;;
    -h|--help) printf 'Usage: %s [--confirm-app-delete] [--confirm-namespace-delete] [--confirm-cluster-delete]\n' "$0"; exit 0 ;;
    *) die "Unknown option: $arg" ;;
  esac
done

confirm() {
  local prompt="$1" answer=""
  [[ -t 0 ]] || die "Non-interactive use requires an explicit confirmation flag for: $prompt"
  read -r -p "$prompt [y/N] " answer
  [[ "$answer" == "y" || "$answer" == "Y" ]]
}

printf 'Cleanup targets: Argo CD Application %s; namespace %s; optional kind cluster %s.\n' "$DEPLOYMENT" "$NAMESPACE" "$CLUSTER_NAME"
printf 'Docker images are never removed by this script.\n'
if [[ "$DELETE_APP" == false ]] && confirm "Delete only the Argo CD Application object?"; then DELETE_APP=true; fi
if [[ "$DELETE_APP" == true ]] && kubectl --context "$(kind_context)" -n argocd get application "$DEPLOYMENT" >/dev/null 2>&1; then
  kubectl --context "$(kind_context)" -n argocd delete application "$DEPLOYMENT"
fi
if [[ "$DELETE_NAMESPACE" == false ]] && confirm "Delete namespace '$NAMESPACE' and its resources?"; then DELETE_NAMESPACE=true; fi
if [[ "$DELETE_NAMESPACE" == true ]] && kubectl --context "$(kind_context)" get namespace "$NAMESPACE" >/dev/null 2>&1; then
  kubectl --context "$(kind_context)" delete namespace "$NAMESPACE" --wait=true --timeout=120s
fi
if [[ "$DELETE_CLUSTER" == false ]] && confirm "Delete the entire kind cluster '$CLUSTER_NAME'?"; then DELETE_CLUSTER=true; fi
if [[ "$DELETE_CLUSTER" == true ]]; then
  if kind get clusters | grep -Fxq "$CLUSTER_NAME"; then
    kind delete cluster --name "$CLUSTER_NAME"
  else
    info "kind cluster '$CLUSTER_NAME' does not exist."
  fi
fi
printf '\nCleanup finished. Any skipped target was left untouched.\n'
