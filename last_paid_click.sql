WITH paid_sources AS (
    SELECT 'cpc' AS medium UNION ALL
    SELECT 'cpm' UNION ALL
    SELECT 'cpa' UNION ALL
    SELECT 'youtube' UNION ALL
    SELECT 'cpp' UNION ALL
    SELECT 'tg' UNION ALL
    SELECT 'social'
),

tagged_sessions AS (
    SELECT 
        s.*,
        CASE 
            WHEN ps.medium IS NOT NULL THEN TRUE
            ELSE FALSE
        END AS is_paid
    FROM sessions s
    LEFT JOIN paid_sources ps 
        ON LOWER(s.medium) = ps.medium
),

last_paid_sessions AS (
    SELECT DISTINCT ON (visitor_id)
        visitor_id,
        visit_date,
        source,
        medium,
        campaign
    FROM tagged_sessions
    WHERE is_paid = TRUE
    ORDER BY visitor_id, visit_date DESC
),

last_all_sessions AS (
    SELECT DISTINCT ON (visitor_id)
        visitor_id,
        visit_date,
        source,
        medium,
        campaign
    FROM tagged_sessions
    ORDER BY visitor_id, visit_date DESC
),

session_attribution AS (
    SELECT 
        COALESCE(lp.visitor_id, la.visitor_id) AS visitor_id,
        COALESCE(lp.visit_date, la.visit_date) AS visit_date,
        COALESCE(lp.source, la.source) AS utm_source,
        COALESCE(lp.medium, la.medium) AS utm_medium,
        COALESCE(lp.campaign, la.campaign) AS utm_campaign
    FROM last_all_sessions la
    LEFT JOIN last_paid_sessions lp ON la.visitor_id = lp.visitor_id
),

leads_joined AS (
    SELECT 
        sa.*,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id
    FROM session_attribution sa
    LEFT JOIN leads l 
        ON sa.visitor_id = l.visitor_id 
        AND l.created_at::date >= sa.visit_date
)

SELECT *
FROM leads_joined
ORDER BY 
    amount DESC NULLS LAST,
    visit_date ASC,
    utm_source,
    utm_medium,
    utm_campaign;