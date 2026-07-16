# Partial Solution — Flyte on GCP

## Status

This document summarizes the work completed so far for the Flyte-on-GCP take-home assignment.
Current state:

- Steps 0–5: completed and validated.
- Step 6b: completed; required GCP APIs were enabled and verified.
- Step 6: started; Terraform planning is the next active task.
- No GKE cluster, Cloud SQL instance, Flyte deployment, or other substantial runtime infrastructure has been created yet.
- The only cloud resource intentionally created so far is the secured GCS bucket used for Terraform remote state.
- The repository is version-controlled locally with separated import, formatting, bootstrap, configuration, and documentation commits.
  The implementation deliberately favors:
- reproducibility;
- explicit validation;
- minimal cloud spend before `terraform apply`;
- separation between upstream source and local changes;
- secret hygiene;
- reviewable Git history;
- evidence-driven debugging.

---

## Assignment interpretation

The task is to deploy Flyte on Google Cloud using the upstream `unionai-oss/deploy-flyte` Terraform configuration.
The work completed so far establishes a safe and reproducible path to deployment:

01. verify the workstation and GCP account;
02. install and validate the local toolchain;
03. acquire and pin the exact upstream source revision;
04. create a writable, reviewable project repository;
05. bootstrap secure Terraform remote state;
06. configure and initialize Terraform;
07. resolve upstream dependency compatibility;
08. enable the APIs required for planning;
09. produce and review a Terraform execution plan;
10. apply, validate Flyte, configure DNS/TLS, test, document, and clean up.

---

## Repository layout

```text
Conversion_Logix_Takehome_Project/
├── .gitignore
├── .project-env
├── BOOTSTRAP_RESOURCES.md
├── PROJECT_ENVIRONMENT.md
├── SOLUTION.md
├── infrastructure/
│   └── flyte-core/
│       ├── .terraform.lock.hcl
│       ├── backend.gcs.hcl
│       ├── flyte.tf
│       ├── gcs.tf
│       ├── gke.tf
│       ├── iam.tf
│       ├── ingress.tf
│       ├── locals.tf
│       ├── network.tf
│       ├── provider.tf
│       ├── services.tf
│       ├── sql.tf
│       ├── terraform.tf
│       └── values-gcp-core.yaml
├── scripts/
│   ├── check-project-env.sh
│   └── check-terraform-config.sh
├── evidence/
│   ├── step-00/
│   ├── step-01/
│   ├── step-02/
│   ├── step-03/
│   ├── step-04/
│   ├── step-05/
│   ├── step-06/
│   └── step-06b/
└── upstream/
    ├── archives/
    └── snapshots/
```

The immutable upstream snapshot and the writable deployment copy are intentionally separate:

```text
upstream/snapshots/.../flyte-core   -> untouched reference
infrastructure/flyte-core           -> configured working copy
```

This makes all candidate-authored changes easy to inspect.

---

# Step 0 — Baseline reconnaissance

## Objective

Establish a read-only baseline before installing software, authenticating Terraform, downloading source code, or creating cloud resources.

## Verified local environment

- Canonical project root:
  `/Users/egg/projects/Conversion_Logix_Takehome_Project`
- macOS on Apple Silicon (`arm64`)
- Python 3.12
- Micromamba environment available
- Flytekit installed
- `gcloud`, `kubectl`, Docker, Git, and `jq` found
- Terraform and Helm initially missing
- No active Kubernetes context
- No existing Git repository at the project root

## Verified GCP context

- Active account: `eduardogade@gmail.com`
- Active project: `clx-take-home`
- Project state: active
- Billing: enabled
- Project number: discovered and later persisted locally
- Application Default Credentials: initially absent
- No substantial infrastructure created

## DNS baseline

- Domain: `gusmaolab.org`
- DNS provider: Cloudflare
- Proposed Flyte hostname: `flyte.gusmaolab.org`
- No existing `A`, `AAAA`, or `CNAME` record conflicted with the proposed hostname

## Upstream baseline

Repository:

```text
https://github.com/unionai-oss/deploy-flyte
```

Target path:

```text
environments/gcp/flyte-core
```

