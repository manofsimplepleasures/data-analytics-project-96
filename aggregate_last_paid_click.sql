WITH
    paid_sessions AS (
        SELECT
            visitor_id,
            visit_date AS visit_ts,
            DATE(visit_date) AS visit_date,
            source AS utm_source,
            medium AS utm_medium,
            campaign AS utm_campaign
        FROM (
            SELECT
                visitor_id,
                visit_date,
                source,
                medium,
                campaign,
                ROW_NUMBER() OVER (
                    PARTITION BY visitor_id, visit_date, source, medium, campaign
                    ORDER BY visit_date DESC
                ) AS rn
            FROM sessions s
            WHERE visitor_id IS NOT NULL
              AND (
                  (source != 'vk' AND medium IN ('cpc', 'cpp', 'cpa', 'social'))
                  OR (source = 'vk')
              )
        ) ranked
        WHERE rn = 1
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
        ORDER BY visitor_id ASC, visit_ts DESC, utm_source ASC, utm_campaign ASC
    ),

    visitors_stats AS (
        SELECT
            visit_date,
            utm_source,
            utm_medium,
            utm_campaign,
            COUNT(visitor_id) AS visitors_count
        FROM last_paid_click
        GROUP BY visit_date, utm_source, utm_medium, utm_campaign
    ),

    marketing_costs AS (
        SELECT
            campaign_date::date AS visit_date,
            utm_source,
            utm_medium,
            utm_campaign,
            SUM(daily_spent) AS total_cost
        FROM (
            SELECT campaign_date, utm_source, utm_medium, utm_campaign, daily_spent
            FROM ya_ads y
            UNION ALL
            SELECT campaign_date, utm_source, utm_medium, utm_campaign, daily_spent
            FROM vk_ads v
        ) combined_ads
        WHERE campaign_date IS NOT NULL
        GROUP BY campaign_date::date, utm_source, utm_medium, utm_campaign
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
        JOIN leads l
            ON l.visitor_id = lpc.visitor_id
            AND l.created_at >= lpc.visit_ts
            AND l.created_at <= lpc.visit_ts + INTERVAL '31 days'
            AND l.visitor_id IS NOT NULL
            AND l.lead_id IS NOT NULL
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

    debug_sessions AS (
        SELECT
            visit_date,
            source AS utm_source,
            medium AS utm_medium,
            campaign AS utm_campaign,
            COUNT(DISTINCT visitor_id) AS debug_visitor_count
        FROM sessions s
        WHERE source = 'vk'
          AND campaign = 'prof-python'
          AND DATE(visit_date) = '2023-06-01'
          AND (medium NOT IN ('cpc', 'cpp', 'cpa', 'social') OR medium IS NULL)
        GROUP BY visit_date, source, medium, campaign
    )

SELECT
    vs.visit_date,
    vs.visitors_count,
    vs.utm_source,
    vs.utm_medium,
    vs.utm_campaign,
    CASE
        WHEN mc.total_cost IS NULL OR mc.total_cost = 0 THEN ''
        ELSE mc.total_cost::TEXT
    END AS total_cost,
    COALESCE(ls.leads_count, 0) AS leads_count,
    COALESCE(rs.purchases_count, 0) AS purchases_count,
    COALESCE(rs.revenue, 0) AS revenue
FROM visitors_stats vs
LEFT JOIN marketing_costs mc
    USING (visit_date, utm_source, utm_medium, utm_campaign)
LEFT JOIN leads_stats ls
    USING (visit_date, utm_source, utm_medium, utm_campaign)
LEFT JOIN revenue_stats rs
    USING (visit_date, utm_source, utm_medium, utm_campaign)
LEFT JOIN debug_sessions ds
    ON vs.visit_date = ds.visit_date
    AND vs.utm_source = ds.utm_source
    AND vs.utm_campaign = ds.utm_campaign
ORDER BY
    COALESCE(rs.revenue, 0) DESC,
    vs.visit_date ASC,
    vs.visitors_count DESC,
    vs.utm_source ASC,
    vs.utm_medium ASC,
    vs.utm_campaign ASC
LIMIT 15;