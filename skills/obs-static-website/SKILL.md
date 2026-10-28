---
name: huawei-cloud-obs-static-website
description: >-
  Generate Huawei Cloud Terraform configurations for OBS static website hosting
  with access control. Use this skill when users want to create an OBS bucket
  for static website hosting, configure bucket policies, upload website files,
  and enable website hosting with index/error pages.
  Trigger when users mention 创建/create、生成/generate、部署/deploy、配置/configure、
  华为云/Huawei Cloud、OBS、对象存储/object storage、桶/bucket、静态网站/static website、
  网站托管/website hosting、桶策略/bucket policy、obsutil、访问控制/access control
---

# Huawei Cloud OBS Static Website — Terraform Generator

## 1. Overview

This skill turns user requirements into Terraform configurations for hosting a static
website on Huawei Cloud OBS with access control. The primary workflow is to:

1. understand the user's website hosting requirements
2. confirm key parameters (bucket name, access control, website files)
3. ensure Terraform and obsutil are available
4. generate Terraform configuration files from templates
5. prepare static website files (index.html, error.html, and optional extra files)
6. run validation steps and fix issues until `terraform plan` succeeds
7. execute `terraform apply` with user confirmation
8. use obsutil to sync any additional website files (CSS/JS/images) if needed
9. output the website URL and verify access

This skill covers **5 resource types**:

| # | Resource | Terraform Type |
|---|----------|---------------|
| 1 | OBS Bucket (single-AZ) | `huaweicloud_obs_bucket` |
| 2 | Bucket Policy (Referer restriction, optional) | `huaweicloud_obs_bucket_policy` |
| 3 | Website Files (index/error) | `null_resource` + obsutil sync |
| 4 | Static Website Hosting | `huaweicloud_obs_bucket` → `website` block |
| 5 | Website URL Output | `output` |

**IMPORTANT — IP Restriction Limitation:**
OBS static website hosting uses the `obs-website` endpoint which goes through an
internal proxy. The `aws:SourceIp` condition in bucket policies does NOT work with
the `obs-website` domain — the source IP is replaced by the internal proxy IP.
Do NOT use IP-based restriction (`IpAddress` / `aws:SourceIp`) for OBS static
website hosting. Use Referer-based control (`StringLike` / `aws:Referer`) instead,
or rely on bucket ACL (`public-read`) for open access.

## 2. Prerequisites

Before using this skill, ensure the following are available:

1. **Terraform** >= 1.9.0 (see `reference/validation-workflow.md`)
2. **obsutil** — installed in PATH (for batch file upload if needed)
3. **Provider download source** — Huawei Cloud mirror (see `reference/validation-workflow.md`)
4. **Target region** — must be identified
5. **Static website files** — user prepares index.html, error.html, and optional extra files

### obsutil Installation

```bash
# Download obsutil
wget https://obs-community.obs.cn-north-1.myhuaweicloud.com/obsutil/current/obsutil_linux_amd64.tar.gz
tar -xzf obsutil_linux_amd64.tar.gz
mv obsutil_linux_amd64_*/obsutil /usr/local/bin/

# Configure with AK/SK
obsutil config -i your_ak -k your_sk -e obs.cn-north-4.myhuaweicloud.com
```

## 3. Parameter Confirmation

Before generating Terraform, propose a concrete plan for the user to confirm.

### Key Parameters to Confirm

| Parameter | Why it matters | Default |
|-----------|---------------|---------|
| Region | OBS endpoint varies by region | cn-north-4 |
| Bucket name | Must be globally unique | Auto-generated |
| Multi-AZ | Single-AZ vs Multi-AZ storage | Single-AZ (multi_az=false) |
| Access control | Referer-based restriction (optional) | None (public-read ACL) |
| Index page | Website homepage | index.html |
| Error page | Error page | error.html |
| Website files location | Local directory with website files | ./site/ |

See `reference/guardrails.md` for rules about not fabricating specifications.

## 4. Workflow

This skill works in eight phases:

### 4.1 Credential Handling (MUST READ)

AK/SK credentials are read from environment variables `HW_ACCESS_KEY` and `HW_SECRET_KEY`.
These same credentials are used for both Terraform (OBS resource management) and obsutil
(file upload). See `reference/guardrails.md` for complete rules.

### 4.2 Understand User Intent

Parse the user's natural language request to identify:
- Bucket name preference (or auto-generate)
- Storage type (single-AZ or multi-AZ)
- Access control requirements (Referer restriction, or open access)
- Website file details (index page, error page, additional files)
- Region and endpoint

