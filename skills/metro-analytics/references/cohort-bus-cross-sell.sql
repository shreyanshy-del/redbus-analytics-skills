-- METRO ACQUIRED NEW USERS IN THAT CITY WHO HAVE TRANSACTED IN ANY BUS
-- Edit params.acq_start / acq_end / lifetime_start / retention_end only.

WITH params AS (
    SELECT
        CAST('2025-04-01 00:00:00' AS TIMESTAMP) AS acq_start,
        CAST('2025-07-01 00:00:00' AS TIMESTAMP) AS acq_end,
        CAST('2015-01-01 00:00:00' AS TIMESTAMP) AS lifetime_start,
        CAST('2026-07-01 00:00:00' AS TIMESTAMP) AS retention_end
),
metro_city_map AS (
    SELECT * FROM (VALUES
        ('MaharashtraMetroRailCoLtd', 'Pune'),
        ('Mumbai Metro One Pvt Ltd', 'Mumbai'),
        ('Bangalore Metro Rail Corporation Limited', 'Bangalore'),
        ('Mumbai Metro Rail Corporation Limited', 'Mumbai'),
        ('Kochi Metro Rail Limited', 'Ernakulam'),
        ('Maha Mumbai Metro Operation Corporation Limited', 'Mumbai'),
        ('Chennai Metro Rail Limited', 'Chennai'),
        ('Delhi Metro Rail Corporation', 'Delhi')
    ) AS t(service_provider_name, city)
),
cities AS (
    SELECT city FROM (VALUES
        ('Chennai'),('Bangalore'),('Ernakulam'),('Mumbai'),('Delhi'),('Pune')
    ) AS t(city)
),
metro_txns AS (
    SELECT a.rb_user_id, m.city, a.tin, a.time_of_event
    FROM transaction.addon_item a
    CROSS JOIN params p
    INNER JOIN metro_city_map m ON a.service_provider_name = m.service_provider_name
    WHERE a.time_of_event >= p.lifetime_start
      AND a.time_of_event < p.acq_end
      AND a.item_type = 13 AND a.s_c_t = 'Ticket' AND a.c_t = 'METRO_TICKETING'
      AND a.event_type = 101 AND a.status = 'CONFIRMED'
      AND a.rb_user_id IS NOT NULL AND a.rb_user_id <> 0 AND a.tin IS NOT NULL
),
first_metro_ever AS (
    SELECT rb_user_id, MIN(time_of_event) AS first_metro_ts
    FROM metro_txns
    GROUP BY 1
),
cohort_base AS (
    SELECT
        f.rb_user_id,
        f.first_metro_ts AS cohort_date,
        MIN_BY(m.city, m.time_of_event) AS acq_city
    FROM first_metro_ever f
    INNER JOIN metro_txns m
        ON f.rb_user_id = m.rb_user_id
       AND f.first_metro_ts = m.time_of_event
    CROSS JOIN params p
    WHERE f.first_metro_ts >= p.acq_start
      AND f.first_metro_ts < p.acq_end
    GROUP BY f.rb_user_id, f.first_metro_ts
),
brh_in_acq_window AS (
    SELECT DISTINCT rb_user_id FROM (
        SELECT b.rb_user_id
        FROM transaction.bus_ticket_events b CROSS JOIN params p
        WHERE b.time_of_event >= p.acq_start AND b.time_of_event < p.acq_end
          AND b.event_class = 2 AND b.event_type = 101 AND b.country_code = 'IND'
          AND b.rb_user_id IS NOT NULL AND b.rb_user_id <> 0
        UNION
        SELECT r.rb_user_id
        FROM transaction.rail_ticket_events r CROSS JOIN params p
        WHERE r.date_of_issue >= p.acq_start AND r.date_of_issue < p.acq_end
          AND r.event_class = 2 AND r.event_type = 101 AND r.country = 'IND'
          AND r.rb_user_id IS NOT NULL AND r.rb_user_id <> 0
        UNION
        SELECT h.rb_user_id
        FROM transaction.hotel_booking_events h CROSS JOIN params p
        WHERE h.date_of_issue >= p.acq_start AND h.date_of_issue < p.acq_end
          AND h.event_class = 2 AND h.event_type = 101 AND h.country_code = 'IND'
          AND h.rb_user_id IS NOT NULL AND h.rb_user_id <> 0
    ) x
),
cohort AS (
    SELECT c.*
    FROM cohort_base c
    LEFT JOIN brh_in_acq_window b ON c.rb_user_id = b.rb_user_id
    WHERE b.rb_user_id IS NULL
),
bus_txns AS (
    SELECT
        b.rb_user_id,
        c.city,
        b.time_of_event
    FROM transaction.bus_ticket_events b
    CROSS JOIN params p
    LEFT JOIN cities c
        ON b.source_location = c.city
        OR b.destination_location = c.city
    WHERE b.time_of_event >= p.acq_start
      AND b.time_of_event < p.retention_end
      AND b.event_class = 2
      AND b.event_type = 101
      AND b.country_code = 'IND'
      AND b.rb_user_id IS NOT NULL
      AND b.rb_user_id <> 0
),
retention_flags AS (
    SELECT
        c.rb_user_id,
        c.acq_city,
        c.cohort_date,
        MAX(CASE WHEN b.time_of_event > c.cohort_date AND b.time_of_event <= c.cohort_date + INTERVAL '30' DAY AND b.city = c.acq_city THEN 1 ELSE 0 END) AS same_30,
        MAX(CASE WHEN b.time_of_event > c.cohort_date AND b.time_of_event <= c.cohort_date + INTERVAL '90' DAY AND b.city = c.acq_city THEN 1 ELSE 0 END) AS same_90,
        MAX(CASE WHEN b.time_of_event > c.cohort_date AND b.time_of_event <= c.cohort_date + INTERVAL '180' DAY AND b.city = c.acq_city THEN 1 ELSE 0 END) AS same_180,
        MAX(CASE WHEN b.time_of_event > c.cohort_date AND b.time_of_event <= c.cohort_date + INTERVAL '365' DAY AND b.city = c.acq_city THEN 1 ELSE 0 END) AS same_365,
        MAX(CASE WHEN b.time_of_event > c.cohort_date AND b.time_of_event <= c.cohort_date + INTERVAL '30' DAY THEN 1 ELSE 0 END) AS any_30,
        MAX(CASE WHEN b.time_of_event > c.cohort_date AND b.time_of_event <= c.cohort_date + INTERVAL '90' DAY THEN 1 ELSE 0 END) AS any_90,
        MAX(CASE WHEN b.time_of_event > c.cohort_date AND b.time_of_event <= c.cohort_date + INTERVAL '180' DAY THEN 1 ELSE 0 END) AS any_180,
        MAX(CASE WHEN b.time_of_event > c.cohort_date AND b.time_of_event <= c.cohort_date + INTERVAL '365' DAY THEN 1 ELSE 0 END) AS any_365
    FROM cohort c
    LEFT JOIN bus_txns b ON c.rb_user_id = b.rb_user_id
    GROUP BY 1, 2, 3
)
SELECT
    acq_city AS city,
    COUNT(*) AS cohort_users,
    SUM(same_30) AS retained_acq_city_bus_30d,
    SUM(same_90) AS retained_acq_city_bus_90d,
    SUM(same_180) AS retained_acq_city_bus_180d,
    SUM(same_365) AS retained_acq_city_bus_365d,
    ROUND(100.0 * SUM(same_30) / COUNT(*), 2) AS retained_acq_city_bus_pct_30d,
    ROUND(100.0 * SUM(same_90) / COUNT(*), 2) AS retained_acq_city_bus_pct_90d,
    ROUND(100.0 * SUM(same_180) / COUNT(*), 2) AS retained_acq_city_bus_pct_180d,
    ROUND(100.0 * SUM(same_365) / COUNT(*), 2) AS retained_acq_city_bus_pct_365d,
    SUM(any_30) AS retained_any_bus_30d,
    SUM(any_90) AS retained_any_bus_90d,
    SUM(any_180) AS retained_any_bus_180d,
    SUM(any_365) AS retained_any_bus_365d,
    ROUND(100.0 * SUM(any_30) / COUNT(*), 2) AS retained_any_bus_pct_30d,
    ROUND(100.0 * SUM(any_90) / COUNT(*), 2) AS retained_any_bus_pct_90d,
    ROUND(100.0 * SUM(any_180) / COUNT(*), 2) AS retained_any_bus_pct_180d,
    ROUND(100.0 * SUM(any_365) / COUNT(*), 2) AS retained_any_bus_pct_365d
FROM retention_flags
GROUP BY acq_city
ORDER BY CASE acq_city
    WHEN 'Bangalore' THEN 1 WHEN 'Chennai' THEN 2 WHEN 'Delhi' THEN 3
    WHEN 'Ernakulam' THEN 4 WHEN 'Mumbai' THEN 5 WHEN 'Pune' THEN 6 ELSE 99
END;