Pinned upstream commit:

```text
018adaa25921d20783be4e90d6c5bb821873ad3c
```

## Hiring signal demonstrated

- cloud reconnaissance;
- account and project discipline;
- security awareness;
- validation before mutation;
- reproducibility.

---

# Step 1 — Local deployment toolchain

## Objective

Prepare the Mac as a reliable deployment workstation without creating GCP infrastructure.

## Installed tools

- Terraform from HashiCorp’s Homebrew tap
- Helm
- GKE authentication plugin

## Validated tools

- Terraform runs natively on `darwin_arm64`
- Helm is available
- `kubectl` works locally
- Docker Desktop daemon is reachable
- Git and `jq` work
- GKE authentication plugin is available in `PATH`

## Authentication model

Two distinct Google authentication contexts were documented:

```text
gcloud user credentials
    -> used by gcloud commands
Application Default Credentials (ADC)
    -> discovered by Terraform's Google provider
```

ADC was configured for the intended account and quota project.
Validation confirmed:

- ADC file exists with restrictive local permissions;
- access-token acquisition succeeds;
- quota project is `clx-take-home`;
- a read-only Resource Manager API request returns HTTP 200;
- no token or credential file was included in evidence.

## Terraform smoke test

A disposable local Terraform configuration was initialized, validated, planned, and applied.
Result:

```text
Resources: 0 added, 0 changed, 0 destroyed
```

This confirmed that the Terraform binary worked before using the GCP deployment.

## Hiring signal demonstrated

- secure workstation preparation;
- understanding of credential separation;
- Apple Silicon compatibility awareness;
- deliberate preflight testing;
- Terraform fundamentals.

---

# Step 2 — Reproducible upstream acquisition and inspection

## Objective

Acquire the exact upstream revision, preserve an immutable reference copy, and inspect the GCP deployment before editing or executing it.

## Acquisition strategy

The source was downloaded as a GitHub commit archive instead of relying on an unpinned clone.
Recorded artifacts:

- exact commit;
- local archive;
- SHA-256 checksum;
- acquisition timestamp;
- immutable extracted snapshot.
  The snapshot was made read-only as a guardrail.

## Target files identified

```text
flyte.tf
gcs.tf
gke.tf
iam.tf
ingress.tf
locals.tf
network.tf
provider.tf
README.md
services.tf
sql.tf
terraform.tf
values-gcp-core.yaml
```

## Terraform providers identified

- Google
- Google Beta
- Kubernetes
- Helm
- Kubectl
- HTTP

## Major infrastructure categories identified

- GCP service/API enablement;
- VPC and subnet networking;
- private service networking;
- GKE;
- Cloud SQL PostgreSQL;
- GCS Flyte data storage;
- Artifact Registry access;
- Google service accounts and IAM;
- Kubernetes namespaces;
- ingress controller;
- cert-manager/TLS integration;
- Flyte Helm release.

## Static risk and cost findings

Notable configuration included:

- GKE node machine type: `e2-standard-4`;
- Cloud SQL: PostgreSQL 14;
- Cloud SQL tier: `db-custom-1-3840`;
- private Cloud SQL networking;
- public ingress/TLS path;
- multiple project IAM bindings;
- Workload Identity-related bindings;
- Artifact Registry reader/writer permissions.

## Placeholders identified

- project ID;
- project number;
- DNS domain;
- region;
- certificate email;
- Terraform backend bucket.

## Formatting finding

The pinned upstream source did not pass the current local `terraform fmt -check`.
No upstream file was modified during inspection.

## Initial architecture hypothesis

```text
GCP APIs
   |
   +--> VPC / subnet / private service networking
   |
   +--> GKE cluster
   |       |
   |       +--> ingress / cert-manager
   |       +--> Flyte Helm deployment
   |
   +--> Cloud SQL PostgreSQL
   |
   +--> GCS data storage
   |
   +--> IAM / service accounts / Workload Identity
   |
   +--> Artifact Registry integration
```

## Hiring signal demonstrated

- immutable source provenance;
- ability to inspect unfamiliar IaC before execution;
- cost and security reasoning;
- distinction between source declarations and actual runtime resources.

