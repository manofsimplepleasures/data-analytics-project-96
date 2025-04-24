WITH tagged_sessions AS (
  SELECT 
    visitor_id,
    visit_date::date AS visit_date,
    LOWER(source) AS utm_source,
    LOWER(medium) AS utm_medium,
    LOWER(campaign) AS utm_campaign,
    ROW_NUMBER() OVER (
      PARTITION BY visitor_id 
      ORDER BY visit_date DESC
    ) AS rn
  FROM sessions
  WHERE LOWER(medium) IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

last_paid_clicks AS (
  SELECT 
    visitor_id,
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign
  FROM tagged_sessions
  WHERE rn = 1
),

leads_joined AS (
  SELECT 
    lpc.visitor_id,
    lpc.visit_date,
    lpc.utm_source,
    lpc.utm_medium,
    lpc.utm_campaign,
    l.lead_id,
    l.created_at,
    CASE 
      WHEN TRIM(l.amount::text) ~ '^[0-9]+(\.[0-9]+)?$' THEN CAST(l.amount AS NUMERIC)
      ELSE NULL 
    END AS amount,
    l.closing_reason,
    CASE 
      WHEN TRIM(l.status_id::text) ~ '^[0-9]+$' THEN CAST(l.status_id AS INTEGER)
      ELSE NULL 
    END AS status_id
  FROM last_paid_clicks lpc
  LEFT JOIN leads l 
    ON lpc.visitor_id = l.visitor_id 
   AND l.created_at::date >= lpc.visit_date
),

ads_combined AS (
  SELECT
    campaign_date::date AS visit_date,
    LOWER(utm_source) AS utm_source,
    LOWER(utm_medium) AS utm_medium,
    LOWER(utm_campaign) AS utm_campaign,
    CASE 
      WHEN TRIM(daily_spent::text) ~ '^[0-9]+(\.[0-9]+)?$' THEN CAST(daily_spent AS NUMERIC)
      ELSE 0 
    END AS daily_spent
  FROM ya_ads
  UNION ALL
  SELECT
    campaign_date::date,
    LOWER(utm_source),
    LOWER(utm_medium),
    LOWER(utm_campaign),
    CASE 
      WHEN TRIM(daily_spent::text) ~ '^[0-9]+(\.[0-9]+)?$' THEN CAST(daily_spent AS NUMERIC)
      ELSE 0 
    END
  FROM vk_ads
),

ads_costs AS (
  SELECT
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    SUM(daily_spent) AS total_cost
  FROM ads_combined
  GROUP BY 1, 2, 3, 4
),

visits_agg AS (
  SELECT
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    COUNT(DISTINCT visitor_id) AS visitors_count
  FROM last_paid_clicks
  GROUP BY 1, 2, 3, 4
),

leads_agg AS (
  SELECT
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    COUNT(DISTINCT lead_id) FILTER (WHERE lead_id IS NOT NULL) AS leads_count,
    COUNT(DISTINCT lead_id) FILTER (
      WHERE closing_reason = 'Успешная продажа' OR status_id = 142
    ) AS purchases_count,
    SUM(amount) FILTER (
      WHERE closing_reason = 'Успешная продажа' OR status_id = 142
    ) AS revenue
  FROM leads_joined
  GROUP BY 1, 2, 3, 4
)

SELECT
  v.visit_date,
  v.utm_source,
  v.utm_medium,
  v.utm_campaign,
  v.visitors_count,
  COALESCE(c.total_cost, 0)::NUMERIC AS total_cost,
  COALESCE(l.leads_count, 0)::INT AS leads_count,
  COALESCE(l.purchases_count, 0)::INT AS purchases_count,
  COALESCE(l.revenue, 0)::NUMERIC AS revenue,

  ROUND(CASE WHEN v.visitors_count > 0 THEN COALESCE(c.total_cost, 0) / v.visitors_count ELSE NULL END, 2) AS cpu,
  ROUND(CASE WHEN COALESCE(l.leads_count, 0) > 0 THEN COALESCE(c.total_cost, 0) / l.leads_count ELSE NULL END, 2) AS cpl,
  ROUND(CASE WHEN COALESCE(l.purchases_count, 0) > 0 THEN COALESCE(c.total_cost, 0) / l.purchases_count ELSE NULL END, 2) AS cppu,
  ROUND(CASE WHEN COALESCE(c.total_cost, 0) > 0 THEN (COALESCE(l.revenue, 0) - c.total_cost) / c.total_cost * 100 ELSE NULL END, 2) AS roi

FROM visits_agg v
LEFT JOIN leads_agg l
  ON v.visit_date = l.visit_date
 AND v.utm_source = l.utm_source
 AND v.utm_medium = l.utm_medium
 AND v.utm_campaign = l.utm_campaign
LEFT JOIN ads_costs c
  ON v.visit_date = c.visit_date
 AND v.utm_source = c.utm_source
 AND v.utm_medium = c.utm_medium
 AND v.utm_campaign = c.utm_campaign
ORDER BY
  revenue DESC NULLS LAST,
  v.visit_date ASC,
  v.utm_source,
  v.utm_medium,
  v.utm_campaign;
