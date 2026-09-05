CREATE VIEW rule5_mule AS
WITH deposits AS (
    SELECT 
        to_account_id AS account_id,
        DATE(txn_timestamp) AS deposit_day,
        COUNT(*) AS deposit_count,
        SUM(amount) AS total_deposited,
        MAX(txn_timestamp) AS last_deposit_time
    FROM transactions
    WHERE amount < 15000
    GROUP BY to_account_id, DATE(txn_timestamp)
    HAVING COUNT(*) >= 8
),
big_withdrawals AS (
    SELECT from_account_id AS account_id, txn_timestamp, amount AS withdrawal_amount
    FROM transactions
    WHERE amount > 50000
)
SELECT DISTINCT ON (d.account_id, d.deposit_day)
    d.account_id, d.deposit_count, d.total_deposited, b.withdrawal_amount, b.txn_timestamp
FROM deposits d
JOIN big_withdrawals b 
    ON d.account_id = b.account_id
    AND b.txn_timestamp BETWEEN d.last_deposit_time AND d.last_deposit_time + INTERVAL '2 days'
WHERE b.withdrawal_amount > 0.8 * d.total_deposited
ORDER BY d.account_id, d.deposit_day, b.txn_timestamp ASC;
SELECT viewname FROM pg_views WHERE schemaname = 'public';
