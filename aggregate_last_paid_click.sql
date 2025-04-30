WITH paid_sessions AS (
    SELECT DISTINCT ON (visitor_id, DATE(visit_date), source, medium, campaign)
        visitor_id,
        visit_date AS visit_ts,
        source AS utm_source,
        medium AS utm_medium,
        campaign AS utm_campaign,
        DATE(visit_date) AS visit_date
    FROM sessions
    WHERE
        visitor_id IS NOT NULL
        AND medium IN ('cpc', 'cpp', 'cpa', 'social')
    ORDER BY
        visitor_id ASC,
        DATE(visit_date),
        source ASC,
        medium ASC,
        campaign ASC,
        visit_date DESC
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
    ORDER BY visitor_id ASC, visit_ts DESC
),

ads_data AS (
    SELECT
        campaign_date::date AS visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM (
        SELECT
            campaign_date,
            utm_source,
            utm_medium,
            utm_campaign,
            daily_spent
        FROM ya_ads
        UNION ALL
        SELECT
            campaign_date,
            utm_source,
            utm_medium,
            utm_campaign,
            daily_spent
        FROM vk_ads
    ) AS ads
    WHERE campaign_date IS NOT NULL
    GROUP BY
        campaign_date::date,
        utm_source,
        utm_medium,
        utm_campaign
),

attributed_data AS (
    SELECT
        lpc.visit_date,
        lpc.utm_source,
        lpc.utm_medium,
        lpc.utm_campaign,
        COUNT(DISTINCT lpc.visitor_id) AS visitors_count,
        COUNT(DISTINCT l.lead_id) AS leads_count,
        COUNT(DISTINCT CASE
            WHEN l.status_id = 142 OR l.closing_reason = 'Успешно реализовано'
            THEN l.lead_id
        END) AS purchases_count,
        SUM(CASE
            WHEN l.status_id = 142 OR l.closing_reason = 'Успешно реализовано'
            THEN l.amount
            ELSE 0
        END) AS revenue
    FROM last_paid_click AS lpc
                LEFT JOIN leads AS l
                    ON lpc.visitor_id = l.visitor_id
                    AND l.created_at BETWEEN lpc.visit_ts
                        AND lpc.visit_ts + interval '31 days'
                    AND l.lead_id IS NOT NULL
    GROUP BY
                lpc.visit_date,
                lpc.utm_source,
                lpc.utm_medium,
                lpc.utm_campaign
)

SELECT
        ad.visit_date,
        ad.visitors_count,
        ad.utm_source,
        ad.utm_medium,
        ad.utm_campaign,
        CASE
            WHEN ac.total_cost IS NULL OR ac.total_cost = 0 THEN ''
            ELSE ac.total_cost::text
        END AS total_cost,
        COALESCE(ad.leads_count, 0) AS leads_count,
        COALESCE(ad.purchases_count, 0) AS purchases_count,
        COALESCE(ad.revenue, 0) AS revenue
FROM attributed_data AS ad
        LEFT JOIN ads_data AS ac
            ON ad.visit_date = ac.visit_date
            AND ad.utm_source = ac.utm_source
            AND ad.utm_medium = ac.utm_medium
            AND ad.utm_campaign = ac.utm_campaign
ORDER BY
    ad.revenue DESC NULLS LAST,
    ad.visit_date ASC,
    ad.visitors_count DESC,
    ad.utm_source ASC,
    ad.utm_medium ASC,
    ad.utm_campaign ASC
LIMIT 15;