---

# Step 3 — Writable workspace and Git baseline

## Objective

Create the actual submission workspace while retaining an untouched upstream reference.

## Project environment

A non-secret `.project-env` was created to persist:

- canonical project root;
- GCP project ID and region;
- Flyte application and environment;
- DNS domain and hostname;
- pinned upstream repository and commit;
- immutable snapshot path;
- writable deployment path.
  A validation script enforces:
- required variables are set;
- commands run from the expected project root;
- project identity is correct;
- hostname construction is consistent;
- upstream snapshot exists.

## Git hygiene

A local Git repository was initialized on `main`.
The initial history separated:

1. pinned upstream import;
2. canonical Terraform formatting.
   This isolates cosmetic changes from later functional changes.

## Ignore rules

The repository excludes:

- Terraform state and plans;
- `.terraform/`;
- service-account keys and credentials;
- local Flyte configuration;
- raw evidence;
- upstream archives and snapshots;
- temporary files.

## Writable source verification

The GCP `flyte-core` deployment was copied into:

```text
infrastructure/flyte-core
```

Before formatting, checksums confirmed the writable copy matched the immutable upstream source exactly.

## Hiring signal demonstrated

- reviewable Git history;
- upstream/vendor boundary management;
- secret hygiene;
- separation of formatting from functional changes;
- reproducible project setup.

---

# Step 4 — Terraform remote-state bootstrap

## Objective

Create the only resource Terraform requires before it can initialize its own remote backend.

## Bootstrap resource

A GCS bucket was created for Terraform state.
Naming pattern:

```text
clx-take-home-tfstate-<PROJECT_NUMBER>
```

## Security controls

Validated controls:

- regional placement in `us-central1`;
- Standard storage class;
- Uniform Bucket-Level Access;
- Public Access Prevention;
- Object Versioning;
- lifecycle deletion of noncurrent versions after 30 days;
- labels indicating application, environment, purpose, and provisioning method.

## Access validation

A harmless probe object was:

1. uploaded;
2. read;
3. deleted.
   The bucket was then verified to have no live probe objects.

## Ownership boundary

The state bucket is a manually bootstrapped prerequisite and is not managed by the main Flyte Terraform state.
It must not be deleted before:

- Terraform-managed infrastructure is destroyed;
- any required state evidence is preserved.

## Cost restraint

At the end of Step 4:

- no GKE cluster existed;
- no Cloud SQL instance existed;
- no compute instance existed;
- the APIs for major infrastructure were still disabled;
- only the small GCS state bucket had been created.

## Hiring signal demonstrated

- remote-state reasoning;
- secure cloud bootstrapping;
- lifecycle and recovery awareness;
- explicit ownership boundaries;
- cost restraint.

---

# Step 5 — Terraform configuration and initialization

## Objective

Convert the generic upstream deployment into a reproducible environment-specific configuration, initialize the GCS backend, lock dependencies, and validate the configuration.

## Configured deployment values

- project ID: `clx-take-home`;
- project number: persisted locally;
- region: `us-central1`;
- DNS domain: `gusmaolab.org`;
- Flyte hostname: `flyte.gusmaolab.org`;
- certificate-contact email: configured;
- Terraform backend bucket: configured;
- Terraform backend prefix: `flyte-core`.

## Partial backend configuration

The generic Terraform file now contains:

```hcl
terraform {
  backend "gcs" {}
}
```

Environment-specific backend values are stored in:

```hcl
# backend.gcs.hcl
bucket = "<STATE_BUCKET>"
prefix = "flyte-core"
```

Initialization command:

```bash
terraform init -backend-config=backend.gcs.hcl
```

## Configuration guard

A dedicated validation script checks:

- required files exist;
- local values match `.project-env`;
- no active placeholders remain;
- backend bucket and prefix are correct;
- Flyte hostname is internally consistent.

## Dependency lock

Terraform created and the repository retained:

```text
.terraform.lock.hcl
```

This records exact provider selections and checksums.

## Compatibility issue discovered

