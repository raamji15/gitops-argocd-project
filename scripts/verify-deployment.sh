#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib.sh
source "$ROOT_DIR/scripts/lib.sh"
require_command kubectl
PORT_FORWARD=false
LOCAL_PORT="${LOCAL_PORT:-8080}"
for arg in "$@"; do
  case "$arg" in
    --port-forward) PORT_FORWARD=true ;;
    --help|-h) printf 'Usage: %s [--port-forward]\nLOCAL_PORT may select the local HTTP port (default 8080).\n' "$0"; exit 0 ;;
    *) die "Unknown option: $arg" ;;
  esac
done
if [[ ! "$LOCAL_PORT" =~ ^[0-9]+$ ]] || (( LOCAL_PORT < 1 || LOCAL_PORT > 65535 )); then
  die "LOCAL_PORT must be between 1 and 65535."
fi
CONTEXT="$(kind_context)"
kubectl config get-contexts -o name | grep -Fxq "$CONTEXT" || die "Expected kube context '$CONTEXT' is not configured. Run scripts/setup-cluster.sh."

info "Checking Deployment, pods, Service, and endpoints in $NAMESPACE."
kubectl --context "$CONTEXT" -n "$NAMESPACE" rollout status "deployment/$DEPLOYMENT" --timeout=120s
kubectl --context "$CONTEXT" -n "$NAMESPACE" get deployment,pods,service,endpoints -o wide
EXPECTED="$(expected_image)"
ACTUAL="$(kubectl --context "$CONTEXT" -n "$NAMESPACE" get "deployment/$DEPLOYMENT" -o jsonpath='{.spec.template.spec.containers[0].image}')"
printf '\nExpected image: %s\nObserved image: %s\n' "$EXPECTED" "$ACTUAL"
[[ "$ACTUAL" == "$EXPECTED" ]] || die "Deployment image does not match app/version.json; update the image reference and rebuild/load that tag."
if kubectl --context "$CONTEXT" -n argocd get application "$DEPLOYMENT" >/dev/null 2>&1; then
  printf '\nArgo CD Application:\n'
  kubectl --context "$CONTEXT" -n argocd get application "$DEPLOYMENT" -o 'custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status'
else
  printf '\nArgo CD Application CR not found; Argo status check skipped.\n'
fi

if [[ "$PORT_FORWARD" == true ]]; then
  require_command curl
  require_command python3
  LOG_FILE="$(mktemp)"
  PF_PID=""
  cleanup_port_forward() {
    if [[ -n "$PF_PID" ]]; then kill "$PF_PID" 2>/dev/null || true; wait "$PF_PID" 2>/dev/null || true; fi
    rm -f "$LOG_FILE"
  }
  trap cleanup_port_forward EXIT INT TERM
  kubectl --context "$CONTEXT" -n "$NAMESPACE" port-forward "service/$SERVICE" "$LOCAL_PORT:8080" >"$LOG_FILE" 2>&1 &
  PF_PID=$!
  ready=false
  for _ in $(seq 1 30); do
    if ! kill -0 "$PF_PID" 2>/dev/null; then cat "$LOG_FILE" >&2; die "kubectl port-forward stopped; the local port may be occupied."; fi
    if curl --fail --silent "http://127.0.0.1:$LOCAL_PORT/healthz" >/dev/null; then ready=true; break; fi
    sleep 1
  done
  [[ "$ready" == true ]] || { cat "$LOG_FILE" >&2; die "No HTTP response after 30 seconds."; }
  printf '\nHTTP health endpoint: '; curl --fail --silent "http://127.0.0.1:$LOCAL_PORT/healthz"; printf '\nRelease metadata:\n'
  RELEASE_JSON="$(curl --fail --silent "http://127.0.0.1:$LOCAL_PORT/version.json")" || die "Could not fetch version.json."
  printf '%s\n' "$RELEASE_JSON" | python3 -c 'import json,sys; data=json.load(sys.stdin); print(json.dumps(data, indent=2)); sys.exit(0 if data.get("version") == sys.argv[1] else 1)' "$(app_version)" || die "Served version.json does not match app/version.json."
  printf '\nDashboard: http://localhost:%s\n' "$LOCAL_PORT"
fi
printf '\nDeployment verification completed.\n'
