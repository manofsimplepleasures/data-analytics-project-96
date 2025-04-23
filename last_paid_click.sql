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
    l.amount,
    l.closing_reason,
    l.status_id
  FROM last_paid_clicks lpc
  LEFT JOIN leads l 
    ON lpc.visitor_id = l.visitor_id 
   AND l.created_at::date >= lpc.visit_date
)

SELECT *
FROM leads_joined
ORDER BY 
  amount DESC NULLS LAST,
  visit_date ASC,
  utm_source,
  utm_medium,
  utm_campaign;
