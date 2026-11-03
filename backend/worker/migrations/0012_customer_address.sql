-- A customer's address, for the invoice and for the statement.
--
-- Kept on the customer rather than copied per invoice: the address on an issued
-- invoice is already frozen in `invoices.customer_address`, and re-editing it
-- here must never rewrite a document that has been sent.
ALTER TABLE customers ADD COLUMN address TEXT;
