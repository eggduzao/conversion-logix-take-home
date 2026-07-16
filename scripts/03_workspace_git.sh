#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-/Users/egg/projects/Conversion_Logix_Takehome_Project}"

cd "$PROJECT_ROOT"
source .project-env
./scripts/check-project-env.sh

mkdir -p evidence/step-03 scripts infrastructure

if [[ -e "$WORKING_FLYTE_CORE_DIR" ]]; then
  echo "ERROR: Working directory already exists: $WORKING_FLYTE_CORE_DIR" >&2
  exit 1
fi

mkdir -p "$(dirname "$WORKING_FLYTE_CORE_DIR")"
cp -R "$UPSTREAM_FLYTE_CORE_DIR" "$WORKING_FLYTE_CORE_DIR"
chmod -R u+w "$WORKING_FLYTE_CORE_DIR"

diff -ru \
  --exclude='UPSTREAM_PROVENANCE.txt' \
  "$UPSTREAM_FLYTE_CORE_DIR" \
  "$WORKING_FLYTE_CORE_DIR" \
  > evidence/step-03/import-diff.txt

git init -b main
git add .gitignore .project-env PROJECT_ENVIRONMENT.md \
  scripts/check-project-env.sh infrastructure/flyte-core
git commit -m "chore: import pinned Flyte GCP deployment"

terraform fmt -recursive "$WORKING_FLYTE_CORE_DIR"
terraform fmt -check -recursive "$WORKING_FLYTE_CORE_DIR"

git add infrastructure/flyte-core
git diff --cached --check
git commit -m "style(terraform): apply canonical formatting"

git status --short --branch
