#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib.sh
source "$ROOT_DIR/scripts/lib.sh"
require_command kubectl
require_kind_cluster
CONTEXT="$(kind_context)"
WAIT_TIMEOUT="${ARGOCD_WAIT_TIMEOUT:-300s}"
if [[ ! "$WAIT_TIMEOUT" =~ ^[1-9][0-9]*s$ ]]; then die "ARGOCD_WAIT_TIMEOUT must be a positive number of seconds (for example 300s)."; fi
DEADLINE=$((SECONDS + ${WAIT_TIMEOUT%s}))

if [[ -n "${ARGOCD_VERSION:-}" ]]; then
  [[ "$ARGOCD_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "ARGOCD_VERSION must look like vX.Y.Z"
  MANIFEST_URL="https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"
else
  MANIFEST_URL="${ARGOCD_INSTALL_URL:-https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml}"
fi
[[ "$MANIFEST_URL" == https://raw.githubusercontent.com/argoproj/argo-cd/*/manifests/install.yaml ]] || die "Install URL must use the official Argo CD raw GitHub manifest path."

info "Installing/updating Argo CD from $MANIFEST_URL"
kubectl --context "$CONTEXT" create namespace argocd --dry-run=client -o yaml | kubectl --context "$CONTEXT" apply -f -
kubectl --context "$CONTEXT" apply --server-side --force-conflicts -n argocd -f "$MANIFEST_URL"
for workload in deployment/argocd-server deployment/argocd-repo-server deployment/argocd-redis statefulset/argocd-application-controller deployment/argocd-applicationset-controller; do
  if kubectl --context "$CONTEXT" -n argocd get "$workload" >/dev/null 2>&1; then
    remaining=$((DEADLINE - SECONDS))
    (( remaining > 0 )) || die "Timed out waiting for Argo CD workloads after $WAIT_TIMEOUT."
    info "Waiting for $workload (up to ${remaining}s remaining)."
    if ! kubectl --context "$CONTEXT" -n argocd rollout status "$workload" --timeout="${remaining}s"; then
      printf '\nArgo CD Pods at the time of failure:\n' >&2
      kubectl --context "$CONTEXT" -n argocd get pods -o wide >&2 || true
      printf '\nRecent Argo CD events:\n' >&2
      kubectl --context "$CONTEXT" -n argocd get events --sort-by=.lastTimestamp 2>/dev/null | tail -20 >&2 || true
      die "$workload did not become ready within the bounded wait. Check registry access, DNS, and available resources."
    fi
  fi
done
kubectl --context "$CONTEXT" -n argocd get pods
cat <<'EOF'

Next: expose the UI with:
  kubectl --context kind-gitops-demo -n argocd port-forward svc/argocd-server 8081:443
Open https://localhost:8081 and accept the local certificate warning.
Retrieve the initial password privately using:
  kubectl --context kind-gitops-demo -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
Do not paste the password into Git, screenshots, or shared logs.
EOF
