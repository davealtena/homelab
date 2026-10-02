# 1. Host OS: NixOS over Talos Linux

- Status: accepted
- Date: 2025-02-25

## Context

This lab needs a host operating system for its single node, `phobos`, which runs
a k3s Kubernetes cluster. Two options were seriously considered:

- **Talos Linux** — a minimal, immutable, API-only OS purpose-built for
  Kubernetes. Popular in the self-hosted / home-ops community.
- **NixOS** — a general-purpose Linux distribution with a fully declarative,
  reproducible configuration model (flakes).

The lab originally ran on Talos, so both options are backed by real hands-on
experience rather than speculation. Several factors drove reopening the choice:

- **Single node, with a GPU.** The cluster was deliberately consolidated from a
  multi-node setup onto one capable machine with an NVIDIA RTX 5060 Ti. Talos's
  strongest advantages (immutable, identical, easily-scaled fleet nodes) mostly
  pay off at 3+ nodes; on a single box they matter far less.
- **GPU / AI workloads are the primary goal.** The headline future workload is
  local LLM inference and hardware transcoding on a Blackwell-generation GPU.
  This needs current NVIDIA drivers, which is where Talos (system-extension
  images pinned to Talos releases) is more constrained than a distro where the
  driver version is declared directly.
- **Declarative config pairs well with an LLM.** NixOS's declarative model turns
  out to work very well when using an LLM as a co-maintainer, which matches how
  this lab is actually operated (time-poor maintainer leaning on AI assistance).
- **Maintainer familiarity and motivation.** A lab the household relies on must
  be one the maintainer will actually keep up. Comfort operating the system is a
  legitimate long-term reliability factor.

A point *against* NixOS was community perception — Talos is more visible in
home-ops circles. On examination this did not hold up: for the maintainer's
actual goal (AI engineering on Kubernetes), the career-relevant and
transferable skills live *above* the host, inside Kubernetes and the GPU
tooling, and are identical on either OS. Community familiarity is not the
audience that matters here.

## Decision

Use **NixOS** as the host OS for `phobos`, defined as a flake under `nixos/`,
running a single-node k3s cluster.

## Consequences

**Positive**

- GPU driver management is declarative and easy to iterate — important for the
  primary AI/inference goal on a current-generation GPU.
- The whole host (kernel, drivers, networking, k3s) is reproducible from Git.
- The declarative model works smoothly with LLM-assisted maintenance.
- The maintainer operates a system they are motivated to keep running.

**Negative / trade-offs**

- NixOS has a steeper learning curve than Talos's appliance model; deep Nix
  expertise is deliberately not a goal — LLM assistance is relied on instead.
- Less community precedent for this exact setup than the common Talos + k3s
  home-ops pattern, so fewer copy-paste references.
- Host-level changes are not GitOps-reconciled; they require a manual NixOS
  rebuild step (see `AGENTS.md` → Common operations).

**Neutral**

- Kubernetes, Flux, Cilium, GPU scheduling, and model-serving skills — the
  career-relevant layer — are unaffected by this choice.

## Notes

Reversing this decision means a full host re-provision and reworking the k3s and
GPU modules, so it is treated as hard-to-reverse. It should only be revisited if
a concrete, blocking problem emerges (for example, if a required GPU driver
cannot be made to work on NixOS), not on the basis of community popularity.
