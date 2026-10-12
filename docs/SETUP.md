# Setup guide

This guide assumes a Bash terminal, an existing GitHub repository, Docker, kubectl, and kind. `make setup` needs Internet access to download kind node images and the official Argo CD installation manifest and images.

## 1. Push the project to GitHub

Argo CD clones Git; it cannot sync an unpushed local filesystem. Create an empty GitHub repository (do not initialize a second README/license if this project already has them), then from this project directory configure `origin` if needed. For the usual main-branch workflow:

```sh
git status --short --branch
git remote -v
git remote add origin https://github.com/OWNER/REPOSITORY.git  # only if origin is not configured
git branch -M main
git push -u origin main
```

If `origin` already exists, confirm it is the intended GitHub repository instead of adding it again. If your current branch is not `main`, either push it and later pass that branch as `GIT_REVISION`, or merge it into `main` and push `main`. Do not set up Argo CD to point at a repository that has not been pushed.

## 2. Configure the repository URL

Set the clone URL, not a web page URL. HTTPS example:

```sh
export GIT_REPO_URL=https://github.com/OWNER/REPOSITORY.git
```

SSH is also accepted:

```sh
export GIT_REPO_URL=git@github.com:OWNER/REPOSITORY.git
```

Replace both uppercase path segments with the owner and repository. `argocd/application.yaml` intentionally contains a conspicuous placeholder. `scripts/deploy-argocd-app.sh` renders the real URL to a temporary file, applies it, then removes the temporary file; the tracked placeholder is not edited. The script rejects unresolved placeholders and non-GitHub URL formats.

## 3. Install/check tools

Required for the complete local exercise: Bash, Git, Docker CLI **and a running Docker daemon**, kubectl, kind, and Python 3 (used for safe temporary manifest rendering and the v2 helper). `jq`, `yq`, ShellCheck, and the `argocd` CLI are optional. The `argocd` CLI is not needed to deploy or inspect the project.

```sh
make check
scripts/check-prerequisites.sh
```

`make check` performs static checks and needs no running cluster. The prerequisite script additionally reports host OS, architecture, CPU, memory, required tools, and optional tools. To build during the prerequisite check, use `scripts/check-prerequisites.sh --docker-build`.

- **macOS / Apple Silicon:** Install Docker Desktop for Mac and enable its Linux container engine; install current kubectl and kind. The Nginx unprivileged Alpine base supports multi-architecture images, including Apple Silicon. Docker Desktop resources must leave enough memory for the cluster and Argo CD.
- **Linux:** Install Docker Engine and ensure your account can access the daemon, then install kubectl and kind. If Docker permission changes require a new login, start a new shell.
- **Windows:** Use WSL2 with a supported Linux distribution and Docker Desktop integration, then run the project commands inside WSL. Keep the repository in the WSL filesystem for better file performance. Use a Windows browser with the forwarded localhost port.

Install references: [Docker](https://docs.docker.com/get-docker/), [kubectl](https://kubernetes.io/docs/tasks/tools/), [kind](https://kind.sigs.k8s.io/docs/user/quick-start/).

## 4. Create the local cluster and install Argo CD

```sh
scripts/setup-cluster.sh
scripts/install-argocd.sh
```

`make setup` runs prerequisites plus these two steps. It reuses a kind cluster named `gitops-demo` if it exists, otherwise creates it. Argo CD install uses the official stable manifest URL. Pin a version by setting `ARGOCD_VERSION=vX.Y.Z`, or configure `ARGOCD_INSTALL_URL` to an official `raw.githubusercontent.com/argoproj/argo-cd/.../manifests/install.yaml` URL. Waits are bounded (default five minutes for Argo workloads).

## 5. Build and load the image

```sh
make build
make load
```

The default tag comes from `app/version.json`, initially `gitops-demo-dashboard:v1.0.0`. `imagePullPolicy: Never` requires the same non-`latest` image tag to be loaded into kind. A custom image tag can be supplied to both scripts, but then the Deployment manifest must refer to that exact tag before sync.

## 6. Create the Argo CD Application

After pushing the `k8s/` manifests and ensuring the repository is accessible to Argo CD:

```sh
export GIT_REPO_URL=https://github.com/OWNER/REPOSITORY.git
make deploy
```

`make deploy` builds and loads the image derived from `app/version.json`, idempotently installs Argo CD, and applies the rendered Application. It requires the cluster from `make setup`. The rendered Application targets `main` by default. For another ref, run `scripts/deploy-argocd-app.sh --revision BRANCH`; set `GIT_REVISION` in your shell to pass a revision when invoking the script. Verify that this revision exists remotely. This step neither pushes Git nor proves the remote repository credentials work.

### Private repositories

For a private repo, grant Argo CD read-only access using the official [private repository credential guidance](https://argo-cd.readthedocs.io/en/stable/user-guide/private-repositories/). Prefer a dedicated read-only deploy key or fine-grained token with only repository contents read access. Never put a token or private key in Git, the Application YAML, screenshots, or shared logs.

One interactive local pattern avoids embedding credentials in command arguments or shell history. It creates short-lived permission-restricted files and streams a Kubernetes Secret to the API; adapt this only for a trusted local cluster:

```bash
umask 077
secret_dir="$(mktemp -d)"
trap 'rm -rf "$secret_dir"; unset repo_user repo_password' EXIT
read -r -p "GitHub username: " repo_user
read -r -s -p "Read-only token/password: " repo_password; printf '\n'
printf '%s' 'https://github.com/OWNER/REPOSITORY.git' >"$secret_dir/url"
printf '%s' "$repo_user" >"$secret_dir/username"
printf '%s' "$repo_password" >"$secret_dir/password"
unset repo_password
kubectl --context kind-gitops-demo -n argocd create secret generic gitops-demo-repo \
  --from-file="$secret_dir" --dry-run=client -o yaml |
  kubectl --context kind-gitops-demo apply -f -
kubectl --context kind-gitops-demo -n argocd label secret gitops-demo-repo \
  argocd.argoproj.io/secret-type=repository --overwrite
rm -rf "$secret_dir"; trap - EXIT
unset repo_user
```

The script only matches an Argo CD repository by URL and does not expose credentials in the URL. Delete the Secret when no longer needed. For shared/production clusters, use the organization’s approved secret manager and access policy instead.

## 7. Open the app and Argo CD

In a terminal, forward the dashboard Service:

```sh
kubectl --context kind-gitops-demo -n gitops-demo port-forward svc/gitops-demo-dashboard 8080:8080
```

Open [http://localhost:8080](http://localhost:8080). Stop forwarding with Ctrl-C.

In a separate terminal, forward the Argo CD UI:

```sh
kubectl --context kind-gitops-demo -n argocd port-forward svc/argocd-server 8081:443
```

Open [https://localhost:8081](https://localhost:8081), accept the local self-signed certificate warning, and sign in as `admin`. Retrieve the initial password in a private terminal:

```sh
kubectl --context kind-gitops-demo -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d; echo
```

Do not publish the value or place it in Git. Rotate/delete the initial secret according to the Argo CD documentation after the demo.

## Optional: use an image registry instead

The default demo intentionally loads an image directly into kind and uses `imagePullPolicy: Never`. For a registry workflow, authenticate to a registry, push an immutable tagged image, update the Deployment to that registry-qualified tag, and change the pull policy to `IfNotPresent` (or `Always` only for a consciously mutable tag). Configure private registry credentials securely as an image pull secret. Do not mix this path with the local `Never` policy.
