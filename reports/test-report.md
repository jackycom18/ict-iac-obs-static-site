# OBS 静态网站验收

- Terraform init：通过
- Terraform validate：通过
- Terraform plan：通过
- Terraform apply：通过
- 单 AZ OBS 桶：通过
- index.html / error.html：已上传并设为 public-read
- 网站访问：返回完整首页 HTML
- 状态证明：`proof/terraform.tfstate`
- Terraform destroy：5 个资源全部销毁
