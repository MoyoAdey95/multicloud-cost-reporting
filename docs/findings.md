# Findings

What the data showed once all three providers were in one place. The figures cover 1 July to 3 October 2026 and come from the files in `evidence/`. The bill is small, $1.36 across three clouds, which makes the shape of it easy to see.

## The numbers reconcile

Every provider and every month in the pipeline matches a separate source. For AWS and Azure, the source is the raw export as loaded, which shows the views neither lose nor double count anything. For GCP it is Google's detailed usage export, a different product from the FOCUS export the pipeline reads, and the two agree for every month from July to October. AWS was also checked against Cost Explorer on 27 September. It reported $0.3032690667 against $0.3033 in the pipeline.

One fix was needed. GCP's billing month runs on US Pacific time, so its September starts at 07:00 UTC while AWS and Azure start at midnight. The first query that grouped all three by month found no GCP rows for September at all.

## Allocation depends on how resources were tagged

| Provider | Billed | Allocated | Unallocated | Not taggable |
|---|---|---|---|---|
| Azure | $0.6243 | $0.6219 | $0.0024 | none |
| AWS | $0.3138 | $0.0810 | $0.2127 | $0.0200 |
| GCP | $0.4192 | $0.0008 | $0.1520 | $0.2664 |

Of the spend that could have carried a tag, 66% did.

Azure is almost fully allocated because the Azure lab passed tags to every resource explicitly since azurerm has no provider-level default. The $0.0024 left over is the storage account holding the cost export which was built by hand early on and never tagged.

AWS is the more instructive case. The lab tagged everything through the provider's `default_tags`, yet only a quarter of its spend carries a project. Most of the gap is resources AWS creates on your behalf. The public IPv4 addresses on the Fargate tasks cost about $0.06, billed under VPC. They belong to network interfaces that ECS creates, and those do not inherit the provider's tags. The Fargate tasks themselves cost $0.04. They are billed per task, and tasks only carry tags when the service propagates them, which the lab did not set. The load balancer is a timing problem. It ran from about 14:05 on 16 September. Cost allocation tags were activated at 16:33 that day, and activation is not retroactive so 16 September is the only day split between tagged and untagged. Cost Explorer API calls costing $0.05 at a cent each cannot be tagged at all, and one of them was the reconciliation check above.

The Fargate and interface explanations fit the data and AWS's documented behaviour, but they were not confirmed by rebuilding the lab with tag propagation switched on.

GCP's unallocated spend is mostly Compute Engine. The labels that do appear on it are GKE's own, such as `goog-gke-node`, which points to the Kubernetes lab's nodes. That lab ran before the project label was agreed so nothing on it carried one.

## Tax is not a tagging failure

GCP's second largest line is a service called Invoice. It is tax which came to $0.26 in July and $0.01 in September plus small rounding adjustments. In July it was almost all of GCP's bill. AWS added $0.02 of tax once September closed. No provider lets you tag tax, so counting it as unallocated made GCP look like a tagging failure when most of its gap could never have been closed. The allocation view now puts tax and adjustments in their own state using FOCUS's `ChargeCategory` which marks them the same way for all three providers.

## Billed cost is not the same as list cost

GCP's September was $0.16 billed against $0.46 at list price. The difference was free tier and credits. Azure's gap is smaller at $0.0038, and comes from the Log Analytics and Azure Monitor free allowances. AWS showed no gap since nothing in the account had a free tier or discount by then. A report built on list price would have overstated GCP nearly three times.

## What the Azure lab actually cost

The Container Apps environment creates a load balancer in a managed resource group. The Azure lab's own documentation had estimated its cost from the price list. The bill shows Load Balancer at $0.00 even at pay-as-you-go prices, so it is not charged to the customer. The largest Azure line was Container Registry at $0.36 followed by the public IP at $0.26 which Azure bills under Virtual Network.

Azure's September total stopped moving after 25 September. The final file for the month added 26 rows and no cost, which matches the lab being torn down around then.

## The pipeline's own cost

The reporting project carries the project label and its own spend across the period was $0.0008. The landing bucket, the BigQuery storage, and the queries all sit inside free tiers at this size.

## The schedule ran late every night

The ingest is scheduled for 21:00 UTC. Every scheduled run started between 23:41 and 00:51, so between 2 hours 40 minutes and nearly 4 hours late. GitHub treats scheduled workflows as best effort. Nothing here depended on the time, but anything with a deadline would need a scheduler that keeps one.
