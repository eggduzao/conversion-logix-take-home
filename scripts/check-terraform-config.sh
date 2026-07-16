#!/usr/bin/env bash

set -euo pipefail

: "${WORKING_FLYTE_CORE_DIR:?Run: source .project-env}"
: "${GCP_PROJECT_ID:?Run: source .project-env}"
: "${GCP_PROJECT_NUMBER:?Run: source .project-env}"
: "${GCP_REGION:?Run: source .project-env}"
: "${FLYTE_DNS_DOMAIN:?Run: source .project-env}"
: "${FLYTE_HOST:?Run: source .project-env}"
: "${FLYTE_CERT_EMAIL:?Run: source .project-env}"
: "${TF_STATE_BUCKET:?Run: source .project-env}"

locals_file="${WORKING_FLYTE_CORE_DIR}/locals.tf"
terraform_file="${WORKING_FLYTE_CORE_DIR}/terraform.tf"
backend_file="${WORKING_FLYTE_CORE_DIR}/backend.gcs.hcl"

for file in "$locals_file" "$terraform_file" "$backend_file"; do
  if [[ ! -f "$file" ]]; then
    printf 'ERROR: Required file missing: %s\n' "$file" >&2
    exit 1
  fi
done

required_patterns=(
  "project_id[[:space:]]*=[[:space:]]*\"${GCP_PROJECT_ID}\""
  "project_number[[:space:]]*=[[:space:]]*\"${GCP_PROJECT_NUMBER}\""
  "dns-domain[[:space:]]*=[[:space:]]*\"${FLYTE_DNS_DOMAIN}\""
  "region[[:space:]]*=[[:space:]]*\"${GCP_REGION}\""
  "email[[:space:]]*=[[:space:]]*\"${FLYTE_CERT_EMAIL}\""
)

for pattern in "${required_patterns[@]}"; do
  if ! grep -Eq "$pattern" "$locals_file"; then
    printf 'ERROR: Expected configuration not found: %s\n' \
      "$pattern" >&2
    exit 1
  fi
done

if grep -REq \
  '<your-|noreply@flyte\.org' \
  "$WORKING_FLYTE_CORE_DIR" \
  --include='*.tf' \
  --include='*.hcl'; then
  printf 'ERROR: Terraform placeholders remain.\n' >&2
  exit 1
fi

if ! grep -Eq \
  'backend[[:space:]]+"gcs"[[:space:]]*\{\}' \
  "$terraform_file"; then
  printf 'ERROR: Partial GCS backend block was not found.\n' >&2
  exit 1
fi

if ! grep -Eq \
  "bucket[[:space:]]*=[[:space:]]*\"${TF_STATE_BUCKET}\"" \
  "$backend_file"; then
  printf 'ERROR: Backend bucket does not match project environment.\n' >&2
  exit 1
fi

if ! grep -Eq \
  'prefix[[:space:]]*=[[:space:]]*"flyte-core"' \
  "$backend_file"; then
  printf 'ERROR: Expected backend prefix was not found.\n' >&2
  exit 1
fi

expected_host="${FLYTE_APPLICATION}.${FLYTE_DNS_DOMAIN}"

if [[ "$FLYTE_HOST" != "$expected_host" ]]; then
  printf 'ERROR: Expected Flyte hostname %s but found %s.\n' \
    "$expected_host" "$FLYTE_HOST" >&2
  exit 1
fi

printf 'Terraform configuration: VALID\n'
printf 'Project:                 %s\n' "$GCP_PROJECT_ID"
printf 'Region:                  %s\n' "$GCP_REGION"
printf 'Flyte host:              %s\n' "$FLYTE_HOST"
printf 'Backend bucket:          gs://%s\n' "$TF_STATE_BUCKET"
printf 'Backend prefix:          flyte-core\n'
