# Home Operations — Agent Guide

Single-node home Kubernetes cluster, GitOps with Flux. Node: `phobos`, cluster
`society`, running on NixOS + k3s. This file is the source of truth for AI agents
working in this repo (Claude Code reads it via `CLAUDE.md`, which imports it).
General, stack-agnostic working standards live in the user's global config and
also apply.

## Layout

```
kubernetes/clusters/phobos/
├── apps/<namespace>/<app>/   # applications (Flux-managed)
└── flux/                     # Flux entrypoint; flux/ks.yaml defines the
│                             #   `phobos-apps` Kustomization (path ./apps,
│                             #   SOPS-decrypted, substituteFrom cluster-settings + cluster-secrets)
nixos/                        # NixOS flake for the phobos host (k3s, Cilium, networking)
.taskfiles/ + Taskfile.yaml   # go-task ops (bootstrap, flux, kubernetes, sops)
.sops.yaml                    # SOPS age creation rules (phobos key)
```

## Stack

| Area          | Tool                                                              |
| ------------- | ---------------------------------------------------------------- |
| Host          | NixOS 26.05 flake → single-node k3s (flannel/kube-proxy/servicelb/traefik/local-storage disabled) |
| GitOps        | Flux (flux-operator + OCIRepository-sourced Helm charts)         |
| CI            | Renovate + GitHub Actions                                       |
| Charts        | bjw-s `app-template` for most apps                              |
| Network       | Cilium (kube-proxy replacement, L2 announcements), Envoy Gateway, external-dns, Cloudflare Tunnel |
| Storage       | csi-driver-nfs → Synology NFS (`nfs-csi-sc`, default); OpenEBS hostpath (local NVMe) |
| Backups       | Synology-native (PVCs live on the NAS) + nightly CNPG logical dump to the NAS |
| Secrets       | External Secrets + 1Password (ClusterSecretStore `onepassword`); SOPS (age) for in-git secrets |
| Observability | Metrics: kube-prometheus-stack (Prometheus/Alertmanager); Logs: VictoriaLogs; Dashboards: Grafana (grafana-operator); badges: kromgo |

## App conventions

Each app: `kubernetes/clusters/phobos/apps/<ns>/<app>/ks.yaml` + `.../app/{ocirepository,helmrelease,kustomization}.yaml` (+ `externalsecret.yaml` when secrets are needed; optional `app/resources/`).

- YAML LSP schema header right under `---`, e.g. `# yaml-language-server: $schema=https://k8s-schemas.bjw-s.dev/...`.
- `OCIRepository.spec.ref.tag` pinned to an explicit version (Renovate bumps via PR).
- `HelmRelease.spec.chartRef` → the OCIRepository; app-template apps configure `values.controllers/containers/service/route/persistence`.
- `ExternalSecret` pulls from 1Password (`remoteRef.key: <1pw item>`) via ClusterSecretStore `onepassword`, consumed via `envFrom: secretRef` or `valueFrom`.
- `ks.yaml`: `metadata.name: &app <name>`, `targetNamespace`, `healthChecks`, `wait: true`, `dependsOn` where ordering matters.
- New app → also add its `ks.yaml` to the namespace `kustomization.yaml`. See the `add-app` skill.

## Common operations

- Reconcile: `flux reconcile source git flux-system` then `flux reconcile kustomization <name>` or `flux reconcile hr <name> -n <ns>`.
- Status: `flux get kustomizations -A`, `flux get hr -A`.
- go-task: `task bootstrap:*` (nixos/cilium/flux), `task flux:*`, `task kubernetes:*`, `task sops:*`.
- Host changes: edit `nixos/`, then `task bootstrap:nixos` (rsync + `nixos-rebuild switch --flake .#phobos`).
- Prefer GitOps over live `kubectl` changes; if a live change is needed for triage, reconcile it back into Git.

## Repo-specific notes

Non-obvious "why is it like this" facts you can't infer from a single file:

