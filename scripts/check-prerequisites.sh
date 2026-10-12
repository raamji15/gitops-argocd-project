#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib.sh
source "$ROOT_DIR/scripts/lib.sh"

STATIC_ONLY=false
DOCKER_BUILD=false
for arg in "$@"; do
  case "$arg" in
    --static-only) STATIC_ONLY=true ;;
    --docker-build) DOCKER_BUILD=true ;;
    -h|--help) printf 'Usage: %s [--static-only] [--docker-build]\n' "$0"; exit 0 ;;
    *) die "Unknown option: $arg" ;;
  esac
done

printf 'Host: %s / %s\n' "$(uname -s 2>/dev/null || printf unknown)" "$(uname -m 2>/dev/null || printf unknown)"
printf 'CPU cores: %s\n' "$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf unknown)"
if [[ -r /proc/meminfo ]]; then
  awk '/^MemTotal:/ { printf "Memory: %.1f GiB\n", $2 / 1048576 }' /proc/meminfo
else
  printf 'Memory: use your operating system system-information tool\n'
fi

failed=0
if [[ "$STATIC_ONLY" == true ]]; then
  printf '\nRequired runtime tools: skipped (--static-only)\n'
else
  printf '\nRequired tools:\n'
  for tool in bash git docker kubectl kind; do
    if command -v "$tool" >/dev/null 2>&1; then
      printf '  available: %s (%s)\n' "$tool" "$(command -v "$tool")"
    else
      printf '  MISSING: %s\n' "$tool"
      case "$tool" in
        docker) printf '    install: https://docs.docker.com/get-docker/\n' ;;
        kubectl) printf '    install: https://kubernetes.io/docs/tasks/tools/\n' ;;
        kind) printf '    install: https://kind.sigs.k8s.io/docs/user/quick-start/\n' ;;
        git) printf '    install: https://git-scm.com/downloads\n' ;;
      esac
      failed=1
    fi
  done
  if command -v python3 >/dev/null 2>&1; then
    printf '  available: python3 (%s; required for safe manifest rendering and v2 helper)\n' "$(command -v python3)"
  else
    printf '  MISSING: python3 (required for safe manifest rendering and v2 helper; https://www.python.org/downloads/)\n'
    failed=1
  fi
  if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
      printf '  available: Docker daemon\n'
    else
      printf '  UNAVAILABLE: Docker daemon is not responding (start Docker Desktop or the Linux service)\n'
      failed=1
    fi
  fi
fi

printf '\nOptional tools:\n'
for tool in argocd jq yq shellcheck; do
  if command -v "$tool" >/dev/null 2>&1; then printf '  available: %s\n' "$tool"; else printf '  optional/unavailable: %s\n' "$tool"; fi
done

printf '\nStatic validation:\n'
for script in "$ROOT_DIR"/scripts/*.sh; do
  bash -n "$script" || die "Bash syntax check failed: ${script#"$ROOT_DIR"/}"
done
printf '  passed: bash -n on every shell script\n'
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "$ROOT_DIR"/scripts/*.sh || die "ShellCheck reported a shell-script issue."
  printf '  passed: ShellCheck on every shell script\n'
else
  printf '  optional/unavailable: ShellCheck\n'
fi
if command -v kubectl >/dev/null 2>&1; then
  kubectl kustomize "$ROOT_DIR/k8s" >/dev/null || die "kubectl kustomize failed for k8s/"
  printf '  passed: kubectl kustomize k8s\n'
fi
if command -v yq >/dev/null 2>&1; then
  yq_version="$(yq --version 2>/dev/null || true)"
  if [[ "$yq_version" == *"version v4"* || "$yq_version" == *"version 4"* ]]; then
  for manifest in "$ROOT_DIR"/k8s/*.yaml "$ROOT_DIR"/argocd/*.yaml "$ROOT_DIR"/kind-config.yaml; do yq eval '.' "$manifest" >/dev/null || die "YAML parse failed: ${manifest#"$ROOT_DIR"/}"; done
    printf '  passed: yq YAML parsing for k8s/, argocd/, and kind-config.yaml\n'
  else
    printf '  unavailable: yq is not Mike Farah yq v4; only Kustomize resources were parsed\n'
  fi
elif ! command -v kubectl >/dev/null 2>&1; then
  printf '  unavailable: no kubectl or yq YAML validator\n'
else
  printf '  unavailable: yq is not installed; kubectl validated k8s/ only\n'
fi
if [[ "$DOCKER_BUILD" == true ]]; then
  require_command docker
  docker info >/dev/null 2>&1 || die "Docker daemon is required for --docker-build"
  docker build -f "$ROOT_DIR/docker/Dockerfile" -t "$(expected_image)" "$ROOT_DIR"
else
  printf '  skipped: Docker build (pass --docker-build to request one)\n'
fi
if [[ "$failed" -ne 0 ]]; then
  printf '\nInstall missing required tools and start the Docker daemon. See docs/SETUP.md.\n' >&2
  exit 1
fi
printf '\nPrerequisite/static check completed.\n'
