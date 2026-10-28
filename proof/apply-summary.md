# 1.19 执行证明

- Region：`cn-north-4`
- Bucket：`iac-static-tlt8w8qb`
- 存储类型：单 AZ，`multi_az = false`
- ACL：桶和对象均为 `public-read`
- 首页对象：`index.html`
- 错误页对象：`error.html`
- 网站 URL：`https://iac-static-tlt8w8qb.obs-website.cn-north-4.myhuaweicloud.com`
- 访问验证：主页返回标题“ICT IaC 静态网站”

验证完成后 `terraform destroy` 返回 5 个资源全部销毁。
