-- Add Hold Feature to Avemar Production Tracking
-- Run this in Supabase SQL Editor

-- Add hold columns to repair_orders
ALTER TABLE repair_orders ADD COLUMN IF NOT EXISTS is_on_hold BOOLEAN DEFAULT false;
ALTER TABLE repair_orders ADD COLUMN IF NOT EXISTS hold_reason TEXT;
ALTER TABLE repair_orders ADD COLUMN IF NOT EXISTS hold_stage INTEGER;
ALTER TABLE repair_orders ADD COLUMN IF NOT EXISTS hold_started_at TIMESTAMPTZ;

-- Hold history table to track all hold/resume events
CREATE TABLE IF NOT EXISTS hold_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  repair_order_id UUID NOT NULL REFERENCES repair_orders(id) ON DELETE CASCADE,
  stage_number INTEGER NOT NULL,
  stage_name TEXT NOT NULL,
  hold_reason TEXT NOT NULL,
  held_by UUID,
  held_at TIMESTAMPTZ DEFAULT now(),
  resumed_by UUID,
  resumed_at TIMESTAMPTZ,
  hold_duration_hours NUMERIC
);

CREATE INDEX IF NOT EXISTS idx_hold_history_repair_order ON hold_history(repair_order_id);

-- RLS Policies for hold_history
ALTER TABLE hold_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read hold_history" ON hold_history FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert hold_history" ON hold_history FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update hold_history" ON hold_history FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete hold_history" ON hold_history FOR DELETE TO authenticated USING (true);
