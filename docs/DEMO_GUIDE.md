# Live demo: v1.0.0 to v2.0.0

## Before presenting

Complete `docs/SETUP.md` and make sure the repository and current manifests are pushed to GitHub. Keep three terminals handy:

1. Dashboard browser forward: `kubectl --context kind-gitops-demo -n gitops-demo port-forward svc/gitops-demo-dashboard 8080:8080`
2. Argo CD browser forward: `kubectl --context kind-gitops-demo -n argocd port-forward svc/argocd-server 8081:443`
3. Commands: `make verify` or `scripts/verify-deployment.sh --port-forward`

Show the app at [http://localhost:8080](http://localhost:8080), Argo CD at [https://localhost:8081](https://localhost:8081), and real status from `kubectl`/Argo CD. The page status badge is deliberately labeled presentation metadata; it is not a live health endpoint.

## Explain the v1 release

```sh
git status --short --branch
docker image ls gitops-demo-dashboard
kubectl --context kind-gitops-demo -n gitops-demo get deploy,pods,svc,endpoints
kubectl --context kind-gitops-demo -n argocd get application gitops-demo-dashboard
scripts/verify-deployment.sh --port-forward
```

The initial release is `v1.0.0`, image `gitops-demo-dashboard:v1.0.0`, and Deployment uses `imagePullPolicy: Never`. Point out the three responsibility boundaries: Git stores desired Kubernetes state, Docker builds the image, and Argo CD reconciles resources in Kubernetes.

## Safely prepare v2

The helper is intentionally two-step. Run it from the project root and review its changes:

```sh
scripts/prepare-v2-release.sh source
git diff -- app/version.json
```

This changes the release title, version, release identifier, notes, date, and history in `version.json`; the browser loads these values at runtime. It refuses to overwrite metadata that is not currently v1.0.0.

Build and load the v2 image **before** changing desired state:

```sh
scripts/build-image.sh gitops-demo-dashboard:v2.0.0
scripts/load-image.sh gitops-demo-dashboard:v2.0.0
```

Now change the tracked Deployment reference:

```sh
scripts/prepare-v2-release.sh manifest
git diff -- app/version.json k8s/deployment.yaml
```

Commit and push both changes to the branch watched by Argo CD (normally `main`):

```sh
git add app/version.json k8s/deployment.yaml
git commit -m "Release dashboard v2.0.0"
git push origin main
```

The local helper never makes a commit or push. Source-only pushes do not build an image; they cannot replace a locally loaded image. For this local cluster, the v2 tag must already exist inside kind before the manifest changes to it.

## Observe synchronization

Refresh the Argo CD Application UI or inspect from the command terminal:

```sh
kubectl --context kind-gitops-demo -n argocd get application gitops-demo-dashboard -w
kubectl --context kind-gitops-demo -n gitops-demo get pods -w
```

Argo CD normally polls Git periodically. To request a sync now, use the Application UI's **Sync** action. If installed, the optional CLI can use `argocd app sync gitops-demo-dashboard` after login. Automated sync is configured, so manual sync is not normally necessary. Wait for `Synced` and `Healthy`, and for the Deployment rollout to finish:

```sh
kubectl --context kind-gitops-demo -n gitops-demo rollout status deployment/gitops-demo-dashboard --timeout=120s
scripts/verify-deployment.sh --port-forward
```

Refresh the browser with a cache bypass if needed; confirm the badge, release ID, summary, and history say v2.0.0. This is genuine runtime status only if you actually ran the commands against your cluster; the dashboard's card remains static metadata.

## Rollback

If the v2 image was loaded and the release commit has been pushed, revert that Git commit and push the revert:

```sh
git revert <v2-release-commit>
git push origin main
```

The revert restores both v1 metadata and the v1 Deployment image reference. The v1 image must still be loaded in kind; if it was removed, rebuild and load it first. Argo CD will reconcile back to the reverted Git state. Never delete resources manually as a substitute for changing desired state.

For a failed local exercise, inspect events/logs before retrying:

```sh
kubectl --context kind-gitops-demo -n gitops-demo describe pod
kubectl --context kind-gitops-demo -n gitops-demo logs deployment/gitops-demo-dashboard
kubectl --context kind-gitops-demo -n argocd describe application gitops-demo-dashboard
```
