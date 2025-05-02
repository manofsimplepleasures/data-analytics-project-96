WITH paid_sessions AS (
    SELECT
        visitor_id,
        source AS utm_source,
        medium AS utm_medium,
        campaign AS utm_campaign,
        visit_date AS visit_ts,
        DATE(visit_date) AS visit_date
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
    ORDER BY visitor_id ASC, visit_ts DESC
)

SELECT
    visitor_id,
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    visit_ts
FROM last_paid_click
ORDER BY visitor_id ASC;