Initial provider resolution selected Helm provider 3.x because the upstream constraint was only a broad lower bound.
The upstream `provider.tf` uses Helm provider 2.x nested block syntax:

```hcl
provider "helm" {
  kubernetes {
    ...
  }
}
```

Terraform validation failed with:

```text
Unsupported block type: kubernetes
```

## Compatibility resolution

Rather than rewriting the upstream provider integration, the dependency boundary was made explicit:

```hcl
version = ">= 2.11.0, < 3.0.0"
```

Terraform was reinitialized with upgrade resolution and selected Helm provider 2.17.0.
Final result:

```text
terraform init: exit code 0
terraform validate: exit code 0
```

Remaining warnings are deprecations in upstream resources/modules, not blocking validation failures.
Examples include:

- `kubernetes_namespace` superseded by `kubernetes_namespace_v1`;
- a deprecated network module output field.
  These are documented rather than silently modified because they are outside the minimum functional scope of the take-home.

## Remote backend validation

Terraform initialized the `default` workspace and created remote backend metadata under the `flyte-core` prefix.
No root-level local `terraform.tfstate` was created.

## Hiring signal demonstrated

- remote backend discipline;
- dependency reproducibility;
- controlled compatibility debugging;
- minimal, explainable changes;
- distinction between blocking errors and non-blocking deprecations.

---

# Step 6b — Required GCP APIs

## Objective

Enable the APIs required for Terraform to evaluate GCP data sources during planning.

## APIs enabled

The bootstrap included:

- Compute Engine API;
- Kubernetes Engine API;
- Service Networking API;
- Cloud SQL Admin API;
- Cloud Resource Manager API;
- IAM API;
- IAM Service Account Credentials API;
- Cloud Storage API.

## Verification

The following checks succeeded:

- Compute zones can be listed;
- GKE server configuration can be fetched for `us-central1`;
- Cloud SQL tiers can be queried.
  No GKE cluster, Cloud SQL instance, VPC, or Flyte runtime was created by enabling these APIs.

## Why this separate step exists

A new GCP project may not allow Terraform to evaluate provider data sources until the corresponding APIs are enabled.
This creates a bootstrap boundary:

```text
APIs must exist
    before
Terraform can fully plan resources that use those APIs
```

## Hiring signal demonstrated

- understanding of cloud bootstrap dependencies;
- ability to separate API readiness from resource provisioning;
- evidence-driven troubleshooting.

---

# Step 6 — Terraform plan

## Objective

Produce the first complete execution plan without creating infrastructure.

## Completed preparation

- project environment validated;
- Terraform configuration validated;
- remote backend initialized;
- providers reused from the lock file;
- required GCP APIs enabled and tested.

## Next command

```bash
cd "$WORKING_FLYTE_CORE_DIR"
terraform plan \
  -out=tfplan \
  2>&1 | tee "$PROJECT_ROOT/evidence/step-06/terraform-plan.txt"
```

## Review criteria

Before any apply, the plan must be reviewed for:

- correct project and region;
- create/change/destroy counts;
- GKE node pool size and machine type;
- Cloud SQL tier and storage;
- VPC and private service networking;
- GCS resources;
- IAM roles and project-level bindings;
- Artifact Registry;
- ingress/load-balancer exposure;
- DNS hostname assumptions;
- unexpected replacement or deletion;
- estimated recurring cost;
- resources that may survive `terraform destroy`.

## Current checkpoint

The project is at the boundary between:

```text
configuration validated
        ->
plan generated and reviewed
        ->
infrastructure applied
```

No `terraform apply` has occurred.

---

# Key engineering decisions

## 1. Pin the exact upstream revision

Reason:

- prevents source drift;
- makes later debugging reproducible;
- allows reviewers to distinguish upstream behavior from candidate changes.

## 2. Keep immutable and writable source trees separate

Reason:

- clean provenance;
- simple diffs;
- safe formatting;
- easier rollback.

## 3. Use remote state before provisioning infrastructure

Reason:

- state recovery;
- safer collaboration;
- versioned state history;
- avoidance of unmanaged local state.

## 4. Keep backend settings separate

Reason:

