# ============================================================
# Authentication Variables
# ============================================================

variable "region_name" {
  description = "The region where the OBS bucket will be created"
  type        = string
}

# AK/SK are read from environment variables (HW_ACCESS_KEY, HW_SECRET_KEY)
# Do NOT put credentials in variables or tfvars files

# ============================================================
# OBS Bucket Variables
# ============================================================

variable "bucket_name" {
  description = "The name of the OBS bucket. Must be globally unique. Leave empty to auto-generate."
  type        = string
  default     = ""
}

variable "multi_az" {
  description = "Whether to enable multi-AZ storage. false = single-AZ, true = multi-AZ"
  type        = bool
  default     = false
}

variable "acl" {
  description = "The ACL for the bucket. Use 'public-read' for static website hosting."
  type        = string
  default     = "public-read"
}

# ============================================================
# Bucket Policy Variables (Referer-based Access Control)
# ============================================================

variable "allowed_referer" {
  description = "The Referer pattern allowed to access the bucket (e.g. 'https://example.com/*'). Leave empty to allow all access (public-read ACL only). NOTE: IP-based restriction (aws:SourceIp) does NOT work with OBS static website hosting because the obs-website endpoint goes through an internal proxy."
  type        = string
  default     = ""
}

# ============================================================
# Website Hosting Variables
# ============================================================

variable "index_document" {
  description = "The index page for the static website"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "The error page for the static website"
  type        = string
  default     = "error.html"
}

# ============================================================
# Website Files Directory
# ============================================================

variable "website_files_dir" {
  description = "Local directory containing static website files (index.html, error.html, CSS, JS, images, etc.). Supports relative or absolute paths."
  type        = string
  default     = "./site"
}
