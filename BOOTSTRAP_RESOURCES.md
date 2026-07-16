# Bootstrap Resources

The following resource must exist before the main Terraform configuration can
initialize its remote backend.

## Terraform state bucket

- GCP project: `clx-take-home`
- Project number: `715475195576`
- Bucket: `gs://clx-take-home-tfstate-715475195576`
- Location: `us-central1`
- Storage class: `STANDARD`
- Uniform bucket-level access: enabled
- Public access prevention: enforced
- Object versioning: enabled
- Noncurrent-version lifecycle: delete after 30 days
- Provisioning method: `gcloud storage`

## Ownership boundary

The state bucket is a bootstrap resource and is not currently managed by the
main Flyte Terraform state.

It must not be deleted before the managed infrastructure has been destroyed
and any required state evidence has been preserved.