- **Cilium is bootstrapped imperatively then adopted by Flux.** CNI must exist before Flux; the running values live in `apps/kube-system/cilium/app/helm-values.yaml` and are re-installed by `task bootstrap:cilium`. L2 announcements advertise the Envoy gateway LB IPs (.130/.131) on the LAN.
- **csi-driver-nfs has fsGroupPolicy disabled** (`feature.enableFSGroupPolicy: false`). NFS + kubelet's recursive fsGroup chown chokes on special files; apps run as their own UID and the restored data already owns the right UID. The CSIDriver object is immutable — changing this needs a delete + recreate.
- **Flux postBuild `substituteFrom`** (cluster-settings + cluster-secrets) runs envsubst over every manifest. Shell `${VAR}` in a manifest (e.g. a CronJob script) must be escaped as `$${VAR}` or Flux replaces it with an empty string.
- **DB backups**: the CNPG cluster has no object store, so a nightly CronJob dumps globals + per-db (`apps/databases/cnpg/cluster/backup-cronjob.yaml`) to a Synology NFS PVC.

## Conventions reminder

- Conventional commits + `--signoff` (`-s`).
- When adding/changing an app, copy the structure and schema headers of a nearby existing app rather than inventing fields.
- Verify against authoritative docs / proven references before hand-rolling config; cite the source.

## PR Review Standards

Instructions for the AI PR reviewer. It sees the **PR diff, the PR description, and this
file**. For dependency-bot PRs (Renovate) the description embeds upstream release
notes/changelogs — use them to judge whether a bump is breaking. Routine bumps
auto-merge and are skipped; only **gated** bot PRs reach the reviewer (majors +
cluster-critical charts, labeled `review/required`). Be quiet unless there's a real
problem; only `critical`/`high` fail the check. Default to silence over nitpicking.

**Flag (high-value, evaluable from the diff):**

- **Leaked secrets** → `critical`. Any plaintext credential/token/key/password added
  inline. Secrets MUST be `external-secrets` (1Password) or SOPS-encrypted. A SOPS
  ciphertext blob or an `ExternalSecret`/`*SecretStore` reference is correct, not a leak.
- **Security/privilege relaxations** → `high`. `privileged: true`, `hostNetwork`/`hostPID`,
  dropping a `securityContext`/`readOnlyRootFilesystem`, loosening a Pod Security
  Admission label (e.g. `restricted` → `privileged`), or broad RBAC (`cluster-admin`,
  `*` verbs/resources) — unless the diff/commit gives a clear reason.
- **Broken GitOps structure** → `high`. A new app missing its `ks.yaml` (or not wired
  into the namespace `kustomization.yaml`), a HelmRelease/OCIRepository with an unpinned
  version/tag, or a missing/wrong schema header. Note: GitHub Actions pinned by commit
  SHA (e.g. `uses: actions/foo@abc1234 # v2`) is correct and intentional — Renovate is
  configured with `helpers:pinGitHubActionDigests`. Never flag SHA-pinned Actions.
- **Breaking / data-loss changes** → `high` (or `critical` for data loss). Removing or
  renaming a resource others depend on, API-version or CRD changes, deleting a PVC, or
  changing a StorageClass / reclaim policy.
- **Correctness bugs in changed lines** → severity to taste. YAML that won't parse,
  wrong namespace/selector, typo'd image ref.

**Do NOT flag (known-good here — avoids false positives):**

- Internal `*.svc.cluster.local` URLs, ClusterIP endpoints, or private RFC1918 IPs.
- "This won't take effect" — changes apply via Flux after merge; that's expected.
- Missing CPU/memory limits or requests — a style preference here, not a blocker.
- `install.crds: CreateReplace` or `upgrade.crds: CreateReplace` on a HelmRelease — this
  is the standard pattern here for charts that ship CRDs (kube-prometheus-stack, cert-manager,
  etc.). Do not flag it as a downtime or conflict risk.
- CRD availability concerns when a chart installs its own CRDs (`crds.enabled: true` or
  `install.crds: CreateReplace`). If the chart itself brings the CRD, it is always present
  by the time the CR is applied.
- Removing stale configuration (old paths, unused references, obsolete keys) — this is
  cleanup, not a security or correctness issue. Specifically: removing a `key_file` pointing
  to a non-existent path is safe cleanup, not secret exposure.
- Soft runtime dependencies between services (e.g. "X needs Y to be running first"). Flux
  `dependsOn` handles hard ordering; soft dependencies like a metrics scrape endpoint being
  unavailable temporarily are not blocking issues.
- A finding you immediately contradict in the same sentence (e.g. "X is missing — but the
  PR already adds it"). If the diff fixes the issue, do not raise it as a finding.
