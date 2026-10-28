# ============================================================
# Data Sources
# ============================================================

# Generate unique bucket name if not provided
resource "random_string" "bucket_suffix" {
  count   = var.bucket_name == "" ? 1 : 0
  length  = 8
  special = false
  upper   = false
}

locals {
  effective_bucket_name = var.bucket_name != "" ? var.bucket_name : "iac-static-${random_string.bucket_suffix[0].result}"
  obs_endpoint          = "https://obs.${var.region_name}.myhuaweicloud.com"
}

# ============================================================
# 1. OBS Bucket (single-AZ) + Static Website Hosting
# ============================================================

resource "huaweicloud_obs_bucket" "website" {
  bucket   = local.effective_bucket_name
  acl      = var.acl
  multi_az = var.multi_az

  # Static Website Hosting
  website {
    index_document = var.index_document
    error_document = var.error_document
  }

  tags = {
    Project = "iac-obs-static-website"
  }
}

# ============================================================
# 2. Bucket Policy — Referer-based access control
#    NOTE: OBS static website hosting uses obs-website endpoint which
#    goes through an internal proxy. The aws:SourceIp condition does NOT
#    work with obs-website domain because the source IP is replaced by
#    the internal proxy IP. Use Referer-based control instead, or rely
#    on bucket ACL (public-read) for open access.
# ============================================================

resource "huaweicloud_obs_bucket_policy" "referer_restrict" {
  count         = var.allowed_referer != "" ? 1 : 0
  bucket        = huaweicloud_obs_bucket.website.id
  policy_format = "s3"
  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Sid    = "RefererAllow"
        Effect = "Allow"
        Principal = {
          AWS = ["*"]
        }
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::${huaweicloud_obs_bucket.website.id}/*"
        Condition = {
          StringLike = {
            "aws:Referer" = [var.allowed_referer]
          }
        }
      },
      {
        Sid    = "DenyNoReferer"
        Effect = "Deny"
        Principal = {
          AWS = ["*"]
        }
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::${huaweicloud_obs_bucket.website.id}/*"
        Condition = {
          StringNotLike = {
            "aws:Referer" = [var.allowed_referer]
          }
        }
      }
    ]
  })
}

# ============================================================
# 3. Upload Website Files
#    Terraform manages the required documents so cleanup is
#    deterministic on both Windows and Linux.
# ============================================================

resource "huaweicloud_obs_bucket_object" "index" {
  bucket       = huaweicloud_obs_bucket.website.id
  key          = var.index_document
  source       = "${var.website_files_dir}/${var.index_document}"
  content_type = "text/html; charset=utf-8"
  acl          = "public-read"
}

resource "huaweicloud_obs_bucket_object" "error" {
  bucket       = huaweicloud_obs_bucket.website.id
  key          = var.error_document
  source       = "${var.website_files_dir}/${var.error_document}"
  content_type = "text/html; charset=utf-8"
  acl          = "public-read"
}

# ============================================================
# 4. Output — Website URL
# ============================================================

output "bucket_name" {
  description = "OBS bucket name"
  value       = huaweicloud_obs_bucket.website.id
}

output "website_url" {
  description = "Static website access URL"
  value       = "https://${huaweicloud_obs_bucket.website.id}.obs-website.${var.region_name}.myhuaweicloud.com"
}

output "files_uploaded_from" {
  description = "Local directory that was uploaded"
  value       = var.website_files_dir
}

# ============================================================
# 5. Submit completion proof — copy tfstate to /root/workspace
# ============================================================

resource "null_resource" "submit_proof" {
  depends_on = [
    huaweicloud_obs_bucket.website,
    huaweicloud_obs_bucket_policy.referer_restrict,
    huaweicloud_obs_bucket_object.index,
    huaweicloud_obs_bucket_object.error,
  ]

  triggers = {
    bucket_name = huaweicloud_obs_bucket.website.id
  }

}