### 4.3 Prepare Website Files

The user prepares static website files in a local directory (default: `./site/`):

```
site/
├── index.html        # Required — homepage
├── error.html        # Required — error page
├── css/
│   └── style.css     # Optional — additional files
├── js/
│   └── app.js        # Optional
└── images/
    └── logo.png      # Optional
```

If the user has not prepared files, the skill template includes default index.html
and error.html content that can be customized in terraform.tfvars.

### 4.4 Generate Terraform Configuration

**CRITICAL: Use `cp` to copy template files, do NOT write files manually.**

Copy all 5 template files from `assets/obs-static-website/` to the target directory at once,
then customize only `terraform.tfvars` with confirmed parameters.

```bash
cp /path/to/skill/assets/obs-static-website/{providers.tf,variables.tf,main.tf,terraform.tfvars,README.md} /target/dir/
```

The template includes 5 files:
- `providers.tf` — Terraform version + Provider configuration
- `variables.tf` — All variable definitions
- `main.tf` — OBS bucket + policy + object upload + website hosting + submit_proof
- `terraform.tfvars` — Variable values (filled from confirmed plan)
- `README.md` — Project documentation

**Terraform handles**: bucket creation, bucket policy, file upload via obsutil sync,
website hosting configuration, submit_proof (copy tfstate + verify.log to /root/workspace).

### 4.5 Upload Additional Files with obsutil (if needed)

If the user has additional files beyond index.html and error.html, they are uploaded
automatically by the `null_resource.upload_files` provisioner in main.tf using
`obsutil sync`. No manual upload needed.

### 4.6 Validate Configuration

Execute validation in this order (see `reference/validation-workflow.md`):

```
terraform fmt -recursive
terraform init     # with TF_CLI_CONFIG_FILE set
terraform validate
terraform plan
```

### 4.7 Apply with User Confirmation

After `terraform plan` succeeds:
1. Show the plan output to the user
2. Popup confirmation dialog
3. If confirmed: execute `terraform apply`
4. Output the website URL

### 4.8 Verify Website Access

Output the website URL and verify:
1. Show the URL: `https://{bucket}.obs-website.{region}.myhuaweicloud.com`
2. Suggest the user open the URL in a browser
3. Verify the page renders correctly

## 5. Resource Architecture

```
OBS Bucket (single-AZ, ACL: public-read)
├── Bucket Policy (optional: Referer restriction)
├── Objects
│   ├── index.html     ← Uploaded by obsutil sync (null_resource)
│   ├── error.html     ← Uploaded by obsutil sync (null_resource)
│   └── css/js/images  ← Uploaded by obsutil sync (if present)
└── Website Hosting
    ├── index_document = "index.html"
    └── error_document = "error.html"

Output: https://{bucket}.obs-website.{region}.myhuaweicloud.com
```

## 6. Template Location

```
assets/obs-static-website/
├── providers.tf          # Terraform + Provider configuration
├── variables.tf          # All variable definitions
├── main.tf               # OBS bucket + policy + upload + website + submit_proof
├── terraform.tfvars      # Variable values (edit before use)
└── README.md             # Template documentation
```

## 7. Business Goal to Resource Mapping

| User says | Resources needed |
|-----------|-----------------|
| "创建OBS桶" + "静态网站" | OBS bucket + website hosting |
| "限制访问" | Bucket policy with Referer condition (NOT IP — see limitation above) |
| "上传网站文件" | null_resource + obsutil sync |
| "开启网站托管" | website block in obs_bucket |
| "单AZ存储" | multi_az = false |

## 8. Quality Checklist

Before finalizing, ensure:

- [ ] The generated Terraform matches the confirmed resource plan
- [ ] All 5 required files were generated and verified
- [ ] `main.tf` includes `null_resource.submit_proof` — this is a required resource, not optional
- [ ] Bucket ACL is set to `public-read` (required for static website hosting)
- [ ] Bucket policy does NOT use `aws:SourceIp` (IP restriction does not work with obs-website endpoint)
- [ ] index.html and error.html are uploaded
- [ ] Website hosting is enabled with correct index/error documents
- [ ] Additional files (if any) are uploaded via obsutil sync
- [ ] Website URL is output and accessible
- [ ] After apply: verify `/root/workspace/terraform.tfstate` and `/root/workspace/verify.log` exist
- [ ] No sensitive information was requested from user
- [ ] Validation reached `terraform plan`, or the blocker was clearly explained
- [ ] User was asked for confirmation before terraform apply
