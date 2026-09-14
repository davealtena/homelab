<div align="center">
  <img src="./docs/assets/nixos.svg" alt="NixOS logo" width="120" height="120">
  <img src="./docs/assets/kubernetes.png" alt="Kubernetes logo" width="120" height="120">
</div>

<h1 align="center">Home Operations</h1>

<p align="center"><em>A single-node home Kubernetes cluster, powered by NixOS and managed with GitOps.</em></p>

<p align="center">
  <a href="https://nixos.org"><img alt="NixOS" src="https://img.shields.io/badge/NixOS-26.05-blue?style=flat-square&logo=nixos&logoColor=white"></a>
  <a href="https://k3s.io"><img alt="k3s" src="https://img.shields.io/badge/k3s-single--node-blue?style=flat-square&logo=k3s&logoColor=white"></a>
  <a href="https://fluxcd.io"><img alt="Flux" src="https://img.shields.io/badge/GitOps-Flux-blue?style=flat-square&logo=flux&logoColor=white"></a>
</p>

---

## Overview

This repository is the single source of truth for my home lab. It declaratively
describes the whole system — from the host operating system up to the
applications — so it can be rebuilt from Git.

- **Host** — [NixOS](https://nixos.org) defines the machine (kernel, drivers,
  networking, k3s) as a reproducible flake under [`nixos/`](./nixos).
- **Cluster** — a single-node [k3s](https://k3s.io) cluster, with in-cluster
  state managed by [Flux](https://fluxcd.io) GitOps under
  [`kubernetes/`](./kubernetes).

The cluster (`society`) runs on one node, **phobos**: an AMD Ryzen 9 9900X with
96 GB RAM and an NVIDIA RTX 5060 Ti, backed by a Synology NAS over NFS.

## Documentation

- **[Architecture](./docs/architecture.md)** — system overview, hardware, GitOps
  flow, and core components.
- **[Decision records](./docs/adr/)** — why key choices were made.
- **[Agent guide](./AGENTS.md)** — repo conventions, gotchas, and operations.

## Credits

This lab started life on Talos Linux, and the
[onedr0p/cluster-template](https://github.com/onedr0p/cluster-template) shaped
the GitOps layout that still guides it after the move to NixOS + k3s. Thanks also
to the [Home Operations Discord](https://discord.gg/home-operations) community.

## License

MIT — see [LICENSE](LICENSE).
