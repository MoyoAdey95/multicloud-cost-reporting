# multicloud-cost-reporting

Billing data from GCP, AWS and Azure brought into one BigQuery dataset, mapped to the FOCUS schema, and allocated by tag. Works with real data. It is what a set of small lab projects on the three providers actually cost. The point is that the numbers are right, not that they are big.

A scheduled GitHub Actions workflow reads the AWS and Azure exports and loads them next to the GCP export. It signs in to all three clouds with OIDC federation, so there are no access keys or SAS tokens stored anywhere in the repo or in its secrets.

Status: in progress.
