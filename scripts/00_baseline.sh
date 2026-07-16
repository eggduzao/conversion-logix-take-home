#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-/Users/egg/projects/Conversion_Logix_Takehome_Project}"
GCP_PROJECT_ID="${GCP_PROJECT_ID:-clx-take-home}"
FLYTE_HOST="${FLYTE_HOST:-flyte.gusmaolab.org}"

cd "$PROJECT_ROOT"
mkdir -p evidence/step-00

{
  echo "=== LOCAL BASELINE ==="
  date -u '+Captured UTC: %Y-%m-%dT%H:%M:%SZ'
  pwd
  uname -m
  sw_vers
  python --version
  echo
  echo "=== TOOL INVENTORY ==="
  for tool in gcloud terraform kubectl helm docker git jq; do
    if command -v "$tool" >/dev/null 2>&1; then
      printf '%-12s FOUND: %s\n' "$tool" "$(command -v "$tool")"
    else
      printf '%-12s MISSING\n' "$tool"
    fi
  done
  echo
  echo "=== GCLOUD CONTEXT ==="
  gcloud config get-value account
  gcloud config get-value project
  gcloud projects describe "$GCP_PROJECT_ID" \
    --format="yaml(projectId,projectNumber,name,lifecycleState)"
  gcloud billing projects describe "$GCP_PROJECT_ID" \
    --format="yaml(projectId,billingEnabled)"
  echo
  echo "=== DNS ==="
  dig +short A "$FLYTE_HOST"
  dig +short AAAA "$FLYTE_HOST"
  dig +short CNAME "$FLYTE_HOST"
} | tee evidence/step-00/partial-baseline.txt
