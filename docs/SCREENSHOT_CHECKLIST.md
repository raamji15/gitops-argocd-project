# Screenshot checklist

Capture genuine output from your own run. Do not create or edit screenshots to imply a build, sync, healthy pod, or browser result that did not happen. Use a consistent terminal font, crop away private data, and keep secrets/credentials out of every image.

| Filename | What must be visible | Exact command/action | Concept proven | Slide-ready caption |
| --- | --- | --- | --- | --- |
| `01-project-structure.png` | Repository root with `app/`, `docker/`, `k8s/`, `argocd/`, `scripts/`, and `docs/`. | From root: `find . -maxdepth 2 -type f -not -path './.git/*' \| sort` | A small, organized source-and-manifest repository. | “One repository contains the app, container recipe, desired state, and runbook.” |
| `02-github-repository.png` | Browser showing the actual GitHub repository and branch/path; no private repo details if inappropriate. | Open the pushed repository page and show `k8s/` and branch `main`. | Argo CD reads committed, remotely available desired state. | “The cluster reconciles a pushed Git revision—not an unshared laptop folder.” |
| `03-docker-build.png` | Successful real build output and tag `gitops-demo-dashboard:v1.0.0`. | `scripts/build-image.sh` | Docker packages app files; it does not deploy them. | “Docker builds a tagged image before Kubernetes can run it.” |
| `04-kubernetes-cluster.png` | Correct `kind-gitops-demo` context and Ready node. | `kubectl config current-context && kubectl --context kind-gitops-demo get nodes` | kind provides the local Kubernetes runtime. | “A local kind node is ready to run the workload.” |
| `05-argocd-synced-healthy.png` | Argo CD UI with app name, `Synced`, `Healthy`, and source/revision. | Open `https://localhost:8081`, select the Application; hide admin identity. | Argo CD observes and reconciles Git desired state. | “Argo CD reports the application’s sync and health separately.” |
| `06-pods-ready.png` | Dashboard Pod `1/1 Running`, deployment and Service. | `kubectl --context kind-gitops-demo -n gitops-demo get deploy,pods,svc,endpoints -o wide` | Kubernetes schedules and exposes the container. | “The Deployment is ready and the Service has an endpoint.” |
| `07-app-v1.png` | Browser showing v1 badge, release ID, and dashboard content. | Open `http://localhost:8080`; check `scripts/verify-deployment.sh --port-forward` was actually run. | Initial release metadata is served by the app. | “Version 1.0.0 is running from the local image.” |
| `08-git-change-v2.png` | Diff with v2 metadata and Deployment image tag, plus actual commit/push evidence if possible. | `git diff app/version.json k8s/deployment.yaml`; then capture GitHub commit after push. | A reviewed Git commit changes desired release state. | “A v2 release updates metadata and the declared image together.” |
| `09-argocd-sync-v2.png` | UI with new revision and eventual `Synced`/`Healthy`; avoid capturing an intermediate state as final. | Refresh app UI after pushing; wait for sync and health. | Git change reaches Argo CD and Kubernetes. | “Argo CD reconciles the new Git revision.” |
| `10-app-v2.png` | Browser with v2 badge, release ID, release note, and history. | Refresh `http://localhost:8080` after rollout. | The updated image and runtime metadata are visible. | “The v2 release is served after image build, load, and reconciliation.” |
| `11-final-verification.png` | Successful verification output for rollout, endpoints, image and optionally HTTP/Application. | `scripts/verify-deployment.sh --port-forward` | Independent CLI checks confirm the live deployment. | “Final checks match the declared image, ready workload, and HTTP endpoint.” |

## Capture on macOS

1. Bring the target window to the foreground and close terminals containing credentials.
2. Press **Shift-Command-5**; choose selected window or selected portion.
3. Save directly into a local `screenshots/` folder using the exact table filename.
4. Review each image at full size and redact private repository names/usernames if required by course policy. Do not redact away a failed state to make it look successful.

## Capture on Windows

1. Bring the target window to the foreground and close credential-bearing terminals.
2. Press **Win-Shift-S**, select the window/region, then save the Snipping Tool capture into `screenshots/` using the exact table filename.
3. Review the saved image and remove any exposed private information without changing the displayed system result.

Keep screenshots out of the repository unless the course requires submission there; never fabricate missing runtime screenshots.
