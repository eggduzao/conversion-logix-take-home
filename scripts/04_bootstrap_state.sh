#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-/Users/egg/projects/Conversion_Logix_Takehome_Project}"

cd "$PROJECT_ROOT"
source .project-env
./scripts/check-project-env.sh

mkdir -p evidence/step-04

ACTIVE_ACCOUNT="$(gcloud config get-value account 2>/dev/null)"
ACTIVE_PROJECT="$(gcloud config get-value project 2>/dev/null)"

if [[ "$ACTIVE_ACCOUNT" != "eduardogade@gmail.com" || "$ACTIVE_PROJECT" != "$GCP_PROJECT_ID" ]]; then
  echo "ERROR: Wrong GCP account or project." >&2
  exit 1
fi

GCP_PROJECT_NUMBER="$(
  gcloud projects describe "$GCP_PROJECT_ID" \
    --format='value(projectNumber)'
)"
TF_STATE_BUCKET="${GCP_PROJECT_ID}-tfstate-${GCP_PROJECT_NUMBER}"

cat > evidence/step-04/state-bucket-lifecycle.json <<'EOF'
{
  "rule": [
    {
      "action": {"type": "Delete"},
      "condition": {"age": 30, "isLive": false}
    }
  ]
}
EOF

jq . evidence/step-04/state-bucket-lifecycle.json >/dev/null

if ! gcloud storage buckets describe "gs://${TF_STATE_BUCKET}" \
    --project="$GCP_PROJECT_ID" >/dev/null 2>&1; then
  gcloud storage buckets create "gs://${TF_STATE_BUCKET}" \
    --project="$GCP_PROJECT_ID" \
    --location="$GCP_REGION" \
    --default-storage-class=STANDARD \
    --uniform-bucket-level-access \
    --public-access-prevention \
    --lifecycle-file=evidence/step-04/state-bucket-lifecycle.json
fi

gcloud storage buckets update "gs://${TF_STATE_BUCKET}" --versioning
gcloud storage buckets update "gs://${TF_STATE_BUCKET}" \
  --update-labels=application=flyte,environment=take-home,managed-by=gcloud,purpose=terraform-state

printf 'Terraform backend access probe\n' \
  > evidence/step-04/backend-access-probe.txt

gcloud storage cp evidence/step-04/backend-access-probe.txt \
  "gs://${TF_STATE_BUCKET}/preflight/backend-access-probe.txt"

gcloud storage cat \
  "gs://${TF_STATE_BUCKET}/preflight/backend-access-probe.txt"

gcloud storage rm \
  "gs://${TF_STATE_BUCKET}/preflight/backend-access-probe.txt"

gcloud storage buckets describe "gs://${TF_STATE_BUCKET}" \
  --format=json \
  > evidence/step-04/state-bucket-full.json
