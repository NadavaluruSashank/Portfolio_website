# AWS hosting for the portfolio (S3 + CloudFront + OIDC)

**Status: AWS deployment — in progress.** The infrastructure code, workflow and scripts are written and validated locally. Nothing has been created in AWS yet. GitHub Pages (https://nadavalurusashank.github.io/Portfolio_website/) stays the live site until the AWS version is deployed and tested.

## What's here

| File | What it is |
|---|---|
| `template.yaml` | CloudFormation template: private S3 bucket, CloudFront + Origin Access Control, bucket policy, GitHub OIDC provider, least-privilege deploy role |
| `deploy.sh` | Creates/updates the stack. **Defaults to a dry run**; `apply` asks you to type your account ID |
| `check_site.py` | Pre-deploy checks used by the workflow (also runnable locally) |
| `architecture.md` | Diagram, components, security decisions |
| `cost-estimate.md` | Expected monthly cost and how to cap it |
| `destroy-guide.md` | Manual clean-up steps (nothing is deleted automatically) |
| `iam/github-oidc-trust-policy.json` | Trust policy used by the role (reference copy with placeholders) |
| `iam/deploy-permissions-policy.json` | Permissions of the role (reference copy with placeholders) |
| `../../.github/workflows/deploy-aws.yml` | Manual GitHub Actions deployment |

## Validation already done

| Check | Tool | Result |
|---|---|---|
| CloudFormation syntax and best practices | `cfn-lint` 1.59 | No errors or warnings |
| IaC security scan | `checkov` | 19 passed, 4 accepted trade-offs (see `architecture.md`) |
| Workflow syntax | `actionlint` 1.7 | No errors |
| Shell script | `shellcheck` 0.11 | No warnings |
| IAM JSON | `python -m json.tool` | Valid JSON |
| Dry run behaviour | `deploy.sh` with a mocked AWS CLI | Only read-only calls were made (`sts get-caller-identity`, `validate-template`, `list-open-id-connect-providers`, `describe-stacks`) |

Not yet tested, because they need a real AWS account: stack creation, OIDC role assumption, upload, invalidation, bucket privacy (direct S3 URL → 403) and the CloudFront URL. The workflow checks the last two automatically on its first run.

## Step 1 — Install and check the AWS CLI (on your Mac)

Install: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html (or `brew install awscli`).

Then sign in with **IAM Identity Center** (recommended, temporary credentials) or an IAM user with admin rights for the one-time setup. Never paste keys into chat, code or GitHub.

```bash
aws --version
```
Shows which AWS CLI version is installed. You want version 2.x. If you get "command not found", the CLI isn't installed yet.

```bash
aws configure list
```
Shows which credentials and region the CLI will use, and where they come from (profile, environment, SSO). It masks the keys. Check that the region is what you expect (for example `eu-west-3`, Paris).

```bash
aws sts get-caller-identity
```
Asks AWS "who am I?". It returns your 12-digit **account ID** and the user or role you're signed in as. If this fails, you're not logged in. Always run it before creating anything, so you know which account you're about to change.

```bash
aws s3 ls
```
Lists the S3 buckets in the account. Read-only. It confirms your credentials work for S3 and shows what already exists, so you don't confuse buckets.

## Step 2 — Dry run (creates nothing)

From the repository root:

```bash
AWS_REGION=eu-west-3 bash cloud/aws/deploy.sh
```

It prints your account, validates the template, checks whether a GitHub OIDC provider already exists, and lists what would be created. If it reports an existing provider, re-run with `OIDC_PROVIDER_ARN=<that ARN>`.

## Step 3 — Create the infrastructure (only after you approve the cost)

Read `cost-estimate.md`, set a billing budget, then:

```bash
AWS_REGION=eu-west-3 bash cloud/aws/deploy.sh apply
```

You'll be asked to type your account ID. CloudFront takes roughly 5–15 minutes to deploy. When it finishes, the script prints the stack outputs.

## Step 4 — Connect GitHub (no secrets needed)

In the repository: **Settings → Secrets and variables → Actions → Variables → New repository variable**. Add five variables from the stack outputs:

| Variable | Stack output |
|---|---|
| `AWS_ROLE_ARN` | `DeployRoleArn` |
| `AWS_REGION` | `BucketRegion` |
| `S3_BUCKET` | `BucketName` |
| `CLOUDFRONT_DISTRIBUTION_ID` | `DistributionId` |
| `CLOUDFRONT_DOMAIN` | `DistributionDomainName` |

These are identifiers, not credentials: the role can only be assumed by a workflow running on `main` in this repository.

## Step 5 — First deployment

**Actions → Deploy to AWS (S3 + CloudFront) → Run workflow** (branch `main`). The run summary shows the CloudFront URL. The workflow fails on purpose if the site doesn't return 200 or if the bucket answers direct requests.

## Step 6 — After it works

- Open the CloudFront URL on desktop and phone, and check that `http://` redirects to `https://`.
- Tell me, and I'll update the portfolio's "AWS deployment — in progress" card to "deployed" with the real URL.
- Optional later: switch the workflow to run on every push to `main`. Not before the manual runs are verified.

## Security notes

- No long-lived AWS keys exist anywhere in GitHub.
- The role can only upload to this one bucket and invalidate this one distribution. It cannot delete objects, read other buckets or change IAM.
- Bucket stays private (all Block Public Access settings on). Only this CloudFront distribution can read it, via OAC.
- Everything in this repository is public: never commit keys, `.env` files or account passwords.
