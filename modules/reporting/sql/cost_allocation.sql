-- One row per charge, with the four allocation tags pulled out into columns
-- and each charge put in one of three allocation states.
--
-- Allocated means the charge carries a project tag. Not taggable means it is
-- tax or an adjustment such as rounding, which no provider lets you tag, so
-- no amount of tagging discipline would move it. Unallocated is everything
-- else, the part a team can actually fix. Keeping not taggable separate stops
-- tax being reported as a tagging failure. FOCUS's ChargeCategory marks these
-- rows the same way for every provider, so tax that AWS or Azure add when a
-- month closes lands in the right state without a change here.
--
-- Nothing is dropped, so the three states always add up to the total bill.
-- All three providers bill this lab in USD. BillingCurrency is kept so that a
-- report can group by it, and a second currency would show up as its own line
-- rather than being added to the first.
WITH tagged AS (
  SELECT
    *,
    (SELECT value FROM UNNEST(Tags) WHERE key = 'project' LIMIT 1) AS project_tag,
    ChargeCategory IN ('Tax', 'Adjustment') AS not_taggable
  FROM `${dataset}.focus_all`
)

SELECT
  ProviderName,
  BillingPeriodStart,
  ChargePeriodStart,
  BillingCurrency,
  ChargeCategory,
  SubAccountName,
  ServiceName,
  ResourceName,
  BilledCost,
  EffectiveCost,
  ListCost,
  CASE
    WHEN not_taggable THEN 'Not taggable'
    WHEN project_tag IS NOT NULL THEN 'Allocated'
    ELSE 'Unallocated'
  END AS allocation_status,
  CASE
    WHEN not_taggable THEN 'not taggable'
    ELSE IFNULL(project_tag, 'unallocated')
  END AS project,
  IFNULL((SELECT value FROM UNNEST(Tags) WHERE key = 'env' LIMIT 1), 'unallocated') AS env,
  IFNULL((SELECT value FROM UNNEST(Tags) WHERE key = 'owner' LIMIT 1), 'unallocated') AS owner,
  IFNULL((SELECT value FROM UNNEST(Tags) WHERE key = 'managed-by' LIMIT 1), 'unallocated') AS managed_by
FROM tagged
