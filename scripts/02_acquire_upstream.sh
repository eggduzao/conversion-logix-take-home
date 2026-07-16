#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-/Users/egg/projects/Conversion_Logix_Takehome_Project}"
UPSTREAM_COMMIT="${UPSTREAM_COMMIT:-018adaa25921d20783be4e90d6c5bb821873ad3c}"

cd "$PROJECT_ROOT"

ARCHIVE="upstream/archives/deploy-flyte-${UPSTREAM_COMMIT}.tar.gz"
SNAPSHOT="upstream/snapshots/deploy-flyte-${UPSTREAM_COMMIT}"

mkdir -p upstream/archives upstream/snapshots evidence/step-02

curl --fail --location --show-error \
  --output "$ARCHIVE" \
  "https://github.com/unionai-oss/deploy-flyte/archive/${UPSTREAM_COMMIT}.tar.gz"

shasum -a 256 "$ARCHIVE" \
  | tee evidence/step-02/upstream-archive-sha256.txt

if [[ -e "$SNAPSHOT" ]]; then
  echo "ERROR: Snapshot already exists: $SNAPSHOT" >&2
  exit 1
fi

mkdir -p "$SNAPSHOT"
tar -xzf "$ARCHIVE" -C "$SNAPSHOT" --strip-components=1

cat > "$SNAPSHOT/UPSTREAM_PROVENANCE.txt" <<EOF
Repository: https://github.com/unionai-oss/deploy-flyte
Commit: ${UPSTREAM_COMMIT}
Acquisition method: GitHub commit archive
Acquired UTC: $(date -u '+%Y-%m-%dT%H:%M:%SZ')
Purpose: Immutable upstream reference; do not edit.
EOF

chmod -R a-w "$SNAPSHOT"

FLYTE_CORE="${SNAPSHOT}/environments/gcp/flyte-core"
test -d "$FLYTE_CORE"

find "$FLYTE_CORE" -maxdepth 1 -type f -print \
  | sort \
  | tee evidence/step-02/flyte-core-files.txt
