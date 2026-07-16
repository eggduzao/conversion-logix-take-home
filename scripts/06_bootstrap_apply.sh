#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-/Users/egg/projects/Conversion_Logix_Takehome_Project}"

cd "$PROJECT_ROOT"
source .project-env
./scripts/check-project-env.sh
./scripts/check-terraform-config.sh

mkdir -p evidence/step-06
cd "$WORKING_FLYTE_CORE_DIR"

terraform init -backend-config=backend.gcs.hcl
terraform validate

terraform plan \
  -out=tfplan \
  2>&1 | tee "$PROJECT_ROOT/evidence/step-06/terraform-plan.txt"

terraform show -no-color tfplan \
  > "$PROJECT_ROOT/evidence/step-06/terraform-plan-readable.txt"

terraform show -json tfplan \
  > "$PROJECT_ROOT/evidence/step-06/terraform-plan.json"

echo "Plan generated. Review before any terraform apply."

mkdir -p evidence/step-06b

gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  servicenetworking.googleapis.com \
  sqladmin.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  storage.googleapis.com \
  --project="$GCP_PROJECT_ID"

gcloud compute zones list --limit=3 \
  | tee evidence/step-06b/compute-api.txt

gcloud container get-server-config \
  --region="$GCP_REGION" \
  > evidence/step-06b/gke-api.txt

gcloud sql tiers list \
  | head \
  | tee evidence/step-06b/cloud-sql-api.txt

{
  echo "=== ENABLED RELEVANT APIS ==="
  gcloud services list \
    --enabled \
    --project="$GCP_PROJECT_ID" \
    --format='value(config.name)' \
    | grep -E \
      'compute|container|servicenetworking|sqladmin|iam|storage'
} | tee evidence/step-06b/enabled-relevant-apis.txt
