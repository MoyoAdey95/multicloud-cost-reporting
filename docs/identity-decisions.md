# Identity decisions

The workflow reads from AWS and Azure and writes into GCP. It does that without any stored secret. There are no AWS access keys, no Azure SAS tokens or client secrets, and no GCP service account keys in the repo or in its GitHub settings. This page sets out how that works on each cloud provider, what each identity is allowed to do, and what I would have had to store otherwise.

## What authenticates to what

| Caller | Identity | Permission | Scope |
|---|---|---|---|
| Terraform, run locally | My own user on each cloud, from gcloud, the `personal` AWS SSO profile and `az login` | Owner or administrator | Each account |
| The workflow, on GCP | Service account `github-cost-ingest` | None yet, roles arrive with the ingestion commits | The cost reporting project |
| The workflow, on AWS | Role `github-cost-ingest` | `s3:GetObject`, and `s3:ListBucket` limited by prefix | The `cost-exports/` prefix in the export bucket |
| The workflow, on Azure | Managed identity `id-github-cost-ingest` | Storage Blob Data Reader | The `cost-exports` container |

The workflow cannot write to either export, cannot see anything else in the AWS bucket, and cannot see the Azure storage account as a whole.

## How the sign-in works

GitHub gives every workflow run a short-lived token signed by its own OIDC issuer. The token says which repository, branch and run it belongs to. Each cloud provider checks the signature, checks that the claims match what it was told to expect, and hands back its own short-lived credentials. Nothing is stored, and any token that leaks stops working within minutes.

The claim that matters most is the subject. This repository uses GitHub's immutable form, `repo:MoyoAdey95@212127446/multicloud-cost-reporting@1383789639:ref:refs/heads/main`, with the numeric owner and repository IDs next to the names. A repository that is renamed keeps working, and a new repository that reuses the name does not get in. I read the value with `gh api` rather than typing it, since a trust policy that expects the older name-only form refuses every token.

All three cloud providers trust only runs on `main`. A pull request or another branch gets a different subject and is turned away.

## The same idea in three forms

Each cloud provider splits the work differently, and this was the part worth learning.

| | Trusts the issuer | Checks it is this repo and branch | What the run becomes |
|---|---|---|---|
| GCP | A provider inside a workload identity pool | The provider's attribute condition, then the principal in an IAM binding | A service account it is allowed to impersonate |
| AWS | An IAM OIDC identity provider | Conditions in the role's trust policy | The role |
| Azure | A federated credential on the identity | The same credential, which holds the exact subject | The managed identity |

GCP has the most pieces and checks twice. The provider's condition refuses any token whose owner and repository IDs are not mine, and the binding on the service account names the full subject. Azure folds everything into one credential and only accepts an exact subject match. AWS sits in between.

## The AWS provider belongs to the account

An AWS account can hold only one OIDC provider for a given issuer URL. If this repo created it in Terraform, the next repo that needed GitHub sign-in would either fail to create its own or have to reach into this repo's state. Neither is good, so the provider is account bootstrap. I created it by hand, tagged it `project=shared` and `managed-by=console-bootstrap`, and the module looks it up with a data source. Destroying this repo leaves it in place.

## Azure details

The identity has no role at subscription level. `azure/login` looks for a subscription to select by default and fails when there is none, so the workflow sets `allow-no-subscriptions: true`.

The container's resource ID is built from its parts in Terraform rather than read with the storage account data source. That data source also returns the account's access keys, and they would have been written into the state file.

## What the static-key version would have looked like

The easy route was an IAM user with an access key for AWS, a SAS token for the Azure container, and a service account key for GCP, all stored as GitHub secrets. All of those are long-lived, have to be rotated by hand, and work from anywhere once they leak. The federated version took three small modules and one workflow run to prove.

## Reuse

The three modules under `modules/github-oidc-*` take the subject and the permissions as inputs and know nothing about cost data. Another repository can copy the folders and point them at its own workflows. It would look up the same AWS provider, not create a second.
