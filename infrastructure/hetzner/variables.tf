# --- Naming -----------------------------------------------------------------

variable "prefix" {
  description = "Prefix for globally-unique names (S3 bucket names are global per Hetzner location)."
  type        = string
  default     = "altena-homelab"
}

# --- Edge VPS (ADR-0003) ------------------------------------------------------

variable "edge_name" {
  description = "Hostname of the edge VPS. Phobos' little brother."
  type        = string
  default     = "deimos"
}

variable "edge_server_type" {
  description = "Hetzner server type. Smallest shared-vCPU x86 is plenty for a packet forwarder. Verify current names with `hcloud server-type list`."
  type        = string
  default     = "cx23"
}

variable "edge_location" {
  description = "Hetzner Cloud location. nbg1 (Nürnberg) / fsn1 (Falkenstein) are closest to NL."
  type        = string
  default     = "nbg1"
}

variable "edge_image" {
  description = "Initial OS image. NixOS is installed on top with nixos-anywhere (see README); any Debian/Ubuntu works as the kexec host."
  type        = string
  default     = "debian-12"
}

variable "ssh_public_key" {
  description = "Public key allowed to SSH into the edge VPS (the 1Password personal key). Public by design."
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMC+1IujIec7B5MhzzTt7OueHIRJyVgjSkbFpJcaR5bZ dave@macbook-1password"
}

variable "wireguard_port" {
  description = "UDP port the cluster-side WireGuard peer connects to on the VPS."
  type        = number
  default     = 51820
}

variable "admin_ssh_cidrs" {
  description = "CIDRs allowed to reach sshd on the VPS. Empty = anywhere (sshd is key-only; tighten once the home IP / Tailscale range is known)."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

# --- Object Storage (ADR-0002) ------------------------------------------------

variable "object_storage_location" {
  description = "Hetzner Object Storage location: fsn1, nbg1 or hel1."
  type        = string
  default     = "nbg1"
}

variable "s3_admin_access_key" {
  description = "Access key of the S3 credential created once in the Hetzner Console. Supplied via TF_VAR_* from op run; never committed."
  type        = string
  sensitive   = true
}

variable "s3_admin_secret_key" {
  description = "Secret key matching s3_admin_access_key."
  type        = string
  sensitive   = true
}

variable "kopiur_retention_days" {
  description = "Safety net: expire noncurrent object versions after this many days. Kopia does its own retention; this only bounds the cost of deleted/overwritten blobs."
  type        = number
  default     = 30
}
