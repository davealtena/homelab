# 3. External access: a Hetzner edge VPS with WireGuard + PROXY protocol

- Status: proposed
- Date: 2026-10-02

## Context

The cluster currently exposes services only on the LAN through a single
Gateway API `Gateway` (`envoy-internal`, 192.168.1.130). A second LB IP
(192.168.1.131) is reserved but unused, and there is no tunnel or port
forward. The household wants selected services (Paperless, Mealie, Actual,
Home Assistant, Forgejo) reachable from outside without a VPN, with Kanidm
OIDC in front as it already is internally.

The home connection sits behind CG-NAT-like constraints and a residential
IP, so "just port-forward" is not an option and would expose the home IP
anyway. Realistic ways in:

- **Cloudflare Tunnel** (what onedr0p/home-ops uses). `cloudflared` runs in
  the cluster, no inbound ports, free. Downsides: Cloudflare terminates TLS
  and sees all traffic, 100 MB upload limit on the free plan, HTTP(S) only
  (no SSH for Forgejo, no raw TCP), and the real client IP only arrives via
  Cloudflare headers.
- **Edge VPS + WireGuard + PROXY protocol** (what bjw-s-labs/home-ops does
  with its `icarus` host). A small VPS terminates nothing: it forwards
  TCP 443 (and optionally 22 for Git over SSH) over a WireGuard tunnel to an
  `envoy-external` Gateway in the cluster, wrapping connections in PROXY
  protocol so Envoy sees the real client IP. TLS stays end-to-end inside the
  cluster (cert-manager). Costs a few euros a month and a second host to
  manage.
- **Pangolin / Twingate-style tunnel products.** Package the VPS pattern with
  their own auth and dashboard. Faster to start, but duplicates Kanidm SSO,
  bypasses the Gateway API model everything else uses, and adds a vendor.
- **Tailscale only.** Excellent for the maintainer's own devices, useless for
  sharing a link with a family member or an Android share-sheet.

Hetzner is chosen as the provider because the backup target (ADR-0002) is
Hetzner Object Storage: one account, one bill, European data centres with
low latency to NL.

## Decision

Run a **Hetzner Cloud VPS (`deimos`, NixOS)** as a dumb edge:

```
Internet ──443──▶ deimos (Hetzner, NixOS)
                   nftables/HAProxy, PROXY protocol v2
                   WireGuard ──▶ 192.168.1.131 (Cilium L2 LB IP)
                                   Gateway envoy-external
                                     listeners: https-proxy (PROXY protocol), ssh (Forgejo)
                                     TLS: cert-manager, Let's Encrypt DNS-01
                                     HTTPRoutes: only the explicitly external apps
```

- **Infrastructure** (VPS, firewall, SSH key, S3 buckets) is declared with
  **OpenTofu** under `infrastructure/hetzner/`. Hetzner's provider cannot
  manage Object Storage, so buckets are created through the `minio` provider
  against the Hetzner S3 endpoint, as Hetzner's own docs recommend.
- **The host** is a NixOS flake output next to `phobos`
  (`nixos/hosts/deimos`): WireGuard peer, forwarder with PROXY protocol,
  hardened sshd, nftables. No Ansible — the lab already standardised on
  NixOS (ADR-0001) and the VPS is just a second host in the same flake.
- **In the cluster**: a second `Gateway` `envoy-external` on `.131` with a
  `ClientTrafficPolicy` enforcing PROXY protocol, a `CiliumNetworkPolicy`
  restricting the proxied listener to the WireGuard peer address, and
  `external-dns` publishing only the external hostnames to Cloudflare DNS
  (pointing at the VPS). The internal Gateway is untouched.
- **Secrets** (Hetzner API token, S3 credentials, WireGuard keys) live in
  1Password; OpenTofu reads them via `op run`, the cluster via External
  Secrets, the VPS via sops-nix. Nothing lands in Git in plaintext.

## Consequences

**Positive**

- End-to-end TLS; no third party decrypts household traffic.
- Real client IPs reach Envoy, so rate limiting, access logs and future
  CrowdSec/fail2ban-style blocking actually work.
- Raw TCP works: Git over SSH for Forgejo, and anything else later.
- Same Gateway API model as internal; an app goes external by adding a
  `parentRef` to `envoy-external`. Kanidm SSO applies unchanged.
- Mirrors the bjw-s reference, so its policies and Lua filters port directly.
- One vendor (Hetzner) for both external access and off-site backup.

**Negative / trade-offs**

- A second host to patch. Mitigated by NixOS: the VPS is rebuilt from the
  same flake, and the attack surface is sshd + WireGuard + a forwarder.
- The VPS is a single point of failure for external access (not for anything
  internal). Acceptable; recreate is `tofu apply` + `nixos-anywhere`.
- Roughly €3.50–4/month for the VPS on top of Object Storage.
- Bootstrap has one unavoidable manual step: creating the Hetzner account and
  the first API token / S3 credential in the Console.

**Neutral**

- Cloudflare still hosts the DNS zone; only the proxy/tunnel features are not
  used.

## Notes

Status is *proposed* until the Hetzner account exists and the first external
route has been exercised end-to-end, after which this becomes *accepted*.
Switching to Cloudflare Tunnel later is a contained change (replace the VPS
and PROXY policy; Gateway and routes stay), so the cluster side of this
decision is the durable part.
