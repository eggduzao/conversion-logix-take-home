#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-/Users/egg/projects/Conversion_Logix_Takehome_Project}"

cd "$PROJECT_ROOT"
source .project-env
./scripts/check-project-env.sh

mkdir -p evidence/step-05

python - <<'PY'
import os
import re
from pathlib import Path

root = Path(os.environ["WORKING_FLYTE_CORE_DIR"])
path = root / "locals.tf"
text = path.read_text(encoding="utf-8")

values = {
    "application": os.environ["FLYTE_APPLICATION"],
    "environment": os.environ["FLYTE_ENVIRONMENT"],
    "project_id": os.environ["GCP_PROJECT_ID"],
    "project_number": os.environ["GCP_PROJECT_NUMBER"],
    "dns-domain": os.environ["FLYTE_DNS_DOMAIN"],
    "region": os.environ["GCP_REGION"],
    "email": os.environ["FLYTE_CERT_EMAIL"],
}

for key, value in values.items():
    pattern = re.compile(
        rf'^(\s*{re.escape(key)}\s*=\s*)"[^"]*"',
        flags=re.MULTILINE,
    )
    text, count = pattern.subn(
        lambda match: f'{match.group(1)}"{value}"',
        text,
        count=1,
    )
    if count != 1:
        raise SystemExit(f"Expected one assignment for {key}; found {count}")

path.write_text(text, encoding="utf-8")
PY

python - <<'PY'
import os
import re
from pathlib import Path

root = Path(os.environ["WORKING_FLYTE_CORE_DIR"])
path = root / "terraform.tf"
text = path.read_text(encoding="utf-8")

text, count = re.subn(
    r'backend\s+"gcs"\s*\{.*?\}',
    'backend "gcs" {}',
    text,
    count=1,
    flags=re.DOTALL,
)
if count != 1:
    raise SystemExit("Expected one GCS backend block")

old = 'version = ">=2.11.0"'
new = 'version = ">= 2.11.0, < 3.0.0"'
if new not in text:
    if old not in text:
        raise SystemExit("Expected Helm provider constraint not found")
    text = text.replace(old, new, 1)

path.write_text(text, encoding="utf-8")
PY

cat > "$WORKING_FLYTE_CORE_DIR/backend.gcs.hcl" <<EOF
bucket = "${TF_STATE_BUCKET}"
prefix = "flyte-core"
EOF

terraform fmt -recursive "$WORKING_FLYTE_CORE_DIR"
./scripts/check-terraform-config.sh

cd "$WORKING_FLYTE_CORE_DIR"

terraform init \
  -upgrade \
  -backend-config=backend.gcs.hcl \
  2>&1 | tee "$PROJECT_ROOT/evidence/step-05/terraform-init.txt"

terraform validate \
  2>&1 | tee "$PROJECT_ROOT/evidence/step-05/terraform-validate.txt"

test -f .terraform.lock.hcl
test ! -f terraform.tfstate
