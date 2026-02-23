-- Avemar Production Tracking - Database Schema
-- Run this in Supabase SQL Editor to create all tables

-- 1. Production Parts (windshield part numbers)
CREATE TABLE IF NOT EXISTS production_parts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  part_number TEXT NOT NULL UNIQUE,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Production Stages (the 15-step workflow)
CREATE TABLE IF NOT EXISTS production_stages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  stage_number INTEGER NOT NULL UNIQUE,
  stage_name TEXT NOT NULL,
  required_role TEXT DEFAULT 'admin',
  time_limit_hours INTEGER DEFAULT 24,
  is_active BOOLEAN DEFAULT true
);

-- 3. Repair Orders
CREATE TABLE IF NOT EXISTS repair_orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  ro_number TEXT NOT NULL UNIQUE,
  customer_name TEXT NOT NULL,
  part_number TEXT NOT NULL REFERENCES production_parts(part_number),
  serial_number TEXT NOT NULL,
  aircraft_tail_number TEXT,
  aircraft_type TEXT,
  contract_type TEXT NOT NULL DEFAULT 'Commercial Sales',
  shipping_address TEXT,
  purchase_order TEXT,
  contact_name TEXT,
  contact_email TEXT,
  contact_phone TEXT,
  current_stage INTEGER DEFAULT 1,
  date_received TIMESTAMPTZ DEFAULT now(),
  expected_completion TIMESTAMPTZ,
  date_completed TIMESTAMPTZ,
  status TEXT DEFAULT 'In Progress',
  notes TEXT,
  is_archived BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Stage History (audit trail)
CREATE TABLE IF NOT EXISTS stage_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  repair_order_id UUID NOT NULL REFERENCES repair_orders(id) ON DELETE CASCADE,
  stage_number INTEGER NOT NULL,
  stage_name TEXT NOT NULL,
  entered_at TIMESTAMPTZ DEFAULT now(),
  exited_at TIMESTAMPTZ,
  completed_by UUID,
  notes TEXT,
  is_late BOOLEAN DEFAULT false
);

-- 5. Subcomponents (repair materials inventory)
CREATE TABLE IF NOT EXISTS subcomponents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  part_number TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  category TEXT DEFAULT 'General',
  unit_of_measure TEXT DEFAULT 'each',
  quantity_on_hand NUMERIC DEFAULT 0,
  reorder_point NUMERIC DEFAULT 0,
  reorder_quantity NUMERIC DEFAULT 0,
  lead_time_days INTEGER DEFAULT 14,
  supplier TEXT,
  unit_cost NUMERIC,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 6. Bill of Materials (links windshield parts to subcomponents)
CREATE TABLE IF NOT EXISTS bom_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  production_part_id UUID NOT NULL REFERENCES production_parts(id) ON DELETE CASCADE,
  subcomponent_id UUID NOT NULL REFERENCES subcomponents(id) ON DELETE CASCADE,
  stage_number INTEGER NOT NULL,
  quantity_required NUMERIC NOT NULL DEFAULT 1,
  notes TEXT,
  is_active BOOLEAN DEFAULT true
);

