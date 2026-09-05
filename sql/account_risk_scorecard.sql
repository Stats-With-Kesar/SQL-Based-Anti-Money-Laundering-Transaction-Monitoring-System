CREATE VIEW account_risk_scorecard AS
SELECT
    a.account_id,
    c.kyc_risk_rating,
    CASE WHEN r1.from_account_id IS NOT NULL THEN 30 ELSE 0 END AS structuring_score,
    CASE WHEN r2.from_account_id IS NOT NULL THEN 25 ELSE 0 END AS velocity_score,
    CASE WHEN r3.origin_account IS NOT NULL THEN 35 ELSE 0 END AS roundtrip_score,
    CASE WHEN r4.origin_account IS NOT NULL THEN 40 ELSE 0 END AS layering_score,
    CASE WHEN r5.account_id IS NOT NULL THEN 30 ELSE 0 END AS mule_score,
    (
        CASE WHEN r1.from_account_id IS NOT NULL THEN 30 ELSE 0 END +
        CASE WHEN r2.from_account_id IS NOT NULL THEN 25 ELSE 0 END +
        CASE WHEN r3.origin_account IS NOT NULL THEN 35 ELSE 0 END +
        CASE WHEN r4.origin_account IS NOT NULL THEN 40 ELSE 0 END +
        CASE WHEN r5.account_id IS NOT NULL THEN 30 ELSE 0 END
    ) AS total_risk_score
FROM accounts a
JOIN customers c ON a.customer_id = c.customer_id
LEFT JOIN (SELECT DISTINCT from_account_id FROM rule1_structuring) r1 ON a.account_id = r1.from_account_id
LEFT JOIN (SELECT DISTINCT from_account_id FROM rule2_velocity) r2 ON a.account_id = r2.from_account_id
LEFT JOIN (SELECT DISTINCT origin_account FROM rule3_roundtripping) r3 ON a.account_id = r3.origin_account
LEFT JOIN (SELECT DISTINCT origin_account FROM rule4_layering) r4 ON a.account_id = r4.origin_account
LEFT JOIN (SELECT DISTINCT account_id FROM rule5_mule) r5 ON a.account_id = r5.account_id;
SELECT * FROM account_risk_scorecard ORDER BY total_risk_score DESC LIMIT 20;
