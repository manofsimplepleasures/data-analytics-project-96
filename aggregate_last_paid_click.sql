WITH paid_sessions AS (
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
daily_visits AS (
    SELECT
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        COUNT(*) AS visitors_count
    FROM paid_sessions
    GROUP BY visit_date, utm_source, utm_medium, utm_campaign
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
    INNER JOIN leads l
        ON l.visitor_id = lpc.visitor_id
        AND l.created_at > lpc.visit_ts
),
leads_stats AS (
    SELECT
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        COUNT(lead_id) AS leads_count
    FROM attributed_leads
    GROUP BY visit_date, utm_source, utm_medium, utm_campaign
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
    WHERE status_id = 142
        OR closing_reason = 'Успешно реализовано'
    GROUP BY visit_date, utm_source, utm_medium, utm_campaign
),
marketing_costs AS (
    SELECT
        ads.visit_date,
        ads.utm_source,
        ads.utm_medium,
        ads.utm_campaign,
        SUM(ads.daily_spent) AS total_cost
    FROM (
        SELECT
            campaign_date::date AS visit_date,
            utm_source,
            utm_medium,
            utm_campaign,
            daily_spent
        FROM ya_ads
        UNION ALL
        SELECT
            campaign_date::date AS visit_date,
            utm_source,
            utm_medium,
            utm_campaign,
            daily_spent
        FROM vk_ads
    ) ads
    GROUP BY ads.visit_date, ads.utm_source, ads.utm_medium, ads.utm_campaign
)
SELECT
    dv.visit_date,
    dv.visitors_count,
    dv.utm_source,
    dv.utm_medium,
    dv.utm_campaign,
    COALESCE(mc.total_cost::text, '') AS total_cost,
    COALESCE(ls.leads_count, 0) AS leads_count,
    COALESCE(rs.purchases_count, 0) AS purchases_count,
    COALESCE(rs.revenue, 0) AS revenue
FROM daily_visits dv
LEFT JOIN marketing_costs mc
    ON mc.visit_date = dv.visit_date
    AND mc.utm_source = dv.utm_source
    AND mc.utm_medium = dv.utm_medium
    AND mc.utm_campaign = dv.utm_campaign
LEFT JOIN leads_stats ls
    ON ls.visit_date = dv.visit_date
    AND ls.utm_source = dv.utm_source
    AND ls.utm_medium = dv.utm_medium
    AND ls.utm_campaign = dv.utm_campaign
LEFT JOIN revenue_stats rs
    ON rs.visit_date = dv.visit_date
    AND rs.utm_source = dv.utm_source
    AND rs.utm_medium = dv.utm_medium
    AND rs.utm_campaign = dv.utm_campaign
ORDER BY
    rs.revenue DESC NULLS LAST,
    dv.visit_date ASC,
    dv.visitors_count DESC,
    dv.utm_source ASC,
    dv.utm_medium ASC,
    dv.utm_campaign ASC;