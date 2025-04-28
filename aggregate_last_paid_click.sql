WITH
  -- 1) все платные сессии: TIMESTAMP и DATE
  paid AS (
    SELECT
      visitor_id,
      visit_date      AS visit_ts,
      DATE(visit_date) AS visit_date,
      source          AS utm_source,
      medium          AS utm_medium,
      campaign        AS utm_campaign
    FROM sessions
    WHERE medium IN ('cpc','cpp','cpa','social')
  ),

  -- 2) visitors_count = число визитов (строк) за день по UTM
  daily_visits AS (
    SELECT
      visit_date,
      utm_source,
      utm_medium,
      utm_campaign,
      COUNT(*) AS visitors_count
    FROM paid
    GROUP BY 1,2,3,4
  ),

  -- 3) расходы из Яндекс + VK
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

  -- 4) все пары (lead, его платный клик ДО создания)
  leads_sessions AS (
    SELECT
      l.lead_id,
      paid.visit_ts,
      paid.visit_date,
      paid.utm_source,
      paid.utm_medium,
      paid.utm_campaign,
      l.status_id,
      l.closing_reason,
      l.amount
    FROM leads l
    JOIN paid
      ON paid.visitor_id = l.visitor_id
     AND paid.visit_ts   < l.created_at
  ),

  -- 5) для каждого lead берём его ПОСЛЕДНИЙ платный клик
  leads_last_click AS (
    SELECT
      lead_id,
      visit_date,
      utm_source,
      utm_medium,
      utm_campaign,
      status_id,
      closing_reason,
      amount
    FROM (
      SELECT
        *,
        ROW_NUMBER() OVER (
          PARTITION BY lead_id
          ORDER BY visit_ts DESC
        ) AS rn
      FROM leads_sessions
    ) t
    WHERE rn = 1
  ),

  -- 6) число таких лидов по дню+UTM
  leads_cnt AS (
    SELECT
      visit_date,
      utm_source,
      utm_medium,
      utm_campaign,
      COUNT(*) AS leads_count
    FROM leads_last_click
    GROUP BY 1,2,3,4
  ),

  -- 7) успешные покупки + выручка
  purchases AS (
    SELECT
      visit_date,
      utm_source,
      utm_medium,
      utm_campaign,
      COUNT(*)    AS purchases_count,
      SUM(amount) AS revenue
    FROM leads_last_click
    WHERE status_id = 142
       OR closing_reason = 'Успешно реализовано'
    GROUP BY 1,2,3,4
  )

SELECT
  dv.visit_date,                   -- 1
  dv.visitors_count,               -- 2
  dv.utm_source,                   -- 3
  dv.utm_medium,                   -- 4
  dv.utm_campaign,                 -- 5
  COALESCE(ac.total_cost,   0)  AS total_cost,
  COALESCE(lc.leads_count,  0)  AS leads_count,
  COALESCE(p.purchases_count,0)  AS purchases_count,
  p.revenue                        AS revenue  -- 9
FROM daily_visits AS dv
LEFT JOIN ads_cost   AS ac USING(visit_date, utm_source, utm_medium, utm_campaign)
LEFT JOIN leads_cnt  AS lc USING(visit_date, utm_source, utm_medium, utm_campaign)
LEFT JOIN purchases  AS p  USING(visit_date, utm_source, utm_medium, utm_campaign)

ORDER BY
  9  DESC NULLS LAST,  -- revenue: от большего к меньшему, NULL в конец
  1   ASC,             -- visit_date: от ранних к поздним
  2   DESC,            -- visitors_count: убыванием
  3   ASC,             -- utm_source: алфавит
  4   ASC,             -- utm_medium
  5   asc;
