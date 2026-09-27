# Bootstrap: the project and the Terraform state bucket

Two things have to exist before `terraform init` can run. A GCP project for everything this repo creates, and a Cloud Storage bucket in it for Terraform state. Both sit outside Terraform for that reason. This page records how they were built and gives the CLI commands to build the same thing from scratch.

## The project

Everything on the GCP side lives in its own project, `multicloud-cost-reporting-lab`. This lab stays up for as long as the reporting is needed, and it holds an identity pool that GitHub Actions is trusted to sign in through, so it gets its own boundary. Deleting the project removes everything in it.

The Cloud Billing export itself stays in the sandbox project, `moyo-cloud-lab`, where it was switched on, and this project reads it from there. Pointing an export somewhere new starts it again from nothing, and the existing data goes back to 1 July.

I created the project in the console with no organisation, the same as my other projects, and linked it to the same billing account. Two of the account's three budgets have no project filter, so they cover the new project without any change. The third is scoped to the sandbox project only.

## The state bucket

I built the bucket in the console. The settings below were read back afterwards with `gcloud storage buckets describe`.

| Setting | Value |
|---|---|
| Name | moyo-cost-reporting-tfstate |
| Location | europe-west2, single region |
| Storage class | Standard |
| Access control | Uniform bucket-level access |
| Public access prevention | Enforced |
| Object versioning | Enabled |
| Soft delete | 7 days, the default |
| Encryption | Google-managed keys |
| Labels | project=multicloud-cost-reporting, env=dev, owner=moyo, managed-by=console-bootstrap |

Versioning matters. If a state file is corrupted or overwritten, the previous version is still there. Uniform access means permissions come from IAM on the bucket alone, with no per-object ACLs to audit.

State for this environment lives under the prefix `multicloud-cost-reporting/dev` in the bucket. The backend authenticates with the gcloud application default credentials on the machine running Terraform.

## Why there is no lock table

The gcs backend writes a lock file next to the state object while a run is in progress and removes it at the end. Cloud Storage only creates an object if it does not already exist when asked to, so two runs cannot both take the lock, and nothing else is needed. A run that dies holding the lock can be cleared with `terraform force-unlock`.

## Building it with the CLI

The bucket commands below were tested on a throwaway bucket, `moyo-cost-reporting-bootstrap-test`, which came out with the same settings as the real one and was then deleted. The project commands were not tested. A deleted project stays in a pending state for 30 days and still counts against the account's project quota, so creating one just to prove the commands was not worth it.

Project IDs and bucket names are global, so change them to something unused. `BILLING_ACCOUNT_ID` comes from `gcloud billing accounts list`.

```bash
gcloud projects create multicloud-cost-reporting-lab --name="Multicloud Cost Reporting Lab"

gcloud billing projects link multicloud-cost-reporting-lab --billing-account=BILLING_ACCOUNT_ID

gcloud storage buckets create gs://moyo-cost-reporting-tfstate \
  --project=multicloud-cost-reporting-lab --location=europe-west2 \
  --default-storage-class=STANDARD \
  --uniform-bucket-level-access --public-access-prevention

gcloud storage buckets update gs://moyo-cost-reporting-tfstate \
  --versioning \
  --update-labels=project=multicloud-cost-reporting,env=dev,owner=moyo,managed-by=cli-bootstrap
```

Soft delete is not set explicitly. New buckets get a 7 day policy by default, and the test bucket showed the same 604800 seconds as the real one.

Resources built this way get `managed-by=cli-bootstrap`. The label records how the resource came to exist, and none of this was built by Terraform.

Once the bucket exists, `terraform init` from `envs/dev/` connects to it.
