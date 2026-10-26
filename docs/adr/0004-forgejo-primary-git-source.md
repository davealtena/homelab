# 4. Forgejo as the primary Git source, GitHub as push-mirror

- Status: accepted
- Date: 2026-10-26

## Context

The repo lived on GitHub (Flux source, GitHub Actions, Mend Renovate app).
Forgejo already runs in the cluster behind Kanidm. The goal is to own the
source of truth and the CI/dependency tooling without giving up the public
GitHub copy.

## Decision

- Forgejo `dave/homelab` is the only write target. Flux reads it in-cluster
  (`http://forgejo-http.selfhosted.svc.cluster.local:3000/dave/homelab.git`,
  public repo, no credentials).
- A Forgejo push-mirror (`sync_on_commit`, branch `main`) keeps
  `github.com/davealtena/homelab` identical. Nothing writes to GitHub directly.
- CI runs on Forgejo Actions with one in-cluster runner that executes jobs as
  Kubernetes Jobs (runner-k8s-plugin); no Docker-in-Docker, no privileged pods.
- Dependency updates come from renovate-operator (mogenius) with a `renovate`
  bot user; `platformAutomerge` + `automergeType: pr` replace the GitHub app.

## Consequences

- Circular bootstrap: Flux deploys Forgejo but reads from it. A cold rebuild
  starts from the GitHub mirror (switch `sync.url`, bootstrap, switch back).
- Forgejo's PVC is backed up by kopiur; GitHub is the second full copy of the
  history. Losing both the NVMe and the NAS repo still leaves GitHub.
- Actions `uses:` references are full `https://github.com/...@sha` URLs so
  Renovate keeps pinning digests.
