-- Metro DRRs, Seats, Unique Users, New Users (IST daily, last 30 complete days by default)
-- Override params.start_ist / today_ist for a fixed range if needed.

WITH params AS (
    SELECT
        CAST(AT_TIMEZONE(CURRENT_TIMESTAMP, 'Asia/Kolkata') AS DATE) AS today_ist,
        DATE_ADD('day', -30, CAST(AT_TIMEZONE(CURRENT_TIMESTAMP, 'Asia/Kolkata') AS DATE)) AS start_ist,
        CAST('2015-01-01' AS DATE) AS history_start_ist
),

metro_city_map AS (
    SELECT *
    FROM (
        VALUES
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

metro_raw AS (
    SELECT
        a.rb_user_id,
        a.tin,
        m.city,
        a.time_of_event,
        CAST(AT_TIMEZONE(a.time_of_event, 'Asia/Kolkata') AS DATE) AS event_date_ist,
        /* quantity varchar like [1,1] => 2; always at least 1 seat per txn */
        GREATEST(
            COALESCE(
                CARDINALITY(TRY(CAST(json_parse(a.quantity) AS ARRAY(INTEGER)))),
                CARDINALITY(
                    TRY(
                        FILTER(
                            TRANSFORM(
                                SPLIT(
                                    REPLACE(REPLACE(REPLACE(a.quantity, '[', ''), ']', ''), ' ', ''),
                                    ','
                                ),
                                x -> TRY_CAST(x AS INTEGER)
                            ),
                            x -> x IS NOT NULL
                        )
                    )
                ),
                0
            ),
            1
        ) AS seats
    FROM transaction.addon_item a
    INNER JOIN metro_city_map m
        ON a.service_provider_name = m.service_provider_name
    CROSS JOIN params p
    WHERE a.country_code = 'IND'
      AND a.item_type = 13
      AND a.s_c_t = 'Ticket'
      AND a.c_t = 'METRO_TICKETING'
      AND a.event_type = 101
      AND a.status = 'CONFIRMED'
      AND a.tin IS NOT NULL
      AND CAST(AT_TIMEZONE(a.time_of_event, 'Asia/Kolkata') AS DATE) >= p.history_start_ist
      AND CAST(AT_TIMEZONE(a.time_of_event, 'Asia/Kolkata') AS DATE) <  p.today_ist
),

metro_txns AS (
    SELECT
        tin,
        MAX(rb_user_id) AS rb_user_id,
        MAX(city) AS city,
        MAX(event_date_ist) AS event_date_ist,
        MAX(time_of_event) AS time_of_event,
        MAX(seats) AS seats
    FROM metro_raw
    GROUP BY tin
),

user_first_metro AS (
    SELECT
        rb_user_id,
        city AS first_city,
        event_date_ist AS first_date_ist
    FROM (
        SELECT
            rb_user_id,
            city,
            event_date_ist,
            ROW_NUMBER() OVER (
                PARTITION BY rb_user_id
                ORDER BY time_of_event, tin
            ) AS rn
        FROM metro_txns
        WHERE rb_user_id IS NOT NULL
          AND rb_user_id <> 0
    ) x
    WHERE rn = 1
),

daily_city AS (
    SELECT
        t.event_date_ist,
        t.city AS metro,
        COUNT(DISTINCT t.tin) AS transactions,
        SUM(t.seats) AS rides_seats,
        COUNT(DISTINCT CASE
            WHEN t.rb_user_id IS NOT NULL AND t.rb_user_id <> 0
            THEN t.rb_user_id
        END) AS unique_users,
        COUNT(DISTINCT CASE
            WHEN f.rb_user_id IS NOT NULL
             AND f.first_date_ist = t.event_date_ist
             AND f.first_city = t.city
            THEN f.rb_user_id
        END) AS new_users
    FROM metro_txns t
    CROSS JOIN params p
    LEFT JOIN user_first_metro f
        ON t.rb_user_id = f.rb_user_id
    WHERE t.event_date_ist >= p.start_ist
      AND t.event_date_ist <  p.today_ist
    GROUP BY 1, 2
),

daily_overall AS (
    SELECT
        t.event_date_ist,
        'Overall' AS metro,
        COUNT(DISTINCT t.tin) AS transactions,
        SUM(t.seats) AS rides_seats,
        COUNT(DISTINCT CASE
            WHEN t.rb_user_id IS NOT NULL AND t.rb_user_id <> 0
            THEN t.rb_user_id
        END) AS unique_users,
        COUNT(DISTINCT CASE
            WHEN f.rb_user_id IS NOT NULL
             AND f.first_date_ist = t.event_date_ist
            THEN f.rb_user_id
        END) AS new_users
    FROM metro_txns t
    CROSS JOIN params p
    LEFT JOIN user_first_metro f
        ON t.rb_user_id = f.rb_user_id
    WHERE t.event_date_ist >= p.start_ist
      AND t.event_date_ist <  p.today_ist
    GROUP BY 1
)

SELECT *
FROM (
    SELECT * FROM daily_overall
    UNION ALL
    SELECT * FROM daily_city
) f
ORDER BY
    event_date_ist,
    CASE metro
        WHEN 'Overall' THEN 0
        WHEN 'Bangalore' THEN 1
        WHEN 'Chennai' THEN 2
        WHEN 'Delhi' THEN 3
        WHEN 'Ernakulam' THEN 4
        WHEN 'Mumbai' THEN 5
        WHEN 'Pune' THEN 6
        ELSE 99
    END;
