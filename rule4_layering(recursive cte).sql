CREATE VIEW rule4_layering AS
WITH RECURSIVE money_trail AS (
    SELECT
        from_account_id AS origin_account,
        from_account_id,
        to_account_id,
        amount,
        amount AS origin_amount,
        txn_timestamp,
        1 AS hop_number,
        ARRAY[from_account_id, to_account_id] AS path
    FROM transactions
    WHERE txn_timestamp >= '2025-01-01'

    UNION ALL

    SELECT
        mt.origin_account,
        t.from_account_id,
        t.to_account_id,
        t.amount,
        mt.origin_amount,
        t.txn_timestamp,
        mt.hop_number + 1,
        mt.path || t.to_account_id
    FROM money_trail mt
    JOIN transactions t
        ON mt.to_account_id = t.from_account_id
        AND t.txn_timestamp > mt.txn_timestamp
        AND t.txn_timestamp <= mt.txn_timestamp + INTERVAL '30 days'
        AND t.to_account_id != ALL(mt.path)
        AND t.amount BETWEEN mt.origin_amount * 0.7 AND mt.origin_amount * 1.05
    WHERE mt.hop_number < 6
)
SELECT origin_account, path, hop_number, amount, txn_timestamp
FROM money_trail
WHERE hop_number >= 4;