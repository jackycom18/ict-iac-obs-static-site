# ============================================================
# Authentication (AK/SK via environment variables)
# ============================================================

region_name = "cn-north-4"
# AK/SK: set HW_ACCESS_KEY and HW_SECRET_KEY environment variables
# export HW_ACCESS_KEY="your_access_key"
# export HW_SECRET_KEY="your_secret_key"

# ============================================================
# OBS Bucket
# ============================================================

bucket_name = ""            # Auto-generate a globally unique bucket name
multi_az    = false         # false = single-AZ, true = multi-AZ
acl         = "public-read" # Required for static website hosting

# ============================================================
# Bucket Policy — Referer-based Access Control (Optional)
# ============================================================
# NOTE: IP-based restriction (aws:SourceIp) does NOT work with OBS static
# website hosting (obs-website endpoint) because it goes through an internal
# proxy. Use Referer-based control if access restriction is needed.
# Leave empty to allow all access (public-read ACL only).

allowed_referer = "" # Public demo access for judge verification

# ============================================================
# Website Hosting
# ============================================================

index_document = "index.html"
error_document = "error.html"

# ============================================================
# Website Files Directory
# ============================================================

# Local directory containing your website files
# Supports relative path (./site) or absolute path (/home/user/my-website)
website_files_dir = "./site"
