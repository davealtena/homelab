---
name: add-app
description: Scaffold a new Flux application in this home-ops repo's conventions (ks.yaml + app/{ocirepository,helmrelease,kustomization}, optional externalsecret). Use when adding a new app under kubernetes/apps.
---

# Add a new application

Scaffolds an app under `kubernetes/apps/<namespace>/<app>/` matching this repo's layout.

## Assumptions (this repo)

- Single cluster `valhalla`; apps are aggregated by the `cluster-apps` Flux Kustomization (`kubernetes/flux/cluster/ks.yaml`, path `./kubernetes/apps`).
- Per-app files: `<ns>/<app>/ks.yaml` + `<ns>/<app>/app/{ocirepository,helmrelease,kustomization}.yaml` (+ `externalsecret.yaml` when secrets are needed).
- Most apps use the bjw-s `app-template` chart sourced via an `OCIRepository`.
- Secrets come from 1Password via `ExternalSecret` (ClusterSecretStore `onepassword-connect`).
- Schema headers use `https://k8s-schemas.bjw-s.dev/...`.
- Storage: `ceph-block` (RWO, default) or `ceph-filesystem` (RWX).

## Steps

1. **Gather inputs** (use the AskUserQuestion tool): app name; namespace (e.g. `media`, `downloads`, `selfhosted`); image repo + tag/digest; primary port; needs ExternalSecret?; needs persistence (which storageClass)?; needs an Envoy Gateway route (hostname)?; any Flux `dependsOn`.
2. **Copy an existing nearby app** as the template (e.g. another app in the same namespace) — match its file layout, schema headers, and field style. Do not invent fields.
3. `ks.yaml` — Flux Kustomization: `metadata.name: &app <app>` / `namespace: flux-system`, `targetNamespace: <ns>`, `path: ./kubernetes/apps/<ns>/<app>/app`, `sourceRef` GitRepository flux-system, `healthChecks` on the HelmRelease, `wait: true`, `dependsOn` as needed.
4. `app/ocirepository.yaml` — chart source, `ref.tag` pinned to an explicit version.
5. `app/helmrelease.yaml` — `chartRef` → the OCIRepository; configure controllers/containers/service/route/persistence.
6. `app/kustomization.yaml` — list the resources (`./ocirepository.yaml`, `./helmrelease.yaml`, `./externalsecret.yaml`).
7. (If secrets) `app/externalsecret.yaml` — 1Password-backed; reference via `envFrom: secretRef` in the HelmRelease.
8. **Wire it in:** add the new app's `ks.yaml` to the namespace `kustomization.yaml` (create the namespace dir + `kustomization.yaml` + `namespace.yaml`/component if the namespace is new).
9. **Validate:** `kubectl kustomize kubernetes/apps/<ns>` builds cleanly; schema headers present. Commit on a branch (conventional commit + `--signoff`) and open a PR.

After merge: `flux reconcile source git flux-system` then `flux reconcile kustomization <app>`.
