# SQL-Based AML Transaction Monitoring System
A rule-based transaction monitoring system — the kind used by banks/fintechs to flag suspicious activity — built primarily in SQL, with Python for realistic synthetic data generation and Excel for analyst-style rule documentation.

# The Problem
Financial institutions are legally required to detect and report suspicious transaction patterns (structuring, layering, mule accounts) under AML (Anti-Money Laundering) regulations. Most production systems still rely on rule-based SQL monitoring rather than black-box ML, because rules are explainable and auditable — a regulator can ask "why was this account flagged?" and get a precise answer.
This project builds that kind of system end-to-end: synthetic data with known ground truth → documented detection rules → SQL implementation → validation against the known fraud.

# Data
All data is synthetically generated using Python (faker, numpy, pandas) — no real customer or transaction data is used anywhere in this project.
2,000 customers, 2,500 accounts, ~60,000+ background transactions (realistic lognormal amount distribution)
Three fraud patterns deliberately injected on top, with known "answer key" accounts:
Structuring: 15 accounts, 3–5 transactions each, just under ₹2,00,000
Round-tripping: 10 chains of A→B→C→A, within 7 days
Mule accounts: 10 accounts, 8–12 small deposits followed by one large withdrawal
See "AML_SQL_PROJECT.ipynb" for the full generation logic.

# Rule Book
Before writing any SQL, five detection rules were documented in analyst-style plain language — see excel rule "rule book.xlsb.xlsx" book. Each rule specifies: business description, numeric threshold, detection logic, and the SQL technique required.
Rule Pattern	             SQL Technique
R1	 Structuring	         Window function (rolling 24h count)
R2	 Velocity Spike	       Window function (rolling 90-day average)
R3	 Round-Tripping	3-way  self-join
R4	 Multi-hop Layering	   Recursive CTE
R5	 Mule Account	         GROUP BY + HAVING, time-windowed join
SQL Detection Engine

All 5 rules are implemented as Postgres views, combined into a single account_risk_scorecard view that assigns weighted risk points per account, and packaged into a generate_daily_sar_report() stored function that returns a ranked list of flagged accounts with human-readable rule breakdowns.
Schema, primary/foreign keys, and indexes: /sql/schema_and_constraints.sql.

# Validation Results
Rather than reporting a suspiciously perfect 100% catch rate, each rule was validated against the known injected fraud, and the actual (imperfect) numbers are reported honestly below:

# Rule	Result	Notes
1. R1 Structuring	7 of 15 known accounts caught with full 5-transaction cluster; remainder caught with smaller cluster sizes	Rolling 24-hour window correctly handles bursts spanning midnight
2. R2 Velocity Spike	Initial version flagged ~6,000 day-instances (too noisy) → added a minimum transaction-count filter → dropped to 274 flagged day-instances	Single large-but-legitimate transactions on sparse-activity days were causing false positives
3. R3 Round-Tripping	10 of 10 known chains caught, after two fixes	(1) tolerance threshold was too tight for compounded skimming across 3 hops, (2) a Python indentation bug was silently truncating the data generator to 1 chain instead of 10
4. R4 Multi-hop Layering	29 candidate 4+ hop chains surfaced from background traffic, Initial version (connectivity + timing only) returned 71,950 rows of noise; adding an amount-consistency check across hops brought this down to a realistic number. No ground truth exists for this rule since it operates on organic background traffic, not injected data — these are candidate chains for analyst review, not confirmed fraud
5. R5 Mule Account	9 of 10 known accounts caught	The missed account's deposit burst likely spanned midnight, which day-based grouping (used here for simplicity) doesn't handle — a rolling-window approach like R1's would likely catch it

# Honest limitations:
R2 and R4 operate on the full dataset, not just injected fraud, so their flagged results include real behavioral anomalies without a labeled ground truth to check against.

# Repo Structure
├── AML_SQL_PROJECT.ipynb
├── rule-book/
│   └── rule book.xlsb.xlsx
├── sql/
│   ├── schema_and_constraints.sql
│   ├── rule1_structuring.sql
│   ├── rule2_velocity.sql
│   ├── rule3_roundtripping.sql
│   ├── rule4_layering.sql
│   ├── rule5_mule.sql
│   ├── account_risk_scorecard.sql
│   └── daily_sar_report.sql
└── README.md

# What I'd Do Differently at Scale
In production, this would run as a nightly batch job with alerting rather than ad-hoc queries, and R4's candidate output would route to human analyst review rather than being treated as a final verdict. Rule thresholds (e.g. R1's ₹1.8–2L band, R2's 3x multiplier) would also need periodic recalibration against real false-positive rates, not fixed once and left alone.
