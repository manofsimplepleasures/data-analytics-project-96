WITH
  -- 1) Платные сессии: сохраняем TIMESTAMP (visit_ts) и дату визита (visit_date)
  paid AS (
    SELECT
      visitor_id,
      visit_date       AS visit_ts,          -- полный TIMESTAMP
      DATE(visit_date) AS visit_date,        -- дата для группировок
      source           AS utm_source,
      medium           AS utm_medium,
      campaign         AS utm_campaign
    FROM sessions
    WHERE medium IN ('cpc','cpp','cpa','social')
  ),

  -- 2) Последний платный клик каждого visitor (глобально)
  last_click AS (
    SELECT
      visitor_id,
      visit_date,     -- DATE
      utm_source,
      utm_medium,
      utm_campaign,
      visit_ts        -- TIMESTAMP последнего клика
    FROM (
      SELECT
        visitor_id,
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        visit_ts,
        ROW_NUMBER() OVER (
          PARTITION BY visitor_id
          ORDER BY visit_ts DESC
        ) AS rn
      FROM paid
    ) t
    WHERE rn = 1
  ),

  -- 3) visitors_count = число посетителей (в last_click) с датой клика и UTM
  visitors_agg AS (
    SELECT
      visit_date,
      utm_source,
      utm_medium,
      utm_campaign,
      COUNT(*) AS visitors_count
    FROM last_click
    GROUP BY 1,2,3,4
  ),

  -- 4) Расходы с Яндекс+VK
  ads AS (
    SELECT
      campaign_date::date AS visit_date,
      utm_source,
      utm_medium,
      utm_campaign,
      SUM(daily_spent)     AS total_cost
    FROM (
      SELECT campaign_date, utm_source, utm_medium, utm_campaign, daily_spent FROM ya_ads
      UNION ALL
      SELECT campaign_date, utm_source, utm_medium, utm_campaign, daily_spent FROM vk_ads
    ) x
    GROUP BY 1,2,3,4
  ),

  -- 5) Атрибуция лидов по последнему клику
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
    JOIN leads l
      ON l.visitor_id = lc.visitor_id
     AND l.created_at > lc.visit_ts
  ),

  -- 6) Число атрибутированных лидов
  leads_cnt AS (
    SELECT
      visit_date,
      utm_source,
      utm_medium,
      utm_campaign,
      COUNT(*) AS leads_count
    FROM leads_attributed
    GROUP BY 1,2,3,4
  ),

  -- 7) Успешные покупки + выручка
  purchases AS (
    SELECT
      visit_date,
      utm_source,
      utm_medium,
      utm_campaign,
      COUNT(*)    AS purchases_count,
      SUM(amount) AS revenue
    FROM leads_attributed
    WHERE status_id = 142
       OR closing_reason = 'Успешно реализовано'
    GROUP BY 1,2,3,4
  )

SELECT
  va.visit_date,                   -- 1
  va.visitors_count,               -- 2
  va.utm_source,                   -- 3
  va.utm_medium,                   -- 4
  va.utm_campaign,                 -- 5
  COALESCE(NULLIF(a.total_cost, 0)::text, '') AS total_cost,
  COALESCE(lc.leads_count, 0) AS leads_count,
  COALESCE(p.purchases_count, 0) AS purchases_count,
  p.revenue                        AS revenue    -- 9
FROM visitors_agg AS va
LEFT JOIN ads AS a USING(visit_date, utm_source, utm_medium, utm_campaign)
LEFT JOIN leads_cnt AS lc USING(visit_date, utm_source, utm_medium, utm_campaign)
LEFT JOIN purchases AS p USING(visit_date, utm_source, utm_medium, utm_campaign)
ORDER BY
  p.revenue DESC NULLS LAST,
  va.visit_date ASC,
  va.visitors_count DESC,
  va.utm_source ASC,
  va.utm_medium ASC,
  va.utm_campaign asc;