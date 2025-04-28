WITH
  paid AS (
    SELECT
      visitor_id,
      visit_date AS visit_ts,
      DATE(visit_date) AS visit_date,
      source AS utm_source,
      medium AS utm_medium,
      campaign AS utm_campaign
    FROM sessions
    WHERE medium IN ('cpc', 'cpp', 'cpa', 'social')
  ),

  last_click AS (
    SELECT DISTINCT ON (visitor_id)
      visitor_id,
      visit_date,
      utm_source,
      utm_medium,
      utm_campaign,
      visit_ts
    FROM paid
    ORDER BY visitor_id, visit_ts DESC
  ),

  visitors_agg AS (
    SELECT
      visit_date,
      utm_source,
      utm_medium,
      utm_campaign,
      COUNT(DISTINCT visitor_id) AS visitors_count
    FROM last_click
    GROUP BY 1, 2, 3, 4
  ),

  ads AS (
    SELECT
      campaign_date::date AS visit_date,
      utm_source,
      utm_medium,
      utm_campaign,
      SUM(daily_spent) AS total_cost
    FROM (
      SELECT campaign_date, utm_source, utm_medium, utm_campaign, daily_spent FROM ya_ads
      UNION ALL
      SELECT campaign_date, utm_source, utm_medium, utm_campaign, daily_spent FROM vk_ads
    ) x
    GROUP BY 1, 2, 3, 4
  ),

  leads_attributed AS (
    SELECT
      lc.visit_date,
      lc.utm_source,
      lc.utm_medium,
      lc.utm_campaign,
      l.lead_id,
      l.status_id,
      l.closing_reason,
      l.amount
    FROM last_click lc
    JOIN leads l ON l.visitor_id = lc.visitor_id AND l.created_at >= lc.visit_ts
  ),

  leads_cnt AS (
    SELECT
      visit_date,
      utm_source,
      utm_medium,
      utm_campaign,
      COUNT(DISTINCT lead_id) AS leads_count
    FROM leads_attributed
    GROUP BY 1, 2, 3, 4
  ),

  purchases AS (
    SELECT
      visit_date,
      utm_source,
      utm_medium,
      utm_campaign,
      COUNT(DISTINCT lead_id) AS purchases_count,
      SUM(amount) AS revenue
    FROM leads_attributed
    WHERE status_id = 142 OR closing_reason = 'Успешно реализовано'
    GROUP BY 1, 2, 3, 4
  )

SELECT
  va.visit_date,
  va.visitors_count,
  va.utm_source,
  va.utm_medium,
  va.utm_campaign,
  NULLIF(a.total_cost, 0)::TEXT AS total_cost,
  COALESCE(lc.leads_count, 0) AS leads_count,
  COALESCE(p.purchases_count, 0) AS purchases_count,
  COALESCE(p.revenue, 0) AS revenue
FROM visitors_agg va
LEFT JOIN ads a USING(visit_date, utm_source, utm_medium, utm_campaign)
LEFT JOIN leads_cnt lc USING(visit_date, utm_source, utm_medium, utm_campaign)
LEFT JOIN purchases p USING(visit_date, utm_source, utm_medium, utm_campaign)
ORDER BY
  COALESCE(p.revenue, 0) DESC,
  va.visit_date ASC,
  va.visitors_count DESC,
  va.utm_source ASC,
  va.utm_medium ASC,
  va.utm_campaign asc
limit 15;