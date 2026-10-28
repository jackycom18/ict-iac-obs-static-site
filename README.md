# IaC OBS 静态网站自动化部署

本项目对应 ICT 2026 云赛道第 19 题。Terraform 创建单 AZ OBS 桶，
启用静态网站托管，上传 `index.html` 和 `error.html`，并设置对象为
`public-read`。

实际验证地址返回完整首页 HTML。验证完成后已执行 `terraform destroy`，
对象、桶和随机后缀资源均被删除。

## 关键文件

- `site/index.html`：响应式静态首页。
- `site/error.html`：404 错误页。
- `proof/terraform.tfstate`：销毁前保存的脱敏资源状态。
- `proof/apply-summary.md`：桶名、访问链接与验证结果。
