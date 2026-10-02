output "edge_ipv4" {
  description = "Public IPv4 of the edge VPS — target for the external DNS records and the WireGuard endpoint."
  value       = hcloud_primary_ip.edge_v4.ip_address
}

output "edge_ipv6" {
  description = "Public IPv6 of the edge VPS (/64)."
  value       = hcloud_primary_ip.edge_v6.ip_address
}

output "edge_ssh" {
  description = "Convenience: how to reach the box after nixos-anywhere."
  value       = "ssh root@${hcloud_primary_ip.edge_v4.ip_address}"
}

output "s3_endpoint" {
  description = "S3 endpoint for kopiur's RepositoryReplication and the tofu backend."
  value       = local.s3_endpoint
}

output "kopiur_bucket" {
  value = minio_s3_bucket.kopiur.bucket
}

output "tofu_state_bucket" {
  value = minio_s3_bucket.tofu_state.bucket
}
