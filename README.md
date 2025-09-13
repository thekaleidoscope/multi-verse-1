# Multi‑Verse‑1: Unified App + Infra (Helm + Crossplane)

This repo contains a minimal microservice plus an "infra" Helm chart that deploys the app and declares cloud infrastructure using Crossplane CRDs (e.g., ECR repo and S3 bucket via a BucketClaim). It’s designed to pair with a platform repo (e.g., `zion`) that installs Crossplane/XRDs and provisions the cluster. Push once, and GitOps/Helm can update app and infra together.

## Branches
- main: baseline application and infra chart
- helm-module: Helm-only microservice packaging
- crossplane-modules: Helm-driven Crossplane resources included
- crossplane-crd: flows that rely on platform-provided XRD/Composition
- add-crossplane-crd, merge-infra-def: work-in-progress feature branches

Switch with `git checkout <branch>` to explore each stage.

## Layout
- infra/
  - Chart.yaml: umbrella chart
  - charts/: vendored packaged deps (tgz)
  - templates/: Crossplane resources (ECR repo, S3 BucketClaim)
  - values-dev.yaml, values-prod.yaml: per-env values
- src/: TypeScript app (built to `dist/`)
- Dockerfile: container build for the service

## Tools
- git: repo + branch workflows
- node + npm + TypeScript: build the app
- docker/buildx: build and push images
- helm: deploy the umbrella chart
- kubectl: inspect resources
- crossplane (in-cluster): provision cloud resources via CRDs

## Prerequisites
- Kubernetes cluster and kubeconfig
- Crossplane installed with AWS provider and a `ProviderConfig` named `aws-provider`
- XRD + Composition for S3 Bucket available in the cluster (from platform repo)
- Helm v3
- Docker with Buildx configured
- AWS credentials for ECR (OCI registry) and for Crossplane (via ProviderConfig)

## Build and Publish Image
- Install deps: `npm ci`
- Build app: `npm run build`
- Build & push image:
  - `REGISTRY=<account>.dkr.ecr.<region>.amazonaws.com`
  - `IMAGE_TAG=<git-sha or semver>`
  - `npm run deploy:image`

## Helm Deploy (Dev)
- If using OCI dependency in `infra/Chart.yaml`, login to ECR for Helm:
  - `aws ecr get-login-password --region <region> | helm registry login --username AWS --password-stdin <account>.dkr.ecr.<region>.amazonaws.com`
- Update or build deps:
  - `helm dependency build infra`  (uses `charts/*.tgz` and lock)
  - or `helm dependency update infra` (pulls from OCI registry if configured)
- Install/upgrade:
  - `helm upgrade -i mv1-dev infra -f infra/values-dev.yaml -n mv1-dev --create-namespace`
- Verify:
  - `kubectl get deploy,svc -n mv1-dev`
  - `kubectl get repositories.ecr.aws.upbound.io -A` (ECR repo)
  - `kubectl get bucketclaims.zion.com -A` (S3 BucketClaim)

## Helm Deploy (Prod)
- `helm upgrade -i mv1-prod infra -f infra/values-prod.yaml -n mv1-prod --create-namespace`

## Crossplane Resources in This Chart
- ECR Repository (`infra/templates/ecr.yaml`): creates an AWS ECR repo for the service image
- S3 BucketClaim (`infra/templates/s3.yaml`): requests a bucket using an XRD/Composition installed by the platform

## Typical Flow
1) Dev modifies app code or infra values in one PR
2) Merge triggers GitOps/ArgoCD or a pipeline to sync Helm
3) Crossplane reconciles cloud resources; deployment rolls forward
4) Rollback = revert the commit → GitOps reconciles back