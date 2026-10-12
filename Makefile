SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

.PHONY: help check setup build load deploy verify demo cleanup

help:
	@printf '%s\n' \
	  'GitOps Demo Dashboard commands:' \
	  '  make check    Static checks (Bash syntax and Kubernetes YAML rendering)' \
	  '  make setup    Check host, create/reuse kind, install Argo CD (Internet required)' \
	  '  make build    Build the image tag from app/version.json' \
	  '  make load     Load that image into kind' \
	  '  make deploy   Build/load image, install Argo CD, and apply the app; requires GIT_REPO_URL' \
	  '  make verify   Check rollout, Service, endpoints, image, and Argo status' \
	  '  make demo     Print safe demo commands and browser port-forward instructions' \
	  '  make cleanup  Interactively confirm each destructive cleanup action'

check:
	@scripts/check-prerequisites.sh --static-only

setup:
	@scripts/check-prerequisites.sh
	@scripts/setup-cluster.sh
	@scripts/install-argocd.sh

build:
	@scripts/build-image.sh

load:
	@scripts/load-image.sh

deploy:
	@test -n "$${GIT_REPO_URL:-}" || { echo 'Error: export GIT_REPO_URL=https://github.com/OWNER/REPOSITORY.git first.' >&2; exit 1; }
	@scripts/build-image.sh
	@scripts/load-image.sh
	@scripts/install-argocd.sh
	@scripts/deploy-argocd-app.sh

verify:
	@scripts/verify-deployment.sh

demo:
	@scripts/run-demo.sh

cleanup:
	@scripts/cleanup.sh
