#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib.sh
source "$ROOT_DIR/scripts/lib.sh"
require_command python3
MODE="${1:-}"
case "$MODE" in
  source)
    python3 - "$ROOT_DIR/app/version.json" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
release = json.loads(path.read_text())
if release.get("version") != "v1.0.0":
    raise SystemExit(f"Expected v1.0.0 source; found {release.get('version')!r}. Refusing to overwrite.")
release.update({
    "version": "v2.0.0",
    "releaseId": "gitops-dashboard-2",
    "releaseDate": "2026-10-12",
    "releaseTitle": "A clearer reconciliation story",
    "releaseNotes": "Version 2 adds an explicit desired-state checklist and a release history entry that explains how an image becomes a running workload.",
    "history": [
        {"version": "v2.0.0", "description": "Adds a release checklist and makes the image-to-workload path easier to present."},
        {"version": "v1.0.0", "description": "Initial dashboard, container, and GitOps workflow."}
    ]
})
path.write_text(json.dumps(release, indent=2) + "\n")
PY
    info "Updated app/version.json to v2.0.0. Build and load gitops-demo-dashboard:v2.0.0 before changing the tracked Deployment image."
    ;;
  manifest)
    python3 - "$ROOT_DIR/k8s/deployment.yaml" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text()
old = "image: gitops-demo-dashboard:v1.0.0"
new = "image: gitops-demo-dashboard:v2.0.0"
if text.count(old) != 1:
    raise SystemExit("Expected exactly one v1.0.0 dashboard image in k8s/deployment.yaml; refusing to edit.")
path.write_text(text.replace(old, new, 1))
PY
    info "Updated k8s/deployment.yaml to v2.0.0. Review, commit, and push this desired-state change."
    ;;
  *) die "Usage: $0 source|manifest (run source before build/load; manifest only after loading the v2 image)" ;;
esac
