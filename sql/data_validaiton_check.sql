SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM accounts;
SELECT COUNT(*) FROM transactions;
SELECT * FROM transactions 
WHERE amount BETWEEN 180000 AND 199000 
LIMIT 10;
