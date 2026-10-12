# 12-slide presentation outline

Replace the student/institution placeholders with accurate information. Use only screenshots you captured from a real run. If a live environment was unavailable, show the architecture/manifest and label it as a planned demo rather than a result.

## 1. Title
- **GitOps-Based Continuous Deployment Using Argo CD and Kubernetes**
- Student: `[Name]` · Roll number: `[ID]` · Department: `[Department]` · Guide: `[Guide]`
- Course / institution: `[Course / Institution]`
- **Visual:** Actual dashboard screenshot or a clean original title diagram.
- **Speaker notes:** Introduce the goal: learn the roles and boundaries among Git, Docker, Argo CD, and Kubernetes.
- **Transition:** “First, what deployment problem does this approach address?”

## 2. Problem statement
- Manual deployments can drift from documented configuration.
- Reproducing a deployment is difficult when changes are not versioned.
- Teams need a reviewable, observable desired state.
- **Visual:** Simple “manual commands vs tracked changes” comparison; use no claimed production statistics.
- **Speaker notes:** Keep the claim scoped to the learning problem, not a universal guarantee.
- **Transition:** “This project turns that problem into a small local experiment.”

## 3. Objectives
- Package a static app with Docker.
- Run it on local Kubernetes through kind.
- Let Argo CD reconcile manifests stored in Git.
- Observe versioned v1 → v2 changes and verify the result.
- **Visual:** The repository's actual directory tree (`01-project-structure.png`).
- **Speaker notes:** State explicitly that the UI's status card is static presentation metadata.
- **Transition:** “The common idea behind the steps is GitOps.”

## 4. GitOps introduction
- Git stores the desired configuration and change history.
- A controller compares desired state with runtime state.
- Reconciliation repeats; it is not a one-time shell deployment.
- **Visual:** Desired state → comparison → reconciliation → observed state.
- **Speaker notes:** Explain reviewable commits and distinguish sync status from health status.
- **Transition:** “Here is how those roles fit together in this demo.”

## 5. Architecture
- GitHub is the source of manifests.
- Docker builds and tags the image; kind hosts Kubernetes.
- Argo CD applies manifests; Kubernetes runs the Pod and Service.
- **Visual:** Mermaid architecture in `docs/ARCHITECTURE.md`, exported as a diagram or redrawn faithfully.
- **Speaker notes:** Argo CD does not build Docker images. This local workflow loads the image into kind before the Deployment points at it.
- **Transition:** “The architecture uses a deliberately small toolset.”

## 6. Technology stack
- Static HTML/CSS/JavaScript + Nginx Alpine.
- Docker image `gitops-demo-dashboard:v1.0.0`.
- Kubernetes/kind, Kustomize, Argo CD, GitHub.
- **Visual:** Actual Docker build (`03-docker-build.png`) and cluster screenshot (`04-kubernetes-cluster.png`).
- **Speaker notes:** Explain the matching non-`latest` tag and `imagePullPolicy: Never`.
- **Transition:** “The repository makes each responsibility inspectable.”

## 7. Repository implementation
- `app/`: dashboard and runtime-fetched release metadata.
- `docker/`: Nginx image and `/healthz`.
- `k8s/` + `argocd/`: desired runtime resources and Application.
- `scripts/` + `docs/`: reproducible commands and operator guidance.
- **Visual:** `01-project-structure.png` or actual `02-github-repository.png`.
- **Speaker notes:** The repository must be pushed before Argo CD can clone it.
- **Transition:** “Kubernetes receives the app through two clear resource types.”

## 8. Deployment and Service
- One Deployment replica with resource limits and HTTP probes.
- ClusterIP Service selects the dashboard Pod on port 8080.
- Namespace is consistently `gitops-demo`.
- **Visual:** Deployment/Service YAML alongside real `06-pods-ready.png`.
- **Speaker notes:** Probes call `/healthz`; `version.json` is app metadata, not health.
- **Transition:** “The controller now watches Git for a change.”

## 9. Live synchronization
- Argo CD displays sync status and workload health separately.
- Auto-sync, prune, self-heal, and bounded retry are configured.
- **Visual:** Actual `05-argocd-synced-healthy.png` (or truthful UI state if not healthy).
- **Speaker notes:** Show the source path, Git revision, and application name; do not expose credentials.
- **Transition:** “A versioned change makes the reconciliation path concrete.”

## 10. v1 → v2 release
- Change `version.json`; build and load the v2 image.
- Change Deployment tag; commit and push desired state.
- Wait for reconciliation and verify browser + Kubernetes.
- **Visual:** Actual `08-git-change-v2.png`, `09-argocd-sync-v2.png`, and `10-app-v2.png`.
- **Speaker notes:** A source-only push does not build a local image; image build/load precedes the Git image-reference change.
- **Transition:** “What did the exercise demonstrate, and what remains out of scope?”

## 11. Results, benefits, limitations, future work
- Results: reproducible local path, visible desired state, observable reconciliation—only claim what was actually run.
- Limits: local kind, static app, local image loading, no production auth/TLS/monitoring.
- Future: CI image build/publish and secure registry integration.
- **Visual:** Actual `11-final-verification.png`; otherwise an explicitly labeled architecture, not a fabricated result.
- **Speaker notes:** State unavailable tests honestly and identify why they were unavailable.
- **Transition:** “The final slide summarizes the responsibility boundary.”

## 12. Conclusion and references
- Git describes; Docker builds; Kubernetes runs; Argo CD reconciles.
- A pushed, reviewable manifest change can drive the deployment.
- References: official [Kubernetes](https://kubernetes.io/docs/), [kind](https://kind.sigs.k8s.io/), [Argo CD](https://argo-cd.readthedocs.io/en/stable/), [Docker](https://docs.docker.com/).
- **Visual:** Final architecture strip and real final screenshot if available.
- **Speaker notes:** Invite questions; distinguish demonstrated behavior from future production work.
