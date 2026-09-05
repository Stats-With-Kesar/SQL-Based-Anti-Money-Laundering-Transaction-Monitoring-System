CREATE OR REPLACE FUNCTION generate_daily_sar_report()
RETURNS TABLE(account_id INT, total_risk_score INT, flagged_rules TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ars.account_id::INT,
        ars.total_risk_score::INT,
        CONCAT_WS(', ',
            CASE WHEN ars.structuring_score > 0 THEN 'Structuring' END,
            CASE WHEN ars.velocity_score > 0 THEN 'Velocity Spike' END,
            CASE WHEN ars.roundtrip_score > 0 THEN 'Round-Tripping' END,
            CASE WHEN ars.layering_score > 0 THEN 'Layering' END,
            CASE WHEN ars.mule_score > 0 THEN 'Mule Pattern' END
        ) AS flagged_rules
    FROM account_risk_scorecard ars
    WHERE ars.total_risk_score >= 30
    ORDER BY ars.total_risk_score DESC;
END;
$$ LANGUAGE plpgsql;
SELECT * FROM generate_daily_sar_report();
