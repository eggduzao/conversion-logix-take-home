#!/usr/bin/env bash

set -euo pipefail

required_variables=(
  PROJECT_ROOT
  GCP_PROJECT_ID
  GCP_PROJECT_NUMBER
  GCP_REGION
  TF_STATE_BUCKET
  FLYTE_APPLICATION
  FLYTE_ENVIRONMENT
  FLYTE_DNS_DOMAIN
  FLYTE_HOST
  FLYTE_CERT_EMAIL
  UPSTREAM_REPOSITORY
  UPSTREAM_COMMIT
  UPSTREAM_SNAPSHOT_ROOT
  UPSTREAM_FLYTE_CORE_DIR
  WORKING_FLYTE_CORE_DIR
)

missing_variables=()

for variable_name in "${required_variables[@]}"; do
  if [[ -z "${!variable_name:-}" ]]; then
    missing_variables+=("$variable_name")
  fi
done

if (( ${#missing_variables[@]} > 0 )); then
  printf 'ERROR: Missing project environment variables:\n' >&2

  for variable_name in "${missing_variables[@]}"; do
    printf '  - %s\n' "$variable_name" >&2
  done

  printf '\nRun:\n  source .project-env\n' >&2
  exit 1
fi

if [[ "$PWD" != "$PROJECT_ROOT" ]]; then
  printf 'ERROR: Wrong working directory.\n' >&2
  printf 'Expected: %s\n' "$PROJECT_ROOT" >&2
  printf 'Actual:   %s\n' "$PWD" >&2
  exit 1
fi

if [[ "$GCP_PROJECT_ID" != "clx-take-home" ]]; then
  printf 'ERROR: Unexpected GCP project: %s\n' "$GCP_PROJECT_ID" >&2
  exit 1
fi

if [[ "$FLYTE_HOST" != "${FLYTE_APPLICATION}.${FLYTE_DNS_DOMAIN}" ]]; then
  printf 'ERROR: Flyte host is inconsistent.\n' >&2
  printf 'Expected: %s.%s\n' "$FLYTE_APPLICATION" "$FLYTE_DNS_DOMAIN" >&2
  printf 'Actual:   %s\n' "$FLYTE_HOST" >&2
  exit 1
fi

if [[ ! -d "$UPSTREAM_FLYTE_CORE_DIR" ]]; then
  printf 'ERROR: Upstream Flyte Core source does not exist:\n' >&2
  printf '  %s\n' "$UPSTREAM_FLYTE_CORE_DIR" >&2
  exit 1
fi

printf 'Project environment: VALID\n'
printf 'Project root:        %s\n' "$PROJECT_ROOT"
printf 'GCP project:         %s\n' "$GCP_PROJECT_ID"
printf 'GCP project number:  %s\n' "$GCP_PROJECT_NUMBER"
printf 'GCP region:          %s\n' "$GCP_REGION"
printf 'Terraform state:     gs://%s\n' "$TF_STATE_BUCKET"
printf 'Flyte host:          %s\n' "$FLYTE_HOST"
printf 'Certificate email:   %s\n' "$FLYTE_CERT_EMAIL"
printf 'Upstream commit:     %s\n' "$UPSTREAM_COMMIT"
