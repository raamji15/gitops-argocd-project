#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER_NAME="${KIND_CLUSTER_NAME:-gitops-demo}"
# These shared names are consumed by scripts that source this file.
# shellcheck disable=SC2034
readonly NAMESPACE="gitops-demo"
# shellcheck disable=SC2034
readonly DEPLOYMENT="gitops-demo-dashboard"
# shellcheck disable=SC2034
readonly SERVICE="gitops-demo-dashboard"

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

info() {
  printf '==> %s\n' "$*"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command '$1' was not found. See docs/SETUP.md for installation guidance."
}

app_version() {
  local version=""
  if command -v jq >/dev/null 2>&1; then
    version="$(jq -er '.version' "$PROJECT_ROOT/app/version.json")" || die "Could not read .version from app/version.json"
  else
    version="$(sed -nE 's/^[[:space:]]*"version":[[:space:]]*"([^"]+)".*/\1/p' "$PROJECT_ROOT/app/version.json" | head -n 1)"
  fi
  [[ "$version" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.-]+)?$ ]] || die "Invalid or missing semantic version in app/version.json: '$version'"
  printf '%s' "$version"
}

expected_image() {
  printf 'gitops-demo-dashboard:%s' "$(app_version)"
}

kind_context() {
  printf 'kind-%s' "$CLUSTER_NAME"
}

require_kind_cluster() {
  require_command kind
  kind get clusters | grep -Fxq "$CLUSTER_NAME" || die "kind cluster '$CLUSTER_NAME' does not exist. Run scripts/setup-cluster.sh first."
}
