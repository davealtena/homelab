# Hetzner infrastructure (OpenTofu)

Declares everything this lab rents at Hetzner: the edge VPS `deimos`
(ADR-0003) and the Object Storage buckets for off-site backups and OpenTofu
state (ADR-0002). Only *that things exist* lives here; what runs on the VPS is
NixOS under `nixos/hosts/deimos`.

Secrets never touch Git: OpenTofu reads them from 1Password via `op run`
(`.env.op` holds references, not values). Run everything through mise:

```
mise run tofu:init
mise run tofu:plan
mise run tofu:apply
```

## One-time bootstrap (human steps)

Hetzner has no API for account creation or for Object Storage credentials, so
these are done once in the Console.

1. **Account + project.** https://console.hetzner.cloud → create project
   `homelab`. Enable 2FA.
2. **API token.** Project → Security → API tokens → *Read & Write*. Store in
   1Password as `Homelab/hetzner` field `api_token`.
3. **Object Storage credentials.** Console → Object Storage → *Manage
   credentials* → create **two** key pairs in the same project:
   - `tofu-admin` → fields `s3_admin_access_key` / `s3_admin_secret_key`
     (used only by OpenTofu).
   - `kopiur` → fields `s3_kopiur_access_key` / `s3_kopiur_secret_key` (used
     by the cluster via ExternalSecret).

   Hetzner keys are project-wide (Ceph RGW, no IAM), so "least privilege" here
   means separate keys you can rotate independently — not bucket scoping.
4. `mise run tofu:init && mise run tofu:apply`. Note `edge_ipv4` from the
   outputs.
5. **Install NixOS** on the VPS (replaces the Debian kexec host):
   ```
   nixos-anywhere --flake ./nixos#deimos root@<edge_ipv4>
   ```
6. **Move state off your laptop** (phase 2): uncomment the `backend "s3"`
   block in `versions.tf`, fill in the bucket name from the outputs, then
   `mise run tofu:init -- -migrate-state`.

## Verifying assumptions

- Server type names change (`cx22` → `cx23` in 2025). Check before the first
  apply: `op run --env-file=.env.op -- hcloud server-type list`.
- Object Storage locations: `fsn1`, `nbg1`, `hel1`. Bucket names are unique
  per location, hence the `prefix` variable.

## Renovate

The `terraform` manager picks up `required_providers` versions in
`versions.tf`; `opentofu` itself is pinned in `.mise.toml`.
