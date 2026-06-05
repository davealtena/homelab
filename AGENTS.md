# Home Operations — Agent Guide

Single-cluster home Kubernetes monorepo, GitOps with Flux. Cluster: `valhalla`.
This file is the source of truth for AI agents working in this repo (Claude Code
reads it via `CLAUDE.md`, which imports it). General, stack-agnostic working
standards live in the user's global config and also apply.

## Layout

```
kubernetes/
├── apps/<namespace>/<app>/   # applications (Flux-managed)
├── components/               # reusable kustomize components
├── flux/                     # Flux entrypoint; flux/cluster/ks.yaml defines the
│                             #   `cluster-apps` Kustomization (path ./kubernetes/apps,
│                             #   SOPS-decrypted, dependsOn cluster-secrets)
└── bootstrap/                # bootstrap
talos/                        # Talos Linux machine configs
.taskfiles/ + Taskfile.yaml   # go-task ops (flux, kubernetes, sops, talos, bootstrap)
renovate.json5                # Renovate config
age.key                       # SOPS age key (do not commit secrets in plaintext)
```

## Stack

| Area          | Tool                                                              |
| ------------- | ---------------------------------------------------------------- |
| GitOps        | Flux (OCIRepository-sourced Helm charts)                         |
| CI            | Renovate + GitHub Actions                                       |
| Charts        | bjw-s `app-template` for most apps                              |
| Storage       | Rook/Ceph — `ceph-block` (RWO, default), `ceph-filesystem` (RWX) |
| Backups       | VolSync + Kopia                                                 |
| Secrets       | External Secrets + 1Password (ClusterSecretStore `onepassword-connect`); SOPS (age) for in-git secrets |
| Observability | Metrics: kube-prometheus-stack (Prometheus/Alertmanager); Logs: VictoriaLogs; alerts via PrometheusRule → Alertmanager → Pushover |
| Network       | Cilium, Envoy Gateway, external-dns                            |

## App conventions

Each app: `kubernetes/apps/<ns>/<app>/ks.yaml` + `.../app/{ocirepository,helmrelease,kustomization}.yaml` (+ `externalsecret.yaml` when secrets are needed; optional `app/resources/`).

- YAML LSP schema header right under `---`, e.g. `# yaml-language-server: $schema=https://k8s-schemas.bjw-s.dev/...`.
- `OCIRepository.spec.ref.tag` pinned to an explicit version (Renovate bumps via PR).
- `HelmRelease.spec.chartRef` → the OCIRepository; app-template apps configure `values.controllers/containers/service/route/persistence`.
- `ExternalSecret` pulls from 1Password (`remoteRef.key: <1pw item>`), consumed via `envFrom: secretRef` or `valueFrom`.
- `ks.yaml`: `metadata.name: &app <name>`, `targetNamespace`, `healthChecks`, `wait: true`, `dependsOn` where ordering matters.
- New app → also add its `ks.yaml` to the namespace `kustomization.yaml`. See the `add-app` skill.

## Common operations

- Reconcile: `flux reconcile source git flux-system` then `flux reconcile kustomization <name>` or `flux reconcile hr <name> -n <ns>`.
- Status: `flux get kustomizations -A`, `flux get hr -A`.
- go-task: `task flux:*`, `task kubernetes:*`, `task sops:*`, `task talos:*`.
- Prefer GitOps over live `kubectl` changes; if a live change is needed for triage, reconcile it back into Git.

## Repo-specific notes

Non-obvious "why is it like this" facts you can't infer from a single file:

- **CSI driver RBAC** comes from the separate `ceph-csi-drivers` HelmRelease (`apps/rook-ceph/ceph-csi-drivers`), not the rook chart — required since rook 1.20. Don't remove it.

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

- Internal `*.svc.cluster.local` URLs, ClusterIP endpoints, or private RFC1918 IPs. CI
  runs on the in-cluster `homelab-runner`, so these ARE reachable — never say "internal
  URL not reachable from CI/GitHub".
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
