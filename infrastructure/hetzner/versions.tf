terraform {
  required_version = ">= 1.10"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.69.0"
    }
    # Hetzner has no API for Object Storage buckets; Hetzner's own docs use the
    # minio provider against the S3 endpoint for this.
    minio = {
      source  = "aminueza/minio"
      version = "3.43.0"
    }
  }

  # Phase 1: local state (gitignored). Phase 2, after the first apply has
  # created the `tofu-state` bucket, uncomment and run `tofu init -migrate-state`.
  #
  # backend "s3" {
  #   bucket                      = "<prefix>-tofu-state"
  #   key                         = "hetzner/terraform.tfstate"
  #   region                      = "eu-central-1"
  #   endpoints                   = { s3 = "https://nbg1.your-objectstorage.com" }
  #   skip_credentials_validation = true
  #   skip_region_validation      = true
  #   skip_requesting_account_id  = true
  #   skip_s3_checksum            = true
  #   use_path_style              = true
  #   # AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY come from `op run` (see README)
  # }
}

provider "hcloud" {
  # HCLOUD_TOKEN from the environment (op run).
}

provider "minio" {
  minio_server   = "${var.object_storage_location}.your-objectstorage.com"
  minio_region   = var.object_storage_location
  minio_ssl      = true
  minio_user     = var.s3_admin_access_key
  minio_password = var.s3_admin_secret_key
}
