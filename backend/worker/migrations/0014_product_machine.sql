-- Which press a product runs on, and which finishing steps are standard for it.
--
-- Without these two fields a machine's hourly rate is data nobody uses: the
-- engine can price press time, but nothing tells it which machine to price.
ALTER TABLE products ADD COLUMN machine_id TEXT;
ALTER TABLE products ADD COLUMN operation_codes_json TEXT NOT NULL DEFAULT '[]';
