# Roadmap

Where this lab is heading, in order. The goal is to run the cluster the way
[bjw-s-labs/home-ops](https://github.com/bjw-s-labs/home-ops) and
[onedr0p/home-ops](https://github.com/onedr0p/home-ops) do — same patterns,
not the same apps — while keeping the deliberate differences recorded in
`docs/adr/`. Items are ordered by value; each is small enough for one PR
unless noted. Tick them off as they merge.

## Done

- [x] Flux-operator + OCIRepository charts, app-template, Envoy Gateway, Cilium
      L2, External Secrets + 1Password, kube-prometheus-stack + VictoriaLogs,
      Kanidm SSO, Renovate with upstream label/semantic-commit layout.
- [x] mise for tooling and ops tasks (replaced go-task) — #2183, #2184.
- [x] Flux error events → Alertmanager → Pushover — #2186.
- [x] gatus + gatus-sidecar status page with auto HTTPRoute checks — #2186.
- [x] smartctl-exporter with SMART alert rules — #2186.
- [x] ADR-0002 storage tiering + backup, ADR-0003 external access, OpenTofu
      for Hetzner — #2185.

## Next (no Hetzner account needed)

1. **kopiur + snapshot-controller + `components/kopiur`** (ADR-0002).
   `ClusterRepository` on the Synology over NFS; per-app `SnapshotPolicy` +
   `SnapshotSchedule` via a component. Pilot: Paperless → OpenEBS, snapshot,
   **restore test**. Then the other SQLite apps one by one (Home Assistant,
   Actual, Mealie, Jellyseerr, \*arr, Forgejo), then CNPG (`pg_dump` pre-hook
   replaces the backup CronJob). Last: drop the default annotation from
   `nfs-csi-sc`.
2. **Cluster side of external access** (ADR-0003): `envoy-external` Gateway
   on 192.168.1.131, `ClientTrafficPolicy` with PROXY protocol,
   `CiliumNetworkPolicy` limiting the proxied listener to the WireGuard peer,
   Let's Encrypt DNS-01 cert, `external-dns` (Cloudflare) publishing only
   external hostnames. Testable from the LAN before the VPS exists.
3. **`nixos/hosts/deimos`**: WireGuard, forwarder with PROXY protocol v2,
   nftables, hardened sshd, sops-nix for the WG key. `nix build` locally;
   `nixos-anywhere` once the VPS has an IP.
4. **Flux layout → bjw-s**: `namespace:` in each namespace kustomization so
   Flux `Kustomization` objects live in their app namespace, plus a
   `components/namespace` for the Namespace object. Enables per-namespace
   components (flux-alerts becomes one again). *Migration, not a tweak*: do
   it per namespace with `prune: false` or `flux suspend` so GC of the old
   Kustomization in `flux-system` cannot take resources with it.
5. **konflate** replaces the hand-rolled `flux-diff.yaml` (same maintainers
   as flate; renders + comments the diff). **lefthook** + yamlfmt/yamllint
   pre-commit.
6. **anubis** component for bot protection on external routes — do together
   with item 2 so no route goes external without it.
7. **dragonfly-operator** for Redis-shaped caches (Paperless currently runs a
   bare redis pod).

## Blocked on the Hetzner account

8. Account, project, 2FA, API token, two S3 key pairs → 1Password
   (`infrastructure/hetzner/README.md`). `mise run tofu:apply`.
9. `nixos-anywhere` deimos; WireGuard up; Cloudflare DNS → VPS IP; first
   external route end-to-end → ADR-0003 status *accepted*.
10. kopiur `RepositoryReplication` → Hetzner Object Storage (the off-site
    copy). Then move tofu state into the `tofu-state` bucket.

## Later / only if a reason appears

- **Additional nodes** (3-node control plane, replicated storage via miroir,
  Spegel). Only when the single node becomes a real problem; two cheap
  nodes for quorum beat a second big one.
- **renovate-operator** in-cluster instead of the GitHub app.
- **k3s version bumps via Renovate** on the NixOS flake input + a rebuild
  flow (the Talos/tuppr equivalent for ADR-0001).

## Deliberately not doing

- Rook-Ceph / miroir on one node (ADR-0002).
- Cloudflare Tunnel (ADR-0003) — revisit only if the VPS becomes a burden.
- Talos (ADR-0001).
