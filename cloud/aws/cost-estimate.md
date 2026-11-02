# Cost estimate

**Short version:** for a personal portfolio with normal traffic, this setup is expected to cost **well under US$1 per month**, very likely a few cents. Nothing in it has a fixed monthly fee.

These are approximate list prices for the Paris region (`eu-west-3`) as I understood them in mid-2026. AWS prices and free-tier rules change, and newer accounts may be on a different free plan. **Check the [AWS Pricing Calculator](https://calculator.aws/) and your account's Billing → Free tier page before you approve the deployment.**

| Service | What is charged | Expected usage | Approx. cost / month |
|---|---|---|---|
| Amazon S3 (Standard) | Storage (~$0.024 per GB-month) | < 5 MB (HTML + CV + old versions) | < $0.01 |
| Amazon S3 requests | PUT/LIST (~$0.005 per 1,000) and GET (~$0.0004 per 1,000) | A few dozen PUTs per deploy; GETs only from CloudFront on cache misses | < $0.01 |
| Amazon CloudFront | Data transfer out and HTTPS requests | A few GB and well under 1M requests | $0 within the always-free tier (1 TB transfer and 10M requests per month at the time of writing) |
| CloudFront invalidations | Paths invalidated | 1 path (`/*`) per deploy | $0 (first 1,000 paths per month free) |
| CloudFormation | Stack management | 1 stack | $0 |
| IAM, OIDC provider, STS | Roles and temporary credentials | 1 role | $0 |
| GitHub Actions | Runner minutes | ~1–2 minutes per manual deploy | $0 for public repositories |

**Not included, on purpose:** WAF, Route 53 hosted zone, domain registration, access-log buckets, EC2, RDS. Each of these would add a monthly cost and needs your approval first.

## Keep costs safe

1. In AWS Billing, create a **budget** (for example US$1/month) with an email alert. Budgets themselves are free for the first two.
2. Keep `PriceClass_100` (cheapest edge locations, includes Europe).
3. Do not make the bucket public or remove the OAC: that is a security issue, not just a cost one.
