# Architecture Decision Records

Records of significant, hard-to-reverse decisions for this lab, and the reasoning
behind them. Format: [MADR](https://adr.github.io/madr/).

An ADR is written only when a decision is (1) hard to reverse, (2) surprising
without context, and (3) the result of a real trade-off between genuine
alternatives. Routine or easily-reversed choices are not recorded here.

| ADR | Title | Status |
| --- | ----- | ------ |
| [0001](0001-host-os-nixos.md) | Host OS: NixOS over Talos Linux | accepted |
| [0002](0002-storage-tiering-and-backup.md) | Storage tiering and backup: NVMe for state, NFS for bulk, Kopia (kopiur) to NAS + Hetzner S3 | accepted |
| [0003](0003-external-access-hetzner-edge.md) | External access: Hetzner edge VPS with WireGuard + PROXY protocol | proposed |
