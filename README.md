# multicloud-cost-reporting

Billing data from GCP, AWS and Azure brought into one BigQuery dataset, mapped to the FOCUS schema, and allocated by tag. The data is real. It is what a set of small lab projects on the three providers actually cost. The point is that the numbers are right, and every provider and month reconciles to a separate source with a difference of zero.

Personal lab, not client or production work. Built and run between 23 September and 3 October 2026, then torn down. Nothing here runs now, so the docs and the captures in [docs/evidence](docs/evidence/) are the record of it working.

## Design

```
AWS Data Exports (FOCUS 1.2, Parquet)    --+
                                            +--> GitHub Actions, nightly
Azure cost export (actual cost, CSV)     --+      signs in to all three with OIDC
                                                  |
                                                  v
                                   landing bucket --> cost_raw (one partition per month)
                                                  |
GCP billing export (FOCUS) -----------------------+
                                                  v
                       cost_reporting views: focus_aws, focus_gcp, focus_azure
                                                  |
                                            focus_all
                                         /        \
                             cost_allocation    reconciliation
                                    |
                           Looker Studio report
```

AWS and Azure write their exports to their own storage. A scheduled workflow copies the newest files into a landing bucket and loads them into BigQuery, replacing the month each time, because both providers resend the whole month every day. GCP's export is already in BigQuery and is read where it is. One view per provider maps its columns to FOCUS. A union puts them together, and the allocation view splits every charge into allocated, unallocated, or not taggable.

The workflow holds no secrets. It signs in to GCP through workload identity federation, to AWS by assuming a role, and to Azure through a federated credential on a managed identity. Each identity can only read the one export it needs. [docs/identity-decisions.md](docs/identity-decisions.md) covers how, and how another repo can reuse the three modules.

## What's in here

```
modules/
  github-oidc-gcp/     workload identity pool, provider and service account
  github-oidc-aws/     role trusting the account's GitHub OIDC provider
  github-oidc-azure/   managed identity and federated credential
  ingestion/           landing bucket, raw dataset and the ingest identity's grants
  reporting/           the FOCUS, union, allocation and reconciliation views, as SQL
envs/dev/              composition root, variables, outputs, backend
ingest/                the two loaders the workflow runs, aws.sh and azure.sh
.github/workflows/     nightly ingest and a manual sign-in check
docs/                  bootstrap, identity, schema mapping, findings, production deltas, evidence
```

## Running it

Prerequisites. Terraform 1.11 or later, the gcloud, AWS and Azure CLIs signed in, and a cost export already switched on in each provider. Exports are not retroactive, so the sooner they start the more there is to report on.

Two things have to exist before Terraform runs. The GCP project and its state bucket, covered in [docs/bootstrap.md](docs/bootstrap.md), and an IAM OIDC provider for GitHub in the AWS account. An account can only have one of those per issuer, so it is created once by hand and every repo that needs it looks it up.

Then, from `envs/dev`:

```bash
terraform init
terraform apply
```

Set the five values the workflow needs as repository variables then run the sign-in check before anything else.

```bash
gh variable set GCP_WORKLOAD_IDENTITY_PROVIDER --body "$(terraform output -raw gcp_workload_identity_provider)"
gh variable set GCP_SERVICE_ACCOUNT --body "$(terraform output -raw gcp_service_account_email)"
gh variable set AWS_ROLE_ARN --body "$(terraform output -raw aws_role_arn)"
gh variable set AZURE_CLIENT_ID --body "$(terraform output -raw azure_client_id)"
gh variable set AZURE_TENANT_ID --body "$(terraform output -raw azure_tenant_id)"
gh workflow run signin-check.yml
```

The ingest then runs every night, or by hand with `gh workflow run ingest.yml`. The views are created by Terraform, but they read the raw tables which only exist after the first ingest. On a fresh build, run the ingest once before the `reporting` module is applied.

## Findings

Every provider and month matches a separate source. AWS and Azure match their exports as loaded, while GCP's FOCUS export matches Google's detailed export for every month from July to October.

Tagging every resource is not the same as allocating every cost. Azure, tagged resource by resource, came out 99.6% allocated. AWS, tagged through the provider's defaults, came out at 26% mostly because of resources AWS creates on your behalf and a tag activation that came after the spend.

Tax is not a tagging failure. Most of GCP's apparent gap was tax, which nobody can tag, so the allocation view gives tax and adjustments a state of their own.

GCP's billing month starts at 07:00 UTC because it runs on US Pacific time. Grouping the three providers by month found no GCP rows at all until that was handled.

The nightly schedule started between 2 hours 40 minutes and nearly 4 hours late every night.

The full write-up is in [docs/findings.md](docs/findings.md), the column mapping in [docs/schema-mapping.md](docs/schema-mapping.md), and the captured output in [docs/evidence](docs/evidence/). [docs/production-deltas.md](docs/production-deltas.md) covers what would change for a real estate.

## Cost

Running the pipeline cost next to nothing. The reporting project's own spend from 27 September to 3 October was $0.0008, with the landing bucket, BigQuery storage, and queries all inside free tiers. The one line that was not free was the AWS Cost Explorer API, at a cent a call, used once to check the AWS figures by hand.

## Teardown

Torn down on 3 October 2026. The ingest workflow was disabled first so a scheduled run could not fire part way through. The landing bucket was emptied because Terraform will not delete a bucket with files in it. `terraform destroy` from `envs/dev` then removed 26 resources across the three clouds including the identities, the bucket, both datasets and all six views. Checks afterwards found no role in AWS, no resource group in Azure, no service account or dataset in GCP, and the workload identity pool in its 30-day soft delete.

The four project APIs were only dropped from state, since `disable_on_destroy` is off, and went with the project. The project was then deleted with `gcloud projects delete`, which took the state bucket with it and leaves the project recoverable for 30 days. The repository variables and the Looker Studio report were deleted by hand. The ingest workflow is disabled rather than removed so its file and run history stay.

Two things were left in place on purpose. The AWS IAM OIDC provider for GitHub belongs to the account rather than this repo, and other repos use it. The cost exports in all three providers existed before this repo and are still collecting.
