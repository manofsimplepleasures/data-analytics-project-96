WITH
  -- 1) все платные сессии: сохраняем TIMESTAMP и DATE
  paid AS (
    SELECT
      visitor_id,
      visit_date       AS visit_ts,            -- полный TIMESTAMP
      DATE(visit_date) AS visit_date,          -- DATE для группировок
      source           AS utm_source,
      medium           AS utm_medium,
      campaign         AS utm_campaign
    FROM sessions
    WHERE medium IN ('cpc','cpp','cpa','social')
  ),

  -- 2) глобальный «last click» по каждому visitor
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

  -- 3) visitors_count = число таких посетителей (последних кликов) по каждой дате/UTM
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

  -- 4) расходы из Яндекс + VK
  ads_cost AS (
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

  -- 5) атрибуция лидов: only those with created_at > last_click.ts
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

  -- 6) число атрибутированных лидов
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

  -- 7) успешные сделки + выручка
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
  COALESCE(ac.total_cost,   0)   AS total_cost,
  COALESCE(lc.leads_count,  0)   AS leads_count,
  COALESCE(p.purchases_count,0)  AS purchases_count,
  p.revenue                        AS revenue    -- 9
FROM visitors_agg AS va
LEFT JOIN ads_cost     AS ac  USING(visit_date, utm_source, utm_medium, utm_campaign)
LEFT JOIN leads_cnt    AS lc  USING(visit_date, utm_source, utm_medium, utm_campaign)
LEFT JOIN purchases    AS p   USING(visit_date, utm_source, utm_medium, utm_campaign)

ORDER BY
  9  DESC NULLS LAST,  -- revenue: от большего к меньшему, NULL вконец
  1   ASC,             -- visit_date: от ранних к поздним
  2   DESC,            -- visitors_count: убыванием
  3   ASC,             -- utm_source: алфавит
  4   ASC,             -- utm_medium
  5   asc;
