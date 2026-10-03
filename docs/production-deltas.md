# Production deltas

This pipeline reports on three small lab accounts and one person reads it. This page lists what would change if the same design had to report on a real estate for a finance team and why each decision was made the way it was here.

## Scheduling and failure

The ingest runs on a GitHub Actions schedule. GitHub treats schedules as best effort, and every run here started between 2 hours 40 minutes and nearly 4 hours after its 21:00 UTC slot. GitHub also switches off scheduled workflows in a public repository after 60 days with no activity, so a quiet repo would stop ingesting without anyone being told. Production would trigger the same job from a scheduler with a guarantee, such as Cloud Scheduler calling a Cloud Run job, and keep the GitHub workflow for manual runs.

Nothing alerts when a run fails or when data stops arriving. A failed run shows a red cross in GitHub and nothing else. Production would alert on a failed run and separately on freshness, alerting when the latest charge date for any provider is more than two days old. The second check catches an export that has quietly stopped, which a green pipeline run would not.

The reconciliation view shows a difference but nothing acts on it. Production would run it at the end of each ingest and fail the run on any non-zero difference. This allows for a bad load to be caught before anyone reads the report.

## Billing scope

Each provider here has one account, subscription or billing account. A real estate has an AWS organisation with a payer account and many member accounts, Azure billing at enrolment or billing profile scope rather than subscription, and GCP billing accounts covering many projects under an organisation. The exports would be set up at those scopes and the allocation would add the sub-account as a dimension next to the tags.

## Commitments and amortisation

There are no reservations, savings plans, or committed use discounts in any of the three accounts so BilledCost and EffectiveCost are the same, and the Azure view sets one equal to the other. With commitments in place, a purchase lands as one large charge in the month it is bought, while EffectiveCost spreads it over the months it covers. Production would need Azure's amortised cost export alongside the actual one, and the reports would default to EffectiveCost for allocation and BilledCost for matching the invoice.

## Currency

All three providers bill this lab in USD. A business billed in more than one currency would need a stated exchange rate source and date, and a converted column next to the original. The allocation view keeps BillingCurrency so that a second currency shows up as its own line instead of being added to the first.

## Tag coverage

Two thirds of taggable spend carries a project tag. The gaps include resources a provider creates on your behalf, a tag activation that came after the spend, and labs that predated the tag scheme. Production would enforce tags when resources are created, with AWS tag policies, Azure Policy, and GCP organisation policy, set `propagate_tags` on ECS services, and decide how to share spend that can never be tagged, such as tax and shared platform costs.

## Access to the data

Everything is readable by the project owner and nobody else. A finance team would get read access to the reporting dataset only through authorised views, so they never need access to the raw tables or to the projects the exports live in. If teams should see only their own spend, row-level security on the project column would do that.

## Ingestion code

The loaders are two bash scripts. They are short, readable and proven against the real exports, but have no tests. A production pipeline would put the same logic in a small job with tests for the cases that matter, including a month with no export, a provider changing its file layout, and an Azure tag value that contains a quote.

The workflow pins actions by major version tag. Production would pin them by commit hash so a changed tag cannot change what runs with the pipeline's credentials.

## The dashboard

The Looker Studio report was built by hand, and the screenshot in `evidence/` is its only record. It cannot be reviewed or rebuilt from the repo. Production would define the report as code so it sits under version control with everything else.
