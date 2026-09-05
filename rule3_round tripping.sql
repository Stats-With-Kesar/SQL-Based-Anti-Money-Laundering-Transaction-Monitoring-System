CREATE VIEW rule3_roundtripping AS
SELECT
    t1.from_account_id AS origin_account,
    t1.to_account_id AS hop_1,
    t2.to_account_id AS hop_2,
    t1.amount AS original_amount,
    t1.txn_timestamp AS start_time,
    t3.txn_timestamp AS return_time
FROM transactions t1
JOIN transactions t2
    ON t1.to_account_id = t2.from_account_id
    AND t2.txn_timestamp BETWEEN t1.txn_timestamp AND t1.txn_timestamp + INTERVAL '7 days'
JOIN transactions t3
    ON t2.to_account_id = t3.from_account_id
    AND t3.to_account_id = t1.from_account_id
    AND t3.txn_timestamp BETWEEN t2.txn_timestamp AND t1.txn_timestamp + INTERVAL '7 days'
WHERE t3.amount BETWEEN t1.amount * 0.80 AND t1.amount * 1.05;