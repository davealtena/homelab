# Edge VPS "deimos" — dumb forwarder in front of the cluster (ADR-0003).
# Terminates nothing: 443 (and later 22) go over WireGuard to envoy-external
# with PROXY protocol. The OS is NixOS (nixos/hosts/deimos), installed with
# nixos-anywhere after the first apply; see README.

resource "hcloud_ssh_key" "admin" {
  name       = "dave-1password"
  public_key = var.ssh_public_key
}

resource "hcloud_firewall" "edge" {
  name = "${var.edge_name}-edge"

  # SSH (key-only; sshd itself is hardened in NixOS)
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = var.admin_ssh_cidrs
  }

  # Public HTTPS — the only thing the household actually hits.
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # HTTP only to redirect to HTTPS / ACME HTTP-01 fallback.
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # WireGuard from the cluster (phobos dials out; the VPS listens).
  rule {
    direction  = "in"
    protocol   = "udp"
    port       = tostring(var.wireguard_port)
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # ICMP for sanity.
  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_primary_ip" "edge_v4" {
  name        = "${var.edge_name}-v4"
  type        = "ipv4"
  location    = var.edge_location
  auto_delete = false # keep the IP (and DNS) if the server is ever recreated
}

resource "hcloud_primary_ip" "edge_v6" {
  name        = "${var.edge_name}-v6"
  type        = "ipv6"
  location    = var.edge_location
  auto_delete = false
}

resource "hcloud_server" "edge" {
  name        = var.edge_name
  server_type = var.edge_server_type
  image       = var.edge_image
  location    = var.edge_location
  ssh_keys    = [hcloud_ssh_key.admin.id]

  firewall_ids = [hcloud_firewall.edge.id]

  public_net {
    ipv4 = hcloud_primary_ip.edge_v4.id
    ipv6 = hcloud_primary_ip.edge_v6.id
  }

  labels = {
    role    = "edge"
    managed = "opentofu"
    os      = "nixos" # after nixos-anywhere; the image above is only the kexec host
  }

  lifecycle {
    # nixos-anywhere replaces the OS; don't let a drifted image attribute
    # trigger a destroy/recreate.
    ignore_changes = [image, ssh_keys]
  }
}
