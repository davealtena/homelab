# Hetzner Object Storage (S3) — off-site replica of the kopiur repository
# (ADR-0002) and, in phase 2, the OpenTofu state itself.
#
# Hetzner exposes no API for buckets/credentials, so this uses the minio
# provider against the S3 endpoint with an admin credential created once in
# the Console. Bucket names are unique per location.

locals {
  s3_endpoint = "https://${var.object_storage_location}.your-objectstorage.com"
}

# --- kopiur off-site repository ----------------------------------------------

resource "minio_s3_bucket" "kopiur" {
  bucket = "${var.prefix}-kopiur"
  acl    = "private"
}

resource "minio_s3_bucket_versioning" "kopiur" {
  bucket = minio_s3_bucket.kopiur.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

# Kopia manages its own retention; versioning + this lifecycle rule only
# protects against an accidental or malicious `rm` of blobs for a bounded
# number of days, and bounds what that protection costs.
resource "minio_ilm_policy" "kopiur" {
  bucket = minio_s3_bucket.kopiur.bucket

  rule {
    id     = "expire-noncurrent"
    status = "Enabled"

    noncurrent_expiration {
      days = var.kopiur_retention_days
    }
  }

  depends_on = [minio_s3_bucket_versioning.kopiur]
}

# NOTE on credentials: Hetzner Object Storage is Ceph RGW behind an S3 API.
# There is no IAM/admin API (the minio_iam_* resources would fail), so access
# keys can only be created in the Hetzner Console and are scoped to the whole
# project, not to a bucket. Create a *second* key pair there for kopiur and
# keep the admin pair for OpenTofu only; both live in 1Password.

# --- OpenTofu remote state (phase 2) -----------------------------------------

resource "minio_s3_bucket" "tofu_state" {
  bucket = "${var.prefix}-tofu-state"
  acl    = "private"
}

resource "minio_s3_bucket_versioning" "tofu_state" {
  bucket = minio_s3_bucket.tofu_state.bucket

  versioning_configuration {
    status = "Enabled"
  }
}
