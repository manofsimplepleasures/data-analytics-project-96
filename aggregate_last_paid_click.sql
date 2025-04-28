WITH
  paid_sessions AS (
    select DISTINCT
      visitor_id,
      visit_date AS visit_ts,
      DATE(visit_date) AS visit_date,
      source AS utm_source,
      medium AS utm_medium,
      campaign AS utm_campaign
    FROM sessions
    WHERE medium IN ('cpc', 'cpp', 'cpa', 'social')
  ),

  last_paid_click AS (
    SELECT DISTINCT ON (visitor_id)
      visitor_id,
      visit_date,
      utm_source,
      utm_medium,
      utm_campaign,
      visit_ts
    FROM paid_sessions
    ORDER BY visitor_id, visit_ts DESC
  ),

  visitors_stats AS (
    SELECT
      visit_date,
      utm_source,
      utm_medium,
      utm_campaign,
      COUNT(visitor_id) AS visitors_count
    FROM last_paid_click
    GROUP BY 1, 2, 3, 4
  ),

  marketing_costs AS (
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
    ) combined_ads
    GROUP BY 1, 2, 3, 4
  ),

  attributed_leads AS (
    SELECT
      lpc.visit_date,
      lpc.utm_source,
      lpc.utm_medium,
      lpc.utm_campaign,
      l.lead_id,
      l.status_id,
      l.closing_reason,
      l.amount,
      l.created_at
    FROM last_paid_click lpc
    JOIN leads l ON l.visitor_id = lpc.visitor_id 
                AND l.created_at BETWEEN lpc.visit_ts AND lpc.visit_ts + INTERVAL '30 days'
  ),

  leads_stats AS (
    SELECT
      visit_date,
      utm_source,
      utm_medium,
      utm_campaign,
      COUNT(lead_id) AS leads_count
    FROM attributed_leads
    GROUP BY 1, 2, 3, 4
  ),

  revenue_stats AS (
    SELECT
      visit_date,
      utm_source,
      utm_medium,
      utm_campaign,
      COUNT(lead_id) AS purchases_count,
      SUM(amount) AS revenue
    FROM attributed_leads
    WHERE status_id = 142 OR closing_reason = 'Успешно реализовано'
    GROUP BY 1, 2, 3, 4
  )

SELECT
  vs.visit_date,
  vs.visitors_count,
  vs.utm_source,
  vs.utm_medium,
  vs.utm_campaign,
  CASE WHEN mc.total_cost IS NULL OR mc.total_cost = 0 THEN '' ELSE mc.total_cost::TEXT END AS total_cost,
  COALESCE(ls.leads_count, 0) AS leads_count,
  COALESCE(rs.purchases_count, 0) AS purchases_count,
  COALESCE(rs.revenue, 0) AS revenue
FROM visitors_stats vs
LEFT JOIN marketing_costs mc USING(visit_date, utm_source, utm_medium, utm_campaign)
LEFT JOIN leads_stats ls USING(visit_date, utm_source, utm_medium, utm_campaign)
LEFT JOIN revenue_stats rs USING(visit_date, utm_source, utm_medium, utm_campaign)
ORDER BY
  COALESCE(rs.revenue, 0) DESC,
  vs.visit_date ASC,
  vs.visitors_count DESC,
  vs.utm_source ASC,
  vs.utm_medium ASC,
  vs.utm_campaign asc;