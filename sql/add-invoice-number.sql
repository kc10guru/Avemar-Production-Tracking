-- Add invoice_number column to repair_orders table
ALTER TABLE repair_orders ADD COLUMN IF NOT EXISTS invoice_number TEXT;