-- 7. Parts Issuance (tracks parts issued to repair orders)
CREATE TABLE IF NOT EXISTS parts_issuance (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  repair_order_id UUID NOT NULL REFERENCES repair_orders(id) ON DELETE CASCADE,
  subcomponent_id UUID NOT NULL REFERENCES subcomponents(id) ON DELETE CASCADE,
  bom_item_id UUID REFERENCES bom_items(id),
  stage_number INTEGER NOT NULL,
  quantity_issued NUMERIC NOT NULL,
  issued_by UUID,
  issued_at TIMESTAMPTZ DEFAULT now(),
  notes TEXT
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_repair_orders_status ON repair_orders(status);
CREATE INDEX IF NOT EXISTS idx_repair_orders_current_stage ON repair_orders(current_stage);
CREATE INDEX IF NOT EXISTS idx_repair_orders_part_number ON repair_orders(part_number);
CREATE INDEX IF NOT EXISTS idx_stage_history_repair_order ON stage_history(repair_order_id);
CREATE INDEX IF NOT EXISTS idx_stage_history_stage_number ON stage_history(stage_number);
CREATE INDEX IF NOT EXISTS idx_bom_items_production_part ON bom_items(production_part_id);
CREATE INDEX IF NOT EXISTS idx_bom_items_subcomponent ON bom_items(subcomponent_id);
CREATE INDEX IF NOT EXISTS idx_parts_issuance_repair_order ON parts_issuance(repair_order_id);
CREATE INDEX IF NOT EXISTS idx_parts_issuance_subcomponent ON parts_issuance(subcomponent_id);

-- Enable Row Level Security
ALTER TABLE production_parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE production_stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE repair_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE stage_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE subcomponents ENABLE ROW LEVEL SECURITY;
ALTER TABLE bom_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE parts_issuance ENABLE ROW LEVEL SECURITY;

-- RLS Policies: allow authenticated users full access
CREATE POLICY "Authenticated users can read production_parts" ON production_parts FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert production_parts" ON production_parts FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update production_parts" ON production_parts FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete production_parts" ON production_parts FOR DELETE TO authenticated USING (true);

CREATE POLICY "Authenticated users can read production_stages" ON production_stages FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert production_stages" ON production_stages FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update production_stages" ON production_stages FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete production_stages" ON production_stages FOR DELETE TO authenticated USING (true);

CREATE POLICY "Authenticated users can read repair_orders" ON repair_orders FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert repair_orders" ON repair_orders FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update repair_orders" ON repair_orders FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete repair_orders" ON repair_orders FOR DELETE TO authenticated USING (true);

CREATE POLICY "Authenticated users can read stage_history" ON stage_history FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert stage_history" ON stage_history FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update stage_history" ON stage_history FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete stage_history" ON stage_history FOR DELETE TO authenticated USING (true);

CREATE POLICY "Authenticated users can read subcomponents" ON subcomponents FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert subcomponents" ON subcomponents FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update subcomponents" ON subcomponents FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete subcomponents" ON subcomponents FOR DELETE TO authenticated USING (true);

CREATE POLICY "Authenticated users can read bom_items" ON bom_items FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert bom_items" ON bom_items FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update bom_items" ON bom_items FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete bom_items" ON bom_items FOR DELETE TO authenticated USING (true);

CREATE POLICY "Authenticated users can read parts_issuance" ON parts_issuance FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert parts_issuance" ON parts_issuance FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update parts_issuance" ON parts_issuance FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete parts_issuance" ON parts_issuance FOR DELETE TO authenticated USING (true);

-- ============================================================
-- SEED DATA
-- ============================================================

-- Seed: 4 windshield part numbers
INSERT INTO production_parts (part_number, description) VALUES
  ('101-384025-21', 'CRJ Windshield Assembly - Dash 21'),
  ('101-384025-22', 'CRJ Windshield Assembly - Dash 22'),
  ('101-384025-23', 'CRJ Windshield Assembly - Dash 23'),
  ('101-384025-24', 'CRJ Windshield Assembly - Dash 24')
ON CONFLICT (part_number) DO NOTHING;

-- Seed: 15 production stages
INSERT INTO production_stages (stage_number, stage_name, required_role, time_limit_hours) VALUES
  (1,  'Receiving',              'receiving',   8),
  (2,  'Document Verification',  'receiving',   8),
  (3,  'Inspection',             'quality',     16),
  (4,  'Disassembly',            'shop_floor',  24),
  (5,  'Cleaning',               'shop_floor',  16),
  (6,  'Polishing',              'shop_floor',  24),
  (7,  'Inspection (Post-Polish)', 'quality',   16),
  (8,  'Heater Installation',    'shop_floor',  24),
  (9,  'Outer Glass Installation','shop_floor',  24),
  (10, 'Cleaning (Pre-Autoclave)','shop_floor',  8),
  (11, 'Autoclave',              'shop_floor',  48),
  (12, 'Testing',                'quality',     24),
  (13, 'Final Inspection',       'quality',     16),
  (14, 'Shipping',               'receiving',   8),
  (15, 'Delivery',               'receiving',   48)
ON CONFLICT (stage_number) DO NOTHING;
