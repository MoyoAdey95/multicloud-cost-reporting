-- One row per charge, with the four allocation tags pulled out into columns.
-- A charge with no project tag is shown as unallocated rather than dropped, so
-- the untagged share of the bill stays visible and adds up with the rest.
--
-- All three providers bill this lab in USD. BillingCurrency is kept so that a
-- report can group by it, and a second currency would show up as its own line
-- rather than being added to the first.
SELECT
  ProviderName,
  BillingPeriodStart,
  ChargePeriodStart,
  BillingCurrency,
  SubAccountName,
  ServiceName,
  ResourceName,
  BilledCost,
  EffectiveCost,
  ListCost,
  IFNULL((SELECT value FROM UNNEST(Tags) WHERE key = 'project' LIMIT 1), 'unallocated') AS project,
  IFNULL((SELECT value FROM UNNEST(Tags) WHERE key = 'env' LIMIT 1), 'unallocated') AS env,
  IFNULL((SELECT value FROM UNNEST(Tags) WHERE key = 'owner' LIMIT 1), 'unallocated') AS owner,
  IFNULL((SELECT value FROM UNNEST(Tags) WHERE key = 'managed-by' LIMIT 1), 'unallocated') AS managed_by
FROM `${dataset}.focus_all`
