#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-/Users/egg/projects/Conversion_Logix_Takehome_Project}"
GCP_PROJECT_ID="${GCP_PROJECT_ID:-clx-take-home}"
EXPECTED_ACCOUNT="${EXPECTED_ACCOUNT:-eduardogade@gmail.com}"

cd "$PROJECT_ROOT"
mkdir -p evidence/step-01

command -v brew >/dev/null
brew tap hashicorp/tap
brew install hashicorp/tap/terraform || true
brew install helm || true

ACTIVE_ACCOUNT="$(gcloud config get-value account 2>/dev/null)"
ACTIVE_PROJECT="$(gcloud config get-value project 2>/dev/null)"

if [[ "$ACTIVE_ACCOUNT" != "$EXPECTED_ACCOUNT" || "$ACTIVE_PROJECT" != "$GCP_PROJECT_ID" ]]; then
  echo "ERROR: Unexpected gcloud context." >&2
  exit 1
fi

if ! command -v gke-gcloud-auth-plugin >/dev/null 2>&1; then
  gcloud components install gke-gcloud-auth-plugin
fi

if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker daemon is not reachable." >&2
  exit 1
fi

gcloud auth application-default login "$EXPECTED_ACCOUNT"
gcloud auth application-default set-quota-project "$GCP_PROJECT_ID"
gcloud auth application-default print-access-token >/dev/null

{
  terraform version
  helm version --short
  kubectl version --client
  gke-gcloud-auth-plugin --version
  docker version --format \
    'client={{.Client.Version}} server={{.Server.Version}}'
  echo "ADC token acquisition: SUCCESS"
} | tee evidence/step-01/partial-workstation.txt
