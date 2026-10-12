#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib.sh
source "$ROOT_DIR/scripts/lib.sh"
printf '%s\n' 'GitOps Demo Dashboard — safe guided run' '========================================='
printf '\nCurrent version: %s\nImage expected: %s\n\n' "$(app_version)" "$(expected_image)"
cat <<'EOF'
Run in order (setup/deploy require Internet; this script does not push Git):
  make check
  make setup
  export GIT_REPO_URL=https://github.com/OWNER/REPOSITORY.git
  make deploy
  make verify

make deploy builds and loads the versioned local image, idempotently installs
Argo CD, and applies the Argo CD Application. It requires an existing kind
cluster from make setup and a repository that is already pushed and accessible.

For local browser access, leave this in a terminal:
  kubectl --context kind-gitops-demo -n gitops-demo port-forward svc/gitops-demo-dashboard 8080:8080
Open http://localhost:8080 in your browser.

For the Argo CD UI, use another terminal:
  kubectl --context kind-gitops-demo -n argocd port-forward svc/argocd-server 8081:443
Open https://localhost:8081. Retrieve its initial password privately as described in docs/SETUP.md.

To demonstrate v1 → v2, follow docs/DEMO_GUIDE.md. Build and load the v2 image locally,
then commit/push both the version metadata and Deployment image change. A source-only
push does not build or load a local image. Argo CD deploys; Docker builds.
EOF
