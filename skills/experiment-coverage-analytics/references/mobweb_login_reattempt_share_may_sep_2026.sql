-- Mobweb users who re-attempted login, by IST calendar month.
-- Window: 2026-05-01 through 2026-09-30 IST (inclusive).
--
-- Definitions:
--   attempted user     = distinct non-null user_id with a Mobweb login-action row
--   re-attempting user = attempted user with at least 2 login-action rows in the month
--   re-attempt event   = every login-action row after a user's first row in the month
--
-- login_datetime is assumed to be UTC. Drop the 330-minute adjustment if it is
-- already stored in IST. Change the two UTC bounds to reuse this query.

WITH login_attempts AS (
  SELECT
    DATE_TRUNC(
      'month',
      l.login_datetime + INTERVAL '330' MINUTE
    ) AS period_start,
    CAST(l.user_id AS VARCHAR) AS user_id
  FROM capi.uid_login_action l
  WHERE l.login_datetime >= TIMESTAMP '2026-04-30 18:30:00'
    AND l.login_datetime <  TIMESTAMP '2026-09-30 18:30:00'
    AND UPPER(l.channel) IN ('MOBILE_WEB', 'MOBWEB', 'MWEB', 'MOB_WEB')
    AND l.user_id IS NOT NULL
    AND TRIM(CAST(l.user_id AS VARCHAR)) NOT IN ('', 'null')
),
attempts_per_user AS (
  SELECT
    period_start,
    user_id,
    COUNT(*) AS attempt_count
  FROM login_attempts
  GROUP BY 1, 2
)
SELECT
  CAST(period_start AS DATE) AS period_start,
  SUM(attempt_count) AS login_attempt_events,
  COUNT(*) AS users_who_attempted_login,
  COUNT_IF(attempt_count >= 2) AS users_who_reattempted_login,
  ROUND(
    100.0 * COUNT_IF(attempt_count >= 2) / NULLIF(COUNT(*), 0),
    2
  ) AS reattempting_users_share_pct,
  SUM(attempt_count - 1) AS reattempt_events,
  ROUND(
    100.0 * SUM(attempt_count - 1) / NULLIF(SUM(attempt_count), 0),
    2
  ) AS reattempt_events_share_pct
FROM attempts_per_user
GROUP BY 1
ORDER BY 1;
