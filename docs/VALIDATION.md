# Validation record

This record describes commands actually run in the coding-agent environment, not a claimed end-to-end classroom deployment. The environment was Linux x86_64 with Bash, Git, Docker CLI/daemon, kubectl, kind, jq, yq, ShellCheck, Python 3, Make, and curl. A `gitops-demo` kind cluster was created for testing, used for the attempts described below, then explicitly removed with the cleanup script.

## Executed successfully

- `bash -n` for every `scripts/*.sh`.
- `shellcheck scripts/*.sh`.
- `make check` and `scripts/check-prerequisites.sh` (Bash syntax, ShellCheck, Kustomize rendering, and yq parsing of Kubernetes, Argo CD, and kind YAML).
- `scripts/build-image.sh` built `gitops-demo-dashboard:v1.0.0` using Docker and the multi-architecture Nginx unprivileged Alpine base.
- Docker smoke test ran the v1 image with a read-only root filesystem and a 16 MiB writable `/tmp`; Docker health became `healthy`, `/healthz` returned `ok`, `/version.json` reported v1.0.0, and `/` served the dashboard HTML.
- `scripts/setup-cluster.sh` created kind `gitops-demo`; its single node reached `Ready`.
- `scripts/load-image.sh` loaded v1.0.0 into the kind node and independently found the image with `crictl images`.
- `scripts/prepare-v2-release.sh source`, the version-derived v2 image build, `scripts/load-image.sh ...:v2.0.0`, and `scripts/prepare-v2-release.sh manifest` all completed in a guarded test. The temporary test restored the tracked `version.json` and Deployment manifest; no commit or push was made.

## Attempted but not successful

- The first client-side `scripts/install-argocd.sh` attempt failed because the current stable `applicationsets.argoproj.io` CRD exceeded the client-side apply annotation limit (262144 bytes). The installer was changed to official-manifest server-side apply. The manifest resources then applied, but Argo CD Pods entered `ImagePullBackOff`: the kind node could not resolve `cdn01.quay.io` (`lookup cdn01.quay.io ... server misbehaving`). The installer was still waiting for workload readiness when that DNS failure was diagnosed.
- After the v1 image was loaded, `kubectl apply -k k8s` created the Namespace, Deployment, and Service, but the Deployment rollout timed out. Nginx started and `kubectl exec` fetched `/healthz` successfully from `127.0.0.1`; kubelet HTTP probes to the Pod IP timed out, and a request to the Pod's own IP also timed out. The Pod later entered `CrashLoopBackOff` as liveness probes restarted it, so this is **not** a successful Kubernetes deployment.

## Not executed

- `scripts/deploy-argocd-app.sh` / `make deploy`, a ready Argo CD installation, the Argo CD UI/login, a successful Application sync, private repository auth, a ready v1 or v2 Kubernetes rollout, and `scripts/verify-deployment.sh` against a ready workload.
- No browser screenshots, Git commit, or Git push were produced. The successful local Docker smoke test and v2 image build/load are not proof of Kubernetes or Argo CD success.

No screenshot or successful Kubernetes/Argo CD result is fabricated. The observed failures above should be resolved in the student's environment before presenting runtime success.
