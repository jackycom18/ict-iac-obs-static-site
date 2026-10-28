# Validation Workflow

## Configure Huawei Cloud Mirror (MUST DO FIRST)

**CRITICAL: Configure Huawei Cloud mirror BEFORE any terraform init attempt.**

### Configuration Steps

1. Create `.tfrc` file:
   ```hcl
   provider_installation {
     network_mirror {
       url = "https://mirrors.huaweicloud.com/terraform/"
       include = ["registry.terraform.io/huaweicloud/*"]
     }
   }
   ```

2. Set environment variable:
   ```bash
   export TF_CLI_CONFIG_FILE="/path/to/.tfrc"
   ```

**MANDATORY: Every `terraform init` MUST include TF_CLI_CONFIG_FILE.**

```bash
# Correct
export TF_CLI_CONFIG_FILE="/path/to/.tfrc" && terraform init

# Forbidden
terraform init  # ❌
```

## obsutil Installation and Configuration

### Install obsutil

```bash
wget https://obs-community.obs.cn-north-1.myhuaweicloud.com/obsutil/current/obsutil_linux_amd64.tar.gz
tar -xzf obsutil_linux_amd64.tar.gz
mv obsutil_linux_amd64_*/obsutil /usr/local/bin/
```

### Configure obsutil with AK/SK

```bash
obsutil config -i $HW_ACCESS_KEY -k $HW_SECRET_KEY -e obs.{region}.myhuaweicloud.com
```

Example for cn-north-4:
```bash
obsutil config -i $HW_ACCESS_KEY -k $HW_SECRET_KEY -e obs.cn-north-4.myhuaweicloud.com
```

### Verify obsutil

```bash
obsutil ls
```

## OBS Bucket Naming Rules

Bucket names must be globally unique across all Huawei Cloud accounts:
- 3-63 characters
- Lowercase letters, numbers, hyphens only
- Must start with a letter or number
- Cannot be an IP address format
- Cannot contain consecutive hyphens

If the user does not specify a bucket name, the template auto-generates one using
`random_string` resource with prefix `iac-static-`.

## Validation Order

After Terraform configuration files are generated, execute validation in this order:

```
terraform fmt -recursive
terraform init
terraform validate
terraform plan
```

## obsutil Sync (Automatic via null_resource)

File upload is handled automatically by a `null_resource` with `local-exec` provisioner.
When `terraform apply` runs, after the bucket and policy are created, obsutil sync
automatically uploads all files from the local directory to the OBS bucket.

No manual obsutil commands needed.

The upload triggers re-run when:
- Bucket name changes
- Website files directory changes
- Any file content in the directory changes (tracked via content hash)

### How It Works

```hcl
resource "null_resource" "upload_files" {
  depends_on = [huaweicloud_obs_bucket.website, huaweicloud_obs_bucket_policy.ip_restrict]

  triggers = {
    bucket_name = huaweicloud_obs_bucket.website.id
    files_dir   = var.website_files_dir
    dir_content_hash = sha256(...)  # changes when any file changes
  }

  provisioner "local-exec" {
    command = <<-EOT
      obsutil config -i $HW_ACCESS_KEY -k $HW_SECRET_KEY -e obs.{region}.myhuaweicloud.com
      obsutil sync ${var.website_files_dir}/ obs://{bucket_name}/ -f
    EOT
  }
}
```

### Manual obsutil (optional)

If the user wants to manually re-upload files without running terraform apply:

```bash
obsutil sync ./site/ obs://{bucket_name}/ -f
```

## OBS Website URL Format

The static website hosting URL follows this format:

```
https://{bucket_name}.obs-website.{region}.myhuaweicloud.com
```

Example:
```
https://iac-static-abc12345.obs-website.cn-north-4.myhuaweicloud.com
```

**Note:** The website URL is different from the OBS object access URL:
- Website URL: `obs-website.{region}.myhuaweicloud.com`
- Object URL: `obs.{region}.myhuaweicloud.com`

## Repair Loop

If any validation step fails:

1. inspect the exact error
2. determine the real cause
3. fix the generated Terraform
4. rerun the validation sequence

## Known Provider Quirks (Tested with provider v1.97.2)

| Resource | Quirk | Fix |
|----------|-------|-----|
| `huaweicloud_obs_bucket` | `multi_az` is ForceNew | Cannot change after creation, must set at bucket creation |
| `huaweicloud_obs_bucket` | `website` block requires `acl = "public-read"` | Set acl to public-read for website hosting |
| `huaweicloud_obs_bucket_policy` | S3 format requires `policy_format = "s3"` | Set policy_format explicitly |
| `huaweicloud_obs_bucket_policy` | Overwrites existing policy | Each apply replaces the full policy |
| `huaweicloud_obs_bucket_object` | `content_type` not auto-detected | Set `content_type = "text/html"` for HTML files |
| `null_resource` + `local-exec` | obsutil must be in PATH | Install obsutil before terraform apply |
| `null_resource` triggers | `fileset()` requires directory exists | Create site/ directory before terraform plan |
| `null_resource` triggers | `file()` cannot read binary files (images) | Use `filebase64()` or exclude binary files from hash |
| `provider "huaweicloud"` | `access_key`/`secret_key` empty string causes 401 | Do NOT set in provider block; let provider read from env vars |
| Bucket name | Must be globally unique | Use `random_string` to auto-generate suffix |
