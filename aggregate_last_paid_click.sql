WITH tagged_sessions AS (
    SELECT 
        *,
        LOWER(source) AS utm_source,
        LOWER(medium) AS utm_medium,
        LOWER(campaign) AS utm_campaign
    FROM sessions
    WHERE LOWER(medium) IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

ranked_sessions AS (
    SELECT 
        s.*,
        ROW_NUMBER() OVER (PARTITION BY visitor_id ORDER BY visit_date DESC) AS rn
    FROM tagged_sessions s
),

last_paid_clicks AS (
    SELECT 
        visitor_id,
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
    FROM ranked_sessions
    WHERE rn = 1
),

session_leads AS (
    SELECT 
        lpc.*,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id
    FROM last_paid_clicks lpc
    LEFT JOIN leads l ON l.visitor_id = lpc.visitor_id
),

costs AS (
    SELECT
        campaign_date AS visit_date,
        LOWER(utm_source) AS utm_source,
        LOWER(utm_medium) AS utm_medium,
        LOWER(utm_campaign) AS utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM (
        SELECT
            campaign_date,
            utm_source,
            utm_medium,
            utm_campaign,
            utm_content,
            daily_spent
        FROM ya_ads
        UNION ALL
        SELECT
            campaign_date,
            utm_source,
            utm_medium,
            utm_campaign,
            utm_content,
            daily_spent
        FROM vk_ads
    ) ads
    GROUP BY campaign_date, utm_source, utm_medium, utm_campaign
),

final AS (
    SELECT 
        sl.visit_date,
        sl.utm_source,
        sl.utm_medium,
        sl.utm_campaign,
        COUNT(sl.visitor_id) AS visitors_count,
        COUNT(sl.lead_id) FILTER (WHERE sl.lead_id IS NOT NULL) AS leads_count,
        COUNT(sl.lead_id) FILTER (
            WHERE sl.closing_reason = 'Успешно реализовано'
               OR sl.status_id = 142
        ) AS purchases_count,
        SUM(sl.amount) FILTER (
            WHERE sl.closing_reason = 'Успешно реализовано'
               OR sl.status_id = 142
        ) AS revenue
    FROM session_leads sl
    GROUP BY sl.visit_date, sl.utm_source, sl.utm_medium, sl.utm_campaign
)

SELECT 
    f.visit_date,
    f.utm_source,
    f.utm_medium,
    f.utm_campaign,
    f.visitors_count,
    COALESCE(c.total_cost, 0) AS total_cost,
    f.leads_count,
    f.purchases_count,
    f.revenue
FROM final f
LEFT JOIN costs c
  ON f.visit_date = c.visit_date
 AND f.utm_source = c.utm_source
 AND f.utm_medium = c.utm_medium
 AND f.utm_campaign = c.utm_campaign
ORDER BY
    f.revenue DESC NULLS LAST,
    f.visit_date ASC,
    f.visitors_count DESC,
    f.utm_source,
    f.utm_medium,
    f.utm_campaign;
