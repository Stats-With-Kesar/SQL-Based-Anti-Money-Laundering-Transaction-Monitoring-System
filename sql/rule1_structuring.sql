CREATE VIEW rule1_structuring AS
WITH flagged AS (
    SELECT
        txn_id,
        from_account_id,
        amount,
        txn_timestamp,
        COUNT(*) OVER (
            PARTITION BY from_account_id
            ORDER BY txn_timestamp
            RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW
        ) AS txns_in_24h
    FROM transactions
    WHERE amount BETWEEN 180000 AND 200000
)
SELECT from_account_id, COUNT(*) AS suspicious_txn_count, MAX(txns_in_24h) AS max_cluster_size
FROM flagged
WHERE txns_in_24h >= 3
GROUP BY from_account_id;
SELECT * FROM rule1_structuring;
