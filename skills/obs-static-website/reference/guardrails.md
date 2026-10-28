# Guardrails

## Do Not Fabricate Specifications or Resource Facts

Recommended specifications and resource facts must not be fabricated.

They must come from one of the following:
1. explicit user input
2. a reliable resource information lookup channel
3. Terraform data sources resolved during Terraform execution

## OBS Bucket Name Uniqueness

OBS bucket names are globally unique across ALL Huawei Cloud accounts.

**Rules:**
- 3-63 characters
- Lowercase letters, numbers, hyphens only
- Must start with a letter or number
- Cannot use consecutive hyphens

**If the user specifies a bucket name that is already taken, `terraform apply` will fail.**
The template auto-generates a unique name using `random_string` if no name is provided.

## IP Restriction Security

The bucket policy restricts access to a specified IP/CIDR. Rules:

- **Must ask the user** for their public IP before generating the policy
- The IP must be in CIDR format (e.g. `1.2.3.4/32` for a single IP)
- Do NOT use `0.0.0.0/0` for the allowed IP — this defeats the purpose of IP restriction
- Do NOT fabricate an IP address

**If the user does not know their public IP:**
```bash
curl -s ifconfig.me
```

## obsutil Credential Handling

obsutil uses the same AK/SK as Terraform. Configure via:

```bash
obsutil config -i $HW_ACCESS_KEY -k $HW_SECRET_KEY -e obs.{region}.myhuaweicloud.com
```

**Rules:**
- Never ask the user to type AK/SK in conversation
- Never log or display AK/SK values
- Use environment variables only

## Static Website File Handling

### Terraform-managed files (index.html, error.html)

- Uploaded via `huaweicloud_obs_bucket_object` with `content` parameter
- Content is defined in `terraform.tfvars` as inline HTML
- These files are managed by Terraform state — modifying tfvars updates the files

### obsutil-managed files (CSS/JS/images)

- Uploaded via `obsutil sync` command
- These files are NOT managed by Terraform state
- `terraform destroy` will NOT remove these files automatically
- User must manually clean up via `obsutil rm` if needed

### File Content Security

- Do not inject sensitive information (AK/SK, passwords) into HTML content
- The default HTML content is a simple demo page — users should customize it

## Execute terraform apply with Explicit User Confirmation

After `terraform plan` succeeds:
1. Show the plan output
2. Popup confirmation dialog
3. If confirmed: execute `terraform apply`
4. If declined: stop

**Never execute `terraform apply` without user confirmation.**

## OBS Bucket Cleanup

OBS buckets with objects cannot be deleted directly. Cleanup order:

1. `terraform destroy` — removes Terraform-managed resources (bucket objects + bucket)
2. If obsutil-uploaded files remain, manually delete:
   ```bash
   obsutil rm obs://{bucket_name}/ -r -f
   ```
3. Then retry `terraform destroy` if bucket deletion failed

## Do Not Request Sensitive Information

Never ask the user to provide AK/SK, passwords, or tokens in conversation.
- AK/SK: environment variables only
- Website content: no credentials in HTML

## Do Not Guide AK/SK Environment Variable Configuration

- Never ask "Have you configured HW_ACCESS_KEY?"
- Never show examples of how to export AK/SK
- Assume credentials are already configured
- Proceed directly to validation
