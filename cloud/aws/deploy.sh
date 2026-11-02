#!/usr/bin/env bash
# Creates or updates the portfolio's AWS infrastructure (CloudFormation stack).
#
#   bash cloud/aws/deploy.sh         # DRY RUN (default): checks only, creates nothing
#   bash cloud/aws/deploy.sh plan     # same as above
#   bash cloud/aws/deploy.sh apply     # creates/updates the stack after you type a confirmation
#   bash cloud/aws/deploy.sh outputs    # prints the stack outputs (values for GitHub variables)
#
# Settings (override with environment variables):
#   AWS_REGION=eu-west-3  STACK_NAME=portfolio-site  OIDC_PROVIDER_ARN=""
#
# This script never deletes anything. See destroy-guide.md for manual clean-up.
set -euo pipefail

MODE="${1:-plan}"
AWS_REGION="${AWS_REGION:-eu-west-3}"
STACK_NAME="${STACK_NAME:-portfolio-site}"
OIDC_PROVIDER_ARN="${OIDC_PROVIDER_ARN:-}"
TEMPLATE="$(cd "$(dirname "$0")" && pwd)/template.yaml"

say() { printf '\n== %s\n' "$*"; }

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing '$1'. Install it first (see cloud/aws/README.md)."; exit 1; }; }

need aws

say "Who am I? (aws sts get-caller-identity)"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
CALLER_ARN="$(aws sts get-caller-identity --query Arn --output text)"
echo "Account: $ACCOUNT_ID"
echo "Caller : $CALLER_ARN"
echo "Region : $AWS_REGION"
echo "Stack  : $STACK_NAME"

say "Validating template"
aws cloudformation validate-template --region "$AWS_REGION" --template-body "file://$TEMPLATE" >/dev/null
echo "Template is valid."

say "Checking for an existing GitHub OIDC provider"
EXISTING="$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?contains(Arn, 'token.actions.githubusercontent.com')].Arn" --output text || true)"
if [ -n "$EXISTING" ] && [ -z "$OIDC_PROVIDER_ARN" ]; then
  echo "Found: $EXISTING"
  echo "An account can only have one. Re-run with: OIDC_PROVIDER_ARN=$EXISTING bash $0 $MODE"
  [ "$MODE" = "apply" ] && exit 1
elif [ -n "$OIDC_PROVIDER_ARN" ]; then
  echo "Using existing provider: $OIDC_PROVIDER_ARN"
else
  echo "None found: the stack will create it."
fi

STATUS="$(aws cloudformation describe-stacks --region "$AWS_REGION" --stack-name "$STACK_NAME" --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo NONE)"
echo "Current stack status: $STATUS"

case "$MODE" in
  plan|dry-run|"")
    say "DRY RUN - nothing was created"
    echo "Resources that 'apply' would create or update:"
    echo "  - S3 bucket (private, Block Public Access on, encrypted, versioned)"
    echo "  - CloudFront distribution + Origin Access Control (HTTPS only, default *.cloudfront.net domain)"
    echo "  - S3 bucket policy (read access for this distribution only)"
    echo "  - IAM role for GitHub Actions (OIDC, repo NadavaluruSashank/Portfolio_website, branch main)"
    [ -z "$OIDC_PROVIDER_ARN" ] && [ -z "$EXISTING" ] && echo "  - IAM OIDC identity provider for GitHub"
    echo
    echo "Expected cost: see cloud/aws/cost-estimate.md (normally cents per month for a personal site)."
    echo "To create it, run:  AWS_REGION=$AWS_REGION bash $0 apply"
    ;;
  apply)
    say "About to create/update stack '$STACK_NAME' in account $ACCOUNT_ID, region $AWS_REGION"
    printf 'Type the account ID (%s) to confirm: ' "$ACCOUNT_ID"
    read -r CONFIRM
    [ "$CONFIRM" = "$ACCOUNT_ID" ] || { echo "Confirmation did not match. Nothing was done."; exit 1; }
    aws cloudformation deploy \
      --region "$AWS_REGION" \
      --stack-name "$STACK_NAME" \
      --template-file "$TEMPLATE" \
      --capabilities CAPABILITY_IAM \
      --no-fail-on-empty-changeset \
      --parameter-overrides "ExistingGitHubOIDCProviderArn=$OIDC_PROVIDER_ARN" \
      --tags project=portfolio
    bash "$0" outputs
    ;;
  outputs)
    say "Stack outputs - copy these into GitHub repository variables"
    aws cloudformation describe-stacks --region "$AWS_REGION" --stack-name "$STACK_NAME" \
      --query 'Stacks[0].Outputs[].[OutputKey,OutputValue]' --output table
    ;;
  *)
    echo "Unknown mode '$MODE'. Use: plan | apply | outputs"; exit 1 ;;
esac
