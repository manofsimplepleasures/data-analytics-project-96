WITH
    paid_sessions AS (
        SELECT
            visitor_id,
            visit_date       AS visit_ts,
            DATE(visit_date) AS visit_date,
            source           AS utm_source,
            medium           AS utm_medium,
            campaign         AS utm_campaign
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
    )
SELECT
    lpc.visitor_id,
    lpc.visit_date,
    lpc.utm_source,
    lpc.utm_medium,
    lpc.utm_campaign,
    lpc.visit_ts
FROM last_paid_click AS lpc
ORDER BY
    lpc.visitor_id ASC;