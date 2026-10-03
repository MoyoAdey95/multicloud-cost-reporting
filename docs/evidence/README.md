# Evidence

Captured from the running pipeline between 27 September and 3 October 2026. Query outputs are saved exactly as BigQuery printed them.

| File | What it shows |
|---|---|
| `signin-check.log` | The first run of the sign-in check. GitHub Actions signed in to GCP, AWS and Azure with no stored secret and read from each. The only credential in it is a short-lived AWS session key, which GitHub masked. |
| `ingest-runs.txt` | Every ingest run. Three by hand on 27 September and one scheduled run each night after that. The schedule is set for 21:00 UTC and the runs started between 23:41 and 00:51. |
| `reconciliation.txt` | The reconciliation view. Each provider and month in the pipeline against a separate source with a difference of zero throughout. |
| `allocation-september.txt` | September's bill by provider and project before tax was separated out. |
| `aws-allocation-by-day.txt` | AWS spend by day and project in September. 16 September is the only day split between tagged and untagged. |
| `aws-allocation-by-service.txt` | AWS spend by service and project in September which shows where the untagged spend came from. |
| `allocation-status.txt` | All months by provider and allocation state after tax and adjustments were separated from unallocated spend. |
| `dashboard.png` | The Looker Studio report on `cost_reporting.cost_allocation`, taken on 3 October. |

Cost Explorer reported $0.3032690667 for AWS in September from the CLI on 27 September against $0.3033 in the pipeline the same day. The Azure figure of $0.6243 was first checked by summing the export file locally before it was loaded. Neither check is in a file here because both are one-off commands rather than outputs of the pipeline.

The dashboard is built in Looker Studio by hand and is not in Terraform so the screenshot is the record of it.
