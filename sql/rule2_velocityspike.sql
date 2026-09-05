CREATE VIEW rule2_velocity AS
WITH daily_totals AS (
    SELECT from_account_id, DATE(txn_timestamp) AS txn_date, 
           SUM(amount) AS daily_amount,
           COUNT(*) AS daily_txn_count
    FROM transactions
    GROUP BY from_account_id, DATE(txn_timestamp)
),
with_avg AS (
    SELECT
        from_account_id,
        txn_date,
        daily_amount,
        daily_txn_count,
        AVG(daily_amount) OVER (
            PARTITION BY from_account_id
            ORDER BY txn_date
            ROWS BETWEEN 90 PRECEDING AND 1 PRECEDING
        ) AS historical_avg
    FROM daily_totals
)
SELECT *
FROM with_avg
WHERE historical_avg IS NOT NULL
  AND daily_amount > 3 * historical_avg
  AND daily_txn_count >= 2;
