# Schema mapping

Each provider's cost data is put on the same eighteen FOCUS columns by one view per provider, in `modules/reporting/sql/`. This page records where every column comes from and what was dropped or derived on the way.

All three providers bill this lab in USD, so no currency conversion is needed. That was checked rather than assumed. AWS and GCP report a `BillingCurrency` column and Azure a `billingCurrency` column, and every row in September said USD.

## Where each column comes from

| FOCUS column | AWS (FOCUS 1.2 export) | GCP (FOCUS preview export) | Azure (actual cost CSV) |
|---|---|---|---|
| ProviderName | ProviderName | ProviderName | Fixed as `Microsoft` |
| BillingAccountId | BillingAccountId | BillingAccountId | billingAccountId |
| SubAccountId | SubAccountId | SubAccountId | SubscriptionId |
| SubAccountName | SubAccountName | SubAccountName | subscriptionName |
| BillingPeriodStart | BillingPeriodStart | BillingPeriodStart, moved to midnight UTC | Month of `date`, see below |
| ChargePeriodStart | ChargePeriodStart | ChargePeriodStart | `date`, parsed from MM/DD/YYYY |
| ChargePeriodEnd | ChargePeriodEnd | ChargePeriodEnd | `date` plus one day |
| ChargeCategory | ChargeCategory | ChargeCategory | chargeType, mapped |
| BillingCurrency | BillingCurrency | BillingCurrency | billingCurrency |
| BilledCost | BilledCost, cast to NUMERIC | BilledCost | costInBillingCurrency |
| EffectiveCost | EffectiveCost, cast to NUMERIC | EffectiveCost | costInBillingCurrency |
| ListCost | ListCost, cast to NUMERIC | ListCost | paygCostInBillingCurrency |
| ServiceName | ServiceName | ServiceName | meterCategory |
| ServiceCategory | ServiceCategory | Not in the export, left empty | Not in the export, left empty |
| RegionId | RegionId | RegionId | resourceLocation |
| ResourceId | ResourceId | ResourceId | ResourceId |
| ResourceName | ResourceName | ResourceName | Last segment of ResourceId |
| Tags | Tags | x_Labels, then x_ProjectLabels | tags, parsed from JSON |

## AWS

AWS already exports FOCUS 1.2, so its view is mostly a trim. The export has about sixty columns, and the ones left out are commitment discount, capacity reservation and SKU detail that nothing here uses.

Costs arrive as FLOAT and are cast to NUMERIC to match GCP. Tags come through as a Parquet map, which BigQuery loads as a repeated key and value list. Some AWS exports prefix user-defined tag keys with `user:`, so the view drops that prefix to make `project` on AWS the same key as `project` everywhere else.

## GCP

GCP's FOCUS export is a preview, and it departs from the spec in two ways that matter.

It has no ServiceCategory column at all, so the view leaves it empty.

Its billing month runs on US Pacific time. September's BillingPeriodStart is 07:00 UTC on 1 September, where AWS and Azure both start at midnight UTC. The first query that filtered all three on midnight found nothing for GCP. The view moves GCP's value to midnight UTC on the same calendar date, so a month means the same thing for all three. The charge period columns are left as GCP wrote them.

Its Tags column is not what the name suggests. On GCP the four keys this repo allocates by are labels, and the FOCUS export puts labels in two provider extensions, `x_Labels` for the resource's own labels and `x_ProjectLabels` for its project's. The extension called `x_Tags` holds Resource Manager tags, which are a separate GCP feature. So the view builds Tags from labels, with the resource's own label winning and the project's label filling in any key the resource does not set.

## Azure

The Azure export is Azure's own schema, not FOCUS, and it lands in BigQuery as text in every column. Each column is mapped by hand.

Dates are written as MM/DD/YYYY and every row covers one day, so ChargePeriodEnd is the day after ChargePeriodStart. The export leaves `billingPeriodStartDate` and `billingPeriodEndDate` empty, so BillingPeriodStart is taken as the first of the month the charge falls in.

`costInBillingCurrency` is what was billed after free allowances. `paygCostInBillingCurrency` is the pay-as-you-go price before them, which is what FOCUS calls ListCost. On this account the gap is the Log Analytics and Azure Monitor free allowances. There are no reservations or savings plans, so EffectiveCost is the same as BilledCost.

`chargeType` maps Usage and Purchase across unchanged, Refund to Credit, and anything else to Adjustment. Only Usage appeared in September.

Azure has no service name column that matches FOCUS. `meterCategory` is the nearest, and gives names like Container Registry and Virtual Network.

Tags arrive as one JSON object per row, such as `{"project":"azure-terraform-lab","env":"dev"}`. BigQuery's JSON functions need a fixed path, so they cannot pull out a key that is only known per row, and the first version of the view was rejected for trying. The view matches each `"key":"value"` pair as text instead. That relies on Azure writing tags as a flat object of text values, which it does, and it would need revisiting if a tag value ever contained a double quote.
