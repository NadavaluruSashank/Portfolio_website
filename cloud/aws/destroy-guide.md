# Destroy guide (manual only)

Nothing in this repository deletes AWS resources automatically. `deploy.sh` has no delete mode, and the deploy role cannot delete anything. If you ever want to remove the AWS hosting, do it yourself, step by step, after checking you are in the right account and region.

GitHub Pages is not affected by any of these steps.

## Before you start

```bash
aws sts get-caller-identity                  # confirm the account
export AWS_REGION=eu-west-3                  # the region you deployed to
aws cloudformation describe-stacks --stack-name portfolio-site --region $AWS_REGION \
  --query 'Stacks[0].Outputs' --output table # note the bucket name
```

## 1. Stop deployments

In GitHub: **Settings → Secrets and variables → Actions → Variables**, delete `AWS_ROLE_ARN` (the workflow will then stop before touching AWS). Optionally disable the workflow under **Actions → Deploy to AWS → ⋯ → Disable workflow**.

## 2. Delete the stack

```bash
aws cloudformation delete-stack --stack-name portfolio-site --region $AWS_REGION
aws cloudformation wait stack-delete-complete --stack-name portfolio-site --region $AWS_REGION
```

This removes CloudFront, the OAC, the bucket policy, the IAM role and (if the stack created it) the GitHub OIDC provider. CloudFront takes several minutes to disable and delete.

If your account had its own OIDC provider before (you passed `OIDC_PROVIDER_ARN`), it is **not** deleted, because the stack never owned it.

## 3. The S3 bucket is kept on purpose

The template uses `DeletionPolicy: Retain`, so the bucket and its files survive stack deletion. That protects you from losing files by accident. When you are sure you no longer need it:

1. Open the S3 console, select the bucket, and use **Empty** (this includes old versions, since versioning is on).
2. Then **Delete** the bucket.

Doing it in the console lets you see exactly what you are deleting. A deleted bucket name can be taken by someone else.

## 4. Check nothing is left

```bash
aws cloudformation list-stacks --region $AWS_REGION --stack-status-filter DELETE_COMPLETE \
  --query "StackSummaries[?StackName=='portfolio-site']"
aws cloudfront list-distributions --query 'DistributionList.Items[].{Id:Id,Comment:Comment}'
```

Finally, check **Billing → Bills** the following month.
