#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib.sh
source "$ROOT_DIR/scripts/lib.sh"
require_command kubectl
require_command python3
require_kind_cluster
REPO_URL="${GIT_REPO_URL:-}"
REVISION="${GIT_REVISION:-main}"
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --repo-url) [[ "$#" -ge 2 ]] || die "--repo-url requires a value"; REPO_URL="$2"; shift 2 ;;
    --revision) [[ "$#" -ge 2 ]] || die "--revision requires a value"; REVISION="$2"; shift 2 ;;
    -h|--help) printf 'Usage: GIT_REPO_URL=https://github.com/OWNER/REPO.git %s [--repo-url URL] [--revision REF]\n' "$0"; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done
[[ -n "$REPO_URL" ]] || die "Set GIT_REPO_URL to the pushed GitHub repository URL (or use --repo-url)."
[[ "$REPO_URL" != *REPLACE_WITH_* ]] || die "Repository URL still contains the documented REPLACE_WITH_OWNER/REPLACE_WITH_REPOSITORY placeholder."
[[ "$REPO_URL" =~ ^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(\.git)?$ || "$REPO_URL" =~ ^git@github\.com:[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(\.git)?$ ]] || die "Use a GitHub HTTPS URL or git@github.com:OWNER/REPOSITORY.git."
[[ "$REVISION" =~ ^[A-Za-z0-9._/-]+$ ]] || die "Revision contains unsupported characters."
TEMP_MANIFEST="$(mktemp)"
trap 'rm -f "$TEMP_MANIFEST"' EXIT
python3 - "$ROOT_DIR/argocd/application.yaml" "$TEMP_MANIFEST" "$REPO_URL" "$REVISION" <<'PY'
import pathlib
import sys

source, destination, repo_url, revision = sys.argv[1:]
text = pathlib.Path(source).read_text()
placeholder = "https://github.com/REPLACE_WITH_OWNER/REPLACE_WITH_REPOSITORY.git"
if text.count(placeholder) != 1:
    raise SystemExit("Expected exactly one repository placeholder in argocd/application.yaml")
text = text.replace(placeholder, repo_url)
text = text.replace("targetRevision: main", f"targetRevision: {revision}", 1)
pathlib.Path(destination).write_text(text)
PY
kubectl --context "$(kind_context)" create namespace argocd --dry-run=client -o yaml | kubectl --context "$(kind_context)" apply -f -
kubectl --context "$(kind_context)" apply -f "$TEMP_MANIFEST"
cat <<EOF

Applied Argo CD Application for $REPO_URL (revision $REVISION).
This does not push Git or prove the repository is reachable. Ensure the repository was pushed and accessible to Argo CD.
Inspect reconciliation:
  kubectl --context $(kind_context) -n argocd get application $DEPLOYMENT
  kubectl --context $(kind_context) -n argocd describe application $DEPLOYMENT
EOF
