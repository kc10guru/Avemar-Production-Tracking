-- Add skipped_stages to repair_orders for inspection-driven workflow
-- Stores an array of stage numbers the inspector determines are not needed
ALTER TABLE repair_orders ADD COLUMN IF NOT EXISTS skipped_stages JSONB DEFAULT '[]';

CREATE INDEX IF NOT EXISTS idx_repair_orders_skipped_stages
  ON repair_orders USING gin (skipped_stages);
