WITH
  paid_sessions AS (
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

  attributed_leads AS (
    SELECT
      lpc.visit_date,
      lpc.utm_source,
      lpc.utm_medium,
      lpc.utm_campaign,
      l.lead_id,
      l.status_id,
      l.closing_reason,
      l.amount
    FROM last_paid_click lpc
    JOIN leads l 
      ON l.visitor_id = lpc.visitor_id 
      AND l.created_at >= lpc.visit_ts
  )

SELECT
  lpc.visit_date,
  lpc.utm_source,
  lpc.utm_medium,
  lpc.utm_campaign,
  COUNT(DISTINCT lpc.visitor_id) AS visitors_count,
  COUNT(DISTINCT al.lead_id) AS leads_count,
  COUNT(DISTINCT CASE 
    WHEN al.status_id = 142 OR al.closing_reason = 'Успешно реализовано' 
    THEN al.lead