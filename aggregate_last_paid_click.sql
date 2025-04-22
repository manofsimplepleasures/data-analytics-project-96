WITH all_ads AS (
    SELECT
        campaign_date::date AS visit_date,
        LOWER(utm_source) AS utm_source,
        LOWER(utm_medium) AS utm_medium,
        LOWER(utm_campaign) AS utm_campaign,
        daily_spent
    FROM ya_ads
    UNION ALL
    SELECT
        campaign_date::date AS visit_date,
        LOWER(utm_source) AS utm_source,
        LOWER(utm_medium) AS utm_medium,
        LOWER(utm_campaign) AS utm_campaign,
        daily_spent
    FROM vk_ads
),

ads_costs AS (
    SELECT
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM all_ads
    GROUP BY visit_date, utm_source, utm_medium, utm_campaign
),

tagged_sessions AS (
    SELECT 
        visitor_id,
        visit_date::date AS visit_date,
        LOWER(source) AS utm_source,
        LOWER(medium) AS utm_medium,
        LOWER(campaign) AS utm_campaign,
        ROW_NUMBER() OVER (PARTITION BY visitor_id ORDER BY visit_date DESC) AS rn
    FROM sessions
    WHERE LOWER(medium) IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

last_paid_clicks AS (
    SELECT *
    FROM tagged_sessions
    WHERE rn = 1
),

session_leads AS (
    SELECT 
        s.visit_date,
        s.visitor_id,
        s.utm_source,
        s.utm_medium,
        s.utm_campaign,
        l.lead_id,
        l.amount,
        l.created_at,
        l.status_id,
        l.closing_reason
    FROM last_paid_clicks s
    LEFT JOIN leads l ON s.visitor_id = l.visitor_id
),

aggregated AS (
    SELECT 
        sl.visit_date,
        sl.utm_source,
        sl.utm_medium,
        sl.utm_campaign,
        COUNT(DISTINCT sl.visitor_id) AS visitors_count,
        COUNT(DISTINCT sl.lead_id) FILTER (WHERE sl.lead_id IS NOT NULL) AS leads_count,
        COUNT(DISTINCT sl.lead_id) FILTER (
            WHERE sl.closing_reason = 'Успешно реализовано' OR sl.status_id = 142
        ) AS purchases_count,
        SUM(sl.amount) FILTER (
            WHERE sl.closing_reason = 'Успешно реализовано' OR sl.status_id = 142
        ) AS revenue
    FROM session_leads sl
    GROUP BY sl.visit_date, sl.utm_source, sl.utm_medium, sl.utm_campaign
)

SELECT 
    a.visit_date,
    a.utm_source,
    a.utm_medium,
    a.utm_campaign,
    a.visitors_count,
    COALESCE(c.total_cost, 0) AS total_cost,
    a.leads_count,
    a.purchases_count,
    a.revenue
FROM aggregated a
LEFT JOIN ads_costs c
  ON a.visit_date = c.visit_date
 AND a.utm_source = c.utm_source
 AND a.utm_medium = c.utm_medium
 AND a.utm_campaign = c.utm_campaign
ORDER BY 
    a.revenue DESC NULLS LAST,
    a.visit_date ASC,
    a.visitors_count DESC,
    a.utm_source,
    a.utm_medium,
    a.utm_campaign;