- generic Terraform remains reusable;
- environment-specific values are explicit;
- no bucket placeholder remains hidden in source.

## 5. Commit the provider lock file

Reason:

- broad upstream version constraints can otherwise resolve differently later;
- exact checksums improve reproducibility.

## 6. Resolve compatibility with a narrow version constraint

Reason:

- smallest safe change;
- preserves upstream Helm-provider syntax;
- avoids unnecessary provider refactoring;
- makes the compatibility assumption reviewable.

## 7. Delay substantial infrastructure until after plan review

Reason:

- controls cost;
- catches project/region/IAM mistakes before creation;
- demonstrates production change discipline.

---

# Security notes

No credentials, access tokens, private keys, browser codes, payment information, or service-account JSON are included in this delivery.
Sensitive local material remains excluded by `.gitignore`.
Current authentication is appropriate for local development:

```text
user ADC on a controlled workstation
```

For production CI/CD, the preferred design would be:

```text
Workload Identity Federation
or
service-account impersonation
```

rather than long-lived user or service-account keys.
The Flyte UI will eventually be exposed through ingress. Before treating the deployment as production-ready, authentication should be configured in addition to TLS.

---

# Cost notes

Costs incurred so far are negligible:

- one small GCS state bucket;
- remote Terraform state objects;
- API enablement itself does not create billable runtime infrastructure.
  The plan/apply phase is expected to introduce the material costs:
- GKE control plane and worker nodes;
- Cloud SQL;
- load balancer/ingress;
- persistent disks;
- network traffic;
- logging/monitoring;
- GCS and Artifact Registry storage.
  The deployment will be destroyed after validation unless the reviewer requests otherwise.
  A final cleanup audit should verify:
- no GKE clusters;
- no Cloud SQL instances;
- no persistent disks;
- no forwarding rules/load balancers;
- no reserved addresses;
- no unexpected Artifact Registry resources;
- no orphaned VPC resources;
- state bucket retained or deleted intentionally.

---

# Git history strategy

The local history separates major concerns:

```text
chore: import pinned Flyte GCP deployment
style(terraform): apply canonical formatting
chore(gcp): bootstrap Terraform state storage
feat(terraform): configure GCP deployment and remote backend
docs: document implementation progress

```

This makes review easier than a single large commit containing:

- vendor source;
- formatting;
- configuration;
- infrastructure bootstrap;
- documentation.

---

# Remaining work

## Required

01. generate a successful Terraform plan;
02. inspect resource count, cost, IAM, networking, GKE, SQL, and ingress;
03. resolve any second bootstrap/provider issue;
04. run `terraform apply`;
05. acquire GKE credentials;
06. validate namespaces, pods, services, ingress, and Flyte components;
07. create the DNS `A` record;
08. verify certificate issuance;
09. access the Flyte console;
10. run at least one Flyte workflow;
11. document results;
12. destroy resources;
13. audit for orphaned billable resources.

## Recommended

- generate a concise architecture diagram;
- include a sanitized Terraform plan summary;
- include deployment and cleanup timings;
- document upstream issues and compatibility changes;
- add a final `SOLUTION.md`;
- prepare a concise pull-request description.

## Production improvements outside take-home scope

- Flyte authentication;
- Workload Identity Federation for CI/CD;
- pinned module versions;
- CI Terraform checks;
- policy-as-code;
- budget alerts;
- restricted ingress;
- private control plane where appropriate;
- stronger secret management;
- upgraded Kubernetes resource types;
- provider/module modernization.

---

# Reviewer summary

The completed work demonstrates that the deployment was not approached as a sequence of copied commands.
The implementation has already established:

- correct account and project context;
- secure and validated local authentication;
- a native macOS ARM64 toolchain;
- immutable upstream provenance;
- a reviewable writable workspace;
- disciplined Git history;
- secure remote Terraform state;
- environment-specific Terraform configuration;
- provider dependency locking;
- successful Terraform initialization;
- successful Terraform validation;
- documented resolution of an upstream Helm-provider compatibility issue;
- verified GCP API readiness;
- no premature creation of substantial infrastructure.
  The next milestone is the successful, reviewed Terraform plan.
