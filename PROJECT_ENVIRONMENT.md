# Project Environment

## Canonical local root

/Users/egg/projects/Conversion_Logix_Takehome_Project

Loading the project environment

From the project root:

source .project-env
./scripts/check-project-env.sh

Deployment identity
GCP project: clx-take-home
Provisional GCP region: us-central1
Flyte hostname: flyte.gusmaolab.org
DNS provider: Cloudflare

Upstream source
Repository: https://github.com/unionai-oss/deploy-flyte
Pinned commit: 018adaa25921d20783be4e90d6c5bb821873ad3c

Security rule

.project-env contains only non-secret configuration.

Never store any of the following in it:

- access or refresh tokens;
- passwords;
- private keys;
- service-account JSON;
- billing identifiers;
- generated database credentials;
- Terraform state.

## Terraform remote state

- Bucket: `gs://clx-take-home-tfstate-715475195576`
- Region: `us-central1`
- Created as a manual bootstrap resource
- Public access prevention: enforced
- Uniform bucket-level access: enabled
- Object versioning: enabled
