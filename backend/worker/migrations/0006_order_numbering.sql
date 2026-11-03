-- Order numbering: uniqueness is on the number a customer sees, not the counter.
--
-- 0002 made (tenant, branch, number) unique. That holds for one device with one
-- series, and breaks the moment numbering is per device — `JOB-SHJ1-PC1-00001`
-- and `JOB-SHJ1-PC2-00001` are two different jobs that both allocated 1. The
-- display number carries the branch and the device, so THAT is what must be
-- unique. Caught by the live smoke once the app started using series codes.

DROP INDEX IF EXISTS idx_orders_number;
CREATE UNIQUE INDEX idx_orders_number_display ON orders (tenant_id, number_display);
CREATE INDEX idx_orders_number ON orders (tenant_id, branch_id, number);
